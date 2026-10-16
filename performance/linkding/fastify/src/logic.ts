export const APP_VERSION = "1.47.0"
export const PAGE_SIZE = 100
export const DT_ERROR =
  "Datetime has wrong format. Use one of these formats instead: YYYY-MM-DDThh:mm[:ss[.uuuuuu]][+HH:MM|-HH:MM|Z]."

const TRUE_VALUES = new Set(["t", "T", "y", "Y", "yes", "YES", "Yes", "true", "True", "TRUE", "on", "On", "ON", "1"])
const FALSE_VALUES = new Set(["f", "F", "n", "N", "no", "NO", "No", "false", "False", "FALSE", "off", "Off", "OFF", "0"])
const FILTERS = new Set(["off", "yes", "no"])

export type Errs = Record<string, string[]>
export type Obj = Record<string, unknown>

export interface BookmarkIn {
  present: Set<string>
  url: string
  title: string
  description: string
  notes: string
  unread: boolean
  shared: boolean
  isArchived: boolean
  tagNames: string[]
  dateAdded: string
  dateModified: string
}

export interface BundleIn {
  present: Set<string>
  name: string
  search: string
  anyTags: string
  allTags: string
  excludedTags: string
  filterUnread: string
  filterShared: string
  order: number
}

function add(errors: Errs, field: string, message: string) {
  ;(errors[field] ??= []).push(message)
}

export function uniqueCI(items: string[]): string[] {
  const index = new Map<string, number>()
  const out: string[] = []
  for (const item of items) {
    const key = item.toLowerCase()
    const at = index.get(key)
    if (at !== undefined) out[at] = item
    else {
      index.set(key, out.length)
      out.push(item)
    }
  }
  return out
}

export function sanitizeTagName(name: string): string {
  return name.trim().replaceAll(" ", "-")
}

export function parseTagString(tagString: string, delimiter = ","): string[] {
  if (!tagString.trim()) return []
  const names = tagString
    .trim()
    .split(delimiter)
    .filter((part) => part.trim() !== "")
    .map(sanitizeTagName)
  const unique = uniqueCI(names)
  unique.sort((a, b) => (a.toLowerCase() < b.toLowerCase() ? -1 : a.toLowerCase() > b.toLowerCase() ? 1 : 0))
  return unique
}

export function bookmarkTagNames(raw: string[]): string[] {
  return parseTagString(raw.join(","))
}

function pyQuote(s: string): string {
  let out = ""
  for (let i = 0; i < s.length; i++) {
    const c = s.charCodeAt(i)
    const ch = s[i]!
    if ((c >= 48 && c <= 57) || (c >= 65 && c <= 90) || (c >= 97 && c <= 122) || "-_.~/".includes(ch)) out += ch
    else out += "%" + c.toString(16).toUpperCase().padStart(2, "0")
  }
  return out
}

export function normalizeURL(raw: string): string {
  raw = raw.trim()
  if (!raw) return ""
  let parsed: URL
  try {
    parsed = new URL(raw)
  } catch {
    return raw
  }
  const host = parsed.hostname.toLowerCase()
  if (!host) return raw
  let netloc = host
  if (parsed.port) netloc += ":" + parsed.port
  if (parsed.username) {
    let auth = decodeURIComponent(parsed.username)
    if (parsed.password) auth += ":" + decodeURIComponent(parsed.password)
    netloc = auth + "@" + netloc
  }
  const path = parsed.pathname.replace(/\/+$/, "")
  let query = ""
  if (parsed.search.length > 1) {
    const pairs: [string, string][] = []
    parsed.searchParams.forEach((value, key) => pairs.push([key, value]))
    pairs.sort((a, b) => (a[0] === b[0] ? (a[1] < b[1] ? -1 : a[1] > b[1] ? 1 : 0) : a[0] < b[0] ? -1 : 1))
    query = pairs.map(([k, v]) => pyQuote(k) + "=" + pyQuote(v)).join("&")
  }
  let out = parsed.protocol.toLowerCase() + "//" + netloc + path
  if (query) out += "?" + query
  if (parsed.hash) out += parsed.hash
  return out
}

