"""Postgres access for the linkding API. SQL fragments come from logic.py."""

from __future__ import annotations

from datetime import datetime, timezone

from .logic import (
    archive_url,
    bookmark_tag_names,
    bundle_search_sql,
    fmt_dt,
    normalize_url,
    order_sql,
    page_links,
    parse_datetime,
    parse_tag_string,
    resolve_limit,
    resolve_offset,
    search_sql,
    tag_sql,
)

BOOKMARK_COLUMNS = """
    b.id, b.owner_id, b.url, b.url_normalized, b.title, b.description, b.notes,
    b.unread, b.is_archived, b.shared, b.date_added, b.date_modified
"""


def now_utc() -> datetime:
    return datetime.now(timezone.utc)


def bookmark_json(row, tag_names: list[str]) -> dict:
    return {
        "id": row["id"],
        "url": row["url"],
        "title": row["title"],
        "description": row["description"],
        "notes": row["notes"],
        "web_archive_snapshot_url": archive_url(row["url"], row["date_added"]),
        "favicon_url": None,
        "preview_image_url": None,
        "is_archived": row["is_archived"],
        "unread": row["unread"],
        "shared": row["shared"],
        "tag_names": sorted(tag_names),
        "date_added": fmt_dt(row["date_added"]),
        "date_modified": fmt_dt(row["date_modified"]),
        "website_title": None,
        "website_description": None,
    }


def tag_json(row) -> dict:
    return {"id": row["id"], "name": row["name"], "date_added": fmt_dt(row["date_added"])}


def bundle_json(row) -> dict:
    return {
        "id": row["id"],
        "name": row["name"],
        "search": row["search"],
        "any_tags": row["any_tags"],
        "all_tags": row["all_tags"],
        "excluded_tags": row["excluded_tags"],
        "filter_unread": row["filter_unread"],
        "filter_shared": row["filter_shared"],
        "order": row["order"],
        "date_created": fmt_dt(row["date_created"]),
        "date_modified": fmt_dt(row["date_modified"]),
    }


async def load_user_by_token(conn, token: str):
    return await conn.fetchrow(
        """
        SELECT u.id, u.username,
               p.theme, p.bookmark_date_display, p.bookmark_link_target,
               p.web_archive_integration, p.tag_search, p.enable_sharing,
               p.enable_public_sharing, p.enable_favicons, p.display_url,
               p.permanent_notes, p.search_preferences, p.legacy_search
        FROM api_tokens t
        JOIN users u ON u.id = t.user_id
        JOIN profiles p ON p.user_id = u.id
        WHERE t.key = $1
        """,
        token,
    )


async def fetch_tag_map(conn, bookmark_ids: list[int]) -> dict[int, list[str]]:
    grouped: dict[int, list[str]] = {bookmark_id: [] for bookmark_id in bookmark_ids}
    if not bookmark_ids:
        return grouped
    rows = await conn.fetch(
        """
        SELECT bt.bookmark_id, t.name
        FROM bookmark_tags bt
        JOIN tags t ON t.id = bt.tag_id
        WHERE bt.bookmark_id = ANY($1::bigint[])
        """,
        bookmark_ids,
    )
    for row in rows:
        grouped[row["bookmark_id"]].append(row["name"])
    return grouped


async def set_tags(conn, bookmark_id: int, owner_id: int, raw_names: list[str], when: datetime):
    names = bookmark_tag_names(raw_names)
    await conn.execute("DELETE FROM bookmark_tags WHERE bookmark_id = $1", bookmark_id)
    for name in names:
        lower = name.lower()
        row = await conn.fetchrow(
            """
            INSERT INTO tags (owner_id, name, name_lower, date_added)
            VALUES ($1, $2, $3, $4)
            ON CONFLICT (owner_id, name_lower) DO NOTHING
            RETURNING id
            """,
            owner_id,
            name,
            lower,
            when,
        )
        if row is None:
            row = await conn.fetchrow(
                "SELECT id FROM tags WHERE owner_id = $1 AND name_lower = $2",
                owner_id,
                lower,
            )
        await conn.execute(
            """
            INSERT INTO bookmark_tags (bookmark_id, tag_id) VALUES ($1, $2)
            ON CONFLICT DO NOTHING
            """,
            bookmark_id,
            row["id"],
        )


