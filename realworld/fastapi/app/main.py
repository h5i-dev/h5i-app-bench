"""Conduit HTTP API on FastAPI, asyncpg, bcrypt cost 12, JWT HS256."""

from __future__ import annotations

import asyncio
import os
import time
from contextlib import asynccontextmanager

import asyncpg
import bcrypt
import jwt
from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse, Response

from app.logic import (
    BCRYPT_COST,
    ApiError,
    article_create_fields,
    article_update_fields,
    comment_body,
    login_fields,
    page_params,
    register_fields,
    slugify,
    update_user_fields,
    with_suffix,
)

DATABASE_URL = os.environ.get(
    "DATABASE_URL", "postgres://conduit:conduit@127.0.0.1:54329/conduit"
)
JWT_SECRET = os.environ.get("JWT_SECRET", "conduit-benchmark-secret")
JWT_TTL = 60 * 24 * 3600
DB_POOL = int(os.environ.get("DB_POOL", "8"))

TS = "to_char({col} AT TIME ZONE 'UTC', 'YYYY-MM-DD\"T\"HH24:MI:SS.MS\"Z\"')"


def article_select(include_body: bool) -> str:
    body = "a.body," if include_body else ""
    return f"""
    SELECT
      a.id,
      a.slug,
      a.title,
      a.description,
      {body}
      {TS.format(col="a.created_at")} AS created_at,
      {TS.format(col="a.updated_at")} AS updated_at,
      u.username AS author_username,
      u.bio AS author_bio,
      u.image AS author_image,
      (SELECT count(*)::int FROM favorites f WHERE f.article_id = a.id) AS favorites_count,
      EXISTS(
        SELECT 1 FROM favorites f WHERE f.article_id = a.id AND f.user_id = $1
      ) AS favorited,
      EXISTS(
        SELECT 1 FROM follows fl
        WHERE fl.follower_id = $1 AND fl.followee_id = a.author_id
      ) AS following,
      COALESCE(
        (SELECT array_agg(t.name ORDER BY at.position)
         FROM article_tags at
         JOIN tags t ON t.id = at.tag_id
         WHERE at.article_id = a.id),
        ARRAY[]::text[]
      ) AS tag_list
    FROM articles a
    JOIN users u ON u.id = a.author_id
    """


DETAIL_SQL = article_select(True)
LIST_SQL = article_select(False)


def sign_token(user_id: int) -> str:
    payload = {"sub": str(user_id), "exp": int(time.time()) + JWT_TTL}
    return jwt.encode(payload, JWT_SECRET, algorithm="HS256")


def read_token(header: str | None, required: bool) -> int | None:
    if header is None or header.strip() == "":
        if required:
            raise ApiError(401, "token", "is missing")
        return None
    if not header.startswith("Token "):
        raise ApiError(401, "token", "is invalid")
    raw = header[6:].strip()
    if not raw:
        raise ApiError(401, "token", "is invalid")
    try:
        payload = jwt.decode(raw, JWT_SECRET, algorithms=["HS256"])
        uid = int(payload["sub"])
    except Exception as exc:
        raise ApiError(401, "token", "is invalid") from exc
    if uid <= 0:
        raise ApiError(401, "token", "is invalid")
    return uid


async def hash_password(password: str) -> str:
    hashed = await asyncio.to_thread(
        bcrypt.hashpw, password.encode("utf-8"), bcrypt.gensalt(BCRYPT_COST)
    )
    return hashed.decode("utf-8")


async def check_password(password: str, hashed: str, dummy: bytes) -> bool:
    target = hashed.encode("utf-8") if hashed else dummy
    return await asyncio.to_thread(bcrypt.checkpw, password.encode("utf-8"), target)


def user_json(row, token: str) -> dict:
    return {
        "email": row["email"],
        "token": token,
        "username": row["username"],
        "bio": row["bio"],
        "image": row["image"],
    }


def profile_json(username: str, bio, image, following: bool) -> dict:
    return {
        "username": username,
        "bio": bio,
        "image": image,
        "following": following,
    }


