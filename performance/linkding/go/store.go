package main

import (
	"context"
	"encoding/json"
	"errors"
	"sort"
	"strconv"
	"strings"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
)

type querier interface {
	Query(ctx context.Context, sql string, args ...any) (pgx.Rows, error)
	QueryRow(ctx context.Context, sql string, args ...any) pgx.Row
	Exec(ctx context.Context, sql string, arguments ...any) (pgconn.CommandTag, error)
}

type userRow struct {
	ID                    int64
	Username              string
	Theme                 string
	BookmarkDateDisplay   string
	BookmarkLinkTarget    string
	WebArchiveIntegration string
	TagSearch             string
	EnableSharing         bool
	EnablePublicSharing   bool
	EnableFavicons        bool
	DisplayURL            bool
	PermanentNotes        bool
	SearchPreferences     []byte
	LegacySearch          bool
}

type bookmarkRow struct {
	ID            int64
	OwnerID       int64
	URL           string
	URLNormalized string
	Title         string
	Description   string
	Notes         string
	Unread        bool
	IsArchived    bool
	Shared        bool
	DateAdded     time.Time
	DateModified  time.Time
}

type tagRow struct {
	ID        int64
	Name      string
	DateAdded time.Time
}

type bundleRow struct {
	ID           int64
	Name         string
	Search       string
	AnyTags      string
	AllTags      string
	ExcludedTags string
	FilterUnread string
	FilterShared string
	Order        int
	DateCreated  time.Time
	DateModified time.Time
}

const bookmarkColumns = `b.id, b.owner_id, b.url, b.url_normalized, b.title, b.description, b.notes, b.unread, b.is_archived, b.shared, b.date_added, b.date_modified`

func scanBookmark(row pgx.Row) (bookmarkRow, error) {
	var item bookmarkRow
	err := row.Scan(&item.ID, &item.OwnerID, &item.URL, &item.URLNormalized, &item.Title, &item.Description, &item.Notes, &item.Unread, &item.IsArchived, &item.Shared, &item.DateAdded, &item.DateModified)
	return item, err
}

func (a *app) loadUser(ctx context.Context, token string) (*userRow, error) {
	row := a.pool.QueryRow(ctx, `
		SELECT u.id, u.username, p.theme, p.bookmark_date_display, p.bookmark_link_target,
		       p.web_archive_integration, p.tag_search, p.enable_sharing, p.enable_public_sharing,
		       p.enable_favicons, p.display_url, p.permanent_notes, p.search_preferences, p.legacy_search
		FROM api_tokens t
		JOIN users u ON u.id = t.user_id
		JOIN profiles p ON p.user_id = u.id
		WHERE t.key = $1`, token)
	var user userRow
	if err := row.Scan(&user.ID, &user.Username, &user.Theme, &user.BookmarkDateDisplay, &user.BookmarkLinkTarget, &user.WebArchiveIntegration, &user.TagSearch, &user.EnableSharing, &user.EnablePublicSharing, &user.EnableFavicons, &user.DisplayURL, &user.PermanentNotes, &user.SearchPreferences, &user.LegacySearch); err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, nil
		}
		return nil, err
	}
	return &user, nil
}

func (a *app) tagMap(ctx context.Context, q querier, ids []int64) (map[int64][]string, error) {
	grouped := map[int64][]string{}
	for _, id := range ids {
		grouped[id] = []string{}
	}
	if len(ids) == 0 {
		return grouped, nil
	}
	rows, err := q.Query(ctx, `
		SELECT bt.bookmark_id, t.name
		FROM bookmark_tags bt
		JOIN tags t ON t.id = bt.tag_id
		WHERE bt.bookmark_id = ANY($1::bigint[])`, ids)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	for rows.Next() {
		var id int64
		var name string
		if err := rows.Scan(&id, &name); err != nil {
			return nil, err
		}
		grouped[id] = append(grouped[id], name)
	}
	return grouped, rows.Err()
}

