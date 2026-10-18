//! PostgreSQL access. Visibility filters follow `can_see_own` and `can_see_shared`.

use chrono::{DateTime, Utc};
use serde_json::{json, Value};
use sqlx::postgres::PgRow;
use sqlx::{PgPool, Postgres, Row, Transaction};

use crate::logic::{
    archive_url, bookmark_tag_names, bundle_search_sql, flag_sql, fmt_time, normalize_url, order_sql,
    page_limit_offset, page_links, parse_tag_string, query_get, search_sql, since_sql, sort_names,
    Arg, BookmarkIn, BundleIn, Sql,
};

#[derive(Clone, Debug)]
pub struct UserRow {
    pub id: i64,
    pub username: String,
    pub theme: String,
    pub bookmark_date_display: String,
    pub bookmark_link_target: String,
    pub web_archive_integration: String,
    pub tag_search: String,
    pub enable_sharing: bool,
    pub enable_public_sharing: bool,
    pub enable_favicons: bool,
    pub display_url: bool,
    pub permanent_notes: bool,
    pub search_preferences: Value,
    pub legacy_search: bool,
}

#[derive(Clone, Debug)]
pub struct BookmarkRow {
    pub id: i64,
    pub owner_id: i64,
    pub url: String,
    pub url_normalized: String,
    pub title: String,
    pub description: String,
    pub notes: String,
    pub unread: bool,
    pub is_archived: bool,
    pub shared: bool,
    pub date_added: DateTime<Utc>,
    pub date_modified: DateTime<Utc>,
}

#[derive(Clone, Debug)]
pub struct TagRow {
    pub id: i64,
    pub owner_id: i64,
    pub name: String,
    pub date_added: DateTime<Utc>,
}

#[derive(Clone, Debug)]
pub struct BundleRow {
    pub id: i64,
    pub owner_id: i64,
    pub name: String,
    pub search: String,
    pub any_tags: String,
    pub all_tags: String,
    pub excluded_tags: String,
    pub filter_unread: String,
    pub filter_shared: String,
    pub order: i32,
    pub date_created: DateTime<Utc>,
    pub date_modified: DateTime<Utc>,
}

const BOOKMARK_COLUMNS: &str = "b.id, b.owner_id, b.url, b.url_normalized, b.title, b.description, b.notes, b.unread, b.is_archived, b.shared, b.date_added, b.date_modified";

fn bind_query<'a>(
    sql: &'a str,
    args: Vec<Arg>,
) -> sqlx::query::Query<'a, Postgres, sqlx::postgres::PgArguments> {
    let mut query = sqlx::query(sql);
    for arg in args {
        query = match arg {
            Arg::I64(value) => query.bind(value),
            Arg::Text(value) => query.bind(value),
            Arg::Bool(value) => query.bind(value),
            Arg::Time(value) => query.bind(value),
        };
    }
    query
}

fn scan_bookmark(row: &PgRow) -> Result<BookmarkRow, sqlx::Error> {
    Ok(BookmarkRow {
        id: row.try_get(0)?,
        owner_id: row.try_get(1)?,
        url: row.try_get(2)?,
        url_normalized: row.try_get(3)?,
        title: row.try_get(4)?,
        description: row.try_get(5)?,
        notes: row.try_get(6)?,
        unread: row.try_get(7)?,
        is_archived: row.try_get(8)?,
        shared: row.try_get(9)?,
        date_added: row.try_get(10)?,
        date_modified: row.try_get(11)?,
    })
}

fn scan_bundle(row: &PgRow) -> Result<BundleRow, sqlx::Error> {
    Ok(BundleRow {
        id: row.try_get(0)?,
        owner_id: row.try_get(1)?,
        name: row.try_get(2)?,
        search: row.try_get(3)?,
        any_tags: row.try_get(4)?,
        all_tags: row.try_get(5)?,
        excluded_tags: row.try_get(6)?,
        filter_unread: row.try_get(7)?,
        filter_shared: row.try_get(8)?,
        order: row.try_get(9)?,
        date_created: row.try_get(10)?,
        date_modified: row.try_get(11)?,
    })
}

pub fn bookmark_json(row: &BookmarkRow, mut names: Vec<String>) -> Value {
    sort_names(&mut names);
    json!({
        "id": row.id,
        "url": row.url,
        "title": row.title,
        "description": row.description,
        "notes": row.notes,
        "web_archive_snapshot_url": archive_url(&row.url, row.date_added),
        "favicon_url": Value::Null,
        "preview_image_url": Value::Null,
        "is_archived": row.is_archived,
        "unread": row.unread,
        "shared": row.shared,
        "tag_names": names,
        "date_added": fmt_time(row.date_added),
        "date_modified": fmt_time(row.date_modified),
        "website_title": Value::Null,
        "website_description": Value::Null,
    })
}