def article_json(row, include_body: bool) -> dict:
    out = {
        "slug": row["slug"],
        "title": row["title"],
        "description": row["description"],
        "tagList": list(row["tag_list"] or []),
        "createdAt": row["created_at"],
        "updatedAt": row["updated_at"],
        "favorited": bool(row["favorited"]),
        "favoritesCount": int(row["favorites_count"]),
        "author": profile_json(
            row["author_username"],
            row["author_bio"],
            row["author_image"],
            bool(row["following"]),
        ),
    }
    if include_body:
        out["body"] = row["body"]
    return out


def comment_json(row) -> dict:
    return {
        "id": int(row["id"]),
        "createdAt": row["created_at"],
        "updatedAt": row["updated_at"],
        "body": row["body"],
        "author": profile_json(
            row["author_username"],
            row["author_bio"],
            row["author_image"],
            bool(row["following"]),
        ),
    }


async def read_object(request: Request, key: str) -> dict:
    raw = await request.body()
    if not raw:
        raise ApiError(422, "body", "is invalid")
    try:
        import json

        data = json.loads(raw)
    except Exception as exc:
        raise ApiError(422, "body", "is invalid") from exc
    if not isinstance(data, dict) or not isinstance(data.get(key), dict):
        raise ApiError(422, key, "is invalid")
    return data[key]


def conflict_from(exc: asyncpg.UniqueViolationError, fallback: str) -> ApiError:
    name = exc.constraint_name or ""
    if "username" in name:
        return ApiError(409, "username", "has already been taken")
    if "email" in name:
        return ApiError(409, "email", "has already been taken")
    if "slug" in name:
        return ApiError(409, "slug", "has already been taken")
    return ApiError(409, fallback, "has already been taken")


async def load_user(conn, uid: int):
    row = await conn.fetchrow(
        "SELECT id, username, email, bio, image, password_hash FROM users WHERE id = $1",
        uid,
    )
    if row is None:
        raise ApiError(401, "token", "is invalid")
    return row


async def following(conn, viewer: int, author_id: int) -> bool:
    if viewer <= 0:
        return False
    return bool(
        await conn.fetchval(
            """
            SELECT EXISTS(
              SELECT 1 FROM follows
              WHERE follower_id = $1 AND followee_id = $2
            )
            """,
            viewer,
            author_id,
        )
    )


async def add_tags(conn, article_id: int, tags: list[str]) -> None:
    for pos, name in enumerate(tags):
        tag_id = await conn.fetchval(
            """
            INSERT INTO tags (name) VALUES ($1)
            ON CONFLICT (name) DO UPDATE SET name = EXCLUDED.name
            RETURNING id
            """,
            name,
        )
        await conn.execute(
            """
            INSERT INTO article_tags (article_id, tag_id, position)
            VALUES ($1, $2, $3)
            """,
            article_id,
            tag_id,
            pos,
        )


async def unique_slug(conn, title: str, exclude_id: int | None) -> str:
    base = slugify(title)
    n = 0
    while n < 100000:
        slug = with_suffix(base, n)
        row = await conn.fetchrow("SELECT id FROM articles WHERE slug = $1", slug)
        if row is None or (exclude_id is not None and row["id"] == exclude_id):
            return slug
        n += 1
    raise ApiError(409, "slug", "has already been taken")


async def fetch_article(conn, viewer: int, slug: str, include_body: bool):
    sql = (DETAIL_SQL if include_body else LIST_SQL) + " WHERE a.slug = $2"
    return await conn.fetchrow(sql, viewer, slug)


def list_filters(viewer: int, tag, author, favorited, feed: bool):
    args: list = [viewer]
    # $1 is the viewer. The count query has no favorited/following subselect,
    # so give the parameter a type and a use even when no other filter names it.
    conds: list[str] = ["$1::bigint >= 0"]

    def bind(value):
        args.append(value)
        return f"${len(args)}"

    if feed:
        conds.append(
            "EXISTS (SELECT 1 FROM follows fl WHERE fl.follower_id = $1 AND fl.followee_id = a.author_id)"
        )
    if tag is not None:
        ph = bind(tag)
        conds.append(
            f"""EXISTS (
                SELECT 1 FROM article_tags at
                JOIN tags t ON t.id = at.tag_id
                WHERE at.article_id = a.id AND t.name = {ph}
            )"""
        )
    if author is not None:
        ph = bind(author)
        conds.append(f"u.username = {ph}")
    if favorited is not None:
        ph = bind(favorited)
        conds.append(
            f"""EXISTS (
                SELECT 1 FROM favorites fv
                JOIN users fu ON fu.id = fv.user_id
                WHERE fv.article_id = a.id AND fu.username = {ph}
            )"""
        )
    where = (" WHERE " + " AND ".join(conds)) if conds else ""
    return where, args