func bookmarkJSON(row bookmarkRow, names []string) map[string]any {
	if names == nil {
		names = []string{}
	}
	sort.Strings(names)
	return map[string]any{
		"id": row.ID, "url": row.URL, "title": row.Title, "description": row.Description, "notes": row.Notes,
		"web_archive_snapshot_url": archiveURL(row.URL, row.DateAdded),
		"favicon_url":              nil, "preview_image_url": nil,
		"is_archived": row.IsArchived, "unread": row.Unread, "shared": row.Shared,
		"tag_names": names, "date_added": fmtTime(row.DateAdded), "date_modified": fmtTime(row.DateModified),
		"website_title": nil, "website_description": nil,
	}
}

func tagJSON(row tagRow) map[string]any {
	return map[string]any{"id": row.ID, "name": row.Name, "date_added": fmtTime(row.DateAdded)}
}

func bundleJSON(row bundleRow) map[string]any {
	return map[string]any{
		"id": row.ID, "name": row.Name, "search": row.Search, "any_tags": row.AnyTags,
		"all_tags": row.AllTags, "excluded_tags": row.ExcludedTags,
		"filter_unread": row.FilterUnread, "filter_shared": row.FilterShared, "order": row.Order,
		"date_created": fmtTime(row.DateCreated), "date_modified": fmtTime(row.DateModified),
	}
}

func (a *app) setTags(ctx context.Context, q querier, bookmarkID, ownerID int64, raw []string, when time.Time) error {
	names := bookmarkTagNames(raw)
	if _, err := q.Exec(ctx, `DELETE FROM bookmark_tags WHERE bookmark_id = $1`, bookmarkID); err != nil {
		return err
	}
	for _, name := range names {
		lower := strings.ToLower(name)
		var id int64
		err := q.QueryRow(ctx, `
			INSERT INTO tags (owner_id, name, name_lower, date_added)
			VALUES ($1, $2, $3, $4)
			ON CONFLICT (owner_id, name_lower) DO NOTHING
			RETURNING id`, ownerID, name, lower, when).Scan(&id)
		if errors.Is(err, pgx.ErrNoRows) {
			if err = q.QueryRow(ctx, `SELECT id FROM tags WHERE owner_id = $1 AND name_lower = $2`, ownerID, lower).Scan(&id); err != nil {
				return err
			}
		} else if err != nil {
			return err
		}
		if _, err := q.Exec(ctx, `INSERT INTO bookmark_tags (bookmark_id, tag_id) VALUES ($1, $2) ON CONFLICT DO NOTHING`, bookmarkID, id); err != nil {
			return err
		}
	}
	return nil
}

func (a *app) findExisting(ctx context.Context, q querier, ownerID int64, raw string) (*bookmarkRow, error) {
	row, err := scanBookmark(q.QueryRow(ctx, `
		SELECT `+bookmarkColumns+`
		FROM bookmarks b
		WHERE b.owner_id = $1 AND (b.url_normalized = $2 OR (b.url_normalized = '' AND b.url = $3))
		ORDER BY b.id ASC LIMIT 1`, ownerID, normalizeURL(raw), raw))
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	return &row, nil
}

func (a *app) getOwned(ctx context.Context, q querier, ownerID, id int64) (*bookmarkRow, error) {
	row, err := scanBookmark(q.QueryRow(ctx, `SELECT `+bookmarkColumns+` FROM bookmarks b WHERE b.id = $1 AND b.owner_id = $2`, id, ownerID))
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	return &row, nil
}

func sinceSQL(params *[]any, column, raw string) string {
	if raw == "" {
		return ""
	}
	parsed, ok := parseTime(raw)
	if !ok {
		return ""
	}
	return column + " > " + bind(params, parsed)
}

func flagSQL(field, raw string) string {
	switch raw {
	case "yes":
		return "b." + field
	case "no":
		return "NOT b." + field
	default:
		return ""
	}
}

