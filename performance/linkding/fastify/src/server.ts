import cluster from "node:cluster"
import Fastify, { type FastifyReply, type FastifyRequest } from "fastify"
import postgres from "postgres"
import {
  authDetail,
  classifyAuth,
  jsonDetail,
  pyTypeName,
  validateBookmark,
  validateBundle,
  validateTag,
} from "./logic.js"
import {
  createBookmark,
  createBundle,
  createTag,
  deleteBookmark,
  deleteBundle,
  deleteTag,
  findExisting,
  getBundle,
  getOwned,
  getTag,
  listBookmarks,
  listBundles,
  listTags,
  loadUser,
  profileJSON,
  serialize,
  setArchived,
  tagJSON,
  bundleJSON,
  updateBookmark,
  updateBundle,
  type Sql,
  type User,
} from "./db.js"

const DATABASE_URL = process.env.DATABASE_URL ?? "postgres://linkding:linkding@127.0.0.1:5440/linkding"
const PORT = Number(process.env.PORT ?? 8103)
const DB_POOL = Number(process.env.DB_POOL ?? 8)
const WORKERS = Number(process.env.WEB_CONCURRENCY ?? 4)

const sql = postgres(DATABASE_URL, {
  max: DB_POOL,
  idle_timeout: 30,
  connect_timeout: 10,
  types: {
    int8: {
      to: 20,
      from: [20],
      serialize: (value: number | string) => String(value),
      parse: (value: string) => Number(value),
    },
  },
  connection: { TimeZone: "UTC" },
}) as unknown as Sql

function send(reply: FastifyReply, status: number, payload: unknown, headers?: Record<string, string>) {
  if (headers) {
    for (const [key, value] of Object.entries(headers)) reply.header(key, value)
  }
  return reply.code(status).send(payload)
}

function notFound(reply: FastifyReply, kind: string) {
  const message =
    kind === "tag"
      ? "No Tag matches the given query."
      : kind === "bundle"
        ? "No BookmarkBundle matches the given query."
        : "No Bookmark matches the given query."
  return send(reply, 404, { detail: message })
}

async function authenticate(request: FastifyRequest, reply: FastifyReply, required: boolean): Promise<User | null | undefined> {
  const [kind, token] = classifyAuth(request.headers.authorization)
  if (kind === "absent") {
    if (required) {
      send(reply, 401, { detail: authDetail(kind) }, { "WWW-Authenticate": "Token" })
      return undefined
    }
    return null
  }
  if (kind !== "token") {
    send(reply, 401, { detail: authDetail(kind) }, { "WWW-Authenticate": "Token" })
    return undefined
  }
  const user = await loadUser(sql, token)
  if (!user) {
    send(reply, 401, { detail: authDetail("bad") }, { "WWW-Authenticate": "Token" })
    return undefined
  }
  return user
}

function queryMap(request: FastifyRequest): Record<string, string | undefined> {
  const out: Record<string, string | undefined> = {}
  const query = request.query as Record<string, unknown>
  for (const [key, value] of Object.entries(query)) {
    if (Array.isArray(value)) out[key] = String(value[value.length - 1])
    else if (value !== undefined) out[key] = String(value)
  }
  return out
}

function requestURL(request: FastifyRequest): string {
  return "http://" + request.headers.host + request.url
}

function pathID(raw: string): number | null {
  if (!/^\d+$/.test(raw)) return null
  return Number(raw)
}

function readBody(request: FastifyRequest, reply: FastifyReply): Record<string, unknown> | undefined {
  const header = request.headers["content-type"] ?? ""
  const media = header.split(";")[0]!.trim().toLowerCase()
  if (media === "") return {}
  if (media !== "application/json") {
    send(reply, 415, { detail: `Unsupported media type "${media}" in request.` })
    return undefined
  }
  const raw = typeof request.body === "string" ? request.body : ""
  if (raw === "") return {}
  let value: unknown
  try {
    value = JSON.parse(raw)
  } catch {
    send(reply, 400, { detail: jsonDetail(raw) })
    return undefined
  }
  if (value === null) {
    send(reply, 400, { non_field_errors: ["No data provided"] })
    return undefined
  }
  if (!value || typeof value !== "object" || Array.isArray(value)) {
    send(reply, 400, { non_field_errors: [`Invalid data. Expected a dictionary, but got ${pyTypeName(value)}.`] })
    return undefined
  }
  return value as Record<string, unknown>
}

