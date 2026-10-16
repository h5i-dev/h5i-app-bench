"""Linkding REST API. No website metadata, favicon, preview, or snapshot I/O."""

from __future__ import annotations

import os
import traceback
from contextlib import asynccontextmanager

import asyncpg
from fastapi import FastAPI, HTTPException, Request
from fastapi.responses import JSONResponse, Response

from .db import (
    create_bookmark,
    create_bundle,
    create_tag,
    delete_bookmark,
    delete_bundle,
    delete_tag,
    find_existing,
    get_bundle,
    get_owned,
    get_tag,
    list_bookmarks,
    list_bundles,
    list_tags,
    load_user_by_token,
    profile_json,
    serialize_one,
    set_archived,
    update_bookmark,
    update_bundle,
)
from .logic import (
    APP_VERSION,
    AUTH_DETAIL,
    classify_auth,
    validate_bookmark,
    validate_bundle,
    validate_tag,
)


def respond(payload, status: int = 200, headers: dict | None = None) -> JSONResponse:
    return JSONResponse(payload, status_code=status, headers=headers)


def auth_error(kind: str) -> JSONResponse:
    return respond({"detail": AUTH_DETAIL[kind]}, 401, {"WWW-Authenticate": "Token"})


def not_found(kind: str) -> JSONResponse:
    names = {
        "bookmark": "No Bookmark matches the given query.",
        "tag": "No Tag matches the given query.",
        "bundle": "No BookmarkBundle matches the given query.",
    }
    return respond({"detail": names[kind]}, 404)


def query_map(request: Request) -> dict:
    out = {}
    for key in request.query_params.keys():
        values = request.query_params.getlist(key)
        if values:
            out[key] = values[-1]
    return out


def path_id(raw: str) -> int | None:
    if not raw.isdigit():
        return None
    try:
        return int(raw)
    except ValueError:
        return None


async def read_body(request: Request):
    ctype = request.headers.get("content-type", "")
    media = ctype.split(";")[0].strip().lower()
    if media == "":
        return {}, None
    if media != "application/json":
        shown = media
        return None, respond(
            {"detail": f'Unsupported media type "{shown}" in request.'},
            415,
        )
    raw = await request.body()
    import json

    try:
        text = raw.decode("utf-8")
    except UnicodeDecodeError:
        return None, respond(
            {"detail": "JSON parse error - Expecting value: line 1 column 1 (char 0)"},
            400,
        )
    # An empty JSON body is "no data", which surfaces as missing fields.
    # Whitespace and other invalid text are parse errors.
    if text == "":
        return {}, None
    try:
        data = json.loads(text)
    except json.JSONDecodeError as exc:
        return None, respond({"detail": f"JSON parse error - {exc}"}, 400)
    if data is None:
        return None, respond({"non_field_errors": ["No data provided"]}, 400)
    if not isinstance(data, dict):
        return None, respond(
            {
                "non_field_errors": [
                    f"Invalid data. Expected a dictionary, but got {type(data).__name__}."
                ]
            },
            400,
        )
    return data, None


async def authenticate(request: Request, required: bool):
    kind, token = classify_auth(request.headers.get("authorization"))
    if kind == "absent":
        if required:
            return None, auth_error("absent")
        return None, None
    if kind != "token":
        return None, auth_error(kind)
    async with request.app.state.pool.acquire() as conn:
        user = await load_user_by_token(conn, token)
    if user is None:
        return None, auth_error("bad")
    return user, None


async def init_conn(conn):
    await conn.execute("SET TIME ZONE 'UTC'")


@asynccontextmanager
async def lifespan(app: FastAPI):
    dsn = os.environ.get(
        "DATABASE_URL", "postgres://linkding:linkding@127.0.0.1:5440/linkding"
    )
    pool = await asyncpg.create_pool(
        dsn,
        min_size=1,
        max_size=int(os.environ.get("DB_POOL", "8")),
        init=init_conn,
    )
    app.state.pool = pool
    yield
    await pool.close()


app = FastAPI(lifespan=lifespan, version=APP_VERSION)


@app.exception_handler(Exception)
async def on_error(_request: Request, exc: Exception):
    if isinstance(exc, HTTPException):
        return respond({"detail": exc.detail}, exc.status_code)
    traceback.print_exception(exc)
    return respond({"detail": "Server error."}, 500)


@app.get("/healthz")
async def healthz(request: Request):
    async with request.app.state.pool.acquire() as conn:
        await conn.fetchval("SELECT 1")
    return Response("ok", media_type="text/plain")


@app.get("/api/user/profile/")
async def profile(request: Request):
    user, err = await authenticate(request, True)
    if err:
        return err
    return respond(profile_json(user))


