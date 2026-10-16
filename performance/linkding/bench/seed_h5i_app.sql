-- The shared schema's rows on rust-h5i's tables.
--
-- rust-h5i keeps its rows in h5i-app's own tables (schema h5iapp, one
-- tenant, id 1, every row keyed by tenant_id; text as UTF-8 bytea; times as
-- microseconds since 1970; a bundle's `order` plus 2^31). Run this once the
-- server has created its tables, right after schema.sql (the conformance
-- fixtures) or bench/seed.sql (the benchmark data): it copies those users,
-- profiles, tokens, bookmarks, tags, tag links and bundles with the same ids,
-- and sets the id counters past them.

BEGIN;

TRUNCATE
    h5iapp.linkding_users,
    h5iapp.linkding_tokens,
    h5iapp.linkding_bookmarks,
    h5iapp.linkding_tags,
    h5iapp.linkding_bookmark_tags,
    h5iapp.linkding_bundles,
    h5iapp.linkding_counters,
    h5iapp.h5i_idempotency;

INSERT INTO h5iapp.linkding_users
    (tenant_id, id, username, theme, date_display, link_target, web_archive, lax, sharing, public_sharing,
     favicons, display_url, permanent_notes, search_prefs, legacy)
SELECT
    1, u.id,
    convert_to(u.username, 'UTF8'),
    convert_to(p.theme, 'UTF8'),
    convert_to(p.bookmark_date_display, 'UTF8'),
    convert_to(p.bookmark_link_target, 'UTF8'),
    convert_to(p.web_archive_integration, 'UTF8'),
    p.tag_search = 'lax', p.enable_sharing, p.enable_public_sharing,
    p.enable_favicons, p.display_url, p.permanent_notes,
    convert_to(p.search_preferences::text, 'UTF8'),
    p.legacy_search
FROM public.users u
JOIN public.profiles p ON p.user_id = u.id;

INSERT INTO h5iapp.linkding_tokens (tenant_id, key, "user")
SELECT 1, convert_to(key, 'UTF8'), user_id FROM public.api_tokens;

INSERT INTO h5iapp.linkding_bookmarks
    (tenant_id, owner, added, id, url, url_norm, title, description, notes, unread, archived, shared, modified)
SELECT
    1, owner_id,
    (extract(epoch FROM date_added) * 1000000)::bigint,
    id,
    convert_to(url, 'UTF8'),
    convert_to(url_normalized, 'UTF8'),
    convert_to(title, 'UTF8'),
    convert_to(description, 'UTF8'),
    convert_to(notes, 'UTF8'),
    unread, is_archived, shared,
    (extract(epoch FROM date_modified) * 1000000)::bigint
FROM public.bookmarks;

-- name_lower is the kernel's: ASCII letters lowercased.
INSERT INTO h5iapp.linkding_tags (tenant_id, id, owner, name, name_lower, added)
SELECT
    1, id, owner_id,
    convert_to(name, 'UTF8'),
    convert_to(translate(name, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'), 'UTF8'),
    (extract(epoch FROM date_added) * 1000000)::bigint
FROM public.tags;

INSERT INTO h5iapp.linkding_bookmark_tags (tenant_id, bookmark, tag)
SELECT 1, bookmark_id, tag_id FROM public.bookmark_tags;

INSERT INTO h5iapp.linkding_bundles
    (tenant_id, id, owner, name, search, any_tags, all_tags, excluded_tags, filter_unread, filter_shared,
     "order", created, modified)
SELECT
    1, id, owner_id,
    convert_to(name, 'UTF8'), convert_to(search, 'UTF8'),
    convert_to(any_tags, 'UTF8'), convert_to(all_tags, 'UTF8'), convert_to(excluded_tags, 'UTF8'),
    convert_to(filter_unread, 'UTF8'), convert_to(filter_shared, 'UTF8'),
    "order"::bigint + 2147483648,
    (extract(epoch FROM date_created) * 1000000)::bigint,
    (extract(epoch FROM date_modified) * 1000000)::bigint
FROM public.bundles;

-- The last ids handed out, so new rows continue where the copy stopped.
INSERT INTO h5iapp.linkding_counters (tenant_id, last_bookmark, last_tag, last_bundle)
SELECT
    1,
    (SELECT coalesce(max(id), 0) FROM public.bookmarks),
    (SELECT coalesce(max(id), 0) FROM public.tags),
    (SELECT coalesce(max(id), 0) FROM public.bundles);

COMMIT;

ANALYZE h5iapp.linkding_users, h5iapp.linkding_tokens, h5iapp.linkding_bookmarks, h5iapp.linkding_tags,
    h5iapp.linkding_bookmark_tags, h5iapp.linkding_bundles, h5iapp.linkding_counters;