pub fn tag_json(row: &TagRow) -> Value {
    json!({
        "id": row.id,
        "name": row.name,
        "date_added": fmt_time(row.date_added),
    })
}

pub fn bundle_json(row: &BundleRow) -> Value {
    json!({
        "id": row.id,
        "name": row.name,
        "search": row.search,
        "any_tags": row.any_tags,
        "all_tags": row.all_tags,
        "excluded_tags": row.excluded_tags,
        "filter_unread": row.filter_unread,
        "filter_shared": row.filter_shared,
        "order": row.order,
        "date_created": fmt_time(row.date_created),
        "date_modified": fmt_time(row.date_modified),
    })
}

pub fn profile_json(user: &UserRow) -> Value {
    json!({
        "theme": user.theme,
        "bookmark_date_display": user.bookmark_date_display,
        "bookmark_link_target": user.bookmark_link_target,
        "web_archive_integration": user.web_archive_integration,
        "tag_search": user.tag_search,
        "enable_sharing": user.enable_sharing,
        "enable_public_sharing": user.enable_public_sharing,
        "enable_favicons": user.enable_favicons,
        "display_url": user.display_url,
        "permanent_notes": user.permanent_notes,
        "search_preferences": user.search_preferences,
        "version": crate::logic::VERSION,
    })
}

pub async fn load_user(pool: &PgPool, token: &str) -> Result<Option<UserRow>, sqlx::Error> {
    let row = sqlx::query(
        "SELECT u.id, u.username, p.theme, p.bookmark_date_display, p.bookmark_link_target,
                p.web_archive_integration, p.tag_search, p.enable_sharing, p.enable_public_sharing,
                p.enable_favicons, p.display_url, p.permanent_notes, p.search_preferences, p.legacy_search
         FROM api_tokens t
         JOIN users u ON u.id = t.user_id
         JOIN profiles p ON p.user_id = u.id
         WHERE t.key = $1",
    )
    .bind(token)
    .fetch_optional(pool)
    .await?;
    let Some(row) = row else {
        return Ok(None);
    };
    let prefs: Value = row.try_get(12)?;
    Ok(Some(UserRow {
        id: row.try_get(0)?,
        username: row.try_get(1)?,
        theme: row.try_get(2)?,
        bookmark_date_display: row.try_get(3)?,
        bookmark_link_target: row.try_get(4)?,
        web_archive_integration: row.try_get(5)?,
        tag_search: row.try_get(6)?,
        enable_sharing: row.try_get(7)?,
        enable_public_sharing: row.try_get(8)?,
        enable_favicons: row.try_get(9)?,
        display_url: row.try_get(10)?,
        permanent_notes: row.try_get(11)?,
        search_preferences: prefs,
        legacy_search: row.try_get(13)?,
    }))
}

async fn tag_map_pool(
    conn: impl sqlx::Executor<'_, Database = Postgres>,
    ids: &[i64],
) -> Result<Vec<(i64, Vec<String>)>, sqlx::Error> {
    let mut grouped: Vec<(i64, Vec<String>)> = ids.iter().map(|id| (*id, Vec::new())).collect();
    if ids.is_empty() {
        return Ok(grouped);
    }
    let rows = sqlx::query(
        "SELECT bt.bookmark_id, t.name
         FROM bookmark_tags bt
         JOIN tags t ON t.id = bt.tag_id
         WHERE bt.bookmark_id = ANY($1::bigint[])",
    )
    .bind(ids)
    .fetch_all(conn)
    .await?;
    for row in rows {
        let id: i64 = row.try_get(0)?;
        let name: String = row.try_get(1)?;
        if let Some((_, names)) = grouped.iter_mut().find(|(key, _)| *key == id) {
            names.push(name);
        }
    }
    Ok(grouped)
}

async fn set_tags(
    tx: &mut Transaction<'_, Postgres>,
    bookmark_id: i64,
    owner_id: i64,
    raw: &[String],
    when: DateTime<Utc>,
) -> Result<(), sqlx::Error> {
    let names = bookmark_tag_names(raw);
    sqlx::query("DELETE FROM bookmark_tags WHERE bookmark_id = $1")
        .bind(bookmark_id)
        .execute(&mut **tx)
        .await?;
    for name in names {
        let lower = name.to_lowercase();
        let inserted: Option<i64> = sqlx::query_scalar(
            "INSERT INTO tags (owner_id, name, name_lower, date_added)
             VALUES ($1, $2, $3, $4)
             ON CONFLICT (owner_id, name_lower) DO NOTHING
             RETURNING id",
        )
        .bind(owner_id)
        .bind(&name)
        .bind(&lower)
        .bind(when)
        .fetch_optional(&mut **tx)
        .await?;
        let id = if let Some(id) = inserted {
            id
        } else {
            sqlx::query_scalar("SELECT id FROM tags WHERE owner_id = $1 AND name_lower = $2")
                .bind(owner_id)
                .bind(&lower)
                .fetch_one(&mut **tx)
                .await?
        };
        sqlx::query(
            "INSERT INTO bookmark_tags (bookmark_id, tag_id) VALUES ($1, $2) ON CONFLICT DO NOTHING",
        )
        .bind(bookmark_id)
        .bind(id)
        .execute(&mut **tx)
        .await?;
    }
    Ok(())
}