@app.api_route(
    "/api/user/profile/",
    methods=["PUT", "PATCH", "POST", "DELETE"],
)
async def profile_method(request: Request):
    return respond(
        {"detail": f'Method "{request.method}" not allowed.'},
        405,
        {"Allow": "GET, HEAD, OPTIONS"},
    )


@app.get("/api/bookmarks/")
async def bookmark_list(request: Request):
    user, err = await authenticate(request, True)
    if err:
        return err
    async with request.app.state.pool.acquire() as conn:
        payload = await list_bookmarks(
            conn, "active", user, False, str(request.url), query_map(request)
        )
    return respond(payload)


@app.post("/api/bookmarks/")
async def bookmark_create(request: Request):
    user, err = await authenticate(request, True)
    if err:
        return err
    data, err = await read_body(request)
    if err:
        return err
    errors, cleaned = validate_bookmark(data, partial=False)
    if errors:
        return respond(errors, 400)
    async with request.app.state.pool.acquire() as conn:
        row = await create_bookmark(conn, user["id"], cleaned)
        payload = await serialize_one(conn, row)
    return respond(payload, 201, {"Location": payload["url"]})


@app.get("/api/bookmarks/archived/")
async def bookmark_archived(request: Request):
    user, err = await authenticate(request, True)
    if err:
        return err
    async with request.app.state.pool.acquire() as conn:
        payload = await list_bookmarks(
            conn, "archived", user, False, str(request.url), query_map(request)
        )
    return respond(payload)


@app.get("/api/bookmarks/shared/")
async def bookmark_shared(request: Request):
    user, err = await authenticate(request, False)
    if err:
        return err
    async with request.app.state.pool.acquire() as conn:
        payload = await list_bookmarks(
            conn,
            "shared",
            user,
            user is None,
            str(request.url),
            query_map(request),
        )
    return respond(payload)


@app.get("/api/bookmarks/check/")
async def bookmark_check(request: Request):
    user, err = await authenticate(request, True)
    if err:
        return err
    qp = query_map(request)
    bookmark = None
    if "url" in qp:
        async with request.app.state.pool.acquire() as conn:
            row = await find_existing(conn, user["id"], qp["url"])
            if row is not None:
                bookmark = await serialize_one(conn, row)
        meta_url = qp["url"]
    else:
        meta_url = None
    return respond(
        {
            "bookmark": bookmark,
            "metadata": {
                "url": meta_url,
                "title": None,
                "description": None,
                "preview_image": None,
            },
            "auto_tags": [],
        }
    )


@app.get("/api/bookmarks/{bookmark_id}/")
async def bookmark_get(request: Request, bookmark_id: str):
    user, err = await authenticate(request, True)
    if err:
        return err
    ident = path_id(bookmark_id)
    if ident is None:
        return not_found("bookmark")
    async with request.app.state.pool.acquire() as conn:
        row = await get_owned(conn, user["id"], ident)
        if row is None:
            return not_found("bookmark")
        return respond(await serialize_one(conn, row))


@app.api_route("/api/bookmarks/{bookmark_id}/", methods=["PUT", "PATCH"])
async def bookmark_update(request: Request, bookmark_id: str):
    user, err = await authenticate(request, True)
    if err:
        return err
    ident = path_id(bookmark_id)
    if ident is None:
        return not_found("bookmark")
    async with request.app.state.pool.acquire() as conn:
        existing = await get_owned(conn, user["id"], ident)
    if existing is None:
        return not_found("bookmark")
    data, err = await read_body(request)
    if err:
        return err
    errors, cleaned = validate_bookmark(data, partial=request.method == "PATCH")
    if errors:
        return respond(errors, 400)
    async with request.app.state.pool.acquire() as conn:
        row, problem = await update_bookmark(conn, user["id"], ident, cleaned)
        if problem == "duplicate":
            return respond({"url": ["A bookmark with this URL already exists."]}, 400)
        if row is None:
            return not_found("bookmark")
        return respond(await serialize_one(conn, row))


@app.delete("/api/bookmarks/{bookmark_id}/")
async def bookmark_delete(request: Request, bookmark_id: str):
    user, err = await authenticate(request, True)
    if err:
        return err
    ident = path_id(bookmark_id)
    if ident is None:
        return not_found("bookmark")
    async with request.app.state.pool.acquire() as conn:
        deleted = await delete_bookmark(conn, user["id"], ident)
    if not deleted:
        return not_found("bookmark")
    return Response(status_code=204)


@app.post("/api/bookmarks/{bookmark_id}/archive/")
async def bookmark_archive(request: Request, bookmark_id: str):
    return await _archive(request, bookmark_id, True)


