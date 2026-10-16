import {
  APP_VERSION,
  bookmarkTagNames,
  bundleSearchSQL,
  normalizeURL,
  orderSQL,
  pageLinks,
  parseTagString,
  resolveLimit,
  resolveOffset,
  searchSQL,
  tagSQL,
  type BookmarkIn,
  type BundleIn,
} from "./logic.js"

export interface Sql {
  unsafe(query: string, parameters?: unknown[]): Promise<Row[]>
  begin<T>(fn: (tx: Sql) => Promise<T>): Promise<T>
}

type Row = Record<string, unknown>

export interface User {
  id: number
  username: string
  theme: string
  bookmark_date_display: string
  bookmark_link_target: string
  web_archive_integration: string
  tag_search: string
  enable_sharing: boolean
  enable_public_sharing: boolean
  enable_favicons: boolean
  display_url: boolean
  permanent_notes: boolean
  search_preferences: unknown
  legacy_search: boolean
}

const STAMP = (col: string) =>
  `CASE WHEN (EXTRACT(MICROSECONDS FROM ${col})::bigint % 1000000) = 0
        THEN to_char(${col} AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS"Z"')
        ELSE to_char(${col} AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.US"Z"') END`

const BOOKMARK_COLUMNS = `
  b.id, b.owner_id, b.url, b.url_normalized, b.title, b.description, b.notes,
  b.unread, b.is_archived, b.shared,
  ${STAMP("b.date_added")} AS date_added,
  ${STAMP("b.date_modified")} AS date_modified`

function num(value: unknown): number {
  return typeof value === "number" ? value : Number(value)
}

function text(value: unknown): string {
  return value == null ? "" : String(value)
}

function flag(value: unknown): boolean {
  return value === true
}

export function archiveURL(url: string, stamp: string): string {
  const head = stamp.slice(0, 19).replaceAll("-", "").replaceAll(":", "").replace("T", "")
  return `https://web.archive.org/web/${head}/${url}`
}

export function bookmarkJSON(row: Row, names: string[]) {
  const tags = [...names].sort()
  return {
    id: num(row.id),
    url: text(row.url),
    title: text(row.title),
    description: text(row.description),
    notes: text(row.notes),
    web_archive_snapshot_url: archiveURL(text(row.url), text(row.date_added)),
    favicon_url: null,
    preview_image_url: null,
    is_archived: flag(row.is_archived),
    unread: flag(row.unread),
    shared: flag(row.shared),
    tag_names: tags,
    date_added: text(row.date_added),
    date_modified: text(row.date_modified),
    website_title: null,
    website_description: null,
  }
}

export function tagJSON(row: Row) {
  return { id: num(row.id), name: text(row.name), date_added: text(row.date_added) }
}

export function bundleJSON(row: Row) {
  return {
    id: num(row.id),
    name: text(row.name),
    search: text(row.search),
    any_tags: text(row.any_tags),
    all_tags: text(row.all_tags),
    excluded_tags: text(row.excluded_tags),
    filter_unread: text(row.filter_unread),
    filter_shared: text(row.filter_shared),
    order: num(row.order),
    date_created: text(row.date_created),
    date_modified: text(row.date_modified),
  }
}

export function profileJSON(user: User) {
  return {
    theme: user.theme,
    bookmark_date_display: user.bookmark_date_display,
    bookmark_link_target: user.bookmark_link_target,
    web_archive_integration: user.web_archive_integration,
    tag_search: user.tag_search,
    enable_sharing: user.enable_sharing,
    enable_public_sharing: user.enable_public_sharing,
    enable_favicons: user.enable_favicons,
    display_url: user.display_url,
    permanent_notes: user.permanent_notes,
    search_preferences: user.search_preferences ?? {},
    version: APP_VERSION,
  }
}

async function one(sql: Sql, query: string, params: unknown[] = []): Promise<Row | null> {
  const rows = await sql.unsafe(query, params)
  return rows[0] ?? null
}