pub async fn find_existing(
    pool: &PgPool,
    owner_id: i64,
    raw: &str,
) -> Result<Option<BookmarkRow>, sqlx::Error> {
    let row = sqlx::query(&format!(
        "SELECT {BOOKMARK_COLUMNS} FROM bookmarks b
         WHERE b.owner_id = $1 AND (b.url_normalized = $2 OR (b.url_normalized = '' AND b.url = $3))
         ORDER BY b.id ASC LIMIT 1"
    ))
    .bind(owner_id)
    .bind(normalize_url(raw))
    .bind(raw)
    .fetch_optional(pool)
    .await?;
    row.as_ref().map(scan_bookmark).transpose()
}

pub async fn get_by_id(pool: &PgPool, id: i64) -> Result<Option<BookmarkRow>, sqlx::Error> {
    let row = sqlx::query(&format!(
        "SELECT {BOOKMARK_COLUMNS} FROM bookmarks b WHERE b.id = $1"
    ))
    .bind(id)
    .fetch_optional(pool)
    .await?;
    row.as_ref().map(scan_bookmark).transpose()
}

/// Fetch the bookmark and its tag names in one statement. Keep the same
/// unfiltered ID lookup used for authorization; the kernel checks ownership
/// before the handler returns either the row or its tags.
pub async fn get_with_tags(
    pool: &PgPool,
    id: i64,
) -> Result<Option<(BookmarkRow, Vec<String>)>, sqlx::Error> {
    let row = sqlx::query(&format!(
        "SELECT {BOOKMARK_COLUMNS},
                ARRAY(SELECT t.name FROM bookmark_tags bt
                      JOIN tags t ON t.id = bt.tag_id
                      WHERE bt.bookmark_id = b.id)
         FROM bookmarks b WHERE b.id = $1"
    ))
    .bind(id)
    .fetch_optional(pool)
    .await?;
    row.as_ref()
        .map(|row| Ok((scan_bookmark(row)?, row.try_get(12)?)))
        .transpose()
}

async fn get_owned_tx(
    tx: &mut Transaction<'_, Postgres>,
    owner_id: i64,
    id: i64,
) -> Result<Option<BookmarkRow>, sqlx::Error> {
    let row = sqlx::query(&format!(
        "SELECT {BOOKMARK_COLUMNS} FROM bookmarks b WHERE b.id = $1 AND b.owner_id = $2"
    ))
    .bind(id)
    .bind(owner_id)
    .fetch_optional(&mut **tx)
    .await?;
    row.as_ref().map(scan_bookmark).transpose()
}

pub async fn serialize(pool: &PgPool, row: &BookmarkRow) -> Result<Value, sqlx::Error> {
    let grouped = tag_map_pool(pool, &[row.id]).await?;
    let names = grouped
        .into_iter()
        .find(|(id, _)| *id == row.id)
        .map(|(_, names)| names)
        .unwrap_or_default();
    Ok(bookmark_json(row, names))
}