@app.post("/api/bookmarks/{bookmark_id}/unarchive/")
async def bookmark_unarchive(request: Request, bookmark_id: str):
    return await _archive(request, bookmark_id, False)


async def _archive(request: Request, bookmark_id: str, archived: bool):
    user, err = await authenticate(request, True)
    if err:
        return err
    ident = path_id(bookmark_id)
    if ident is None:
        return not_found("bookmark")
    async with request.app.state.pool.acquire() as conn:
        row = await set_archived(conn, user["id"], ident, archived)
    if row is None:
        return not_found("bookmark")
    return Response(status_code=204)


@app.get("/api/tags/")
async def tag_list(request: Request):
    user, err = await authenticate(request, True)
    if err:
        return err
    async with request.app.state.pool.acquire() as conn:
        payload = await list_tags(conn, user["id"], str(request.url), query_map(request))
    return respond(payload)


@app.post("/api/tags/")
async def tag_create(request: Request):
    user, err = await authenticate(request, True)
    if err:
        return err
    data, err = await read_body(request)
    if err:
        return err
    errors, name = validate_tag(data)
    if errors:
        return respond(errors, 400)
    async with request.app.state.pool.acquire() as conn:
        row = await create_tag(conn, user["id"], name)
    from .db import tag_json

    return respond(tag_json(row), 201)


@app.get("/api/tags/{tag_id}/")
async def tag_get(request: Request, tag_id: str):
    user, err = await authenticate(request, True)
    if err:
        return err
    ident = path_id(tag_id)
    if ident is None:
        return not_found("tag")
    async with request.app.state.pool.acquire() as conn:
        row = await get_tag(conn, user["id"], ident)
    if row is None:
        return not_found("tag")
    from .db import tag_json

    return respond(tag_json(row))


@app.delete("/api/tags/{tag_id}/")
async def tag_delete(request: Request, tag_id: str):
    user, err = await authenticate(request, True)
    if err:
        return err
    ident = path_id(tag_id)
    if ident is None:
        return not_found("tag")
    async with request.app.state.pool.acquire() as conn:
        deleted = await delete_tag(conn, user["id"], ident)
    if not deleted:
        return not_found("tag")
    return Response(status_code=204)


@app.get("/api/bundles/")
async def bundle_list(request: Request):
    user, err = await authenticate(request, True)
    if err:
        return err
    async with request.app.state.pool.acquire() as conn:
        payload = await list_bundles(conn, user["id"], str(request.url), query_map(request))
    return respond(payload)


@app.post("/api/bundles/")
async def bundle_create(request: Request):
    user, err = await authenticate(request, True)
    if err:
        return err
    data, err = await read_body(request)
    if err:
        return err
    errors, cleaned = validate_bundle(data, partial=False)
    if errors:
        return respond(errors, 400)
    async with request.app.state.pool.acquire() as conn:
        row = await create_bundle(conn, user["id"], cleaned)
    from .db import bundle_json

    return respond(bundle_json(row), 201)


@app.get("/api/bundles/{bundle_id}/")
async def bundle_get(request: Request, bundle_id: str):
    user, err = await authenticate(request, True)
    if err:
        return err
    ident = path_id(bundle_id)
    if ident is None:
        return not_found("bundle")
    async with request.app.state.pool.acquire() as conn:
        row = await get_bundle(conn, user["id"], ident)
    if row is None:
        return not_found("bundle")
    from .db import bundle_json

    return respond(bundle_json(row))


@app.api_route("/api/bundles/{bundle_id}/", methods=["PUT", "PATCH"])
async def bundle_update(request: Request, bundle_id: str):
    user, err = await authenticate(request, True)
    if err:
        return err
    ident = path_id(bundle_id)
    if ident is None:
        return not_found("bundle")
    async with request.app.state.pool.acquire() as conn:
        existing = await get_bundle(conn, user["id"], ident)
    if existing is None:
        return not_found("bundle")
    data, err = await read_body(request)
    if err:
        return err
    errors, cleaned = validate_bundle(data, partial=request.method == "PATCH")
    if errors:
        return respond(errors, 400)
    async with request.app.state.pool.acquire() as conn:
        row = await update_bundle(conn, user["id"], ident, cleaned)
    if row is None:
        return not_found("bundle")
    from .db import bundle_json

    return respond(bundle_json(row))


@app.delete("/api/bundles/{bundle_id}/")
async def bundle_delete(request: Request, bundle_id: str):
    user, err = await authenticate(request, True)
    if err:
        return err
    ident = path_id(bundle_id)
    if ident is None:
        return not_found("bundle")
    async with request.app.state.pool.acquire() as conn:
        deleted = await delete_bundle(conn, user["id"], ident)
    if not deleted:
        return not_found("bundle")
    return Response(status_code=204)
