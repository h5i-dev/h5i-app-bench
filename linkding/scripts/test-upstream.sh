#!/usr/bin/env bash
# Validate tests/ against the pinned linkding image.
# Uses Postgres container linkding-pg-probe (port 5449) and the app container
# linkding-up on http://127.0.0.1:8105. Bookmark rows are cleared before each
# file. The five fixture users are created or updated in place.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
HURL="${HURL:-/var/tmp/tools/hurl}"
HOST="${HOST:-http://127.0.0.1:8105}"
PG="${LINKDING_UPSTREAM_PG:-linkding-pg-probe}"
APP="${LINKDING_UPSTREAM_APP:-linkding-up}"
PG_PORT="${LINKDING_UPSTREAM_PG_PORT:-5449}"
APP_PORT="${LINKDING_UPSTREAM_PORT:-8105}"
DATA_PG="${LINKDING_UPSTREAM_PG_DATA:-/var/tmp/linkding-pg-probe-data}"
DATA_APP="${LINKDING_UPSTREAM_APP_DATA:-/var/tmp/linkding-up-data}"

if ! docker ps -a --format '{{.Names}}' | grep -qx "$PG"; then
  mkdir -p "$DATA_PG"
  docker run -d --name "$PG" \
    -e POSTGRES_USER=linkding \
    -e POSTGRES_PASSWORD=linkding \
    -e POSTGRES_DB=linkding \
    -p "127.0.0.1:${PG_PORT}:5432" \
    -v "${DATA_PG}:/var/lib/postgresql/data" \
    postgres:16
fi
if [ "$(docker inspect -f '{{.State.Running}}' "$PG")" != "true" ]; then
  docker start "$PG" >/dev/null
fi

if ! docker ps -a --format '{{.Names}}' | grep -qx "$APP"; then
  mkdir -p "$DATA_APP"
  docker run -d --name "$APP" --network host \
    -e LD_SERVER_HOST=127.0.0.1 \
    -e LD_SERVER_PORT="$APP_PORT" \
    -e LD_DB_HOST=127.0.0.1 \
    -e LD_DB_PORT="$PG_PORT" \
    -e LD_DB_USER=linkding \
    -e LD_DB_PASSWORD=linkding \
    -e LD_DB_NAME=linkding \
    -e LD_SUPERUSER_NAME=alice \
    -e LD_SUPERUSER_PASSWORD=alice-pass-123 \
    -e LD_DISABLE_BACKGROUND_TASKS=True \
    -v "${DATA_APP}:/etc/linkding/data" \
    sissbruecker/linkding:1.47.0
fi
if [ "$(docker inspect -f '{{.State.Running}}' "$APP")" != "true" ]; then
  docker start "$APP" >/dev/null
fi

ready=0
for _ in $(seq 1 90); do
  if curl -sf "$HOST/api/bookmarks/shared/" >/dev/null; then
    ready=1
    break
  fi
  sleep 1
done
if [ "$ready" != 1 ]; then
  echo "upstream linkding did not become ready" >&2
  exit 1
fi

docker exec -i "$PG" psql -U linkding -d linkding -v ON_ERROR_STOP=1 <<'SQL'
INSERT INTO auth_user (username, password, is_superuser, first_name, last_name, email, is_staff, is_active, date_joined)
SELECT v.username, '!', FALSE, '', '', '', FALSE, TRUE, now()
FROM (VALUES ('bob'), ('cara'), ('dave'), ('erin')) AS v(username)
WHERE NOT EXISTS (SELECT 1 FROM auth_user u WHERE u.username = v.username);