export async function loadUser(sql: Sql, token: string): Promise<User | null> {
  const row = await one(
    sql,
    `SELECT u.id, u.username, p.theme, p.bookmark_date_display, p.bookmark_link_target,
            p.web_archive_integration, p.tag_search, p.enable_sharing, p.enable_public_sharing,
            p.enable_favicons, p.display_url, p.permanent_notes, p.search_preferences, p.legacy_search
     FROM api_tokens t JOIN users u ON u.id = t.user_id JOIN profiles p ON p.user_id = u.id
     WHERE t.key = $1`,
    [token],
  )
  if (!row) return null
  return {
    id: num(row.id),
    username: text(row.username),
    theme: text(row.theme),
    bookmark_date_display: text(row.bookmark_date_display),
    bookmark_link_target: text(row.bookmark_link_target),
    web_archive_integration: text(row.web_archive_integration),
    tag_search: text(row.tag_search),
    enable_sharing: flag(row.enable_sharing),
    enable_public_sharing: flag(row.enable_public_sharing),
    enable_favicons: flag(row.enable_favicons),
    display_url: flag(row.display_url),
    permanent_notes: flag(row.permanent_notes),
    search_preferences: row.search_preferences ?? {},
    legacy_search: flag(row.legacy_search),
  }
}

async function tagMap(sql: Sql, ids: number[]): Promise<Map<number, string[]>> {
  const grouped = new Map<number, string[]>()
  for (const id of ids) grouped.set(id, [])
  if (!ids.length) return grouped
  const rows = await sql.unsafe(
    `SELECT bt.bookmark_id, t.name FROM bookmark_tags bt JOIN tags t ON t.id = bt.tag_id WHERE bt.bookmark_id = ANY($1::bigint[])`,
    [ids],
  )
  for (const row of rows) grouped.get(num(row.bookmark_id))!.push(text(row.name))
  return grouped
}

async function setTags(sql: Sql, bookmarkId: number, ownerId: number, raw: string[]) {
  const names = bookmarkTagNames(raw)
  await sql.unsafe(`DELETE FROM bookmark_tags WHERE bookmark_id = $1`, [bookmarkId])
  for (const name of names) {
    const lower = name.toLowerCase()
    const inserted = await sql.unsafe(
      `INSERT INTO tags (owner_id, name, name_lower, date_added) VALUES ($1,$2,$3,clock_timestamp())
       ON CONFLICT (owner_id, name_lower) DO NOTHING RETURNING id`,
      [ownerId, name, lower],
    )
    const id = inserted[0] ? num(inserted[0].id) : num((await one(sql, `SELECT id FROM tags WHERE owner_id=$1 AND name_lower=$2`, [ownerId, lower]))!.id)
    await sql.unsafe(`INSERT INTO bookmark_tags (bookmark_id, tag_id) VALUES ($1,$2) ON CONFLICT DO NOTHING`, [bookmarkId, id])
  }
}

async function findExisting(sql: Sql, ownerId: number, raw: string): Promise<Row | null> {
  return one(
    sql,
    `SELECT ${BOOKMARK_COLUMNS} FROM bookmarks b
     WHERE b.owner_id = $1 AND (b.url_normalized = $2 OR (b.url_normalized = '' AND b.url = $3))
     ORDER BY b.id ASC LIMIT 1`,
    [ownerId, normalizeURL(raw), raw],
  )
}

export async function getOwned(sql: Sql, ownerId: number, id: number): Promise<Row | null> {
  return one(sql, `SELECT ${BOOKMARK_COLUMNS} FROM bookmarks b WHERE b.id = $1 AND b.owner_id = $2`, [id, ownerId])
}

export async function serialize(sql: Sql, row: Row) {
  const tags = await tagMap(sql, [num(row.id)])
  return bookmarkJSON(row, tags.get(num(row.id)) ?? [])
}