async def find_existing(conn, owner_id: int, url: str):
    normalized = normalize_url(url)
    return await conn.fetchrow(
        f"""
        SELECT {BOOKMARK_COLUMNS}
        FROM bookmarks b
        WHERE b.owner_id = $1
          AND (b.url_normalized = $2 OR (b.url_normalized = '' AND b.url = $3))
        ORDER BY b.id ASC
        LIMIT 1
        """,
        owner_id,
        normalized,
        url,
    )


async def get_owned(conn, owner_id: int, bookmark_id: int):
    return await conn.fetchrow(
        f"SELECT {BOOKMARK_COLUMNS} FROM bookmarks b WHERE b.id = $1 AND b.owner_id = $2",
        bookmark_id,
        owner_id,
    )


def _since(params: list, column: str, raw: str | None) -> str | None:
    if not raw:
        return None
    parsed = parse_datetime(raw)
    if parsed is None:
        return None
    params.append(parsed)
    return f"{column} > ${len(params)}"


def _flag_filter(field: str, raw: str | None) -> str | None:
    if raw == "yes":
        return f"b.{field}"
    if raw == "no":
        return f"NOT b.{field}"
    return None


async def _apply_bundle(conn, where: list[str], params: list, viewer_id: int | None, raw: str | None):
    if not raw or viewer_id is None:
        return
    try:
        bundle_id = int(raw)
    except ValueError:
        return
    bundle = await conn.fetchrow(
        'SELECT * FROM bundles WHERE id = $1 AND owner_id = $2',
        bundle_id,
        viewer_id,
    )
    if bundle is None:
        return
    search = bundle_search_sql(bundle["search"], params)
    if search:
        where.append(search)
    for column, mode in (
        ("any_tags", "any"),
        ("all_tags", "all"),
        ("excluded_tags", "excluded"),
    ):
        names = parse_tag_string(bundle[column], " ")
        if not names:
            continue
        if mode == "any":
            parts = [tag_sql(name, params) for name in names]
            where.append("(" + " OR ".join(parts) + ")")
        elif mode == "all":
            for name in names:
                where.append(tag_sql(name, params))
        else:
            parts = [tag_sql(name, params) for name in names]
            where.append("NOT (" + " OR ".join(parts) + ")")
    if bundle["filter_unread"] == "yes":
        where.append("b.unread")
    elif bundle["filter_unread"] == "no":
        where.append("NOT b.unread")
    if bundle["filter_shared"] == "yes":
        where.append("b.shared")
    elif bundle["filter_shared"] == "no":
        where.append("NOT b.shared")