function isIPv4(host: string): boolean {
  const parts = host.split(".")
  if (parts.length !== 4) return false
  for (const part of parts) {
    if (!/^[0-9]+$/.test(part) || (part.length > 1 && part.startsWith("0")) || Number(part) > 255) return false
  }
  return true
}

function isIPv6(host: string): boolean {
  if (!host.includes(":")) return false
  return /^[0-9a-fA-F:.]+$/.test(host) && host.includes(":")
}

function labelOK(label: string, tld: boolean): boolean {
  if (!label || [...label].length > 63) return false
  if (label.startsWith("-") || label.endsWith("-")) return false
  if (tld && label.toLowerCase().startsWith("xn--")) {
    const rest = label.slice(4)
    return rest.length >= 1 && rest.length <= 59 && /^[A-Za-z0-9]+$/.test(rest)
  }
  for (const ch of label) {
    const code = ch.codePointAt(0) ?? 0
    if (code >= 0xa1 || ch === "-" || /[0-9A-Za-z]/.test(ch) || /\p{L}|\p{N}/u.test(ch)) continue
    return false
  }
  if (tld && [...label].length < 2) return false
  return true
}

function isDomain(host: string): boolean {
  if (host.endsWith(".")) host = host.slice(0, -1)
  if (!host || host.length > 253) return false
  const labels = host.split(".")
  if (labels.length < 2) return false
  return labels.every((label, i) => labelOK(label, i === labels.length - 1))
}

export function validURL(value: string): boolean {
  if (value.length > 2048 || /[\t\r\n]/.test(value) || !value.includes("://")) return false
  const scheme = value.split("://", 1)[0]!.toLowerCase()
  if (!["http", "https", "ftp", "ftps"].includes(scheme)) return false
  let parsed: URL
  try {
    parsed = new URL(value)
  } catch {
    return false
  }
  const host = parsed.hostname
  if (!host || host.length > 253) return false
  const lower = host.toLowerCase()
  if (lower !== "localhost" && !isIPv4(lower) && !isIPv6(host) && !isDomain(lower)) return false
  if (parsed.port) {
    const n = Number(parsed.port)
    if (!Number.isInteger(n) || n < 0 || n > 65535) return false
  }
  return true
}

function parseQuery(raw: string): Map<string, string[]> {
  const out = new Map<string, string[]>()
  if (!raw) return out
  for (const part of raw.split("&")) {
    if (!part) continue
    const eq = part.indexOf("=")
    const key = decodeURIComponent(eq >= 0 ? part.slice(0, eq) : part)
    const val = decodeURIComponent(eq >= 0 ? part.slice(eq + 1) : "")
    const list = out.get(key) ?? []
    list.push(val)
    out.set(key, list)
  }
  return out
}

function encodeQuery(values: Map<string, string[]>): string {
  const keys = [...values.keys()].sort()
  const parts: string[] = []
  for (const key of keys) {
    for (const value of values.get(key) ?? []) parts.push(encodeURIComponent(key) + "=" + encodeURIComponent(value))
  }
  return parts.join("&")
}

function splitRaw(raw: string): [string, string, string] {
  let fragment = ""
  const hash = raw.indexOf("#")
  if (hash >= 0) {
    fragment = raw.slice(hash + 1)
    raw = raw.slice(0, hash)
  }
  let query = ""
  const q = raw.indexOf("?")
  if (q >= 0) {
    query = raw.slice(q + 1)
    raw = raw.slice(0, q)
  }
  return [raw, query, fragment]
}

export function replaceQueryParam(raw: string, key: string, val: string): string {
  const [base, query, fragment] = splitRaw(raw)
  const values = parseQuery(query)
  values.set(key, [val])
  const encoded = encodeQuery(values)
  return base + (encoded ? "?" + encoded : "") + (fragment ? "#" + fragment : "")
}

export function removeQueryParam(raw: string, key: string): string {
  const [base, query, fragment] = splitRaw(raw)
  const values = parseQuery(query)
  values.delete(key)
  const encoded = encodeQuery(values)
  return base + (encoded ? "?" + encoded : "") + (fragment ? "#" + fragment : "")
}

