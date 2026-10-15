export const BCRYPT_COST = 12
const MIN_PASSWORD = 8

export class ApiError extends Error {
  status: number
  field: string
  constructor(status: number, field: string, message: string) {
    super(message)
    this.status = status
    this.field = field
  }
}

export type Obj = Record<string, unknown>

type Kind = "absent" | "null" | "blank" | "value"

export interface FieldVal {
  kind: Kind | "clear" | "set"
  val: string
}

export interface TagField {
  kind: "absent" | "replace"
  tags: string[]
}

export interface UserUpdate {
  username: FieldVal
  email: FieldVal
  password: FieldVal
  bio: FieldVal
  image: FieldVal
}

export interface ArticleUpdate {
  title: FieldVal
  description: FieldVal
  body: FieldVal
  tags: TagField
}

export function slugify(title: string): string {
  const raw = Buffer.from(title, "utf8")
  const out: number[] = []
  let prevHyphen = true
  for (const c0 of raw) {
    let c = c0
    if (c >= 65 && c <= 90) c += 32
    if ((c >= 97 && c <= 122) || (c >= 48 && c <= 57)) {
      out.push(c)
      prevHyphen = false
    } else if (c === 32 || c === 9 || c === 10 || c === 13 || c === 45 || c === 95) {
      if (!prevHyphen) {
        out.push(45)
        prevHyphen = true
      }
    }
  }
  while (out.length > 0 && out[out.length - 1] === 45) out.pop()
  if (out.length === 0) return "article"
  return Buffer.from(out).toString("utf8")
}

export function withSuffix(base: string, n: number): string {
  if (n === 0) return base
  return `${base}-${n}`
}

function classify(obj: Obj, key: string): { kind: Kind; val: string } {
  if (!Object.prototype.hasOwnProperty.call(obj, key)) return { kind: "absent", val: "" }
  const raw = obj[key]
  if (raw === null) return { kind: "null", val: "" }
  if (typeof raw !== "string") throw new ApiError(422, key, "is invalid")
  if (raw === "") return { kind: "blank", val: "" }
  return { kind: "value", val: raw }
}

function requireNewText(obj: Obj, key: string): string {
  const { kind, val } = classify(obj, key)
  if (kind !== "value") throw new ApiError(422, key, "can't be blank")
  return val
}

function optionalText(obj: Obj, key: string): FieldVal {
  const { kind, val } = classify(obj, key)
  if (kind === "absent") return { kind: "absent", val: "" }
  if (kind === "null" || kind === "blank") return { kind: "clear", val: "" }
  return { kind: "set", val }
}

function optionalRequiredText(obj: Obj, key: string): FieldVal {
  const { kind, val } = classify(obj, key)
  if (kind === "absent") return { kind: "absent", val: "" }
  if (kind !== "value") throw new ApiError(422, key, "can't be blank")
  return { kind: "set", val }
}

function checkPasswordValue(password: string): void {
  if (Array.from(password).length < MIN_PASSWORD) {
    throw new ApiError(422, "password", "is too short (minimum is 8 characters)")
  }
}

export function registerFields(user: Obj): { username: string; email: string; password: string } {
  const username = requireNewText(user, "username")
  const email = requireNewText(user, "email")
  const password = requireNewText(user, "password")
  checkPasswordValue(password)
  return { username, email, password }
}

export function loginFields(user: Obj): { email: string; password: string } {
  const email = requireNewText(user, "email")
  const { kind, val } = classify(user, "password")
  if (kind !== "value") throw new ApiError(422, "password", "can't be blank")
  return { email, password: val }
}

export function updateUserFields(user: Obj): UserUpdate {
  const username = optionalRequiredText(user, "username")
  const email = optionalRequiredText(user, "email")
  const passwordKind = classify(user, "password")
  let password: FieldVal
  if (passwordKind.kind === "absent") password = { kind: "absent", val: "" }
  else if (passwordKind.kind === "value") {
    checkPasswordValue(passwordKind.val)
    password = { kind: "set", val: passwordKind.val }
  } else {
    throw new ApiError(422, "password", "can't be blank")
  }
  const bio = optionalText(user, "bio")
  const image = optionalText(user, "image")
  if (
    username.kind === "absent" &&
    email.kind === "absent" &&
    password.kind === "absent" &&
    bio.kind === "absent" &&
    image.kind === "absent"
  ) {
    throw new ApiError(422, "user", "is invalid")
  }
  return { username, email, password, bio, image }
}

export function parseTagList(article: Obj): TagField {
  if (!Object.prototype.hasOwnProperty.call(article, "tagList")) return { kind: "absent", tags: [] }
  const raw = article.tagList
  if (raw === null || !Array.isArray(raw)) throw new ApiError(422, "tagList", "is invalid")
  const seen = new Set<string>()
  const tags: string[] = []
  for (const item of raw) {
    if (typeof item !== "string") throw new ApiError(422, "tagList", "is invalid")
    if (item === "" || seen.has(item)) continue
    seen.add(item)
    tags.push(item)
  }
  return { kind: "replace", tags }
}

export function articleCreateFields(article: Obj): {
  title: string
  description: string
  body: string
  tags: string[]
} {
  const title = requireNewText(article, "title")
  const description = requireNewText(article, "description")
  const body = requireNewText(article, "body")
  const tags = parseTagList(article)
  return { title, description, body, tags: tags.kind === "absent" ? [] : tags.tags }
}

export function articleUpdateFields(article: Obj): ArticleUpdate {
  const title = optionalRequiredText(article, "title")
  const description = optionalRequiredText(article, "description")
  const body = optionalRequiredText(article, "body")
  const tags = parseTagList(article)
  if (title.kind === "absent" && description.kind === "absent" && body.kind === "absent" && tags.kind === "absent") {
    throw new ApiError(422, "article", "is invalid")
  }
  return { title, description, body, tags }
}

export function commentBody(comment: Obj): string {
  return requireNewText(comment, "body")
}

export function pageParams(limitRaw: string, offsetRaw: string): { limit: number; offset: number } {
  let limit = 20
  let offset = 0
  if (limitRaw !== "") {
    if (!/^[0-9]+$/.test(limitRaw)) throw new ApiError(422, "limit", "is invalid")
    limit = Number(limitRaw)
    if (limit < 1) throw new ApiError(422, "limit", "is invalid")
    if (limit > 100) limit = 100
  }
  if (offsetRaw !== "") {
    if (!/^[0-9]+$/.test(offsetRaw)) throw new ApiError(422, "offset", "is invalid")
    offset = Number(offsetRaw)
  }
  return { limit, offset }
}