function since(params: unknown[], column: string, raw: string | undefined): string {
  if (!raw) return ""
  const parsed = normalizeTime(raw)
  if (!parsed) return ""
  return `${column} > (${bind(params, parsed)}::text)::timestamptz`
}

function bind(params: unknown[], value: unknown): string {
  params.push(value)
  return "$" + params.length
}

function flagSQL(field: string, raw: string | undefined): string {
  if (raw === "yes") return `b.${field}`
  if (raw === "no") return `NOT b.${field}`
  return ""
}

function normalizeTime(value: string): string | null {
  const match = /^(\d{4}-\d{2}-\d{2})[T ](\d{2}):(\d{2})(?::(\d{2})(?:\.(\d+))?)?(Z|[+-]\d{2}:?\d{2})?$/.exec(value.trim())
  if (!match) return null
  return value.trim()
}

async function applyBundle(sql: Sql, where: string[], params: unknown[], viewerId: number | null, raw: string | undefined) {
  if (!raw || viewerId == null || !/^-?\d+$/.test(raw)) return
  const bundle = await one(
    sql,
    `SELECT search, any_tags, all_tags, excluded_tags, filter_unread, filter_shared FROM bundles WHERE id = $1 AND owner_id = $2`,
    [Number(raw), viewerId],
  )
  if (!bundle) return
  const search = bundleSearchSQL(text(bundle.search), params)
  if (search) where.push(search)
  for (const spec of [
    [text(bundle.any_tags), "any"],
    [text(bundle.all_tags), "all"],
    [text(bundle.excluded_tags), "excluded"],
  ] as const) {
    const names = parseTagString(spec[0], " ")
    if (!names.length) continue
    if (spec[1] === "any") where.push("(" + names.map((name) => tagSQL(name, params)).join(" OR ") + ")")
    else if (spec[1] === "all") for (const name of names) where.push(tagSQL(name, params))
    else where.push("NOT (" + names.map((name) => tagSQL(name, params)).join(" OR ") + ")")
  }
  if (bundle.filter_unread === "yes") where.push("b.unread")
  else if (bundle.filter_unread === "no") where.push("NOT b.unread")
  if (bundle.filter_shared === "yes") where.push("b.shared")
  else if (bundle.filter_shared === "no") where.push("NOT b.shared")
}

export async function listBookmarks(sql: Sql, kind: string, viewer: User | null, publicOnly: boolean, requestURL: string, qp: Record<string, string | undefined>) {
  const params: unknown[] = []
  const where: string[] = []
  let joins = ""
  const legacy = viewer?.legacy_search ?? false
  const lax = viewer?.tag_search === "lax"
  if (kind === "shared") {
    joins = "JOIN profiles p ON p.user_id = b.owner_id"
    where.push("b.shared", "p.enable_sharing")
    if (publicOnly) where.push("p.enable_public_sharing")
    if (qp.user) {
      const owner = await one(sql, `SELECT id FROM users WHERE username = $1`, [qp.user])
      if (owner) where.push(`b.owner_id = ${bind(params, num(owner.id))}`)
    }
  } else {
    where.push(`b.owner_id = ${bind(params, viewer!.id)}`)
    where.push(kind === "archived" ? "b.is_archived" : "NOT b.is_archived")
  }
  for (const clause of [
    since(params, "b.date_modified", qp.modified_since),
    since(params, "b.date_added", qp.added_since),
    flagSQL("unread", qp.unread),
    flagSQL("shared", qp.shared),
    searchSQL(qp.q ?? "", legacy, lax, params),
  ]) {
    if (clause) where.push(clause)
  }
  await applyBundle(sql, where, params, viewer?.id ?? null, qp.bundle)
  const whereSQL = where.length ? where.join(" AND ") : "TRUE"
  const totalRow = await one(sql, `SELECT count(*)::int AS count FROM bookmarks b ${joins} WHERE ${whereSQL}`, params)
  const limit = resolveLimit(qp.limit)
  const offset = resolveOffset(qp.offset)
  const rows = await sql.unsafe(
    `SELECT ${BOOKMARK_COLUMNS} FROM bookmarks b ${joins} WHERE ${whereSQL} ORDER BY ${orderSQL(qp.sort)} LIMIT $${params.length + 1} OFFSET $${params.length + 2}`,
    [...params, limit, offset],
  )
  const tags = await tagMap(sql, rows.map((row) => num(row.id)))
  const [next, previous] = pageLinks(requestURL, limit, offset, num(totalRow?.count ?? 0))
  return { count: num(totalRow?.count ?? 0), next, previous, results: rows.map((row) => bookmarkJSON(row, tags.get(num(row.id)) ?? [])) }
}