INSERT INTO bookmarks_userprofile (
    theme, user_id, bookmark_date_display, bookmark_link_target, web_archive_integration,
    enable_sharing, enable_favicons, tag_search, display_url, permanent_notes,
    enable_public_sharing, search_preferences, custom_css, bookmark_description_display,
    bookmark_description_max_lines, display_archive_bookmark_action, display_edit_bookmark_action,
    display_remove_bookmark_action, display_view_bookmark_action, enable_automatic_html_snapshots,
    default_mark_unread, enable_preview_images, tag_grouping, auto_tagging_rules, items_per_page,
    sticky_pagination, custom_css_hash, collapse_side_panel, hide_bundles, default_mark_shared,
    legacy_search
)
SELECT
    p.theme, u.id, p.bookmark_date_display, p.bookmark_link_target, p.web_archive_integration,
    p.enable_sharing, p.enable_favicons, p.tag_search, p.display_url, p.permanent_notes,
    p.enable_public_sharing, p.search_preferences, p.custom_css, p.bookmark_description_display,
    p.bookmark_description_max_lines, p.display_archive_bookmark_action, p.display_edit_bookmark_action,
    p.display_remove_bookmark_action, p.display_view_bookmark_action, p.enable_automatic_html_snapshots,
    p.default_mark_unread, p.enable_preview_images, p.tag_grouping, '', p.items_per_page,
    p.sticky_pagination, '', p.collapse_side_panel, p.hide_bundles, p.default_mark_shared,
    FALSE
FROM auth_user u
JOIN bookmarks_userprofile p ON p.user_id = (SELECT id FROM auth_user WHERE username = 'alice')
WHERE u.username IN ('bob', 'cara', 'dave', 'erin')
  AND NOT EXISTS (SELECT 1 FROM bookmarks_userprofile x WHERE x.user_id = u.id);

UPDATE bookmarks_userprofile p SET
    enable_sharing = s.sharing,
    enable_public_sharing = s.public,
    tag_search = s.tag_search,
    legacy_search = s.legacy,
    auto_tagging_rules = ''
FROM (
    VALUES
        ('alice', TRUE, TRUE, 'strict', FALSE),
        ('bob', TRUE, FALSE, 'strict', FALSE),
        ('cara', FALSE, FALSE, 'strict', FALSE),
        ('dave', TRUE, FALSE, 'lax', FALSE),
        ('erin', TRUE, FALSE, 'strict', TRUE)
) AS s(username, sharing, public, tag_search, legacy)
JOIN auth_user u ON u.username = s.username
WHERE p.user_id = u.id;

INSERT INTO bookmarks_apitoken (key, name, created, user_id)
SELECT s.key, 'conformance', now(), u.id
FROM (
    VALUES
        ('alice', repeat('a', 40)),
        ('bob', repeat('b', 40)),
        ('cara', repeat('c', 40)),
        ('dave', repeat('d', 40)),
        ('erin', repeat('e', 40))
) AS s(username, key)
JOIN auth_user u ON u.username = s.username
ON CONFLICT (key) DO NOTHING;
SQL

truncate_rows() {
  docker exec -i "$PG" psql -U linkding -d linkding -v ON_ERROR_STOP=1 \
    -c "TRUNCATE bookmarks_bookmark_tags, bookmarks_bookmarkasset, bookmarks_bookmark, bookmarks_tag, bookmarks_bookmarkbundle RESTART IDENTITY CASCADE;" \
    >/dev/null
}

alice="$(printf 'a%.0s' {1..40})"
bob="$(printf 'b%.0s' {1..40})"
cara="$(printf 'c%.0s' {1..40})"
dave="$(printf 'd%.0s' {1..40})"
erin="$(printf 'e%.0s' {1..40})"

for file in "$ROOT"/tests/*.hurl; do
  echo "hurl $(basename "$file") $HOST"
  truncate_rows
  "$HURL" --test --jobs 1 \
    --variable "host=$HOST" \
    --variable "alice=$alice" \
    --variable "bob=$bob" \
    --variable "cara=$cara" \
    --variable "dave=$dave" \
    --variable "erin=$erin" \
    "$file"
done
echo "upstream hurl ok"