export function resolveLimit(raw: string | undefined): number {
  if (raw === undefined || raw === "") return PAGE_SIZE
  const n = Number(raw)
  if (!Number.isInteger(n) || n <= 0) return PAGE_SIZE
  return n
}

export function resolveOffset(raw: string | undefined): number {
  if (raw === undefined || raw === "") return 0
  const n = Number(raw)
  if (!Number.isInteger(n) || n < 0) return 0
  return n
}

export function pageLinks(raw: string, limit: number, offset: number, count: number): [string | null, string | null] {
  let next: string | null = null
  let prev: string | null = null
  if (offset + limit < count) next = replaceQueryParam(replaceQueryParam(raw, "limit", String(limit)), "offset", String(offset + limit))
  if (offset > 0) {
    const base = replaceQueryParam(raw, "limit", String(limit))
    prev = offset - limit <= 0 ? removeQueryParam(base, "offset") : replaceQueryParam(base, "offset", String(offset - limit))
  }
  return [next, prev]
}

export function classifyAuth(header: string | undefined): [string, string] {
  if (!header || !header.trim()) return ["absent", ""]
  const parts = header.trim().split(/\s+/)
  const keyword = parts[0]!.toLowerCase()
  if (keyword !== "token" && keyword !== "bearer") return ["absent", ""]
  if (parts.length === 1) return ["nocreds", ""]
  if (parts.length > 2) return ["spaces", ""]
  return ["token", parts[1]!]
}

export function authDetail(kind: string): string {
  if (kind === "nocreds") return "Invalid token header. No credentials provided."
  if (kind === "spaces") return "Invalid token header. Token string should not contain spaces."
  if (kind === "bad") return "Invalid token."
  return "Authentication credentials were not provided."
}

export function parseBool(value: unknown): boolean | null {
  if (typeof value === "boolean") return value
  if (typeof value === "number" && (value === 1 || value === 0)) return value === 1
  if (typeof value === "string") {
    if (TRUE_VALUES.has(value)) return true
    if (FALSE_VALUES.has(value)) return false
  }
  return null
}

export function normalizeTime(value: string): string | null {
  const text = value.trim()
  if (!text) return null
  const match = /^(\d{4}-\d{2}-\d{2})T(\d{2}):(\d{2})(?::(\d{2})(?:\.(\d{1,9}))?)?(Z|[+-]\d{2}:\d{2})?$/.exec(text)
  if (!match) return null
  const [, date, hh, mm, ss = "00", frac = "", zone = ""] = match
  const hour = Number(hh)
  const minute = Number(mm)
  const second = Number(ss)
  if (hour > 23 || minute > 59 || second > 59) return null
  let suffix = zone || "Z"
  if (suffix !== "Z") {
    const sign = suffix[0] === "-" ? -1 : 1
    const zh = Number(suffix.slice(1, 3))
    const zm = Number(suffix.slice(4, 6))
    if (zh > 23 || zm > 59) return null
    const base = Date.parse(`${date}T${hh}:${mm}:${ss}Z`)
    if (Number.isNaN(base)) return null
    const utc = new Date(base - sign * (zh * 60 + zm) * 60000)
    const iso = utc.toISOString()
    const micros = (frac + "000000").slice(0, 6)
    const head = iso.slice(0, 19)
    return micros === "000000" ? head + "Z" : head + "." + micros + "Z"
  }
  const probe = Date.parse(`${date}T${hh}:${mm}:${ss}Z`)
  if (Number.isNaN(probe)) return null
  const micros = (frac + "000000").slice(0, 6)
  const head = `${date}T${hh}:${mm}:${String(second).padStart(2, "0")}`
  return micros === "000000" ? head + "Z" : head + "." + micros + "Z"
}