export async function createBookmark(sql: Sql, ownerId: number, cleaned: BookmarkIn) {
  return sql.begin(async (tx) => {
    const existing = await findExisting(tx, ownerId, cleaned.url)
    const title = cleaned.present.has("title") ? cleaned.title : ""
    const description = cleaned.present.has("description") ? cleaned.description : ""
    const notes = cleaned.present.has("notes") ? cleaned.notes : ""
    const unread = cleaned.present.has("unread") ? cleaned.unread : false
    const shared = cleaned.present.has("shared") ? cleaned.shared : false
    const tags = cleaned.present.has("tag_names") ? cleaned.tagNames : []
    if (existing) {
      await tx.unsafe(
        `UPDATE bookmarks SET title=$1, description=$2, notes=$3, unread=$4, shared=$5, date_modified=clock_timestamp() WHERE id=$6`,
        [title, description, notes, unread, shared, num(existing.id)],
      )
      await setTags(tx, num(existing.id), ownerId, tags)
      return (await getOwned(tx, ownerId, num(existing.id)))!
    }
    const inserted = await tx.unsafe(
      `INSERT INTO bookmarks (owner_id, url, url_normalized, title, description, notes, unread, is_archived, shared, date_added, date_modified)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,
               CASE WHEN $10::text IS NULL THEN clock_timestamp() ELSE ($10::text)::timestamptz END,
               CASE WHEN $11::text IS NULL THEN clock_timestamp() ELSE ($11::text)::timestamptz END)
       RETURNING id`,
      [
        ownerId,
        cleaned.url,
        normalizeURL(cleaned.url),
        title,
        description,
        notes,
        unread,
        cleaned.present.has("is_archived") ? cleaned.isArchived : false,
        shared,
        cleaned.present.has("date_added") ? cleaned.dateAdded : null,
        cleaned.present.has("date_modified") ? cleaned.dateModified : null,
      ],
    )
    const id = num(inserted[0]!.id)
    await setTags(tx, id, ownerId, tags)
    return (await getOwned(tx, ownerId, id))!
  })
}

export async function updateBookmark(sql: Sql, ownerId: number, id: number, cleaned: BookmarkIn): Promise<[Row | null, string]> {
  const current = await getOwned(sql, ownerId, id)
  if (!current) return [null, "missing"]
  if (cleaned.present.has("url")) {
    const dup = await one(sql, `SELECT id FROM bookmarks WHERE owner_id=$1 AND url=$2 AND id<>$3`, [ownerId, cleaned.url, id])
    if (dup) return [null, "duplicate"]
  }
  const url = cleaned.present.has("url") ? cleaned.url : text(current.url)
  return sql.begin(async (tx) => {
    await tx.unsafe(
      `UPDATE bookmarks SET url=$1, url_normalized=$2, title=$3, description=$4, notes=$5, unread=$6, shared=$7, is_archived=$8,
              date_added=CASE WHEN $9::text IS NULL THEN date_added ELSE ($9::text)::timestamptz END,
              date_modified=clock_timestamp() WHERE id=$10`,
      [
        url,
        normalizeURL(url),
        cleaned.present.has("title") ? cleaned.title : text(current.title),
        cleaned.present.has("description") ? cleaned.description : text(current.description),
        cleaned.present.has("notes") ? cleaned.notes : text(current.notes),
        cleaned.present.has("unread") ? cleaned.unread : flag(current.unread),
        cleaned.present.has("shared") ? cleaned.shared : flag(current.shared),
        cleaned.present.has("is_archived") ? cleaned.isArchived : flag(current.is_archived),
        cleaned.present.has("date_added") ? cleaned.dateAdded : null,
        id,
      ],
    )
    if (cleaned.present.has("tag_names")) await setTags(tx, id, ownerId, cleaned.tagNames)
    return [(await getOwned(tx, ownerId, id))!, ""]
  })
}

