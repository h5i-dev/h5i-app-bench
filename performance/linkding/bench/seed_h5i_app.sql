-- The seed.sql dataset on rust-h5i's (h5i-app engine) tables.
--
-- rust-h5i keeps its rows in h5i-app's own tables (schema h5iapp, one tenant,
-- id 1, every row keyed by tenant_id; text as UTF-8 bytea; times as
-- milliseconds since 1970). Run this right after seed.sql, against the same
-- database, once the server has created its tables (it does so at start): it
-- copies the rows seed.sql loaded into the shared public schema so both hold
-- the same users, tokens, bookmarks, tags and bundles with the same ids.
--
-- Validated against a hand-written-SQL variant (fastify/rust-h5i-optimized) on
-- the same dataset: the same queries return the same bookmarks and counts.

BEGIN;

TRUNCATE
    h5iapp.linkding_tokens,
    h5iapp.linkding_users,
    h5iapp.linkding_bookmarks,
    h5iapp.linkding_tags,
    h5iapp.linkding_bookmark_tags,
    h5iapp.linkding_bundles,
    h5iapp.linkding_counters,
    h5iapp.h5i_clock,
    h5iapp.h5i_idempotency;

-- Tokens: key as UTF-8 bytes, the user it names.
INSERT INTO h5iapp.linkding_tokens (tenant_id, key, "user")
SELECT 1, convert_to(key, 'UTF8'), user_id
FROM public.api_tokens;

-- Users: profile preferences fold into the user row. tag_search is 'lax' or
-- 'strict' in the shared schema; the kernel keeps the boolean (lax = 'lax').
INSERT INTO h5iapp.linkding_users (
    tenant_id, id, username, theme, date_display, link_target, web_archive,
    lax, sharing, public_sharing, favicons, display_url, permanent_notes,
    search_prefs, legacy)
SELECT
    1, u.id,
    convert_to(u.username, 'UTF8'),
    convert_to(coalesce(p.theme, ''), 'UTF8'),
    convert_to(coalesce(p.bookmark_date_display, ''), 'UTF8'),
    convert_to(coalesce(p.bookmark_link_target, ''), 'UTF8'),
    convert_to(coalesce(p.web_archive_integration, ''), 'UTF8'),
    coalesce(p.tag_search, 'strict') = 'lax',
    coalesce(p.enable_sharing, false),
    coalesce(p.enable_public_sharing, false),
    coalesce(p.enable_favicons, false),
    coalesce(p.display_url, false),
    coalesce(p.permanent_notes, false),
    convert_to(coalesce(p.search_preferences::text, '{}'), 'UTF8'),
    coalesce(p.legacy_search, false)
FROM public.users u
LEFT JOIN public.profiles p ON p.user_id = u.id;

-- Bookmarks: timestamps as milliseconds since the epoch.
INSERT INTO h5iapp.linkding_bookmarks (
    tenant_id, owner, added, id, url, url_norm, title, description, notes,
    unread, archived, shared, modified)
SELECT
    1, owner_id,
    (extract(epoch from date_added) * 1000000)::bigint,
    id,
    convert_to(coalesce(url, ''), 'UTF8'),
    convert_to(coalesce(url_normalized, ''), 'UTF8'),
    convert_to(coalesce(title, ''), 'UTF8'),
    convert_to(coalesce(description, ''), 'UTF8'),
    convert_to(coalesce(notes, ''), 'UTF8'),
    unread, is_archived, shared,
    (extract(epoch from date_modified) * 1000000)::bigint
FROM public.bookmarks;

-- Tags.
INSERT INTO h5iapp.linkding_tags (tenant_id, id, owner, name, name_lower, added)
SELECT
    1, id, owner_id,
    convert_to(coalesce(name, ''), 'UTF8'),
    convert_to(coalesce(name_lower, ''), 'UTF8'),
    (extract(epoch from date_added) * 1000000)::bigint
FROM public.tags;

-- Bookmark/tag links.
INSERT INTO h5iapp.linkding_bookmark_tags (tenant_id, bookmark, tag)
SELECT 1, bookmark_id, tag_id FROM public.bookmark_tags;

-- Bundles (the search-field texts stay as UTF-8 bytes).
INSERT INTO h5iapp.linkding_bundles (
    tenant_id, id, owner, name, search, any_tags, all_tags, excluded_tags,
    filter_unread, filter_shared, "order", created, modified)
SELECT
    1, id, owner_id,
    convert_to(coalesce(name, ''), 'UTF8'),
    convert_to(coalesce(search, ''), 'UTF8'),
    convert_to(coalesce(any_tags, ''), 'UTF8'),
    convert_to(coalesce(all_tags, ''), 'UTF8'),
    convert_to(coalesce(excluded_tags, ''), 'UTF8'),
    convert_to(coalesce(filter_unread, ''), 'UTF8'),
    convert_to(coalesce(filter_shared, ''), 'UTF8'),
    "order",
    (extract(epoch from date_created) * 1000000)::bigint,
    (extract(epoch from date_modified) * 1000000)::bigint
FROM public.bundles;

-- Counters: the last id handed out for each sequence.
INSERT INTO h5iapp.linkding_counters (tenant_id, last_bookmark, last_tag, last_bundle)
VALUES (
    1,
    coalesce((SELECT max(id) FROM public.bookmarks), 0),
    coalesce((SELECT max(id) FROM public.tags), 0),
    coalesce((SELECT max(id) FROM public.bundles), 0));

-- Logical clock: past every seeded timestamp, so new writes sort after them.
INSERT INTO h5iapp.h5i_clock (tenant_id, last)
VALUES (
    1,
    coalesce((SELECT max((extract(epoch from date_modified) * 1000000)::bigint)
              FROM public.bookmarks), 0));

COMMIT;