function takeText(data: Obj, field: string, errors: Errs, required: boolean, allowBlank: boolean, maxLen: number): [string, boolean] {
  if (!(field in data)) {
    if (required) add(errors, field, "This field is required.")
    return ["", false]
  }
  const value = data[field]
  if (value === null) {
    add(errors, field, "This field may not be null.")
    return ["", true]
  }
  if (typeof value !== "string") {
    add(errors, field, "Not a valid string.")
    return ["", true]
  }
  const text = value.trim()
  if (text === "" && !allowBlank) {
    add(errors, field, "This field may not be blank.")
    return ["", true]
  }
  if (maxLen > 0 && [...text].length > maxLen) {
    add(errors, field, `Ensure this field has no more than ${maxLen} characters.`)
    return ["", true]
  }
  return [text, true]
}

function takeURL(data: Obj, errors: Errs, required: boolean): [string, boolean] {
  if (!("url" in data)) {
    if (required) add(errors, "url", "This field is required.")
    return ["", false]
  }
  const value = data.url
  if (value === null) {
    add(errors, "url", "This field may not be null.")
    return ["", true]
  }
  if (typeof value !== "string") {
    add(errors, "url", "Enter a valid URL.")
    return ["", true]
  }
  const text = value.trim()
  if (text === "") {
    add(errors, "url", "This field may not be blank.")
    return ["", true]
  }
  const messages: string[] = []
  if (text.length > 2048 || !validURL(text)) messages.push("Enter a valid URL.")
  if (text.length > 2048) messages.push("Ensure this field has no more than 2048 characters.")
  if (messages.length) {
    errors.url = messages
    return ["", true]
  }
  return [text, true]
}

export function pyTypeName(value: unknown): string {
  if (typeof value === "string") return "str"
  if (typeof value === "boolean") return "bool"
  if (Array.isArray(value)) return "list"
  if (value && typeof value === "object") return "dict"
  if (typeof value === "number") return Number.isInteger(value) ? "int" : "float"
  return "str"
}

export function validateBookmark(data: Obj, partial: boolean): [Errs, BookmarkIn] {
  const errors: Errs = {}
  const cleaned: BookmarkIn = {
    present: new Set(),
    url: "",
    title: "",
    description: "",
    notes: "",
    unread: false,
    shared: false,
    isArchived: false,
    tagNames: [],
    dateAdded: "",
    dateModified: "",
  }
  const [url, urlPresent] = takeURL(data, errors, !partial)
  if (urlPresent && !errors.url) {
    cleaned.present.add("url")
    cleaned.url = url
  }
  for (const field of [
    ["title", 512],
    ["description", 0],
    ["notes", 0],
  ] as const) {
    const [text, present] = takeText(data, field[0], errors, false, true, field[1])
    if (present && !errors[field[0]]) {
      cleaned.present.add(field[0])
      if (field[0] === "title") cleaned.title = text
      if (field[0] === "description") cleaned.description = text
      if (field[0] === "notes") cleaned.notes = text
    }
  }
  for (const field of ["unread", "shared", "is_archived"] as const) {
    if (!(field in data)) continue
    if (data[field] === null) {
      add(errors, field, "This field may not be null.")
      continue
    }
    const flag = parseBool(data[field])
    if (flag === null) {
      add(errors, field, "Must be a valid boolean.")
      continue
    }
    cleaned.present.add(field)
    if (field === "unread") cleaned.unread = flag
    if (field === "shared") cleaned.shared = flag
    if (field === "is_archived") cleaned.isArchived = flag
  }
  if ("tag_names" in data) {
    const value = data.tag_names
    if (value === null) add(errors, "tag_names", "This field may not be null.")
    else if (Array.isArray(value)) {
      const names: string[] = []
      let bad = false
      for (const item of value) {
        if (typeof item !== "string") {
          add(errors, "tag_names", "Not a valid string.")
          bad = true
          break
        }
        names.push(item)
      }
      if (!bad) {
        cleaned.present.add("tag_names")
        cleaned.tagNames = names
      }
    } else add(errors, "tag_names", `Expected a list of items but got type "${pyTypeName(value)}".`)
  }
  for (const field of ["date_added", "date_modified"] as const) {
    if (!(field in data)) continue
    const value = data[field]
    if (value === null) {
      add(errors, field, "This field may not be null.")
      continue
    }
    const parsed = typeof value === "string" ? normalizeTime(value) : null
    if (!parsed) {
      add(errors, field, DT_ERROR)
      continue
    }
    cleaned.present.add(field)
    if (field === "date_added") cleaned.dateAdded = parsed
    else cleaned.dateModified = parsed
  }
  return [errors, cleaned]
}

