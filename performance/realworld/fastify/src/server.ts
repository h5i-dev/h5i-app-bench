import cluster from "node:cluster"
import bcrypt from "bcrypt"
import Fastify, { type FastifyRequest } from "fastify"
import jwt from "jsonwebtoken"
import postgres from "postgres"
import {
  ApiError,
  BCRYPT_COST,
  type Obj,
  articleCreateFields,
  articleUpdateFields,
  commentBody,
  loginFields,
  pageParams,
  registerFields,
  slugify,
  updateUserFields,
  withSuffix,
} from "./logic.js"

const DATABASE_URL = process.env.DATABASE_URL ?? "postgres://conduit:conduit@127.0.0.1:54329/conduit"
const JWT_SECRET = process.env.JWT_SECRET ?? "conduit-benchmark-secret"
const JWT_TTL = 60 * 24 * 3600
const PORT = Number(process.env.PORT ?? 8003)
const DB_POOL = Number(process.env.DB_POOL ?? 8)
const WORKERS = Number(process.env.WEB_CONCURRENCY ?? 4)

type Row = Record<string, unknown>

interface Db {
  unsafe(query: string, parameters?: unknown[]): Promise<Row[]>
}

const TS = (col: string) =>
  `to_char(${col} AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"')`

function articleSelect(includeBody: boolean): string {
  const body = includeBody ? "a.body," : ""
  return `
SELECT
  a.id,
  a.slug,
  a.title,
  a.description,
  ${body}
  ${TS("a.created_at")} AS created_at,
  ${TS("a.updated_at")} AS updated_at,
  u.username AS author_username,
  u.bio AS author_bio,
  u.image AS author_image,
  (SELECT count(*)::int FROM favorites f WHERE f.article_id = a.id) AS favorites_count,
  EXISTS(SELECT 1 FROM favorites f WHERE f.article_id = a.id AND f.user_id = $1) AS favorited,
  EXISTS(SELECT 1 FROM follows fl WHERE fl.follower_id = $1 AND fl.followee_id = a.author_id) AS following,
  COALESCE(
    (SELECT array_agg(t.name ORDER BY at.position)
     FROM article_tags at
     JOIN tags t ON t.id = at.tag_id
     WHERE at.article_id = a.id),
    ARRAY[]::text[]
  ) AS tag_list
FROM articles a
JOIN users u ON u.id = a.author_id`
}

function idOf(v: unknown): number {
  const n = typeof v === "number" ? v : Number(v)
  if (!Number.isFinite(n)) throw new Error("bad id")
  return n
}

function textOrNull(v: unknown): string | null {
  if (v === null || v === undefined) return null
  return String(v)
}

function asBool(v: unknown): boolean {
  return v === true
}

function asTags(v: unknown): string[] {
  if (!Array.isArray(v)) return []
  return v.map((item) => String(item))
}

function asInt(v: unknown): number {
  const n = typeof v === "number" ? v : Number(v)
  if (!Number.isFinite(n)) return 0
  return n
}

function conflictFrom(err: unknown, fallback: string): ApiError | null {
  if (typeof err !== "object" || err === null) return null
  const e = err as { code?: string; constraint_name?: string }
  if (e.code !== "23505") return null
  const name = e.constraint_name ?? ""
  if (name.includes("username")) return new ApiError(409, "username", "has already been taken")
  if (name.includes("email")) return new ApiError(409, "email", "has already been taken")
  if (name.includes("slug")) return new ApiError(409, "slug", "has already been taken")
  return new ApiError(409, fallback, "has already been taken")
}

function readObject(body: unknown, key: string): Obj {
  if (body === null || typeof body !== "object" || Array.isArray(body)) {
    throw new ApiError(422, key, "is invalid")
  }
  const obj = (body as Obj)[key]
  if (obj === null || typeof obj !== "object" || Array.isArray(obj)) {
    throw new ApiError(422, key, "is invalid")
  }
  return obj as Obj
}