func (a *app) applyBundle(ctx context.Context, q querier, where *[]string, params *[]any, viewerID int64, raw string, hasViewer bool) error {
	if raw == "" || !hasViewer {
		return nil
	}
	bundleID, err := strconv.ParseInt(raw, 10, 64)
	if err != nil {
		return nil
	}
	var bundle bundleRow
	err = q.QueryRow(ctx, `
		SELECT id, name, search, any_tags, all_tags, excluded_tags, filter_unread, filter_shared, "order", date_created, date_modified
		FROM bundles WHERE id = $1 AND owner_id = $2`, bundleID, viewerID).Scan(
		&bundle.ID, &bundle.Name, &bundle.Search, &bundle.AnyTags, &bundle.AllTags, &bundle.ExcludedTags,
		&bundle.FilterUnread, &bundle.FilterShared, &bundle.Order, &bundle.DateCreated, &bundle.DateModified)
	if errors.Is(err, pgx.ErrNoRows) {
		return nil
	}
	if err != nil {
		return err
	}
	if search := bundleSearchSQL(bundle.Search, params); search != "" {
		*where = append(*where, search)
	}
	for _, spec := range []struct{ column, mode string }{
		{bundle.AnyTags, "any"}, {bundle.AllTags, "all"}, {bundle.ExcludedTags, "excluded"},
	} {
		names := parseTagString(spec.column, " ")
		if len(names) == 0 {
			continue
		}
		switch spec.mode {
		case "any":
			parts := make([]string, len(names))
			for i, name := range names {
				parts[i] = tagSQL(name, params)
			}
			*where = append(*where, "("+joinAND(parts, " OR ")+")")
		case "all":
			for _, name := range names {
				*where = append(*where, tagSQL(name, params))
			}
		default:
			parts := make([]string, len(names))
			for i, name := range names {
				parts[i] = tagSQL(name, params)
			}
			*where = append(*where, "NOT ("+joinAND(parts, " OR ")+")")
		}
	}
	if bundle.FilterUnread == "yes" {
		*where = append(*where, "b.unread")
	} else if bundle.FilterUnread == "no" {
		*where = append(*where, "NOT b.unread")
	}
	if bundle.FilterShared == "yes" {
		*where = append(*where, "b.shared")
	} else if bundle.FilterShared == "no" {
		*where = append(*where, "NOT b.shared")
	}
	return nil
}

func joinAND(parts []string, sep string) string {
	out := ""
	for i, part := range parts {
		if i > 0 {
			out += sep
		}
		out += part
	}
	return out
}