@asynccontextmanager
async def lifespan(app: FastAPI):
    app.state.pool = await asyncpg.create_pool(
        DATABASE_URL, min_size=1, max_size=DB_POOL, command_timeout=30
    )
    app.state.dummy = await asyncio.to_thread(
        bcrypt.hashpw, b"dummy-password-for-timing", bcrypt.gensalt(BCRYPT_COST)
    )
    yield
    await app.state.pool.close()


app = FastAPI(lifespan=lifespan, docs_url=None, redoc_url=None, openapi_url=None)


@app.exception_handler(ApiError)
async def on_api_error(_request: Request, exc: ApiError):
    return JSONResponse(
        status_code=exc.status, content={"errors": {exc.field: [exc.message]}}
    )


@app.get("/healthz")
async def healthz():
    async with app.state.pool.acquire() as conn:
        await conn.fetchval("SELECT 1")
    return {"ok": True}


@app.post("/api/users")
async def register(request: Request):
    user = await read_object(request, "user")
    username, email, password = register_fields(user)
    password_hash = await hash_password(password)
    async with app.state.pool.acquire() as conn:
        taken = await conn.fetchrow(
            "SELECT username, email FROM users WHERE username = $1 OR email = $2",
            username,
            email,
        )
        if taken is not None:
            if taken["username"] == username:
                raise ApiError(409, "username", "has already been taken")
            raise ApiError(409, "email", "has already been taken")
        try:
            row = await conn.fetchrow(
                """
                INSERT INTO users (username, email, password_hash)
                VALUES ($1, $2, $3)
                RETURNING id, username, email, bio, image
                """,
                username,
                email,
                password_hash,
            )
        except asyncpg.UniqueViolationError as exc:
            raise conflict_from(exc, "username") from exc
    return JSONResponse(
        status_code=201, content={"user": user_json(row, sign_token(row["id"]))}
    )


@app.post("/api/users/login")
async def login(request: Request):
    user = await read_object(request, "user")
    email, password = login_fields(user)
    async with app.state.pool.acquire() as conn:
        row = await conn.fetchrow(
            "SELECT id, username, email, bio, image, password_hash FROM users WHERE email = $1",
            email,
        )
    hashed = row["password_hash"] if row else ""
    ok = await check_password(password, hashed, app.state.dummy)
    if row is None or not ok:
        raise ApiError(401, "credentials", "invalid")
    return {"user": user_json(row, sign_token(row["id"]))}


@app.get("/api/user")
async def current_user(request: Request):
    uid = read_token(request.headers.get("authorization"), required=True)
    async with app.state.pool.acquire() as conn:
        row = await load_user(conn, uid)
    return {"user": user_json(row, sign_token(row["id"]))}


@app.put("/api/user")
async def update_user(request: Request):
    uid = read_token(request.headers.get("authorization"), required=True)
    user = await read_object(request, "user")
    fields = update_user_fields(user)
    async with app.state.pool.acquire() as conn:
        async with conn.transaction():
            row = await load_user(conn, uid)
            if fields["username"][0] == "set":
                name = fields["username"][1]
                clash = await conn.fetchval(
                    "SELECT 1 FROM users WHERE username = $1 AND id <> $2", name, uid
                )
                if clash:
                    raise ApiError(409, "username", "has already been taken")
            if fields["email"][0] == "set":
                email = fields["email"][1]
                clash = await conn.fetchval(
                    "SELECT 1 FROM users WHERE email = $1 AND id <> $2", email, uid
                )
                if clash:
                    raise ApiError(409, "email", "has already been taken")
            sets = []
            args: list = []

            def bind(column: str, value):
                args.append(value)
                sets.append(f"{column} = ${len(args)}")

            if fields["username"][0] == "set":
                bind("username", fields["username"][1])
            if fields["email"][0] == "set":
                bind("email", fields["email"][1])
            if fields["password"][0] == "set":
                bind("password_hash", await hash_password(fields["password"][1]))
            if fields["bio"][0] == "set":
                bind("bio", fields["bio"][1])
            elif fields["bio"][0] == "clear":
                sets.append("bio = NULL")
            if fields["image"][0] == "set":
                bind("image", fields["image"][1])
            elif fields["image"][0] == "clear":
                sets.append("image = NULL")
            args.append(uid)
            try:
                updated = await conn.fetchrow(
                    f"""
                    UPDATE users SET {", ".join(sets)}
                    WHERE id = ${len(args)}
                    RETURNING id, username, email, bio, image
                    """,
                    *args,
                )
            except asyncpg.UniqueViolationError as exc:
                raise conflict_from(exc, "username") from exc
    return {"user": user_json(updated, sign_token(updated["id"]))}