function queryValue(query: unknown, key: string): string {
  if (query === null || typeof query !== "object") return ""
  const v = (query as Record<string, unknown>)[key]
  if (v === undefined || v === null) return ""
  if (Array.isArray(v)) return v.length ? String(v[0]) : ""
  return String(v)
}

function queryPresent(query: unknown, key: string): string | undefined {
  if (query === null || typeof query !== "object") return undefined
  const bag = query as Record<string, unknown>
  if (!Object.prototype.hasOwnProperty.call(bag, key)) return undefined
  return queryValue(query, key)
}

function userJSON(row: Row, token: string) {
  return {
    email: String(row.email),
    token,
    username: String(row.username),
    bio: textOrNull(row.bio),
    image: textOrNull(row.image),
  }
}

function profileJSON(username: string, bio: string | null, image: string | null, following: boolean) {
  return { username, bio, image, following }
}

function articleJSON(row: Row, includeBody: boolean) {
  const out: Record<string, unknown> = {
    slug: String(row.slug),
    title: String(row.title),
    description: String(row.description),
    tagList: asTags(row.tag_list),
    createdAt: String(row.created_at),
    updatedAt: String(row.updated_at),
    favorited: asBool(row.favorited),
    favoritesCount: asInt(row.favorites_count),
    author: profileJSON(
      String(row.author_username),
      textOrNull(row.author_bio),
      textOrNull(row.author_image),
      asBool(row.following),
    ),
  }
  if (includeBody) out.body = String(row.body)
  return out
}

function commentJSON(row: Row) {
  return {
    id: idOf(row.id),
    createdAt: String(row.created_at),
    updatedAt: String(row.updated_at),
    body: String(row.body),
    author: profileJSON(
      String(row.author_username),
      textOrNull(row.author_bio),
      textOrNull(row.author_image),
      asBool(row.following),
    ),
  }
}