export async function setArchived(sql: Sql, ownerId: number, id: number, archived: boolean) {
  const row = await getOwned(sql, ownerId, id)
  if (!row) return null
  await sql.unsafe(`UPDATE bookmarks SET is_archived=$1, date_modified=clock_timestamp() WHERE id=$2`, [archived, id])
  return getOwned(sql, ownerId, id)
}

export async function deleteBookmark(sql: Sql, ownerId: number, id: number) {
  const rows = await sql.unsafe(`DELETE FROM bookmarks WHERE id=$1 AND owner_id=$2 RETURNING id`, [id, ownerId])
  return rows.length === 1
}

export async function listTags(sql: Sql, ownerId: number, requestURL: string, qp: Record<string, string | undefined>) {
  const total = num((await one(sql, `SELECT count(*)::int AS count FROM tags WHERE owner_id=$1`, [ownerId]))!.count)
  const limit = resolveLimit(qp.limit)
  const offset = resolveOffset(qp.offset)
  const rows = await sql.unsafe(
    `SELECT id, name, ${STAMP("date_added")} AS date_added FROM tags WHERE owner_id=$1 ORDER BY id ASC LIMIT $2 OFFSET $3`,
    [ownerId, limit, offset],
  )
  const [next, previous] = pageLinks(requestURL, limit, offset, total)
  return { count: total, next, previous, results: rows.map(tagJSON) }
}

export async function getTag(sql: Sql, ownerId: number, id: number) {
  return one(sql, `SELECT id, name, ${STAMP("date_added")} AS date_added FROM tags WHERE id=$1 AND owner_id=$2`, [id, ownerId])
}

export async function createTag(sql: Sql, ownerId: number, name: string) {
  const lower = name.toLowerCase()
  const existing = await getTagByName(sql, ownerId, lower)
  if (existing) return existing
  return (await one(
    sql,
    `INSERT INTO tags (owner_id, name, name_lower, date_added) VALUES ($1,$2,$3,clock_timestamp()) RETURNING id, name, ${STAMP("date_added")} AS date_added`,
    [ownerId, name, lower],
  ))!
}

async function getTagByName(sql: Sql, ownerId: number, lower: string) {
  return one(sql, `SELECT id, name, ${STAMP("date_added")} AS date_added FROM tags WHERE owner_id=$1 AND name_lower=$2`, [ownerId, lower])
}

export async function deleteTag(sql: Sql, ownerId: number, id: number) {
  const rows = await sql.unsafe(`DELETE FROM tags WHERE id=$1 AND owner_id=$2 RETURNING id`, [id, ownerId])
  return rows.length === 1
}

const BUNDLE_COLUMNS = `id, name, search, any_tags, all_tags, excluded_tags, filter_unread, filter_shared, "order", ${STAMP("date_created")} AS date_created, ${STAMP("date_modified")} AS date_modified`