async def list_bookmarks(conn, kind: str, viewer, public_only: bool, request_url: str, qp: dict):
    params: list = []
    where: list[str] = []
    joins = ""
    viewer_id = None if viewer is None else viewer["id"]
    legacy = False if viewer is None else bool(viewer["legacy_search"])
    lax = False if viewer is None else viewer["tag_search"] == "lax"

    if kind == "shared":
        joins = "JOIN profiles p ON p.user_id = b.owner_id"
        where.append("b.shared")
        where.append("p.enable_sharing")
        if public_only:
            where.append("p.enable_public_sharing")
        username = qp.get("user") or ""
        if username:
            owner = await conn.fetchrow("SELECT id FROM users WHERE username = $1", username)
            if owner is not None:
                params.append(owner["id"])
                where.append(f"b.owner_id = ${len(params)}")
    else:
        params.append(viewer_id)
        where.append(f"b.owner_id = ${len(params)}")
        if kind == "archived":
            where.append("b.is_archived")
        else:
            where.append("NOT b.is_archived")

    modified = _since(params, "b.date_modified", qp.get("modified_since"))
    if modified:
        where.append(modified)
    added = _since(params, "b.date_added", qp.get("added_since"))
    if added:
        where.append(added)
    unread = _flag_filter("unread", qp.get("unread"))
    if unread:
        where.append(unread)
    shared = _flag_filter("shared", qp.get("shared"))
    if shared:
        where.append(shared)
    query_sql = search_sql(qp.get("q") or "", legacy=legacy, lax=lax, params=params)
    if query_sql:
        where.append(query_sql)
    await _apply_bundle(conn, where, params, viewer_id, qp.get("bundle"))

    where_sql = " AND ".join(where) if where else "TRUE"
    order = order_sql(qp.get("sort"))
    total = await conn.fetchval(
        f"SELECT count(*) FROM bookmarks b {joins} WHERE {where_sql}",
        *params,
    )
    limit = resolve_limit(qp.get("limit"))
    offset = resolve_offset(qp.get("offset"))
    rows = await conn.fetch(
        f"""
        SELECT {BOOKMARK_COLUMNS}
        FROM bookmarks b {joins}
        WHERE {where_sql}
        ORDER BY {order}
        LIMIT ${len(params) + 1} OFFSET ${len(params) + 2}
        """,
        *params,
        limit,
        offset,
    )
    tag_map = await fetch_tag_map(conn, [row["id"] for row in rows])
    nxt, prev = page_links(request_url, limit, offset, int(total))
    return {
        "count": int(total),
        "next": nxt,
        "previous": prev,
        "results": [bookmark_json(row, tag_map[row["id"]]) for row in rows],
    }


async def serialize_one(conn, row) -> dict:
    tag_map = await fetch_tag_map(conn, [row["id"]])
    return bookmark_json(row, tag_map[row["id"]])


async def create_bookmark(conn, owner_id: int, cleaned: dict):
    when = now_utc()
    url = cleaned["url"]
    title = cleaned.get("title", "")
    description = cleaned.get("description", "")
    notes = cleaned.get("notes", "")
    unread = cleaned.get("unread", False)
    shared = cleaned.get("shared", False)
    is_archived = cleaned.get("is_archived", False)
    tag_names = cleaned.get("tag_names", [])
    async with conn.transaction():
        existing = await find_existing(conn, owner_id, url)
        if existing is not None:
            await conn.execute(
                """
                UPDATE bookmarks
                SET title = $1, description = $2, notes = $3, unread = $4,
                    shared = $5, date_modified = $6
                WHERE id = $7
                """,
                title,
                description,
                notes,
                unread,
                shared,
                when,
                existing["id"],
            )
            await set_tags(conn, existing["id"], owner_id, tag_names, when)
            row = await get_owned(conn, owner_id, existing["id"])
            return row
        date_added = cleaned.get("date_added") or when
        date_modified = cleaned.get("date_modified") or when
        row = await conn.fetchrow(
            """
            INSERT INTO bookmarks (
                owner_id, url, url_normalized, title, description, notes,
                unread, is_archived, shared, date_added, date_modified
            ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
            RETURNING id
            """,
            owner_id,
            url,
            normalize_url(url),
            title,
            description,
            notes,
            unread,
            is_archived,
            shared,
            date_added,
            date_modified,
        )
        row = await get_owned(conn, owner_id, row["id"])
        await set_tags(conn, row["id"], owner_id, tag_names, when)
        return row