pub async fn list_bookmarks(
    pool: &PgPool,
    kind: &str,
    viewer: Option<&UserRow>,
    request_url: &str,
    pairs: &[(String, String)],
) -> Result<Value, sqlx::Error> {
    let mut sql = Sql::new();
    let mut where_parts: Vec<String> = Vec::new();
    let mut joins = String::new();
    let legacy = viewer.is_some_and(|user| user.legacy_search);
    let lax = viewer.is_some_and(|user| user.tag_search == "lax");
    if kind == "shared" {
        joins = "JOIN profiles p ON p.user_id = b.owner_id".to_string();
        where_parts.push("b.shared".to_string());
        where_parts.push("p.enable_sharing".to_string());
        if viewer.is_none() {
            where_parts.push("p.enable_public_sharing".to_string());
        }
        if let Some(username) = query_get(pairs, "user") {
            if !username.is_empty() {
                let owner: Option<i64> =
                    sqlx::query_scalar("SELECT id FROM users WHERE username = $1")
                        .bind(username)
                        .fetch_optional(pool)
                        .await?;
                if let Some(owner_id) = owner {
                    let placeholder = sql.bind(Arg::I64(owner_id));
                    where_parts.push(format!("b.owner_id = {placeholder}"));
                }
            }
        }
    } else if let Some(viewer) = viewer {
        let placeholder = sql.bind(Arg::I64(viewer.id));
        where_parts.push(format!("b.owner_id = {placeholder}"));
        if kind == "archived" {
            where_parts.push("b.is_archived".to_string());
        } else {
            where_parts.push("NOT b.is_archived".to_string());
        }
    }
    if let Some(raw) = query_get(pairs, "modified_since") {
        let clause = since_sql("b.date_modified", raw, &mut sql);
        if !clause.is_empty() {
            where_parts.push(clause);
        }
    }
    if let Some(raw) = query_get(pairs, "added_since") {
        let clause = since_sql("b.date_added", raw, &mut sql);
        if !clause.is_empty() {
            where_parts.push(clause);
        }
    }
    if let Some(raw) = query_get(pairs, "unread") {
        let clause = flag_sql("unread", raw);
        if !clause.is_empty() {
            where_parts.push(clause);
        }
    }
    if let Some(raw) = query_get(pairs, "shared") {
        let clause = flag_sql("shared", raw);
        if !clause.is_empty() {
            where_parts.push(clause);
        }
    }
    let search = search_sql(query_get(pairs, "q").unwrap_or(""), legacy, lax, &mut sql);
    if !search.is_empty() {
        where_parts.push(search);
    }
    if let Some(viewer) = viewer {
        if let Some(raw) = query_get(pairs, "bundle") {
            apply_bundle(pool, &mut where_parts, &mut sql, viewer.id, raw).await?;
        }
    }
    let where_sql = if where_parts.is_empty() {
        "TRUE".to_string()
    } else {
        where_parts.join(" AND ")
    };
    let count_sql = format!("SELECT count(*)::bigint FROM bookmarks b {joins} WHERE {where_sql}");
    let total: i64 = bind_query(&count_sql, sql.args.clone())
        .fetch_one(pool)
        .await?
        .try_get(0)?;
    let (limit_bad, limit, offset_bad, offset) = crate::logic::page_params(pairs);
    let (limit_n, offset_n) = page_limit_offset(total, limit_bad, limit, offset_bad, offset);
    let mut args = sql.args.clone();
    let limit_ph = args.len() + 1;
    args.push(Arg::I64(limit_n));
    let offset_ph = args.len() + 1;
    args.push(Arg::I64(offset_n));
    let sort = order_sql(query_get(pairs, "sort").unwrap_or(""));
    let list_sql = format!(
        "SELECT {BOOKMARK_COLUMNS} FROM bookmarks b {joins} WHERE {where_sql} ORDER BY {sort} LIMIT ${limit_ph} OFFSET ${offset_ph}"
    );
    let rows = bind_query(&list_sql, args).fetch_all(pool).await?;
    let mut items = Vec::new();
    for row in rows {
        items.push(scan_bookmark(&row)?);
    }
    let ids: Vec<i64> = items.iter().map(|item| item.id).collect();
    let grouped = tag_map_pool(pool, &ids).await?;
    let mut results = Vec::new();
    for item in &items {
        let names = grouped
            .iter()
            .find(|(id, _)| *id == item.id)
            .map(|(_, names)| names.clone())
            .unwrap_or_default();
        results.push(bookmark_json(item, names));
    }
    let (next, prev) = page_links(request_url, total, limit_bad, limit, offset_bad, offset);
    Ok(json!({
        "count": total,
        "next": next,
        "previous": prev,
        "results": results,
    }))
}

async fn apply_bundle(
    pool: &PgPool,
    where_parts: &mut Vec<String>,
    sql: &mut Sql,
    viewer_id: i64,
    raw: &str,
) -> Result<(), sqlx::Error> {
    if raw.is_empty() {
        return Ok(());
    }
    let Ok(bundle_id) = raw.parse::<i64>() else {
        return Ok(());
    };
    let row = sqlx::query(
        "SELECT id, owner_id, name, search, any_tags, all_tags, excluded_tags, filter_unread, filter_shared, \"order\", date_created, date_modified
         FROM bundles WHERE id = $1 AND owner_id = $2",
    )
    .bind(bundle_id)
    .bind(viewer_id)
    .fetch_optional(pool)
    .await?;
    let Some(row) = row else {
        return Ok(());
    };
    let bundle = scan_bundle(&row)?;
    let search = bundle_search_sql(&bundle.search, sql);
    if !search.is_empty() {
        where_parts.push(search);
    }
    for (column, mode) in [
        (bundle.any_tags, "any"),
        (bundle.all_tags, "all"),
        (bundle.excluded_tags, "excluded"),
    ] {
        let names = parse_tag_string(&column, " ");
        if names.is_empty() {
            continue;
        }
        match mode {
            "any" => {
                let parts: Vec<String> = names.iter().map(|name| tag_sql_pub(name, sql)).collect();
                where_parts.push(format!("({})", parts.join(" OR ")));
            }
            "all" => {
                for name in names {
                    where_parts.push(tag_sql_pub(&name, sql));
                }
            }
            _ => {
                let parts: Vec<String> = names.iter().map(|name| tag_sql_pub(name, sql)).collect();
                where_parts.push(format!("NOT ({})", parts.join(" OR ")));
            }
        }
    }
    if bundle.filter_unread == "yes" {
        where_parts.push("b.unread".to_string());
    } else if bundle.filter_unread == "no" {
        where_parts.push("NOT b.unread".to_string());
    }
    if bundle.filter_shared == "yes" {
        where_parts.push("b.shared".to_string());
    } else if bundle.filter_shared == "no" {
        where_parts.push("NOT b.shared".to_string());
    }
    Ok(())
}