@app.get("/api/profiles/{username}")
async def get_profile(username: str, request: Request):
    viewer = read_token(request.headers.get("authorization"), required=False) or 0
    async with app.state.pool.acquire() as conn:
        if viewer:
            await load_user(conn, viewer)
        row = await conn.fetchrow(
            """
            SELECT id, username, bio, image,
              EXISTS(
                SELECT 1 FROM follows
                WHERE follower_id = $1 AND followee_id = users.id
              ) AS following
            FROM users WHERE username = $2
            """,
            viewer,
            username,
        )
    if row is None:
        raise ApiError(404, "profile", "not found")
    return {
        "profile": profile_json(row["username"], row["bio"], row["image"], bool(row["following"]))
    }


async def set_follow(username: str, request: Request, follow: bool):
    uid = read_token(request.headers.get("authorization"), required=True)
    async with app.state.pool.acquire() as conn:
        async with conn.transaction():
            await load_user(conn, uid)
            target = await conn.fetchrow(
                "SELECT id, username, bio, image FROM users WHERE username = $1",
                username,
            )
            if target is None:
                raise ApiError(404, "profile", "not found")
            if follow:
                await conn.execute(
                    """
                    INSERT INTO follows (follower_id, followee_id)
                    VALUES ($1, $2)
                    ON CONFLICT DO NOTHING
                    """,
                    uid,
                    target["id"],
                )
            else:
                await conn.execute(
                    "DELETE FROM follows WHERE follower_id = $1 AND followee_id = $2",
                    uid,
                    target["id"],
                )
    return {
        "profile": profile_json(target["username"], target["bio"], target["image"], follow)
    }


@app.post("/api/profiles/{username}/follow")
async def follow_user(username: str, request: Request):
    return await set_follow(username, request, True)


@app.delete("/api/profiles/{username}/follow")
async def unfollow_user(username: str, request: Request):
    return await set_follow(username, request, False)


@app.get("/api/articles/feed")
async def feed(request: Request):
    uid = read_token(request.headers.get("authorization"), required=True)
    limit, offset = page_params(
        request.query_params.get("limit"), request.query_params.get("offset")
    )
    return await list_articles(uid, None, None, None, True, limit, offset)


@app.get("/api/articles")
async def list_articles_route(request: Request):
    viewer = read_token(request.headers.get("authorization"), required=False) or 0
    limit, offset = page_params(
        request.query_params.get("limit"), request.query_params.get("offset")
    )
    tag = request.query_params.get("tag")
    author = request.query_params.get("author")
    favorited = request.query_params.get("favorited")
    return await list_articles(viewer, tag, author, favorited, False, limit, offset)


async def list_articles(viewer, tag, author, favorited, feed_only, limit, offset):
    where, args = list_filters(viewer, tag, author, favorited, feed_only)
    count_args = list(args)
    args.append(limit)
    limit_ph = f"${len(args)}"
    args.append(offset)
    offset_ph = f"${len(args)}"
    sql = (
        LIST_SQL
        + where
        + f" ORDER BY a.created_at DESC, a.id DESC LIMIT {limit_ph} OFFSET {offset_ph}"
    )
    count_sql = (
        "SELECT count(*)::int FROM articles a JOIN users u ON u.id = a.author_id" + where
    )
    async with app.state.pool.acquire() as conn:
        if viewer:
            await load_user(conn, viewer)
        rows = await conn.fetch(sql, *args)
        total = await conn.fetchval(count_sql, *count_args)
    return {
        "articles": [article_json(row, include_body=False) for row in rows],
        "articlesCount": int(total),
    }