async def update_bookmark(conn, owner_id: int, bookmark_id: int, cleaned: dict):
    row = await get_owned(conn, owner_id, bookmark_id)
    if row is None:
        return None, "missing"
    if "url" in cleaned:
        dup = await conn.fetchrow(
            "SELECT id FROM bookmarks WHERE owner_id = $1 AND url = $2 AND id <> $3",
            owner_id,
            cleaned["url"],
            bookmark_id,
        )
        if dup is not None:
            return None, "duplicate"
    when = now_utc()
    url = cleaned.get("url", row["url"])
    title = cleaned.get("title", row["title"])
    description = cleaned.get("description", row["description"])
    notes = cleaned.get("notes", row["notes"])
    unread = cleaned.get("unread", row["unread"])
    shared = cleaned.get("shared", row["shared"])
    is_archived = cleaned.get("is_archived", row["is_archived"])
    date_added = cleaned.get("date_added", row["date_added"])
    async with conn.transaction():
        await conn.execute(
            """
            UPDATE bookmarks
            SET url = $1, url_normalized = $2, title = $3, description = $4, notes = $5,
                unread = $6, shared = $7, is_archived = $8, date_added = $9, date_modified = $10
            WHERE id = $11
            """,
            url,
            normalize_url(url),
            title,
            description,
            notes,
            unread,
            shared,
            is_archived,
            date_added,
            when,
            bookmark_id,
        )
        if "tag_names" in cleaned:
            await set_tags(conn, bookmark_id, owner_id, cleaned["tag_names"], when)
    return await get_owned(conn, owner_id, bookmark_id), None


async def set_archived(conn, owner_id: int, bookmark_id: int, archived: bool):
    row = await get_owned(conn, owner_id, bookmark_id)
    if row is None:
        return None
    await conn.execute(
        "UPDATE bookmarks SET is_archived = $1, date_modified = $2 WHERE id = $3",
        archived,
        now_utc(),
        bookmark_id,
    )
    return await get_owned(conn, owner_id, bookmark_id)


async def delete_bookmark(conn, owner_id: int, bookmark_id: int) -> bool:
    result = await conn.execute(
        "DELETE FROM bookmarks WHERE id = $1 AND owner_id = $2",
        bookmark_id,
        owner_id,
    )
    return result.endswith("1")


async def list_tags(conn, owner_id: int, request_url: str, qp: dict):
    total = await conn.fetchval("SELECT count(*) FROM tags WHERE owner_id = $1", owner_id)
    limit = resolve_limit(qp.get("limit"))
    offset = resolve_offset(qp.get("offset"))
    rows = await conn.fetch(
        """
        SELECT id, name, date_added FROM tags
        WHERE owner_id = $1
        ORDER BY id ASC
        LIMIT $2 OFFSET $3
        """,
        owner_id,
        limit,
        offset,
    )
    nxt, prev = page_links(request_url, limit, offset, int(total))
    return {
        "count": int(total),
        "next": nxt,
        "previous": prev,
        "results": [tag_json(row) for row in rows],
    }


async def get_tag(conn, owner_id: int, tag_id: int):
    return await conn.fetchrow(
        "SELECT id, name, date_added FROM tags WHERE id = $1 AND owner_id = $2",
        tag_id,
        owner_id,
    )


async def create_tag(conn, owner_id: int, name: str):
    when = now_utc()
    lower = name.lower()
    existing = await conn.fetchrow(
        "SELECT id, name, date_added FROM tags WHERE owner_id = $1 AND name_lower = $2",
        owner_id,
        lower,
    )
    if existing is not None:
        return existing
    return await conn.fetchrow(
        """
        INSERT INTO tags (owner_id, name, name_lower, date_added)
        VALUES ($1, $2, $3, $4)
        RETURNING id, name, date_added
        """,
        owner_id,
        name,
        lower,
        when,
    )


async def delete_tag(conn, owner_id: int, tag_id: int) -> bool:
    result = await conn.execute(
        "DELETE FROM tags WHERE id = $1 AND owner_id = $2",
        tag_id,
        owner_id,
    )
    return result.endswith("1")


async def list_bundles(conn, owner_id: int, request_url: str, qp: dict):
    total = await conn.fetchval("SELECT count(*) FROM bundles WHERE owner_id = $1", owner_id)
    limit = resolve_limit(qp.get("limit"))
    offset = resolve_offset(qp.get("offset"))
    rows = await conn.fetch(
        """
        SELECT id, name, search, any_tags, all_tags, excluded_tags,
               filter_unread, filter_shared, "order", date_created, date_modified
        FROM bundles
        WHERE owner_id = $1
        ORDER BY "order" ASC, id ASC
        LIMIT $2 OFFSET $3
        """,
        owner_id,
        limit,
        offset,
    )
    nxt, prev = page_links(request_url, limit, offset, int(total))
    return {
        "count": int(total),
        "next": nxt,
        "previous": prev,
        "results": [bundle_json(row) for row in rows],
    }


