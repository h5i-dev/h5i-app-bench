-- Same benchmark rows on the upstream Django tables.
-- Run after the image has migrated and created the superuser alice.
-- Bookmarks, tags, and the join table are replaced. Alice is kept.
-- web_archive_snapshot_url, favicon_file, and preview_image_file are empty
-- strings (the columns are NOT NULL). No snapshot rows are inserted.

TRUNCATE bookmarks_bookmark_tags, bookmarks_bookmark, bookmarks_tag, bookmarks_bookmarkasset
RESTART IDENTITY CASCADE;

INSERT INTO auth_user (
    username, password, is_superuser, first_name, last_name, email,
    is_staff, is_active, date_joined
)
SELECT
    'user' || i,
    '!',
    false,
    '',
    '',
    'user' || i || '@bench.test',
    false,
    true,
    timestamptz '2020-01-01+00'
FROM generate_series(2, 50) AS g(i)
WHERE NOT EXISTS (SELECT 1 FROM auth_user u WHERE u.username = 'user' || g.i);

INSERT INTO bookmarks_userprofile (
    theme, user_id, bookmark_date_display, bookmark_link_target,
    web_archive_integration, enable_sharing, enable_favicons, tag_search,
    display_url, permanent_notes, enable_public_sharing, search_preferences,
    custom_css, bookmark_description_display, bookmark_description_max_lines,
    display_archive_bookmark_action, display_edit_bookmark_action,
    display_remove_bookmark_action, display_view_bookmark_action,
    enable_automatic_html_snapshots, default_mark_unread, enable_preview_images,
    tag_grouping, auto_tagging_rules, items_per_page, sticky_pagination,
    custom_css_hash, collapse_side_panel, hide_bundles, default_mark_shared,
    legacy_search
)
SELECT
    'auto', u.id, 'relative', '_blank',
    'disabled', true, false, 'strict',
    false, false, false, '{}'::jsonb,
    '', 'inline', 1,
    true, true,
    true, true,
    false, false, false,
    'alphabetical', '', 30, false,
    '', false, false, false,
    false
FROM auth_user u
WHERE u.username LIKE 'user%'
  AND NOT EXISTS (
      SELECT 1 FROM bookmarks_userprofile p WHERE p.user_id = u.id
  );

UPDATE bookmarks_userprofile AS p
SET enable_sharing = true,
    enable_public_sharing = true,
    legacy_search = false,
    tag_search = 'strict',
    enable_automatic_html_snapshots = false
FROM auth_user u
WHERE p.user_id = u.id AND u.username = 'alice';

INSERT INTO bookmarks_apitoken (key, name, created, user_id)
SELECT repeat('a', 40), 'bench', timestamptz '2020-01-01+00', u.id
FROM auth_user u
WHERE u.username = 'alice'
ON CONFLICT (key) DO NOTHING;

INSERT INTO bookmarks_tag (name, date_added, owner_id)
SELECT 'tag' || i, timestamptz '2020-01-01+00', u.id
FROM generate_series(0, 1999) AS g(i)
CROSS JOIN auth_user u
WHERE u.username = 'alice';

INSERT INTO bookmarks_bookmark (
    url, title, description, notes, unread, is_archived, shared,
    date_added, date_modified, owner_id, web_archive_snapshot_url,
    favicon_file, preview_image_file, url_normalized
)
SELECT
    'https://example.com/b/' || i,
    CASE WHEN i % 50 = 0 THEN 'alpha ' || i ELSE 'bookmark ' || i END,
    '',
    '',
    (i % 7 = 0),
    (i % 20 = 0),
    (i % 10 = 0),
    timestamptz '2020-01-01+00' + (i * interval '1 second'),
    timestamptz '2020-01-01+00' + (i * interval '1 second'),
    u.id,
    '',
    '',
    '',
    'https://example.com/b/' || i
FROM generate_series(1, 100000) AS g(i)
CROSS JOIN auth_user u
WHERE u.username = 'alice';

INSERT INTO bookmarks_bookmark_tags (bookmark_id, tag_id)
SELECT i, ((i - 1) % 2000) + 1 FROM generate_series(1, 100000) AS g(i);

INSERT INTO bookmarks_bookmark_tags (bookmark_id, tag_id)
SELECT i, (i % 2000) + 1 FROM generate_series(1, 100000) AS g(i);

ANALYZE;