@app.post("/api/articles")
async def create_article(request: Request):
    uid = read_token(request.headers.get("authorization"), required=True)
    article = await read_object(request, "article")
    title, description, body, tags = article_create_fields(article)
    tags = tags or []
    async with app.state.pool.acquire() as conn:
        author = await load_user(conn, uid)
        row = None
        for _ in range(8):
            slug = await unique_slug(conn, title, None)
            try:
                async with conn.transaction():
                    row = await conn.fetchrow(
                        f"""
                        INSERT INTO articles (author_id, slug, title, description, body)
                        VALUES ($1, $2, $3, $4, $5)
                        RETURNING id,
                          {TS.format(col="created_at")} AS created_at,
                          {TS.format(col="updated_at")} AS updated_at
                        """,
                        uid,
                        slug,
                        title,
                        description,
                        body,
                    )
                    await add_tags(conn, row["id"], tags)
                break
            except asyncpg.UniqueViolationError:
                row = None
                continue
        if row is None:
            raise ApiError(409, "slug", "has already been taken")
        follows_author = await following(conn, uid, uid)
    return JSONResponse(
        status_code=201,
        content={
            "article": {
                "slug": slug,
                "title": title,
                "description": description,
                "body": body,
                "tagList": tags,
                "createdAt": row["created_at"],
                "updatedAt": row["updated_at"],
                "favorited": False,
                "favoritesCount": 0,
                "author": profile_json(
                    author["username"], author["bio"], author["image"], follows_author
                ),
            }
        },
    )


@app.get("/api/articles/{slug}")
async def get_article(slug: str, request: Request):
    viewer = read_token(request.headers.get("authorization"), required=False) or 0
    async with app.state.pool.acquire() as conn:
        if viewer:
            await load_user(conn, viewer)
        row = await fetch_article(conn, viewer, slug, True)
    if row is None:
        raise ApiError(404, "article", "not found")
    return {"article": article_json(row, True)}


@app.put("/api/articles/{slug}")
async def update_article(slug: str, request: Request):
    uid = read_token(request.headers.get("authorization"), required=True)
    article = await read_object(request, "article")
    fields = article_update_fields(article)
    async with app.state.pool.acquire() as conn:
        async with conn.transaction():
            await load_user(conn, uid)
            current = await conn.fetchrow(
                "SELECT id, author_id, slug, title FROM articles WHERE slug = $1", slug
            )
            if current is None:
                raise ApiError(404, "article", "not found")
            if current["author_id"] != uid:
                raise ApiError(403, "article", "forbidden")
            sets = [
                "updated_at = GREATEST(statement_timestamp(), updated_at + interval '1 millisecond')"
            ]
            args: list = []

            def bind(column: str, value):
                args.append(value)
                sets.append(f"{column} = ${len(args)}")

            if fields["title"][0] == "set":
                new_slug = await unique_slug(conn, fields["title"][1], current["id"])
                bind("title", fields["title"][1])
                bind("slug", new_slug)
            if fields["description"][0] == "set":
                bind("description", fields["description"][1])
            if fields["body"][0] == "set":
                bind("body", fields["body"][1])
            args.append(current["id"])
            try:
                await conn.execute(
                    f"UPDATE articles SET {', '.join(sets)} WHERE id = ${len(args)}",
                    *args,
                )
            except asyncpg.UniqueViolationError as exc:
                raise conflict_from(exc, "slug") from exc
            if fields["tags"][0] == "replace":
                await conn.execute(
                    "DELETE FROM article_tags WHERE article_id = $1", current["id"]
                )
                await add_tags(conn, current["id"], fields["tags"][1])
            fresh = await conn.fetchrow(
                "SELECT slug FROM articles WHERE id = $1", current["id"]
            )
        row = await fetch_article(conn, uid, fresh["slug"], True)
    return {"article": article_json(row, True)}


@app.delete("/api/articles/{slug}")
async def delete_article(slug: str, request: Request):
    uid = read_token(request.headers.get("authorization"), required=True)
    async with app.state.pool.acquire() as conn:
        await load_user(conn, uid)
        current = await conn.fetchrow(
            "SELECT id, author_id FROM articles WHERE slug = $1", slug
        )
        if current is None:
            raise ApiError(404, "article", "not found")
        if current["author_id"] != uid:
            raise ApiError(403, "article", "forbidden")
        await conn.execute("DELETE FROM articles WHERE id = $1", current["id"])
    return Response(status_code=204)