func (a *app) listBookmarks(ctx context.Context, kind string, viewer *userRow, publicOnly bool, requestURL string, qp map[string]string) (map[string]any, error) {
	params := []any{}
	where := []string{}
	joins := ""
	legacy := false
	lax := false
	var viewerID int64
	hasViewer := viewer != nil
	if hasViewer {
		viewerID = viewer.ID
		legacy = viewer.LegacySearch
		lax = viewer.TagSearch == "lax"
	}
	if kind == "shared" {
		joins = "JOIN profiles p ON p.user_id = b.owner_id"
		where = append(where, "b.shared", "p.enable_sharing")
		if publicOnly {
			where = append(where, "p.enable_public_sharing")
		}
		if username := qp["user"]; username != "" {
			var ownerID int64
			err := a.pool.QueryRow(ctx, `SELECT id FROM users WHERE username = $1`, username).Scan(&ownerID)
			if err == nil {
				where = append(where, "b.owner_id = "+bind(&params, ownerID))
			} else if !errors.Is(err, pgx.ErrNoRows) {
				return nil, err
			}
		}
	} else {
		where = append(where, "b.owner_id = "+bind(&params, viewerID))
		if kind == "archived" {
			where = append(where, "b.is_archived")
		} else {
			where = append(where, "NOT b.is_archived")
		}
	}
	if clause := sinceSQL(&params, "b.date_modified", qp["modified_since"]); clause != "" {
		where = append(where, clause)
	}
	if clause := sinceSQL(&params, "b.date_added", qp["added_since"]); clause != "" {
		where = append(where, clause)
	}
	if clause := flagSQL("unread", qp["unread"]); clause != "" {
		where = append(where, clause)
	}
	if clause := flagSQL("shared", qp["shared"]); clause != "" {
		where = append(where, clause)
	}
	if clause := searchSQL(qp["q"], legacy, lax, &params); clause != "" {
		where = append(where, clause)
	}
	if err := a.applyBundle(ctx, a.pool, &where, &params, viewerID, qp["bundle"], hasViewer); err != nil {
		return nil, err
	}
	whereSQL := "TRUE"
	if len(where) > 0 {
		whereSQL = joinAND(where, " AND ")
	}
	var total int
	if err := a.pool.QueryRow(ctx, "SELECT count(*) FROM bookmarks b "+joins+" WHERE "+whereSQL, params...).Scan(&total); err != nil {
		return nil, err
	}
	_, limitOK := qp["limit"]
	_, offsetOK := qp["offset"]
	limit := resolveLimit(qp["limit"], limitOK)
	offset := resolveOffset(qp["offset"], offsetOK)
	rows, err := a.pool.Query(ctx, `
		SELECT `+bookmarkColumns+`
		FROM bookmarks b `+joins+`
		WHERE `+whereSQL+`
		ORDER BY `+orderSQL(qp["sort"])+`
		LIMIT $`+itoa(len(params)+1)+` OFFSET $`+itoa(len(params)+2), append(params, limit, offset)...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	items := []bookmarkRow{}
	for rows.Next() {
		var item bookmarkRow
		if err := rows.Scan(&item.ID, &item.OwnerID, &item.URL, &item.URLNormalized, &item.Title, &item.Description, &item.Notes, &item.Unread, &item.IsArchived, &item.Shared, &item.DateAdded, &item.DateModified); err != nil {
			return nil, err
		}
		items = append(items, item)
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}
	ids := make([]int64, len(items))
	for i, item := range items {
		ids[i] = item.ID
	}
	tags, err := a.tagMap(ctx, a.pool, ids)
	if err != nil {
		return nil, err
	}
	results := make([]any, len(items))
	for i, item := range items {
		results[i] = bookmarkJSON(item, tags[item.ID])
	}
	next, prev := pageLinks(requestURL, limit, offset, total)
	return map[string]any{"count": total, "next": next, "previous": prev, "results": results}, nil
}

func itoa(n int) string { return strconv.Itoa(n) }

func (a *app) serialize(ctx context.Context, q querier, row bookmarkRow) (map[string]any, error) {
	tags, err := a.tagMap(ctx, q, []int64{row.ID})
	if err != nil {
		return nil, err
	}
	return bookmarkJSON(row, tags[row.ID]), nil
}

func (a *app) createBookmark(ctx context.Context, ownerID int64, cleaned bookmarkIn) (bookmarkRow, error) {
	when := time.Now().UTC()
	tx, err := a.pool.Begin(ctx)
	if err != nil {
		return bookmarkRow{}, err
	}
	defer tx.Rollback(ctx)
	existing, err := a.findExisting(ctx, tx, ownerID, cleaned.URL)
	if err != nil {
		return bookmarkRow{}, err
	}
	title, description, notes := cleaned.Title, cleaned.Description, cleaned.Notes
	unread, shared := cleaned.Unread, cleaned.Shared
	tags := cleaned.TagNames
	if !cleaned.present["title"] {
		title = ""
	}
	if !cleaned.present["description"] {
		description = ""
	}
	if !cleaned.present["notes"] {
		notes = ""
	}
	if !cleaned.present["unread"] {
		unread = false
	}
	if !cleaned.present["shared"] {
		shared = false
	}
	if !cleaned.present["tag_names"] {
		tags = nil
	}
	if existing != nil {
		if _, err := tx.Exec(ctx, `
			UPDATE bookmarks SET title = $1, description = $2, notes = $3, unread = $4, shared = $5, date_modified = $6
			WHERE id = $7`, title, description, notes, unread, shared, when, existing.ID); err != nil {
			return bookmarkRow{}, err
		}
		if err := a.setTags(ctx, tx, existing.ID, ownerID, tags, when); err != nil {
			return bookmarkRow{}, err
		}
		row, err := a.getOwned(ctx, tx, ownerID, existing.ID)
		if err != nil || row == nil {
			return bookmarkRow{}, err
		}
		if err := tx.Commit(ctx); err != nil {
			return bookmarkRow{}, err
		}
		return *row, nil
	}
	dateAdded := when
	dateModified := when
	isArchived := false
	if cleaned.present["date_added"] {
		dateAdded = cleaned.DateAdded
	}
	if cleaned.present["date_modified"] {
		dateModified = cleaned.DateModified
	}
	if cleaned.present["is_archived"] {
		isArchived = cleaned.IsArchived
	}
	var id int64
	if err := tx.QueryRow(ctx, `
		INSERT INTO bookmarks (owner_id, url, url_normalized, title, description, notes, unread, is_archived, shared, date_added, date_modified)
		VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11) RETURNING id`,
		ownerID, cleaned.URL, normalizeURL(cleaned.URL), title, description, notes, unread, isArchived, shared, dateAdded, dateModified).Scan(&id); err != nil {
		return bookmarkRow{}, err
	}
	if err := a.setTags(ctx, tx, id, ownerID, tags, when); err != nil {
		return bookmarkRow{}, err
	}
	row, err := a.getOwned(ctx, tx, ownerID, id)
	if err != nil || row == nil {
		return bookmarkRow{}, err
	}
	if err := tx.Commit(ctx); err != nil {
		return bookmarkRow{}, err
	}
	return *row, nil
}

func (a *app) updateBookmark(ctx context.Context, ownerID, id int64, cleaned bookmarkIn) (*bookmarkRow, string, error) {
	current, err := a.getOwned(ctx, a.pool, ownerID, id)
	if err != nil || current == nil {
		return nil, "missing", err
	}
	if cleaned.present["url"] {
		var dup int64
		err := a.pool.QueryRow(ctx, `SELECT id FROM bookmarks WHERE owner_id = $1 AND url = $2 AND id <> $3`, ownerID, cleaned.URL, id).Scan(&dup)
		if err == nil {
			return nil, "duplicate", nil
		}
		if !errors.Is(err, pgx.ErrNoRows) {
			return nil, "", err
		}
	}
	when := time.Now().UTC()
	urlValue, title, description, notes := current.URL, current.Title, current.Description, current.Notes
	unread, shared, archived := current.Unread, current.Shared, current.IsArchived
	dateAdded := current.DateAdded
	if cleaned.present["url"] {
		urlValue = cleaned.URL
	}
	if cleaned.present["title"] {
		title = cleaned.Title
	}
	if cleaned.present["description"] {
		description = cleaned.Description
	}
	if cleaned.present["notes"] {
		notes = cleaned.Notes
	}
	if cleaned.present["unread"] {
		unread = cleaned.Unread
	}
	if cleaned.present["shared"] {
		shared = cleaned.Shared
	}
	if cleaned.present["is_archived"] {
		archived = cleaned.IsArchived
	}
	if cleaned.present["date_added"] {
		dateAdded = cleaned.DateAdded
	}
	tx, err := a.pool.Begin(ctx)
	if err != nil {
		return nil, "", err
	}
	defer tx.Rollback(ctx)
	if _, err := tx.Exec(ctx, `
		UPDATE bookmarks SET url=$1, url_normalized=$2, title=$3, description=$4, notes=$5,
			unread=$6, shared=$7, is_archived=$8, date_added=$9, date_modified=$10
		WHERE id=$11`, urlValue, normalizeURL(urlValue), title, description, notes, unread, shared, archived, dateAdded, when, id); err != nil {
		return nil, "", err
	}
	if cleaned.present["tag_names"] {
		if err := a.setTags(ctx, tx, id, ownerID, cleaned.TagNames, when); err != nil {
			return nil, "", err
		}
	}
	row, err := a.getOwned(ctx, tx, ownerID, id)
	if err != nil {
		return nil, "", err
	}
	if err := tx.Commit(ctx); err != nil {
		return nil, "", err
	}
	return row, "", nil
}

func (a *app) setArchived(ctx context.Context, ownerID, id int64, archived bool) (*bookmarkRow, error) {
	row, err := a.getOwned(ctx, a.pool, ownerID, id)
	if err != nil || row == nil {
		return nil, err
	}
	if _, err := a.pool.Exec(ctx, `UPDATE bookmarks SET is_archived=$1, date_modified=$2 WHERE id=$3`, archived, time.Now().UTC(), id); err != nil {
		return nil, err
	}
	return a.getOwned(ctx, a.pool, ownerID, id)
}

func (a *app) deleteBookmark(ctx context.Context, ownerID, id int64) (bool, error) {
	tag, err := a.pool.Exec(ctx, `DELETE FROM bookmarks WHERE id=$1 AND owner_id=$2`, id, ownerID)
	if err != nil {
		return false, err
	}
	return tag.RowsAffected() == 1, nil
}

func (a *app) listTags(ctx context.Context, ownerID int64, requestURL string, qp map[string]string) (map[string]any, error) {
	var total int
	if err := a.pool.QueryRow(ctx, `SELECT count(*) FROM tags WHERE owner_id=$1`, ownerID).Scan(&total); err != nil {
		return nil, err
	}
	_, limitOK := qp["limit"]
	_, offsetOK := qp["offset"]
	limit := resolveLimit(qp["limit"], limitOK)
	offset := resolveOffset(qp["offset"], offsetOK)
	rows, err := a.pool.Query(ctx, `SELECT id, name, date_added FROM tags WHERE owner_id=$1 ORDER BY id ASC LIMIT $2 OFFSET $3`, ownerID, limit, offset)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	results := []any{}
	for rows.Next() {
		var row tagRow
		if err := rows.Scan(&row.ID, &row.Name, &row.DateAdded); err != nil {
			return nil, err
		}
		results = append(results, tagJSON(row))
	}
	next, prev := pageLinks(requestURL, limit, offset, total)
	return map[string]any{"count": total, "next": next, "previous": prev, "results": results}, rows.Err()
}

func (a *app) getTag(ctx context.Context, ownerID, id int64) (*tagRow, error) {
	var row tagRow
	err := a.pool.QueryRow(ctx, `SELECT id, name, date_added FROM tags WHERE id=$1 AND owner_id=$2`, id, ownerID).Scan(&row.ID, &row.Name, &row.DateAdded)
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	return &row, nil
}

func (a *app) createTag(ctx context.Context, ownerID int64, name string) (tagRow, error) {
	lower := strings.ToLower(name)
	var row tagRow
	err := a.pool.QueryRow(ctx, `SELECT id, name, date_added FROM tags WHERE owner_id=$1 AND name_lower=$2`, ownerID, lower).Scan(&row.ID, &row.Name, &row.DateAdded)
	if err == nil {
		return row, nil
	}
	if !errors.Is(err, pgx.ErrNoRows) {
		return tagRow{}, err
	}
	err = a.pool.QueryRow(ctx, `INSERT INTO tags (owner_id, name, name_lower, date_added) VALUES ($1,$2,$3,$4) RETURNING id, name, date_added`, ownerID, name, lower, time.Now().UTC()).Scan(&row.ID, &row.Name, &row.DateAdded)
	return row, err
}

func (a *app) deleteTag(ctx context.Context, ownerID, id int64) (bool, error) {
	tag, err := a.pool.Exec(ctx, `DELETE FROM tags WHERE id=$1 AND owner_id=$2`, id, ownerID)
	if err != nil {
		return false, err
	}
	return tag.RowsAffected() == 1, nil
}

func scanBundle(row pgx.Row) (bundleRow, error) {
	var item bundleRow
	err := row.Scan(&item.ID, &item.Name, &item.Search, &item.AnyTags, &item.AllTags, &item.ExcludedTags, &item.FilterUnread, &item.FilterShared, &item.Order, &item.DateCreated, &item.DateModified)
	return item, err
}

func (a *app) listBundles(ctx context.Context, ownerID int64, requestURL string, qp map[string]string) (map[string]any, error) {
	var total int
	if err := a.pool.QueryRow(ctx, `SELECT count(*) FROM bundles WHERE owner_id=$1`, ownerID).Scan(&total); err != nil {
		return nil, err
	}
	_, limitOK := qp["limit"]
	_, offsetOK := qp["offset"]
	limit := resolveLimit(qp["limit"], limitOK)
	offset := resolveOffset(qp["offset"], offsetOK)
	rows, err := a.pool.Query(ctx, `
		SELECT id, name, search, any_tags, all_tags, excluded_tags, filter_unread, filter_shared, "order", date_created, date_modified
		FROM bundles WHERE owner_id=$1 ORDER BY "order" ASC, id ASC LIMIT $2 OFFSET $3`, ownerID, limit, offset)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	results := []any{}
	for rows.Next() {
		var item bundleRow
		if err := rows.Scan(&item.ID, &item.Name, &item.Search, &item.AnyTags, &item.AllTags, &item.ExcludedTags, &item.FilterUnread, &item.FilterShared, &item.Order, &item.DateCreated, &item.DateModified); err != nil {
			return nil, err
		}
		results = append(results, bundleJSON(item))
	}
	next, prev := pageLinks(requestURL, limit, offset, total)
	return map[string]any{"count": total, "next": next, "previous": prev, "results": results}, rows.Err()
}

func (a *app) getBundle(ctx context.Context, q querier, ownerID, id int64) (*bundleRow, error) {
	item, err := scanBundle(q.QueryRow(ctx, `
		SELECT id, name, search, any_tags, all_tags, excluded_tags, filter_unread, filter_shared, "order", date_created, date_modified
		FROM bundles WHERE id=$1 AND owner_id=$2`, id, ownerID))
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	return &item, nil
}

func (a *app) createBundle(ctx context.Context, ownerID int64, cleaned bundleIn) (bundleRow, error) {
	when := time.Now().UTC()
	order := 0
	if cleaned.present["order"] {
		order = cleaned.Order
	} else {
		var current int
		if err := a.pool.QueryRow(ctx, `SELECT COALESCE(MAX("order"), -1) FROM bundles WHERE owner_id=$1`, ownerID).Scan(&current); err != nil {
			return bundleRow{}, err
		}
		order = current + 1
	}
	name := cleaned.Name
	search, anyTags, allTags, excluded := "", "", "", ""
	unread, shared := "off", "off"
	if cleaned.present["search"] {
		search = cleaned.Search
	}
	if cleaned.present["any_tags"] {
		anyTags = cleaned.AnyTags
	}
	if cleaned.present["all_tags"] {
		allTags = cleaned.AllTags
	}
	if cleaned.present["excluded_tags"] {
		excluded = cleaned.ExcludedTags
	}
	if cleaned.present["filter_unread"] {
		unread = cleaned.FilterUnread
	}
	if cleaned.present["filter_shared"] {
		shared = cleaned.FilterShared
	}
	return scanBundle(a.pool.QueryRow(ctx, `
		INSERT INTO bundles (owner_id, name, search, any_tags, all_tags, excluded_tags, filter_unread, filter_shared, "order", date_created, date_modified)
		VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11)
		RETURNING id, name, search, any_tags, all_tags, excluded_tags, filter_unread, filter_shared, "order", date_created, date_modified`,
		ownerID, name, search, anyTags, allTags, excluded, unread, shared, order, when, when))
}

func (a *app) updateBundle(ctx context.Context, ownerID, id int64, cleaned bundleIn) (*bundleRow, error) {
	current, err := a.getBundle(ctx, a.pool, ownerID, id)
	if err != nil || current == nil {
		return nil, err
	}
	name, search := current.Name, current.Search
	anyTags, allTags, excluded := current.AnyTags, current.AllTags, current.ExcludedTags
	unread, shared, order := current.FilterUnread, current.FilterShared, current.Order
	if cleaned.present["name"] {
		name = cleaned.Name
	}
	if cleaned.present["search"] {
		search = cleaned.Search
	}
	if cleaned.present["any_tags"] {
		anyTags = cleaned.AnyTags
	}
	if cleaned.present["all_tags"] {
		allTags = cleaned.AllTags
	}
	if cleaned.present["excluded_tags"] {
		excluded = cleaned.ExcludedTags
	}
	if cleaned.present["filter_unread"] {
		unread = cleaned.FilterUnread
	}
	if cleaned.present["filter_shared"] {
		shared = cleaned.FilterShared
	}
	if cleaned.present["order"] {
		order = cleaned.Order
	}
	item, err := scanBundle(a.pool.QueryRow(ctx, `
		UPDATE bundles SET name=$1, search=$2, any_tags=$3, all_tags=$4, excluded_tags=$5,
			filter_unread=$6, filter_shared=$7, "order"=$8, date_modified=$9
		WHERE id=$10
		RETURNING id, name, search, any_tags, all_tags, excluded_tags, filter_unread, filter_shared, "order", date_created, date_modified`,
		name, search, anyTags, allTags, excluded, unread, shared, order, time.Now().UTC(), id))
	if err != nil {
		return nil, err
	}
	return &item, nil
}

func (a *app) deleteBundle(ctx context.Context, ownerID, id int64) (bool, error) {
	tx, err := a.pool.Begin(ctx)
	if err != nil {
		return false, err
	}
	defer tx.Rollback(ctx)
	tag, err := tx.Exec(ctx, `DELETE FROM bundles WHERE id=$1 AND owner_id=$2`, id, ownerID)
	if err != nil {
		return false, err
	}
	if tag.RowsAffected() != 1 {
		return false, tx.Commit(ctx)
	}
	rows, err := tx.Query(ctx, `SELECT id FROM bundles WHERE owner_id=$1 ORDER BY "order" ASC, id ASC`, ownerID)
	if err != nil {
		return false, err
	}
	ids := []int64{}
	for rows.Next() {
		var rowID int64
		if err := rows.Scan(&rowID); err != nil {
			rows.Close()
			return false, err
		}
		ids = append(ids, rowID)
	}
	rows.Close()
	if err := rows.Err(); err != nil {
		return false, err
	}
	for index, rowID := range ids {
		if _, err := tx.Exec(ctx, `UPDATE bundles SET "order"=$1 WHERE id=$2`, index, rowID); err != nil {
			return false, err
		}
	}
	return true, tx.Commit(ctx)
}

func profileJSON(user userRow) map[string]any {
	prefs := user.SearchPreferences
	if len(prefs) == 0 {
		prefs = []byte("{}")
	}
	return map[string]any{
		"theme": user.Theme, "bookmark_date_display": user.BookmarkDateDisplay,
		"bookmark_link_target": user.BookmarkLinkTarget, "web_archive_integration": user.WebArchiveIntegration,
		"tag_search": user.TagSearch, "enable_sharing": user.EnableSharing,
		"enable_public_sharing": user.EnablePublicSharing, "enable_favicons": user.EnableFavicons,
		"display_url": user.DisplayURL, "permanent_notes": user.PermanentNotes,
		"search_preferences": json.RawMessage(prefs), "version": appVersion,
	}
}
