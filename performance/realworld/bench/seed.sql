-- Identical Conduit dataset for every benchmark point.
-- 100 users, 20 tags, 10_000 articles, 2 tags each, 10_000 comments,
-- 1_000 follows, 5_000 favorites.
-- The password hash is bcrypt cost 12 of "password123", passed as :'hash'
-- so the dollar signs stay inside a quoted literal.

TRUNCATE
    comments,
    favorites,
    follows,
    article_tags,
    tags,
    articles,
    users
RESTART IDENTITY CASCADE;

INSERT INTO users (username, email, password_hash)
SELECT
    'user' || i,
    'user' || i || '@bench.test',
    :'hash'
FROM generate_series(1, 100) AS g(i);

INSERT INTO tags (name)
SELECT 'tag' || i FROM generate_series(0, 19) AS g(i);

INSERT INTO articles (
    author_id, slug, title, description, body, created_at, updated_at
)
SELECT
    ((i - 1) % 100) + 1,
    'article-' || i,
    'Title ' || i,
    'Description ' || i,
    'Body of article ' || i,
    timestamptz '2020-01-01+00' + (i * interval '1 second'),
    timestamptz '2020-01-01+00' + (i * interval '1 second')
FROM generate_series(1, 10000) AS g(i);

INSERT INTO article_tags (article_id, tag_id, position)
SELECT i, ((i - 1) % 20) + 1, 0 FROM generate_series(1, 10000) AS g(i);

INSERT INTO article_tags (article_id, tag_id, position)
SELECT i, (i % 20) + 1, 1 FROM generate_series(1, 10000) AS g(i);

INSERT INTO comments (article_id, author_id, body, created_at, updated_at)
SELECT
    i,
    (i % 100) + 1,
    'Comment ' || i,
    timestamptz '2020-01-01+00' + (i * interval '1 second'),
    timestamptz '2020-01-01+00' + (i * interval '1 second')
FROM generate_series(1, 10000) AS g(i);

INSERT INTO follows (follower_id, followee_id)
SELECT u, ((u - 1 + k) % 100) + 1
FROM generate_series(1, 100) AS a(u)
CROSS JOIN generate_series(1, 10) AS b(k);

INSERT INTO favorites (user_id, article_id)
SELECT ((i - 1) % 100) + 1, i
FROM generate_series(1, 5000) AS g(i);

ANALYZE;