@app.get("/api/articles/{slug}/comments")
async def list_comments(slug: str, request: Request):
    viewer = read_token(request.headers.get("authorization"), required=False) or 0
    async with app.state.pool.acquire() as conn:
        if viewer:
            await load_user(conn, viewer)
        article = await conn.fetchrow("SELECT id FROM articles WHERE slug = $1", slug)
        if article is None:
            raise ApiError(404, "article", "not found")
        rows = await conn.fetch(
            f"""
            SELECT c.id, c.body,
              {TS.format(col="c.created_at")} AS created_at,
              {TS.format(col="c.updated_at")} AS updated_at,
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
            ORDER BY c.created_at ASC, c.id ASC
            """,
            viewer,
            article["id"],
        )
    return {"comments": [comment_json(row) for row in rows]}


@app.post("/api/articles/{slug}/comments")
async def create_comment(slug: str, request: Request):
    uid = read_token(request.headers.get("authorization"), required=True)
    comment = await read_object(request, "comment")
    body = comment_body(comment)
    async with app.state.pool.acquire() as conn:
        author = await load_user(conn, uid)
        article = await conn.fetchrow("SELECT id FROM articles WHERE slug = $1", slug)
        if article is None:
            raise ApiError(404, "article", "not found")
        row = await conn.fetchrow(
            f"""
            INSERT INTO comments (article_id, author_id, body)
            VALUES ($1, $2, $3)
            RETURNING id,
              {TS.format(col="created_at")} AS created_at,
              {TS.format(col="updated_at")} AS updated_at
            """,
            article["id"],
            uid,
            body,
        )
        follows_author = await following(conn, uid, uid)
    return JSONResponse(
        status_code=201,
        content={
            "comment": {
                "id": int(row["id"]),
                "createdAt": row["created_at"],
                "updatedAt": row["updated_at"],
                "body": body,
                "author": profile_json(
                    author["username"], author["bio"], author["image"], follows_author
                ),
            }
        },
    )


@app.delete("/api/articles/{slug}/comments/{comment_id}")
async def delete_comment(slug: str, comment_id: int, request: Request):
    uid = read_token(request.headers.get("authorization"), required=True)
    async with app.state.pool.acquire() as conn:
        await load_user(conn, uid)
        article = await conn.fetchrow("SELECT id FROM articles WHERE slug = $1", slug)
        if article is None:
            raise ApiError(404, "article", "not found")
        comment = await conn.fetchrow(
            "SELECT id, author_id FROM comments WHERE id = $1 AND article_id = $2",
            comment_id,
            article["id"],
        )
        if comment is None:
            raise ApiError(404, "comment", "not found")
        if comment["author_id"] != uid:
            raise ApiError(403, "comment", "forbidden")
        await conn.execute("DELETE FROM comments WHERE id = $1", comment["id"])
    return Response(status_code=204)


async def favorite(slug: str, request: Request, on: bool):
    uid = read_token(request.headers.get("authorization"), required=True)
    async with app.state.pool.acquire() as conn:
        async with conn.transaction():
            await load_user(conn, uid)
            article = await conn.fetchrow("SELECT id FROM articles WHERE slug = $1", slug)
            if article is None:
                raise ApiError(404, "article", "not found")
            if on:
                await conn.execute(
                    """
                    INSERT INTO favorites (user_id, article_id)
                    VALUES ($1, $2)
                    ON CONFLICT DO NOTHING
                    """,
                    uid,
                    article["id"],
                )
            else:
                await conn.execute(
                    "DELETE FROM favorites WHERE user_id = $1 AND article_id = $2",
                    uid,
                    article["id"],
                )
        row = await fetch_article(conn, uid, slug, True)
    return {"article": article_json(row, True)}


@app.post("/api/articles/{slug}/favorite")
async def favorite_article(slug: str, request: Request):
    return await favorite(slug, request, True)


@app.delete("/api/articles/{slug}/favorite")
async def unfavorite_article(slug: str, request: Request):
    return await favorite(slug, request, False)


@app.get("/api/tags")
async def tags():
    async with app.state.pool.acquire() as conn:
        rows = await conn.fetch("SELECT name FROM tags ORDER BY name ASC")
    return {"tags": [row["name"] for row in rows]}