export function validateTag(data: Obj): [Errs, string] {
  const errors: Errs = {}
  const [name] = takeText(data, "name", errors, true, false, 64)
  return [errors, name]
}

export function validateBundle(data: Obj, partial: boolean): [Errs, BundleIn] {
  const errors: Errs = {}
  const cleaned: BundleIn = {
    present: new Set(),
    name: "",
    search: "",
    anyTags: "",
    allTags: "",
    excludedTags: "",
    filterUnread: "off",
    filterShared: "off",
    order: 0,
  }
  const [name, namePresent] = takeText(data, "name", errors, !partial, false, 256)
  if (namePresent && !errors.name) {
    cleaned.present.add("name")
    cleaned.name = name
  }
  for (const field of [
    ["search", 256],
    ["any_tags", 1024],
    ["all_tags", 1024],
    ["excluded_tags", 1024],
  ] as const) {
    const [text, present] = takeText(data, field[0], errors, false, true, field[1])
    if (present && !errors[field[0]]) {
      cleaned.present.add(field[0])
      if (field[0] === "search") cleaned.search = text
      if (field[0] === "any_tags") cleaned.anyTags = text
      if (field[0] === "all_tags") cleaned.allTags = text
      if (field[0] === "excluded_tags") cleaned.excludedTags = text
    }
  }
  for (const field of ["filter_unread", "filter_shared"] as const) {
    if (!(field in data)) continue
    const value = data[field]
    if (value === null) {
      add(errors, field, "This field may not be null.")
      continue
    }
    if (typeof value !== "string" || !FILTERS.has(value)) {
      add(errors, field, `"${String(value)}" is not a valid choice.`)
      continue
    }
    cleaned.present.add(field)
    if (field === "filter_unread") cleaned.filterUnread = value
    else cleaned.filterShared = value
  }
  if ("order" in data) {
    const value = data.order
    if (value === null) add(errors, "order", "This field may not be null.")
    else if (typeof value !== "number" || !Number.isInteger(value)) add(errors, "order", "A valid integer is required.")
    else {
      cleaned.present.add("order")
      cleaned.order = value
    }
  }
  return [errors, cleaned]
}

type Expr =
  | { k: "term"; term: string }
  | { k: "tag"; tag: string }
  | { k: "keyword"; keyword: string }
  | { k: "and"; left: Expr; right: Expr }
  | { k: "or"; left: Expr; right: Expr }
  | { k: "not"; operand: Expr }

class Tokenizer {
  query: string
  pos = 0
  constructor(query: string) {
    this.query = query.trim()
  }
  get current(): string | undefined {
    return this.pos < this.query.length ? this.query[this.pos] : undefined
  }
  advance() {
    this.pos++
  }
  skip() {
    while (this.current && /\s/u.test(this.current)) this.advance()
  }
  readTerm(): string {
    let out = ""
    while (this.current && !/\s/u.test(this.current) && !"()\"'#!".includes(this.current)) {
      out += this.current
      this.advance()
    }
    return out
  }
  readQuoted(quote: string): string {
    let out = ""
    this.advance()
    while (this.current && this.current !== quote) {
      if (this.current === "\\") {
        this.advance()
        if (!this.current) break
        const map: Record<string, string> = { n: "\n", t: "\t", r: "\r", "\\": "\\", [quote]: quote }
        out += map[this.current] ?? this.current
        this.advance()
      } else {
        out += this.current
        this.advance()
      }
    }
    if (this.current === quote) this.advance()
    return out
  }
  readMarked(): string {
    let out = ""
    this.advance()
    while (this.current && !/\s/u.test(this.current) && !"()\"'".includes(this.current)) {
      out += this.current
      this.advance()
    }
    return out
  }
  tokenize(): { kind: string; value: string }[] {
    const tokens: { kind: string; value: string }[] = []
    while (this.current) {
      this.skip()
      if (!this.current) break
      const ch = this.current
      if (ch === "(") {
        tokens.push({ kind: "LPAREN", value: "(" })
        this.advance()
      } else if (ch === ")") {
        tokens.push({ kind: "RPAREN", value: ")" })
        this.advance()
      } else if (ch === '"' || ch === "'") tokens.push({ kind: "TERM", value: this.readQuoted(ch) })
      else if (ch === "#") {
        const tag = this.readMarked()
        if (tag) tokens.push({ kind: "TAG", value: tag })
      } else if (ch === "!") {
        const keyword = this.readMarked()
        if (keyword) tokens.push({ kind: "KEYWORD", value: keyword })
      } else {
        const term = this.readTerm()
        const lower = term.toLowerCase()
        if (lower === "and" || lower === "or" || lower === "not") tokens.push({ kind: lower.toUpperCase(), value: term })
        else tokens.push({ kind: "TERM", value: term })
      }
    }
    tokens.push({ kind: "EOF", value: "" })
    return tokens
  }
}

