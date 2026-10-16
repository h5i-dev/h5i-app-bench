-- The seed.sql dataset on rust-h5i-app's tables.
--
-- rust-h5i-app keeps its rows in h5i-app's own tables (schema conduit, one
-- tenant, id 1, every row keyed by tenant_id; text as UTF-8 bytea; times as
-- milliseconds since 1970). Run this right after seed.sql, against the same
-- database, once the server has created its tables: it copies the rows
-- seed.sql has just loaded into the shared schema, so both hold the same
-- users, articles, tags, comments, follows and favorites with the same ids,
-- slugs, password hashes and timestamps. An empty bio or image is NULL in the
-- shared schema and empty here; both render as null.

BEGIN;

TRUNCATE
    conduit.conduit_users,
    conduit.conduit_follows,
    conduit.conduit_articles,
    conduit.conduit_tags,
    conduit.conduit_favorites,
    conduit.conduit_comments,
    conduit.conduit_counters,
    conduit.h5i_idempotency;

INSERT INTO conduit.conduit_users (tenant_id, id, username, email, password, bio, image)
SELECT
    1, id,
    convert_to(username, 'UTF8'),
    convert_to(email, 'UTF8'),
    convert_to(password_hash, 'UTF8'),
    convert_to(coalesce(bio, ''), 'UTF8'),
    convert_to(coalesce(image, ''), 'UTF8')
FROM public.users;

INSERT INTO conduit.conduit_follows (tenant_id, follower, followed)
SELECT 1, follower_id, followee_id FROM public.follows;

INSERT INTO conduit.conduit_articles
    (tenant_id, id, author, slug, title, description, body, created, updated)
SELECT
    1, id, author_id,
    convert_to(slug, 'UTF8'),
    convert_to(title, 'UTF8'),
    convert_to(description, 'UTF8'),
    convert_to(body, 'UTF8'),
    (extract(epoch FROM created_at) * 1000)::bigint,
    (extract(epoch FROM updated_at) * 1000)::bigint
FROM public.articles;

INSERT INTO conduit.conduit_tags (tenant_id, article, tag)
SELECT 1, at.article_id, convert_to(t.name, 'UTF8')
FROM public.article_tags at
JOIN public.tags t ON t.id = at.tag_id;

INSERT INTO conduit.conduit_favorites (tenant_id, article, "user")
SELECT 1, article_id, user_id FROM public.favorites;

INSERT INTO conduit.conduit_comments (tenant_id, id, article, author, body, created)
SELECT
    1, id, article_id, author_id,
    convert_to(body, 'UTF8'),
    (extract(epoch FROM created_at) * 1000)::bigint
FROM public.comments;

-- The last ids handed out, so new rows continue where seed.sql stopped.
INSERT INTO conduit.conduit_counters (tenant_id, last_user, last_article, last_comment)
SELECT
    1,
    (SELECT coalesce(max(id), 0) FROM public.users),
    (SELECT coalesce(max(id), 0) FROM public.articles),
    (SELECT coalesce(max(id), 0) FROM public.comments);

COMMIT;

ANALYZE conduit.conduit_users, conduit.conduit_follows, conduit.conduit_articles, conduit.conduit_tags,
    conduit.conduit_favorites, conduit.conduit_comments, conduit.conduit_counters;