export async function listBundles(sql: Sql, ownerId: number, requestURL: string, qp: Record<string, string | undefined>) {
  const total = num((await one(sql, `SELECT count(*)::int AS count FROM bundles WHERE owner_id=$1`, [ownerId]))!.count)
  const limit = resolveLimit(qp.limit)
  const offset = resolveOffset(qp.offset)
  const rows = await sql.unsafe(`SELECT ${BUNDLE_COLUMNS} FROM bundles WHERE owner_id=$1 ORDER BY "order" ASC, id ASC LIMIT $2 OFFSET $3`, [ownerId, limit, offset])
  const [next, previous] = pageLinks(requestURL, limit, offset, total)
  return { count: total, next, previous, results: rows.map(bundleJSON) }
}

export async function getBundle(sql: Sql, ownerId: number, id: number) {
  return one(sql, `SELECT ${BUNDLE_COLUMNS} FROM bundles WHERE id=$1 AND owner_id=$2`, [id, ownerId])
}

export async function createBundle(sql: Sql, ownerId: number, cleaned: BundleIn) {
  let order = cleaned.order
  if (!cleaned.present.has("order")) {
    const current = await one(sql, `SELECT COALESCE(MAX("order"), -1)::int AS n FROM bundles WHERE owner_id=$1`, [ownerId])
    order = num(current?.n) + 1
  }
  return (await one(
    sql,
    `INSERT INTO bundles (owner_id, name, search, any_tags, all_tags, excluded_tags, filter_unread, filter_shared, "order", date_created, date_modified)
     VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,clock_timestamp(),clock_timestamp())
     RETURNING ${BUNDLE_COLUMNS}`,
    [
      ownerId,
      cleaned.name,
      cleaned.present.has("search") ? cleaned.search : "",
      cleaned.present.has("any_tags") ? cleaned.anyTags : "",
      cleaned.present.has("all_tags") ? cleaned.allTags : "",
      cleaned.present.has("excluded_tags") ? cleaned.excludedTags : "",
      cleaned.present.has("filter_unread") ? cleaned.filterUnread : "off",
      cleaned.present.has("filter_shared") ? cleaned.filterShared : "off",
      order,
    ],
  ))!
}

export async function updateBundle(sql: Sql, ownerId: number, id: number, cleaned: BundleIn) {
  const current = await getBundle(sql, ownerId, id)
  if (!current) return null
  return one(
    sql,
    `UPDATE bundles SET name=$1, search=$2, any_tags=$3, all_tags=$4, excluded_tags=$5, filter_unread=$6, filter_shared=$7, "order"=$8, date_modified=clock_timestamp()
     WHERE id=$9 RETURNING ${BUNDLE_COLUMNS}`,
    [
      cleaned.present.has("name") ? cleaned.name : text(current.name),
      cleaned.present.has("search") ? cleaned.search : text(current.search),
      cleaned.present.has("any_tags") ? cleaned.anyTags : text(current.any_tags),
      cleaned.present.has("all_tags") ? cleaned.allTags : text(current.all_tags),
      cleaned.present.has("excluded_tags") ? cleaned.excludedTags : text(current.excluded_tags),
      cleaned.present.has("filter_unread") ? cleaned.filterUnread : text(current.filter_unread),
      cleaned.present.has("filter_shared") ? cleaned.filterShared : text(current.filter_shared),
      cleaned.present.has("order") ? cleaned.order : num(current.order),
      id,
    ],
  )
}

export async function deleteBundle(sql: Sql, ownerId: number, id: number) {
  return sql.begin(async (tx) => {
    const deleted = await tx.unsafe(`DELETE FROM bundles WHERE id=$1 AND owner_id=$2 RETURNING id`, [id, ownerId])
    if (!deleted.length) return false
    const rows = await tx.unsafe(`SELECT id FROM bundles WHERE owner_id=$1 ORDER BY "order" ASC, id ASC`, [ownerId])
    for (let index = 0; index < rows.length; index++) {
      await tx.unsafe(`UPDATE bundles SET "order"=$1 WHERE id=$2`, [index, num(rows[index]!.id)])
    }
    return true
  })
}

export { findExisting }