fn tag_sql_pub(tag: &str, sql: &mut Sql) -> String {
    let placeholder = sql.bind(Arg::Text(tag.to_lowercase()));
    format!(
        "EXISTS (SELECT 1 FROM bookmark_tags bt JOIN tags t ON t.id = bt.tag_id WHERE bt.bookmark_id = b.id AND t.name_lower = {placeholder})"
    )
}

pub async fn create_bookmark(
    pool: &PgPool,
    owner_id: i64,
    cleaned: &BookmarkIn,
) -> Result<BookmarkRow, sqlx::Error> {
    let when = Utc::now();
    let mut tx = pool.begin().await?;
    let existing = {
        let row = sqlx::query(&format!(
            "SELECT {BOOKMARK_COLUMNS} FROM bookmarks b
             WHERE b.owner_id = $1 AND (b.url_normalized = $2 OR (b.url_normalized = '' AND b.url = $3))
             ORDER BY b.id ASC LIMIT 1"
        ))
        .bind(owner_id)
        .bind(normalize_url(&cleaned.url))
        .bind(&cleaned.url)
        .fetch_optional(&mut *tx)
        .await?;
        row.as_ref().map(scan_bookmark).transpose()?
    };
    let title = if cleaned.has("title") { cleaned.title.clone() } else { String::new() };
    let description = if cleaned.has("description") {
        cleaned.description.clone()
    } else {
        String::new()
    };
    let notes = if cleaned.has("notes") { cleaned.notes.clone() } else { String::new() };
    let unread = cleaned.has("unread") && cleaned.unread;
    let shared = cleaned.has("shared") && cleaned.shared;
    let tags: Vec<String> = if cleaned.has("tag_names") {
        cleaned.tag_names.clone()
    } else {
        Vec::new()
    };
    if let Some(existing) = existing {
        sqlx::query(
            "UPDATE bookmarks SET title = $1, description = $2, notes = $3, unread = $4, shared = $5, date_modified = $6 WHERE id = $7",
        )
        .bind(&title)
        .bind(&description)
        .bind(&notes)
        .bind(unread)
        .bind(shared)
        .bind(when)
        .bind(existing.id)
        .execute(&mut *tx)
        .await?;
        set_tags(&mut tx, existing.id, owner_id, &tags, when).await?;
        let row = get_owned_tx(&mut tx, owner_id, existing.id)
            .await?
            .ok_or(sqlx::Error::RowNotFound)?;
        tx.commit().await?;
        return Ok(row);
    }
    let date_added = if cleaned.has("date_added") {
        cleaned.date_added.unwrap_or(when)
    } else {
        when
    };
    let date_modified = if cleaned.has("date_modified") {
        cleaned.date_modified.unwrap_or(when)
    } else {
        when
    };
    let is_archived = cleaned.has("is_archived") && cleaned.is_archived;
    let id: i64 = sqlx::query_scalar(
        "INSERT INTO bookmarks (owner_id, url, url_normalized, title, description, notes, unread, is_archived, shared, date_added, date_modified)
         VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11) RETURNING id",
    )
    .bind(owner_id)
    .bind(&cleaned.url)
    .bind(normalize_url(&cleaned.url))
    .bind(&title)
    .bind(&description)
    .bind(&notes)
    .bind(unread)
    .bind(is_archived)
    .bind(shared)
    .bind(date_added)
    .bind(date_modified)
    .fetch_one(&mut *tx)
    .await?;
    set_tags(&mut tx, id, owner_id, &tags, when).await?;
    let row = get_owned_tx(&mut tx, owner_id, id)
        .await?
        .ok_or(sqlx::Error::RowNotFound)?;
    tx.commit().await?;
    Ok(row)
}

pub enum UpdateProblem {
    Missing,
    Duplicate,
}

