-- Shared Conduit schema. Every implementation uses this database.
--
-- Password hashes are bcrypt with cost 12.
-- Timestamps are timestamptz, rendered as UTC YYYY-MM-DDTHH:MM:SS.MSZ.

CREATE TABLE IF NOT EXISTS users (
    id BIGSERIAL PRIMARY KEY,
    username TEXT NOT NULL,
    email TEXT NOT NULL,
    password_hash TEXT NOT NULL,
    bio TEXT,
    image TEXT,
    CONSTRAINT users_username_unique UNIQUE (username),
    CONSTRAINT users_email_unique UNIQUE (email)
);

CREATE TABLE IF NOT EXISTS articles (
    id BIGSERIAL PRIMARY KEY,
    author_id BIGINT NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    slug TEXT NOT NULL,
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    body TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT statement_timestamp(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT statement_timestamp(),
    CONSTRAINT articles_slug_unique UNIQUE (slug)
);

CREATE INDEX IF NOT EXISTS articles_author_created_idx
    ON articles (author_id, created_at DESC, id DESC);
CREATE INDEX IF NOT EXISTS articles_created_idx
    ON articles (created_at DESC, id DESC);

CREATE TABLE IF NOT EXISTS tags (
    id BIGSERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    CONSTRAINT tags_name_unique UNIQUE (name)
);

CREATE TABLE IF NOT EXISTS article_tags (
    article_id BIGINT NOT NULL REFERENCES articles (id) ON DELETE CASCADE,
    tag_id BIGINT NOT NULL REFERENCES tags (id),
    position INTEGER NOT NULL,
    PRIMARY KEY (article_id, tag_id)
);

CREATE INDEX IF NOT EXISTS article_tags_tag_idx
    ON article_tags (tag_id, article_id);

CREATE TABLE IF NOT EXISTS follows (
    follower_id BIGINT NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    followee_id BIGINT NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    PRIMARY KEY (follower_id, followee_id)
);

CREATE INDEX IF NOT EXISTS follows_followee_idx ON follows (followee_id);

CREATE TABLE IF NOT EXISTS favorites (
    user_id BIGINT NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    article_id BIGINT NOT NULL REFERENCES articles (id) ON DELETE CASCADE,
    PRIMARY KEY (user_id, article_id)
);

CREATE INDEX IF NOT EXISTS favorites_article_idx ON favorites (article_id);

CREATE TABLE IF NOT EXISTS comments (
    id BIGSERIAL PRIMARY KEY,
    article_id BIGINT NOT NULL REFERENCES articles (id) ON DELETE CASCADE,
    author_id BIGINT NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    body TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT statement_timestamp(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT statement_timestamp()
);

CREATE INDEX IF NOT EXISTS comments_article_idx
    ON comments (article_id, created_at, id);
