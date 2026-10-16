-- Identical dataset for every benchmark point on schema.sql.
-- 50 users (alice is user 1, plus user6..user50), 2000 tags owned by alice,
-- 100000 bookmarks owned by alice, two tags each.
-- Archived when i % 20 = 0, shared when i % 10 = 0, unread when i % 7 = 0.
-- Titles of every 50th bookmark contain "alpha" so text search scans and matches.
-- The bench token is alice's 40-character key from schema.sql.

TRUNCATE bookmark_tags, bookmarks, tags, bundles RESTART IDENTITY CASCADE;

INSERT INTO users (id, username)
SELECT i, 'user' || i
FROM generate_series(6, 50) AS g(i)
ON CONFLICT (id) DO NOTHING;

SELECT setval('users_id_seq', GREATEST((SELECT MAX(id) FROM users), 1));

INSERT INTO profiles (user_id)
SELECT i
FROM generate_series(6, 50) AS g(i)
ON CONFLICT (user_id) DO NOTHING;

INSERT INTO tags (owner_id, name, name_lower, date_added)
SELECT 1, 'tag' || i, 'tag' || i, timestamptz '2020-01-01+00'
FROM generate_series(0, 1999) AS g(i);

INSERT INTO bookmarks (
    owner_id, url, url_normalized, title, description, notes,
    unread, is_archived, shared, date_added, date_modified
)
SELECT
    1,
    'https://example.com/b/' || i,
    'https://example.com/b/' || i,
    CASE WHEN i % 50 = 0 THEN 'alpha ' || i ELSE 'bookmark ' || i END,
    '',
    '',
    (i % 7 = 0),
    (i % 20 = 0),
    (i % 10 = 0),
    timestamptz '2020-01-01+00' + (i * interval '1 second'),
    timestamptz '2020-01-01+00' + (i * interval '1 second')
FROM generate_series(1, 100000) AS g(i);

INSERT INTO bookmark_tags (bookmark_id, tag_id)
SELECT i, ((i - 1) % 2000) + 1 FROM generate_series(1, 100000) AS g(i);

INSERT INTO bookmark_tags (bookmark_id, tag_id)
SELECT i, (i % 2000) + 1 FROM generate_series(1, 100000) AS g(i);

ANALYZE;