async function serve(): Promise<void> {
  const sql = postgres(DATABASE_URL, {
    max: DB_POOL,
    idle_timeout: 30,
    connect_timeout: 10,
    connection: { application_name: "conduit-fastify" },
  })
  const db = sql as unknown as Db & {
    begin<T>(fn: (tx: Db) => Promise<T>): Promise<T>
  }
  const dummy = await bcrypt.hash("dummy-password-for-timing", BCRYPT_COST)

  const app = Fastify({ logger: false })

  app.setErrorHandler((err, request, reply) => {
    if (err instanceof ApiError) {
      return reply.code(err.status).send({ errors: { [err.field]: [err.message] } })
    }
    const code = (err as { code?: string }).code
    if (code === "FST_ERR_CTP_INVALID_JSON_BODY" || code === "FST_ERR_CTP_EMPTY_JSON_BODY") {
      return reply.code(422).send({ errors: { body: ["is invalid"] } })
    }
    request.log.error(err)
    console.error(err)
    return reply.code(500).send({ errors: { server: ["error"] } })
  })

  function signToken(userId: number): string {
    return jwt.sign({ sub: String(userId) }, JWT_SECRET, { algorithm: "HS256", expiresIn: JWT_TTL })
  }

  function userID(request: FastifyRequest, required: boolean): number {
    const header = request.headers.authorization
    if (header === undefined || header.trim() === "") {
      if (required) throw new ApiError(401, "token", "is missing")
      return 0
    }
    if (!header.startsWith("Token ")) throw new ApiError(401, "token", "is invalid")
    const raw = header.slice("Token ".length).trim()
    if (raw === "") throw new ApiError(401, "token", "is invalid")
    try {
      const payload = jwt.verify(raw, JWT_SECRET, { algorithms: ["HS256"] })
      if (typeof payload === "string" || payload.sub === undefined) {
        throw new ApiError(401, "token", "is invalid")
      }
      const uid = Number(payload.sub)
      if (!Number.isInteger(uid) || uid <= 0) throw new ApiError(401, "token", "is invalid")
      return uid
    } catch (err) {
      if (err instanceof ApiError) throw err
      throw new ApiError(401, "token", "is invalid")
    }
  }

  async function one(database: Db, query: string, params: unknown[]): Promise<Row | null> {
    const rows = await database.unsafe(query, params)
    return rows.length ? rows[0] : null
  }

  async function loadUser(database: Db, uid: number): Promise<Row> {
    const row = await one(
      database,
      "SELECT id, username, email, bio, image, password_hash FROM users WHERE id = $1",
      [uid],
    )
    if (!row) throw new ApiError(401, "token", "is invalid")
    return row
  }

  async function isFollowing(database: Db, viewer: number, author: number): Promise<boolean> {
    if (viewer <= 0) return false
    const row = await one(
      database,
      "SELECT EXISTS(SELECT 1 FROM follows WHERE follower_id = $1 AND followee_id = $2) AS following",
      [viewer, author],
    )
    return asBool(row?.following)
  }

  async function addTags(database: Db, articleId: number, tags: string[]): Promise<void> {
    for (let pos = 0; pos < tags.length; pos++) {
      const rows = await database.unsafe(
        `INSERT INTO tags (name) VALUES ($1)
         ON CONFLICT (name) DO UPDATE SET name = EXCLUDED.name
         RETURNING id`,
        [tags[pos]],
      )
      await database.unsafe(
        "INSERT INTO article_tags (article_id, tag_id, position) VALUES ($1, $2, $3)",
        [articleId, idOf(rows[0].id), pos],
      )
    }
  }

  async function uniqueSlug(database: Db, title: string, excludeId: number | null): Promise<string> {
    const base = slugify(title)
    for (let n = 0; n < 100000; n++) {
      const slug = withSuffix(base, n)
      const row = await one(database, "SELECT id FROM articles WHERE slug = $1", [slug])
      if (!row || (excludeId !== null && idOf(row.id) === excludeId)) return slug
    }
    throw new ApiError(409, "slug", "has already been taken")
  }

  async function fetchArticle(database: Db, viewer: number, slug: string, includeBody: boolean): Promise<Row | null> {
    return one(database, `${articleSelect(includeBody)} WHERE a.slug = $2`, [viewer, slug])
  }

  function listFilters(viewer: number, tag?: string, author?: string, favorited?: string, feed = false) {
    const args: unknown[] = [viewer]
    const conds = ["$1::bigint >= 0"]
    const bind = (value: unknown) => {
      args.push(value)
      return `$${args.length}`
    }
    if (feed) {
      conds.push(
        "EXISTS (SELECT 1 FROM follows fl WHERE fl.follower_id = $1 AND fl.followee_id = a.author_id)",
      )
    }
    if (tag !== undefined) {
      const ph = bind(tag)
      conds.push(
        `EXISTS (SELECT 1 FROM article_tags at JOIN tags t ON t.id = at.tag_id WHERE at.article_id = a.id AND t.name = ${ph})`,
      )
    }
    if (author !== undefined) conds.push(`u.username = ${bind(author)}`)
    if (favorited !== undefined) {
      const ph = bind(favorited)
      conds.push(
        `EXISTS (SELECT 1 FROM favorites fv JOIN users fu ON fu.id = fv.user_id WHERE fv.article_id = a.id AND fu.username = ${ph})`,
      )
    }
    return { where: ` WHERE ${conds.join(" AND ")}`, args }
  }

  app.get("/healthz", async () => {
    await db.unsafe("SELECT 1")
    return { ok: true }
  })

  app.post("/api/users", async (request, reply) => {
    const { username, email, password } = registerFields(readObject(request.body, "user"))
    const passwordHash = await bcrypt.hash(password, BCRYPT_COST)
    const taken = await one(db, "SELECT username, email FROM users WHERE username = $1 OR email = $2", [
      username,
      email,
    ])
    if (taken) {
      if (String(taken.username) === username) throw new ApiError(409, "username", "has already been taken")
      throw new ApiError(409, "email", "has already been taken")
    }
    let row: Row | null
    try {
      row = await one(
        db,
        `INSERT INTO users (username, email, password_hash)
         VALUES ($1, $2, $3)
         RETURNING id, username, email, bio, image`,
        [username, email, passwordHash],
      )
    } catch (err) {
      const conflict = conflictFrom(err, "username")
      if (conflict) throw conflict
      throw err
    }
    if (!row) throw new Error("insert returned no row")
    return reply.code(201).send({ user: userJSON(row, signToken(idOf(row.id))) })
  })

  app.post("/api/users/login", async (request) => {
    const { email, password } = loginFields(readObject(request.body, "user"))
    const row = await one(
      db,
      "SELECT id, username, email, bio, image, password_hash FROM users WHERE email = $1",
      [email],
    )
    const hash = row ? String(row.password_hash) : dummy
    const ok = await bcrypt.compare(password, hash)
    if (!row || !ok) throw new ApiError(401, "credentials", "invalid")
    return { user: userJSON(row, signToken(idOf(row.id))) }
  })

  app.get("/api/user", async (request) => {
    const uid = userID(request, true)
    const row = await loadUser(db, uid)
    return { user: userJSON(row, signToken(idOf(row.id))) }
  })

  app.put("/api/user", async (request) => {
    const uid = userID(request, true)
    const fields = updateUserFields(readObject(request.body, "user"))
    let passwordHash = ""
    if (fields.password.kind === "set") passwordHash = await bcrypt.hash(fields.password.val, BCRYPT_COST)
    const updated = await db.begin(async (tx) => {
      await loadUser(tx, uid)
      if (fields.username.kind === "set") {
        const clash = await one(tx, "SELECT 1 FROM users WHERE username = $1 AND id <> $2", [
          fields.username.val,
          uid,
        ])
        if (clash) throw new ApiError(409, "username", "has already been taken")
      }
      if (fields.email.kind === "set") {
        const clash = await one(tx, "SELECT 1 FROM users WHERE email = $1 AND id <> $2", [fields.email.val, uid])
        if (clash) throw new ApiError(409, "email", "has already been taken")
      }
      const sets: string[] = []
      const args: unknown[] = []
      const bind = (column: string, value: unknown) => {
        args.push(value)
        sets.push(`${column} = $${args.length}`)
      }
      if (fields.username.kind === "set") bind("username", fields.username.val)
      if (fields.email.kind === "set") bind("email", fields.email.val)
      if (fields.password.kind === "set") bind("password_hash", passwordHash)
      if (fields.bio.kind === "set") bind("bio", fields.bio.val)
      else if (fields.bio.kind === "clear") sets.push("bio = NULL")
      if (fields.image.kind === "set") bind("image", fields.image.val)
      else if (fields.image.kind === "clear") sets.push("image = NULL")
      args.push(uid)
      try {
        const row = await one(
          tx,
          `UPDATE users SET ${sets.join(", ")} WHERE id = $${args.length}
           RETURNING id, username, email, bio, image`,
          args,
        )
        if (!row) throw new Error("update returned no row")
        return row
      } catch (err) {
        const conflict = conflictFrom(err, "username")
        if (conflict) throw conflict
        throw err
      }
    })
    return { user: userJSON(updated, signToken(idOf(updated.id))) }
  })

  app.get("/api/profiles/:username", async (request) => {
    const viewer = userID(request, false)
    if (viewer > 0) await loadUser(db, viewer)
    const username = (request.params as { username: string }).username
    const row = await one(
      db,
      `SELECT id, username, bio, image,
         EXISTS(SELECT 1 FROM follows WHERE follower_id = $1 AND followee_id = users.id) AS following
       FROM users WHERE username = $2`,
      [viewer, username],
    )
    if (!row) throw new ApiError(404, "profile", "not found")
    return {
      profile: profileJSON(String(row.username), textOrNull(row.bio), textOrNull(row.image), asBool(row.following)),
    }
  })

  async function setFollow(request: FastifyRequest, follow: boolean) {
    const uid = userID(request, true)
    const username = (request.params as { username: string }).username
    const target = await db.begin(async (tx) => {
      await loadUser(tx, uid)
      const row = await one(tx, "SELECT id, username, bio, image FROM users WHERE username = $1", [username])
      if (!row) throw new ApiError(404, "profile", "not found")
      if (follow) {
        await tx.unsafe(
          "INSERT INTO follows (follower_id, followee_id) VALUES ($1, $2) ON CONFLICT DO NOTHING",
          [uid, idOf(row.id)],
        )
      } else {
        await tx.unsafe("DELETE FROM follows WHERE follower_id = $1 AND followee_id = $2", [uid, idOf(row.id)])
      }
      return row
    })
    return {
      profile: profileJSON(String(target.username), textOrNull(target.bio), textOrNull(target.image), follow),
    }
  }

  app.post("/api/profiles/:username/follow", async (request) => setFollow(request, true))
  app.delete("/api/profiles/:username/follow", async (request) => setFollow(request, false))

  async function listArticles(request: FastifyRequest, viewer: number, feed: boolean) {
    const { limit, offset } = pageParams(queryValue(request.query, "limit"), queryValue(request.query, "offset"))
    const tag = feed ? undefined : queryPresent(request.query, "tag")
    const author = feed ? undefined : queryPresent(request.query, "author")
    const favorited = feed ? undefined : queryPresent(request.query, "favorited")
    const { where, args } = listFilters(viewer, tag, author, favorited, feed)
    const countArgs = args.slice()
    args.push(limit)
    const limitPh = `$${args.length}`
    args.push(offset)
    const offsetPh = `$${args.length}`
    if (viewer > 0) await loadUser(db, viewer)
    const rows = await db.unsafe(
      `${articleSelect(false)}${where} ORDER BY a.created_at DESC, a.id DESC LIMIT ${limitPh} OFFSET ${offsetPh}`,
      args,
    )
    const countRows = await db.unsafe(
      `SELECT count(*)::int AS n FROM articles a JOIN users u ON u.id = a.author_id${where}`,
      countArgs,
    )
    return {
      articles: rows.map((row) => articleJSON(row, false)),
      articlesCount: asInt(countRows[0]?.n),
    }
  }

  app.get("/api/articles/feed", async (request) => listArticles(request, userID(request, true), true))
  app.get("/api/articles", async (request) => listArticles(request, userID(request, false), false))

  app.post("/api/articles", async (request, reply) => {
    const uid = userID(request, true)
    const { title, description, body, tags } = articleCreateFields(readObject(request.body, "article"))
    const author = await loadUser(db, uid)
    let created: { id: number; slug: string; created_at: string; updated_at: string } | null = null
    for (let attempt = 0; attempt < 8; attempt++) {
      const slug = await uniqueSlug(db, title, null)
      try {
        created = await db.begin(async (tx) => {
          const row = await one(
            tx,
            `INSERT INTO articles (author_id, slug, title, description, body)
             VALUES ($1, $2, $3, $4, $5)
             RETURNING id, ${TS("created_at")} AS created_at, ${TS("updated_at")} AS updated_at`,
            [uid, slug, title, description, body],
          )
          if (!row) throw new Error("insert returned no row")
          await addTags(tx, idOf(row.id), tags)
          return {
            id: idOf(row.id),
            slug,
            created_at: String(row.created_at),
            updated_at: String(row.updated_at),
          }
        })
        break
      } catch (err) {
        if (conflictFrom(err, "slug")) continue
        throw err
      }
    }
    if (!created) throw new ApiError(409, "slug", "has already been taken")
    const following = await isFollowing(db, uid, uid)
    return reply.code(201).send({
      article: {
        slug: created.slug,
        title,
        description,
        body,
        tagList: tags,
        createdAt: created.created_at,
        updatedAt: created.updated_at,
        favorited: false,
        favoritesCount: 0,
        author: profileJSON(
          String(author.username),
          textOrNull(author.bio),
          textOrNull(author.image),
          following,
        ),
      },
    })
  })

  app.get("/api/articles/:slug", async (request) => {
    const viewer = userID(request, false)
    if (viewer > 0) await loadUser(db, viewer)
    const slug = (request.params as { slug: string }).slug
    const row = await fetchArticle(db, viewer, slug, true)
    if (!row) throw new ApiError(404, "article", "not found")
    return { article: articleJSON(row, true) }
  })

  app.put("/api/articles/:slug", async (request) => {
    const uid = userID(request, true)
    const fields = articleUpdateFields(readObject(request.body, "article"))
    const slug = (request.params as { slug: string }).slug
    const freshSlug = await db.begin(async (tx) => {
      await loadUser(tx, uid)
      const current = await one(tx, "SELECT id, author_id FROM articles WHERE slug = $1", [slug])
      if (!current) throw new ApiError(404, "article", "not found")
      if (idOf(current.author_id) !== uid) throw new ApiError(403, "article", "forbidden")
      const sets = ["updated_at = GREATEST(statement_timestamp(), updated_at + interval '1 millisecond')"]
      const args: unknown[] = []
      const bind = (column: string, value: unknown) => {
        args.push(value)
        sets.push(`${column} = $${args.length}`)
      }
      if (fields.title.kind === "set") {
        const newSlug = await uniqueSlug(tx, fields.title.val, idOf(current.id))
        bind("title", fields.title.val)
        bind("slug", newSlug)
      }
      if (fields.description.kind === "set") bind("description", fields.description.val)
      if (fields.body.kind === "set") bind("body", fields.body.val)
      args.push(idOf(current.id))
      try {
        await tx.unsafe(`UPDATE articles SET ${sets.join(", ")} WHERE id = $${args.length}`, args)
      } catch (err) {
        const conflict = conflictFrom(err, "slug")
        if (conflict) throw conflict
        throw err
      }
      if (fields.tags.kind === "replace") {
        await tx.unsafe("DELETE FROM article_tags WHERE article_id = $1", [idOf(current.id)])
        await addTags(tx, idOf(current.id), fields.tags.tags)
      }
      const fresh = await one(tx, "SELECT slug FROM articles WHERE id = $1", [idOf(current.id)])
      if (!fresh) throw new Error("updated article disappeared")
      return String(fresh.slug)
    })
    const row = await fetchArticle(db, uid, freshSlug, true)
    if (!row) throw new ApiError(404, "article", "not found")
    return { article: articleJSON(row, true) }
  })

  app.delete("/api/articles/:slug", async (request, reply) => {
    const uid = userID(request, true)
    await loadUser(db, uid)
    const slug = (request.params as { slug: string }).slug
    const current = await one(db, "SELECT id, author_id FROM articles WHERE slug = $1", [slug])
    if (!current) throw new ApiError(404, "article", "not found")
    if (idOf(current.author_id) !== uid) throw new ApiError(403, "article", "forbidden")
    await db.unsafe("DELETE FROM articles WHERE id = $1", [idOf(current.id)])
    return reply.code(204).send()
  })

  app.get("/api/articles/:slug/comments", async (request) => {
    const viewer = userID(request, false)
    if (viewer > 0) await loadUser(db, viewer)
    const slug = (request.params as { slug: string }).slug
    const article = await one(db, "SELECT id FROM articles WHERE slug = $1", [slug])
    if (!article) throw new ApiError(404, "article", "not found")
    const rows = await db.unsafe(
      `SELECT c.id, c.body,
         ${TS("c.created_at")} AS created_at,
         ${TS("c.updated_at")} AS updated_at,
         u.username AS author_username,
         u.bio AS author_bio,
         u.image AS author_image,
         EXISTS(
           SELECT 1 FROM follows fl
           WHERE fl.follower_id = $1 AND fl.followee_id = c.author_id
         ) AS following
       FROM comments c
       JOIN users u ON u.id = c.author_id
       WHERE c.article_id = $2
       ORDER BY c.created_at ASC, c.id ASC`,
      [viewer, idOf(article.id)],
    )
    return { comments: rows.map(commentJSON) }
  })

  app.post("/api/articles/:slug/comments", async (request, reply) => {
    const uid = userID(request, true)
    const body = commentBody(readObject(request.body, "comment"))
    const author = await loadUser(db, uid)
    const slug = (request.params as { slug: string }).slug
    const article = await one(db, "SELECT id FROM articles WHERE slug = $1", [slug])
    if (!article) throw new ApiError(404, "article", "not found")
    const row = await one(
      db,
      `INSERT INTO comments (article_id, author_id, body)
       VALUES ($1, $2, $3)
       RETURNING id, ${TS("created_at")} AS created_at, ${TS("updated_at")} AS updated_at`,
      [idOf(article.id), uid, body],
    )
    if (!row) throw new Error("insert returned no row")
    const following = await isFollowing(db, uid, uid)
    return reply.code(201).send({
      comment: {
        id: idOf(row.id),
        createdAt: String(row.created_at),
        updatedAt: String(row.updated_at),
        body,
        author: profileJSON(String(author.username), textOrNull(author.bio), textOrNull(author.image), following),
      },
    })
  })

  app.delete("/api/articles/:slug/comments/:commentId", async (request, reply) => {
    const uid = userID(request, true)
    const params = request.params as { slug: string; commentId: string }
    if (!/^[0-9]+$/.test(params.commentId)) throw new ApiError(422, "comment", "is invalid")
    const commentId = Number(params.commentId)
    await loadUser(db, uid)
    const article = await one(db, "SELECT id FROM articles WHERE slug = $1", [params.slug])
    if (!article) throw new ApiError(404, "article", "not found")
    const comment = await one(db, "SELECT id, author_id FROM comments WHERE id = $1 AND article_id = $2", [
      commentId,
      idOf(article.id),
    ])
    if (!comment) throw new ApiError(404, "comment", "not found")
    if (idOf(comment.author_id) !== uid) throw new ApiError(403, "comment", "forbidden")
    await db.unsafe("DELETE FROM comments WHERE id = $1", [commentId])
    return reply.code(204).send()
  })

  async function setFavorite(request: FastifyRequest, on: boolean) {
    const uid = userID(request, true)
    const slug = (request.params as { slug: string }).slug
    await db.begin(async (tx) => {
      await loadUser(tx, uid)
      const article = await one(tx, "SELECT id FROM articles WHERE slug = $1", [slug])
      if (!article) throw new ApiError(404, "article", "not found")
      if (on) {
        await tx.unsafe(
          "INSERT INTO favorites (user_id, article_id) VALUES ($1, $2) ON CONFLICT DO NOTHING",
          [uid, idOf(article.id)],
        )
      } else {
        await tx.unsafe("DELETE FROM favorites WHERE user_id = $1 AND article_id = $2", [uid, idOf(article.id)])
      }
    })
    const row = await fetchArticle(db, uid, slug, true)
    if (!row) throw new ApiError(404, "article", "not found")
    return { article: articleJSON(row, true) }
  }

  app.post("/api/articles/:slug/favorite", async (request) => setFavorite(request, true))
  app.delete("/api/articles/:slug/favorite", async (request) => setFavorite(request, false))

  app.get("/api/tags", async () => {
    const rows = await db.unsafe("SELECT name FROM tags ORDER BY name ASC")
    return { tags: rows.map((row) => String(row.name)) }
  })

  const shutdown = async () => {
    try {
      await app.close()
    } catch {
      /* already closed */
    }
    try {
      await sql.end({ timeout: 2 })
    } catch {
      /* pool already ended */
    }
    process.exit(0)
  }
  process.on("SIGTERM", () => void shutdown())
  process.on("SIGINT", () => void shutdown())

  await app.listen({ host: "127.0.0.1", port: PORT })
  console.error(`listening on 127.0.0.1:${PORT} pool=${DB_POOL}`)
}

async function main(): Promise<void> {
  if (cluster.isPrimary && WORKERS > 1) {
    for (let i = 0; i < WORKERS; i++) cluster.fork()
    cluster.on("exit", (worker, code, signal) => {
      console.error(`worker ${worker.process.pid} exited code=${code} signal=${signal}`)
      cluster.fork()
    })
    return
  }
  await serve()
}

main().catch((err) => {
  console.error(err)
  process.exit(1)
})