pub async fn update_bookmark(
    pool: &PgPool,
    owner_id: i64,
    id: i64,
    cleaned: &BookmarkIn,
) -> Result<Result<BookmarkRow, UpdateProblem>, sqlx::Error> {
    let current = get_by_id(pool, id).await?;
    let Some(current) = current else {
        return Ok(Err(UpdateProblem::Missing));
    };
    if current.owner_id != owner_id {
        return Ok(Err(UpdateProblem::Missing));
    }
    if cleaned.has("url") {
        let dup: Option<i64> = sqlx::query_scalar(
            "SELECT id FROM bookmarks WHERE owner_id = $1 AND url = $2 AND id <> $3",
        )
        .bind(owner_id)
        .bind(&cleaned.url)
        .bind(id)
        .fetch_optional(pool)
        .await?;
        if dup.is_some() {
            return Ok(Err(UpdateProblem::Duplicate));
        }
    }
    let when = Utc::now();
    let url_value = if cleaned.has("url") { cleaned.url.clone() } else { current.url.clone() };
    let title = if cleaned.has("title") { cleaned.title.clone() } else { current.title.clone() };
    let description = if cleaned.has("description") {
        cleaned.description.clone()
    } else {
        current.description.clone()
    };
    let notes = if cleaned.has("notes") { cleaned.notes.clone() } else { current.notes.clone() };
    let unread = if cleaned.has("unread") { cleaned.unread } else { current.unread };
    let shared = if cleaned.has("shared") { cleaned.shared } else { current.shared };
    let archived = if cleaned.has("is_archived") { cleaned.is_archived } else { current.is_archived };
    let date_added = if cleaned.has("date_added") {
        cleaned.date_added.unwrap_or(current.date_added)
    } else {
        current.date_added
    };
    let mut tx = pool.begin().await?;
    sqlx::query(
        "UPDATE bookmarks SET url=$1, url_normalized=$2, title=$3, description=$4, notes=$5,
            unread=$6, shared=$7, is_archived=$8, date_added=$9, date_modified=$10
         WHERE id=$11",
    )
    .bind(&url_value)
    .bind(normalize_url(&url_value))
    .bind(&title)
    .bind(&description)
    .bind(&notes)
    .bind(unread)
    .bind(shared)
    .bind(archived)
    .bind(date_added)
    .bind(when)
    .bind(id)
    .execute(&mut *tx)
    .await?;
    if cleaned.has("tag_names") {
        set_tags(&mut tx, id, owner_id, &cleaned.tag_names, when).await?;
    }
    let row = get_owned_tx(&mut tx, owner_id, id)
        .await?
        .ok_or(sqlx::Error::RowNotFound)?;
    tx.commit().await?;
    Ok(Ok(row))
}

pub async fn set_archived(
    pool: &PgPool,
    owner_id: i64,
    id: i64,
    archived: bool,
) -> Result<Option<BookmarkRow>, sqlx::Error> {
    let current = get_by_id(pool, id).await?;
    let Some(current) = current else {
        return Ok(None);
    };
    if current.owner_id != owner_id {
        return Ok(None);
    }
    sqlx::query("UPDATE bookmarks SET is_archived=$1, date_modified=$2 WHERE id=$3")
        .bind(archived)
        .bind(Utc::now())
        .bind(id)
        .execute(pool)
        .await?;
    get_by_id(pool, id).await
}

pub async fn delete_bookmark(pool: &PgPool, owner_id: i64, id: i64) -> Result<bool, sqlx::Error> {
    let result = sqlx::query("DELETE FROM bookmarks WHERE id=$1 AND owner_id=$2")
        .bind(id)
        .bind(owner_id)
        .execute(pool)
        .await?;
    Ok(result.rows_affected() == 1)
}

pub async fn list_tags(
    pool: &PgPool,
    owner_id: i64,
    request_url: &str,
    pairs: &[(String, String)],
) -> Result<Value, sqlx::Error> {
    let total: i64 = sqlx::query_scalar("SELECT count(*)::bigint FROM tags WHERE owner_id=$1")
        .bind(owner_id)
        .fetch_one(pool)
        .await?;
    let (limit_bad, limit, offset_bad, offset) = crate::logic::page_params(pairs);
    let (limit_n, offset_n) = page_limit_offset(total, limit_bad, limit, offset_bad, offset);
    let rows = sqlx::query(
        "SELECT id, owner_id, name, date_added FROM tags WHERE owner_id=$1 ORDER BY id ASC LIMIT $2 OFFSET $3",
    )
    .bind(owner_id)
    .bind(limit_n)
    .bind(offset_n)
    .fetch_all(pool)
    .await?;
    let mut results = Vec::new();
    for row in rows {
        let item = TagRow {
            id: row.try_get(0)?,
            owner_id: row.try_get(1)?,
            name: row.try_get(2)?,
            date_added: row.try_get(3)?,
        };
        results.push(tag_json(&item));
    }
    let (next, prev) = page_links(request_url, total, limit_bad, limit, offset_bad, offset);
    Ok(json!({
        "count": total,
        "next": next,
        "previous": prev,
        "results": results,
    }))
}

