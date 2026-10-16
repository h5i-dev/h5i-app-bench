-- Shared schema for the FastAPI, Go, Fastify, and Rust linkding API servers.
-- The upstream reference server keeps Django's own tables and is seeded separately.
-- Length limits are enforced in the application. Columns are TEXT so a limit
-- change does not require a migration.

CREATE TABLE IF NOT EXISTS users (
    id BIGSERIAL PRIMARY KEY,
    username TEXT NOT NULL UNIQUE,
    password TEXT NOT NULL DEFAULT ''
);

CREATE TABLE IF NOT EXISTS profiles (
    user_id BIGINT PRIMARY KEY REFERENCES users (id) ON DELETE CASCADE,
    theme TEXT NOT NULL DEFAULT 'auto',
    bookmark_date_display TEXT NOT NULL DEFAULT 'relative',
    bookmark_link_target TEXT NOT NULL DEFAULT '_blank',
    web_archive_integration TEXT NOT NULL DEFAULT 'disabled',
    tag_search TEXT NOT NULL DEFAULT 'strict',
    enable_sharing BOOLEAN NOT NULL DEFAULT TRUE,
    enable_public_sharing BOOLEAN NOT NULL DEFAULT FALSE,
    enable_favicons BOOLEAN NOT NULL DEFAULT FALSE,
    display_url BOOLEAN NOT NULL DEFAULT FALSE,
    permanent_notes BOOLEAN NOT NULL DEFAULT FALSE,
    search_preferences JSONB NOT NULL DEFAULT '{}'::jsonb,
    version TEXT NOT NULL DEFAULT '1.47.0',
    legacy_search BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE TABLE IF NOT EXISTS api_tokens (
    user_id BIGINT NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    key TEXT NOT NULL UNIQUE
);

CREATE INDEX IF NOT EXISTS api_tokens_user_idx ON api_tokens (user_id);

CREATE TABLE IF NOT EXISTS bookmarks (
    id BIGSERIAL PRIMARY KEY,
    owner_id BIGINT NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    url TEXT NOT NULL,
    url_normalized TEXT NOT NULL DEFAULT '',
    title TEXT NOT NULL DEFAULT '',
    description TEXT NOT NULL DEFAULT '',
    notes TEXT NOT NULL DEFAULT '',
    unread BOOLEAN NOT NULL DEFAULT FALSE,
    is_archived BOOLEAN NOT NULL DEFAULT FALSE,
    shared BOOLEAN NOT NULL DEFAULT FALSE,
    date_added TIMESTAMPTZ NOT NULL,
    date_modified TIMESTAMPTZ NOT NULL
);

CREATE INDEX IF NOT EXISTS bookmarks_owner_arch_added_idx
    ON bookmarks (owner_id, is_archived, date_added DESC, id DESC);
CREATE INDEX IF NOT EXISTS bookmarks_owner_modified_idx
    ON bookmarks (owner_id, is_archived, date_modified DESC, id DESC);
CREATE INDEX IF NOT EXISTS bookmarks_owner_norm_idx
    ON bookmarks (owner_id, url_normalized);
CREATE INDEX IF NOT EXISTS bookmarks_shared_idx
    ON bookmarks (shared, owner_id);

CREATE TABLE IF NOT EXISTS tags (
    id BIGSERIAL PRIMARY KEY,
    owner_id BIGINT NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    name_lower TEXT NOT NULL,
    date_added TIMESTAMPTZ NOT NULL,
    UNIQUE (owner_id, name_lower)
);

CREATE INDEX IF NOT EXISTS tags_owner_lower_idx ON tags (owner_id, name_lower);

CREATE TABLE IF NOT EXISTS bookmark_tags (
    bookmark_id BIGINT NOT NULL REFERENCES bookmarks (id) ON DELETE CASCADE,
    tag_id BIGINT NOT NULL REFERENCES tags (id) ON DELETE CASCADE,
    PRIMARY KEY (bookmark_id, tag_id)
);

CREATE INDEX IF NOT EXISTS bookmark_tags_tag_idx ON bookmark_tags (tag_id);

CREATE TABLE IF NOT EXISTS bundles (
    id BIGSERIAL PRIMARY KEY,
    owner_id BIGINT NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    search TEXT NOT NULL DEFAULT '',
    any_tags TEXT NOT NULL DEFAULT '',
    all_tags TEXT NOT NULL DEFAULT '',
    excluded_tags TEXT NOT NULL DEFAULT '',
    filter_unread TEXT NOT NULL DEFAULT 'off',
    filter_shared TEXT NOT NULL DEFAULT 'off',
    "order" INTEGER NOT NULL DEFAULT 0,
    date_created TIMESTAMPTZ NOT NULL,
    date_modified TIMESTAMPTZ NOT NULL
);

CREATE INDEX IF NOT EXISTS bundles_owner_order_idx ON bundles (owner_id, "order", id);

-- Conformance fixtures. Tokens are 40 characters, matching upstream ApiToken.
INSERT INTO users (id, username) VALUES
    (1, 'alice'),
    (2, 'bob'),
    (3, 'cara'),
    (4, 'dave'),
    (5, 'erin')
ON CONFLICT (id) DO UPDATE SET username = EXCLUDED.username;

SELECT setval('users_id_seq', GREATEST((SELECT MAX(id) FROM users), 1));

INSERT INTO profiles (
    user_id, tag_search, enable_sharing, enable_public_sharing, legacy_search
) VALUES
    (1, 'strict', TRUE, TRUE, FALSE),
    (2, 'strict', TRUE, FALSE, FALSE),
    (3, 'strict', FALSE, FALSE, FALSE),
    (4, 'lax', TRUE, FALSE, FALSE),
    (5, 'strict', TRUE, FALSE, TRUE)
ON CONFLICT (user_id) DO UPDATE SET
    tag_search = EXCLUDED.tag_search,
    enable_sharing = EXCLUDED.enable_sharing,
    enable_public_sharing = EXCLUDED.enable_public_sharing,
    legacy_search = EXCLUDED.legacy_search;

INSERT INTO api_tokens (user_id, key) VALUES
    (1, repeat('a', 40)),
    (2, repeat('b', 40)),
    (3, repeat('c', 40)),
    (4, repeat('d', 40)),
    (5, repeat('e', 40))
ON CONFLICT (key) DO NOTHING;