async function build() {
  const app = Fastify({ logger: false })
  app.removeAllContentTypeParsers()
  app.addContentTypeParser("*", { parseAs: "string" }, (_request, body, done) => done(null, body))
  app.get("/healthz", async () => {
    await sql.unsafe("SELECT 1")
    return "ok"
  })
  app.get("/api/user/profile/", async (request, reply) => {
    const user = await authenticate(request, reply, true)
    if (!user) return
    return send(reply, 200, profileJSON(user))
  })
  for (const method of ["put", "patch", "post", "delete"] as const) {
    app[method]("/api/user/profile/", async (request, reply) => {
      return send(reply, 405, { detail: `Method "${request.method}" not allowed.` }, { Allow: "GET, HEAD, OPTIONS" })
    })
  }
  const list = (kind: string, required: boolean) => async (request: FastifyRequest, reply: FastifyReply) => {
    const user = await authenticate(request, reply, required)
    if (user === undefined) return
    const payload = await listBookmarks(sql, kind, user, user === null, requestURL(request), queryMap(request))
    return send(reply, 200, payload)
  }
  app.get("/api/bookmarks/", list("active", true))
  app.get("/api/bookmarks/archived/", list("archived", true))
  app.get("/api/bookmarks/shared/", list("shared", false))
  app.post("/api/bookmarks/", async (request, reply) => {
    const user = await authenticate(request, reply, true)
    if (!user) return
    const data = readBody(request, reply)
    if (!data) return
    const [errors, cleaned] = validateBookmark(data, false)
    if (Object.keys(errors).length) return send(reply, 400, errors)
    const row = await createBookmark(sql, user.id, cleaned)
    return send(reply, 201, await serialize(sql, row), { Location: String(row.url) })
  })
  app.get("/api/bookmarks/check/", async (request, reply) => {
    const user = await authenticate(request, reply, true)
    if (!user) return
    const qp = queryMap(request)
    let bookmark: unknown = null
    let metaURL: unknown = null
    if ("url" in (request.query as object)) {
      metaURL = qp.url ?? ""
      const row = await findExisting(sql, user.id, String(qp.url ?? ""))
      if (row) bookmark = await serialize(sql, row)
    }
    return send(reply, 200, {
      bookmark,
      metadata: { url: metaURL, title: null, description: null, preview_image: null },
      auto_tags: [],
    })
  })
  app.get("/api/bookmarks/:id/", async (request, reply) => {
    const user = await authenticate(request, reply, true)
    if (!user) return
    const id = pathID((request.params as { id: string }).id)
    if (id === null) return notFound(reply, "bookmark")
    const row = await getOwned(sql, user.id, id)
    if (!row) return notFound(reply, "bookmark")
    return send(reply, 200, await serialize(sql, row))
  })
  const write = async (request: FastifyRequest, reply: FastifyReply) => {
    const user = await authenticate(request, reply, true)
    if (!user) return
    const id = pathID((request.params as { id: string }).id)
    if (id === null) return notFound(reply, "bookmark")
    if (!(await getOwned(sql, user.id, id))) return notFound(reply, "bookmark")
    const data = readBody(request, reply)
    if (!data) return
    const [errors, cleaned] = validateBookmark(data, request.method === "PATCH")
    if (Object.keys(errors).length) return send(reply, 400, errors)
    const [row, problem] = await updateBookmark(sql, user.id, id, cleaned)
    if (problem === "duplicate") return send(reply, 400, { url: ["A bookmark with this URL already exists."] })
    if (!row) return notFound(reply, "bookmark")
    return send(reply, 200, await serialize(sql, row))
  }
  app.put("/api/bookmarks/:id/", write)
  app.patch("/api/bookmarks/:id/", write)
  app.delete("/api/bookmarks/:id/", async (request, reply) => {
    const user = await authenticate(request, reply, true)
    if (!user) return
    const id = pathID((request.params as { id: string }).id)
    if (id === null) return notFound(reply, "bookmark")
    if (!(await deleteBookmark(sql, user.id, id))) return notFound(reply, "bookmark")
    return reply.code(204).send()
  })
  const archive = (archived: boolean) => async (request: FastifyRequest, reply: FastifyReply) => {
    const user = await authenticate(request, reply, true)
    if (!user) return
    const id = pathID((request.params as { id: string }).id)
    if (id === null) return notFound(reply, "bookmark")
    if (!(await setArchived(sql, user.id, id, archived))) return notFound(reply, "bookmark")
    return reply.code(204).send()
  }
  app.post("/api/bookmarks/:id/archive/", archive(true))
  app.post("/api/bookmarks/:id/unarchive/", archive(false))
  app.get("/api/tags/", async (request, reply) => {
    const user = await authenticate(request, reply, true)
    if (!user) return
    return send(reply, 200, await listTags(sql, user.id, requestURL(request), queryMap(request)))
  })
  app.post("/api/tags/", async (request, reply) => {
    const user = await authenticate(request, reply, true)
    if (!user) return
    const data = readBody(request, reply)
    if (!data) return
    const [errors, name] = validateTag(data)
    if (Object.keys(errors).length) return send(reply, 400, errors)
    return send(reply, 201, tagJSON(await createTag(sql, user.id, name)))
  })
  app.get("/api/tags/:id/", async (request, reply) => {
    const user = await authenticate(request, reply, true)
    if (!user) return
    const id = pathID((request.params as { id: string }).id)
    if (id === null) return notFound(reply, "tag")
    const row = await getTag(sql, user.id, id)
    if (!row) return notFound(reply, "tag")
    return send(reply, 200, tagJSON(row))
  })
  app.delete("/api/tags/:id/", async (request, reply) => {
    const user = await authenticate(request, reply, true)
    if (!user) return
    const id = pathID((request.params as { id: string }).id)
    if (id === null) return notFound(reply, "tag")
    if (!(await deleteTag(sql, user.id, id))) return notFound(reply, "tag")
    return reply.code(204).send()
  })
  app.get("/api/bundles/", async (request, reply) => {
    const user = await authenticate(request, reply, true)
    if (!user) return
    return send(reply, 200, await listBundles(sql, user.id, requestURL(request), queryMap(request)))
  })
  app.post("/api/bundles/", async (request, reply) => {
    const user = await authenticate(request, reply, true)
    if (!user) return
    const data = readBody(request, reply)
    if (!data) return
    const [errors, cleaned] = validateBundle(data, false)
    if (Object.keys(errors).length) return send(reply, 400, errors)
    return send(reply, 201, bundleJSON(await createBundle(sql, user.id, cleaned)))
  })
  app.get("/api/bundles/:id/", async (request, reply) => {
    const user = await authenticate(request, reply, true)
    if (!user) return
    const id = pathID((request.params as { id: string }).id)
    if (id === null) return notFound(reply, "bundle")
    const row = await getBundle(sql, user.id, id)
    if (!row) return notFound(reply, "bundle")
    return send(reply, 200, bundleJSON(row))
  })
  const bundleWrite = async (request: FastifyRequest, reply: FastifyReply) => {
    const user = await authenticate(request, reply, true)
    if (!user) return
    const id = pathID((request.params as { id: string }).id)
    if (id === null) return notFound(reply, "bundle")
    if (!(await getBundle(sql, user.id, id))) return notFound(reply, "bundle")
    const data = readBody(request, reply)
    if (!data) return
    const [errors, cleaned] = validateBundle(data, request.method === "PATCH")
    if (Object.keys(errors).length) return send(reply, 400, errors)
    const row = await updateBundle(sql, user.id, id, cleaned)
    if (!row) return notFound(reply, "bundle")
    return send(reply, 200, bundleJSON(row))
  }
  app.put("/api/bundles/:id/", bundleWrite)
  app.patch("/api/bundles/:id/", bundleWrite)
  app.delete("/api/bundles/:id/", async (request, reply) => {
    const user = await authenticate(request, reply, true)
    if (!user) return
    const id = pathID((request.params as { id: string }).id)
    if (id === null) return notFound(reply, "bundle")
    if (!(await deleteBundle(sql, user.id, id))) return notFound(reply, "bundle")
    return reply.code(204).send()
  })
  app.setErrorHandler((error, _request, reply) => {
    app.log.error(error)
    return send(reply, 500, { detail: "Server error." })
  })
  await app.listen({ host: "127.0.0.1", port: PORT })
}

if (cluster.isPrimary && WORKERS > 1) {
  for (let i = 0; i < WORKERS; i++) cluster.fork()
  cluster.on("exit", () => {
    cluster.fork()
  })
} else {
  build().catch((error) => {
    console.error(error)
    process.exit(1)
  })
}