pub async fn get_tag(pool: &PgPool, id: i64) -> Result<Option<TagRow>, sqlx::Error> {
    let row = sqlx::query("SELECT id, owner_id, name, date_added FROM tags WHERE id=$1")
        .bind(id)
        .fetch_optional(pool)
        .await?;
    let Some(row) = row else {
        return Ok(None);
    };
    Ok(Some(TagRow {
        id: row.try_get(0)?,
        owner_id: row.try_get(1)?,
        name: row.try_get(2)?,
        date_added: row.try_get(3)?,
    }))
}

pub async fn create_tag(pool: &PgPool, owner_id: i64, name: &str) -> Result<TagRow, sqlx::Error> {
    let lower = name.to_lowercase();
    let existing = sqlx::query(
        "SELECT id, owner_id, name, date_added FROM tags WHERE owner_id=$1 AND name_lower=$2",
    )
    .bind(owner_id)
    .bind(&lower)
    .fetch_optional(pool)
    .await?;
    if let Some(row) = existing {
        return Ok(TagRow {
            id: row.try_get(0)?,
            owner_id: row.try_get(1)?,
            name: row.try_get(2)?,
            date_added: row.try_get(3)?,
        });
    }
    let row = sqlx::query(
        "INSERT INTO tags (owner_id, name, name_lower, date_added) VALUES ($1,$2,$3,$4)
         RETURNING id, owner_id, name, date_added",
    )
    .bind(owner_id)
    .bind(name)
    .bind(&lower)
    .bind(Utc::now())
    .fetch_one(pool)
    .await?;
    Ok(TagRow {
        id: row.try_get(0)?,
        owner_id: row.try_get(1)?,
        name: row.try_get(2)?,
        date_added: row.try_get(3)?,
    })
}

pub async fn delete_tag(pool: &PgPool, owner_id: i64, id: i64) -> Result<bool, sqlx::Error> {
    let result = sqlx::query("DELETE FROM tags WHERE id=$1 AND owner_id=$2")
        .bind(id)
        .bind(owner_id)
        .execute(pool)
        .await?;
    Ok(result.rows_affected() == 1)
}

pub async fn list_bundles(
    pool: &PgPool,
    owner_id: i64,
    request_url: &str,
    pairs: &[(String, String)],
) -> Result<Value, sqlx::Error> {
    let total: i64 = sqlx::query_scalar("SELECT count(*)::bigint FROM bundles WHERE owner_id=$1")
        .bind(owner_id)
        .fetch_one(pool)
        .await?;
    let (limit_bad, limit, offset_bad, offset) = crate::logic::page_params(pairs);
    let (limit_n, offset_n) = page_limit_offset(total, limit_bad, limit, offset_bad, offset);
    let rows = sqlx::query(
        "SELECT id, owner_id, name, search, any_tags, all_tags, excluded_tags, filter_unread, filter_shared, \"order\", date_created, date_modified
         FROM bundles WHERE owner_id=$1 ORDER BY \"order\" ASC, id ASC LIMIT $2 OFFSET $3",
    )
    .bind(owner_id)
    .bind(limit_n)
    .bind(offset_n)
    .fetch_all(pool)
    .await?;
    let mut results = Vec::new();
    for row in rows {
        results.push(bundle_json(&scan_bundle(&row)?));
    }
    let (next, prev) = page_links(request_url, total, limit_bad, limit, offset_bad, offset);
    Ok(json!({
        "count": total,
        "next": next,
        "previous": prev,
        "results": results,
    }))
}

pub async fn get_bundle(pool: &PgPool, id: i64) -> Result<Option<BundleRow>, sqlx::Error> {
    let row = sqlx::query(
        "SELECT id, owner_id, name, search, any_tags, all_tags, excluded_tags, filter_unread, filter_shared, \"order\", date_created, date_modified
         FROM bundles WHERE id=$1",
    )
    .bind(id)
    .fetch_optional(pool)
    .await?;
    row.as_ref().map(scan_bundle).transpose()
}