async def get_bundle(conn, owner_id: int, bundle_id: int):
    return await conn.fetchrow(
        """
        SELECT id, name, search, any_tags, all_tags, excluded_tags,
               filter_unread, filter_shared, "order", date_created, date_modified
        FROM bundles WHERE id = $1 AND owner_id = $2
        """,
        bundle_id,
        owner_id,
    )


async def create_bundle(conn, owner_id: int, cleaned: dict):
    when = now_utc()
    if "order" in cleaned:
        order = cleaned["order"]
    else:
        current = await conn.fetchval(
            'SELECT COALESCE(MAX("order"), -1) FROM bundles WHERE owner_id = $1',
            owner_id,
        )
        order = int(current) + 1
    return await conn.fetchrow(
        """
        INSERT INTO bundles (
            owner_id, name, search, any_tags, all_tags, excluded_tags,
            filter_unread, filter_shared, "order", date_created, date_modified
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
        RETURNING id, name, search, any_tags, all_tags, excluded_tags,
                  filter_unread, filter_shared, "order", date_created, date_modified
        """,
        owner_id,
        cleaned["name"],
        cleaned.get("search", ""),
        cleaned.get("any_tags", ""),
        cleaned.get("all_tags", ""),
        cleaned.get("excluded_tags", ""),
        cleaned.get("filter_unread", "off"),
        cleaned.get("filter_shared", "off"),
        order,
        when,
        when,
    )


async def update_bundle(conn, owner_id: int, bundle_id: int, cleaned: dict):
    row = await get_bundle(conn, owner_id, bundle_id)
    if row is None:
        return None
    when = now_utc()
    return await conn.fetchrow(
        """
        UPDATE bundles SET
            name = $1, search = $2, any_tags = $3, all_tags = $4, excluded_tags = $5,
            filter_unread = $6, filter_shared = $7, "order" = $8, date_modified = $9
        WHERE id = $10
        RETURNING id, name, search, any_tags, all_tags, excluded_tags,
                  filter_unread, filter_shared, "order", date_created, date_modified
        """,
        cleaned.get("name", row["name"]),
        cleaned.get("search", row["search"]),
        cleaned.get("any_tags", row["any_tags"]),
        cleaned.get("all_tags", row["all_tags"]),
        cleaned.get("excluded_tags", row["excluded_tags"]),
        cleaned.get("filter_unread", row["filter_unread"]),
        cleaned.get("filter_shared", row["filter_shared"]),
        cleaned.get("order", row["order"]),
        when,
        bundle_id,
    )


async def delete_bundle(conn, owner_id: int, bundle_id: int) -> bool:
    async with conn.transaction():
        result = await conn.execute(
            "DELETE FROM bundles WHERE id = $1 AND owner_id = $2",
            bundle_id,
            owner_id,
        )
        if not result.endswith("1"):
            return False
        rows = await conn.fetch(
            'SELECT id FROM bundles WHERE owner_id = $1 ORDER BY "order" ASC, id ASC',
            owner_id,
        )
        for index, row in enumerate(rows):
            await conn.execute('UPDATE bundles SET "order" = $1 WHERE id = $2', index, row["id"])
    return True


def profile_json(user) -> dict:
    prefs = user["search_preferences"]
    if isinstance(prefs, str):
        import json

        prefs = json.loads(prefs)
    return {
        "theme": user["theme"],
        "bookmark_date_display": user["bookmark_date_display"],
        "bookmark_link_target": user["bookmark_link_target"],
        "web_archive_integration": user["web_archive_integration"],
        "tag_search": user["tag_search"],
        "enable_sharing": user["enable_sharing"],
        "enable_public_sharing": user["enable_public_sharing"],
        "enable_favicons": user["enable_favicons"],
        "display_url": user["display_url"],
        "permanent_notes": user["permanent_notes"],
        "search_preferences": prefs,
        "version": "1.47.0",
    }