class Parser {
  tokens: { kind: string; value: string }[]
  pos = 0
  constructor(tokens: { kind: string; value: string }[]) {
    this.tokens = tokens
  }
  get current() {
    return this.tokens[this.pos]!
  }
  advance() {
    if (this.pos < this.tokens.length - 1) this.pos++
  }
  parseOr(): Expr {
    let left = this.parseAnd()
    while (this.current.kind === "OR") {
      this.advance()
      left = { k: "or", left, right: this.parseAnd() }
    }
    return left
  }
  parseAnd(): Expr {
    let left = this.parseNot()
    while (["AND", "TERM", "TAG", "KEYWORD", "LPAREN", "NOT"].includes(this.current.kind)) {
      if (this.current.kind === "AND") this.advance()
      left = { k: "and", left, right: this.parseNot() }
    }
    return left
  }
  parseNot(): Expr {
    if (this.current.kind === "NOT") {
      this.advance()
      return { k: "not", operand: this.parseNot() }
    }
    return this.parsePrimary()
  }
  parsePrimary(): Expr {
    const kind = this.current.kind
    if (kind === "TERM" || kind === "TAG" || kind === "KEYWORD") {
      const value = this.current.value
      this.advance()
      if (kind === "TERM") return { k: "term", term: value }
      if (kind === "TAG") return { k: "tag", tag: value }
      return { k: "keyword", keyword: value }
    }
    if (kind === "LPAREN") {
      this.advance()
      const expr = this.parseOr()
      if (this.current.kind !== "RPAREN") throw new Error("parse")
      this.advance()
      return expr
    }
    throw new Error("parse")
  }
}

function parseSearch(query: string): Expr | null {
  if (!query.trim()) return null
  const tokens = new Tokenizer(query).tokenize()
  if (tokens.length === 1) return null
  const parser = new Parser(tokens)
  const expr = parser.parseOr()
  if (parser.current.kind !== "EOF") throw new Error("parse")
  return expr
}

function legacy(query: string) {
  const words = query.trim().split(" ").filter((word) => word !== "")
  const terms: string[] = []
  let tags: string[] = []
  let untagged = false
  let unread = false
  for (const word of words) {
    if (word.startsWith("#")) tags.push(word.slice(1))
    else if (word.startsWith("!")) {
      if (word === "!untagged") untagged = true
      if (word === "!unread") unread = true
    } else terms.push(word)
  }
  tags = uniqueCI(tags)
  return { terms, tags, untagged, unread }
}

function likeContains(text: string): string {
  return "%" + text.replaceAll("\\", "\\\\").replaceAll("%", "\\%").replaceAll("_", "\\_") + "%"
}

function bind(params: unknown[], value: unknown): string {
  params.push(value)
  return "$" + params.length
}

const UNTAGGED = "NOT EXISTS (SELECT 1 FROM bookmark_tags bt WHERE bt.bookmark_id = b.id)"