pub async fn create_bundle(
    pool: &PgPool,
    owner_id: i64,
    cleaned: &BundleIn,
) -> Result<BundleRow, sqlx::Error> {
    let when = Utc::now();
    let order = if cleaned.has("order") {
        cleaned.order
    } else {
        let current: i32 =
            sqlx::query_scalar("SELECT COALESCE(MAX(\"order\"), -1)::int FROM bundles WHERE owner_id=$1")
                .bind(owner_id)
                .fetch_one(pool)
                .await?;
        current + 1
    };
    let search = if cleaned.has("search") { cleaned.search.clone() } else { String::new() };
    let any_tags = if cleaned.has("any_tags") { cleaned.any_tags.clone() } else { String::new() };
    let all_tags = if cleaned.has("all_tags") { cleaned.all_tags.clone() } else { String::new() };
    let excluded = if cleaned.has("excluded_tags") {
        cleaned.excluded_tags.clone()
    } else {
        String::new()
    };
    let unread = if cleaned.has("filter_unread") {
        cleaned.filter_unread.clone()
    } else {
        "off".to_string()
    };
    let shared = if cleaned.has("filter_shared") {
        cleaned.filter_shared.clone()
    } else {
        "off".to_string()
    };
    let row = sqlx::query(
        "INSERT INTO bundles (owner_id, name, search, any_tags, all_tags, excluded_tags, filter_unread, filter_shared, \"order\", date_created, date_modified)
         VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11)
         RETURNING id, owner_id, name, search, any_tags, all_tags, excluded_tags, filter_unread, filter_shared, \"order\", date_created, date_modified",
    )
    .bind(owner_id)
    .bind(&cleaned.name)
    .bind(&search)
    .bind(&any_tags)
    .bind(&all_tags)
    .bind(&excluded)
    .bind(&unread)
    .bind(&shared)
    .bind(order)
    .bind(when)
    .bind(when)
    .fetch_one(pool)
    .await?;
    scan_bundle(&row)
}

pub async fn update_bundle(
    pool: &PgPool,
    owner_id: i64,
    id: i64,
    cleaned: &BundleIn,
) -> Result<Option<BundleRow>, sqlx::Error> {
    let Some(current) = get_bundle(pool, id).await? else {
        return Ok(None);
    };
    if current.owner_id != owner_id {
        return Ok(None);
    }
    let name = if cleaned.has("name") { cleaned.name.clone() } else { current.name };
    let search = if cleaned.has("search") { cleaned.search.clone() } else { current.search };
    let any_tags = if cleaned.has("any_tags") { cleaned.any_tags.clone() } else { current.any_tags };
    let all_tags = if cleaned.has("all_tags") { cleaned.all_tags.clone() } else { current.all_tags };
    let excluded = if cleaned.has("excluded_tags") {
        cleaned.excluded_tags.clone()
    } else {
        current.excluded_tags
    };
    let unread = if cleaned.has("filter_unread") {
        cleaned.filter_unread.clone()
    } else {
        current.filter_unread
    };
    let shared = if cleaned.has("filter_shared") {
        cleaned.filter_shared.clone()
    } else {
        current.filter_shared
    };
    let order = if cleaned.has("order") { cleaned.order } else { current.order };
    let row = sqlx::query(
        "UPDATE bundles SET name=$1, search=$2, any_tags=$3, all_tags=$4, excluded_tags=$5,
            filter_unread=$6, filter_shared=$7, \"order\"=$8, date_modified=$9
         WHERE id=$10
         RETURNING id, owner_id, name, search, any_tags, all_tags, excluded_tags, filter_unread, filter_shared, \"order\", date_created, date_modified",
    )
    .bind(&name)
    .bind(&search)
    .bind(&any_tags)
    .bind(&all_tags)
    .bind(&excluded)
    .bind(&unread)
    .bind(&shared)
    .bind(order)
    .bind(Utc::now())
    .bind(id)
    .fetch_one(pool)
    .await?;
    Ok(Some(scan_bundle(&row)?))
}

pub async fn delete_bundle(pool: &PgPool, owner_id: i64, id: i64) -> Result<bool, sqlx::Error> {
    let mut tx = pool.begin().await?;
    let result = sqlx::query("DELETE FROM bundles WHERE id=$1 AND owner_id=$2")
        .bind(id)
        .bind(owner_id)
        .execute(&mut *tx)
        .await?;
    if result.rows_affected() != 1 {
        tx.commit().await?;
        return Ok(false);
    }
    let rows = sqlx::query("SELECT id FROM bundles WHERE owner_id=$1 ORDER BY \"order\" ASC, id ASC")
        .bind(owner_id)
        .fetch_all(&mut *tx)
        .await?;
    let mut ids = Vec::new();
    for row in rows {
        ids.push(row.try_get::<i64, _>(0)?);
    }
    for (index, row_id) in ids.iter().enumerate() {
        sqlx::query("UPDATE bundles SET \"order\"=$1 WHERE id=$2")
            .bind(index as i32)
            .bind(row_id)
            .execute(&mut *tx)
            .await?;
    }
    tx.commit().await?;
    Ok(true)
}

pub async fn ping(pool: &PgPool) -> Result<(), sqlx::Error> {
    sqlx::query("SELECT 1").execute(pool).await?;
    Ok(())
}