function termSQL(term: string, lax: boolean, params: unknown[]): string {
  const placeholder = bind(params, likeContains(term))
  let sql = `(b.title ILIKE ${placeholder} ESCAPE '\\' OR b.description ILIKE ${placeholder} ESCAPE '\\' OR b.notes ILIKE ${placeholder} ESCAPE '\\' OR b.url ILIKE ${placeholder} ESCAPE '\\'`
  if (lax) sql += ` OR EXISTS (SELECT 1 FROM bookmark_tags bt JOIN tags t ON t.id = bt.tag_id WHERE bt.bookmark_id = b.id AND t.name_lower = ${bind(params, term.toLowerCase())})`
  return sql + ")"
}

export function tagSQL(tag: string, params: unknown[]): string {
  return `EXISTS (SELECT 1 FROM bookmark_tags bt JOIN tags t ON t.id = bt.tag_id WHERE bt.bookmark_id = b.id AND t.name_lower = ${bind(params, tag.toLowerCase())})`
}

function compile(node: Expr, lax: boolean, params: unknown[]): string {
  if (node.k === "term") return termSQL(node.term, lax, params)
  if (node.k === "tag") return tagSQL(node.tag, params)
  if (node.k === "keyword") {
    const keyword = node.keyword.toLowerCase()
    if (keyword === "unread") return "b.unread"
    if (keyword === "untagged") return UNTAGGED
    return "TRUE"
  }
  if (node.k === "and") return `(${compile(node.left, lax, params)} AND ${compile(node.right, lax, params)})`
  if (node.k === "or") return `(${compile(node.left, lax, params)} OR ${compile(node.right, lax, params)})`
  return `(NOT (${compile(node.operand, lax, params)}))`
}

export function searchSQL(query: string, legacyMode: boolean, lax: boolean, params: unknown[]): string {
  if (legacyMode) {
    const parts = legacy(query || "")
    const conds = parts.terms.map((term) => termSQL(term, lax, params))
    for (const tag of parts.tags) conds.push(tagSQL(tag, params))
    if (parts.untagged) conds.push(UNTAGGED)
    if (parts.unread) conds.push("b.unread")
    return conds.length ? "(" + conds.join(" AND ") + ")" : ""
  }
  try {
    const ast = parseSearch(query || "")
    if (!ast) return ""
    return compile(ast, lax, params)
  } catch {
    return "FALSE"
  }
}

export function bundleSearchSQL(search: string, params: unknown[]): string {
  const parts = legacy(search || "")
  if (!parts.terms.length) return ""
  return "(" + parts.terms.map((term) => termSQL(term, false, params)).join(" AND ") + ")"
}

export function orderSQL(sort: string | undefined): string {
  switch (sort) {
    case "added_asc":
      return "b.date_added ASC"
    case "added_desc":
      return "b.date_added DESC"
    case "modified_asc":
      return "b.date_modified ASC"
    case "modified_desc":
      return "b.date_modified DESC"
    case "title_asc":
      return "lower(CASE WHEN b.title <> '' THEN b.title ELSE b.url END) ASC"
    case "title_desc":
      return "lower(CASE WHEN b.title <> '' THEN b.title ELSE b.url END) DESC"
    default:
      return "b.date_added DESC"
  }
}

export function jsonDetail(raw: string): string {
  const trimmed = raw.trim()
  if (!trimmed || (trimmed[0] !== "{" && trimmed[0] !== "[" && trimmed[0] !== '"')) {
    let pos = 0
    while (pos < raw.length && " \t\n\r".includes(raw[pos]!)) pos++
    let line = 1
    let col = 1
    for (let i = 0; i < pos; i++) {
      if (raw[i] === "\n") {
        line++
        col = 1
      } else col++
    }
    return `JSON parse error - Expecting value: line ${line} column ${col} (char ${pos})`
  }
  try {
    JSON.parse(raw)
  } catch (err) {
    return "JSON parse error - " + (err instanceof Error ? err.message : "parse error")
  }
  return "JSON parse error - Expecting value: line 1 column 1 (char 0)"
}
