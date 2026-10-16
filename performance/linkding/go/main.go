package main

import (
	"bytes"
	"context"
	"encoding/json"
	"io"
	"log"
	"net/http"
	"os"
	"runtime"
	"strconv"
	"strings"
	"time"
	"unicode"

	"github.com/go-chi/chi/v5"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

type app struct {
	pool *pgxpool.Pool
}

func main() {
	if raw := os.Getenv("WEB_CONCURRENCY"); raw != "" {
		if n, err := strconv.Atoi(raw); err == nil && n > 0 {
			runtime.GOMAXPROCS(n)
		}
	}
	dbURL := env("DATABASE_URL", "postgres://linkding:linkding@127.0.0.1:5440/linkding")
	port := env("PORT", "8102")
	dbPool := 8
	if raw := os.Getenv("DB_POOL"); raw != "" {
		if n, err := strconv.Atoi(raw); err == nil && n > 0 {
			dbPool = n
		}
	}
	cfg, err := pgxpool.ParseConfig(dbURL)
	if err != nil {
		log.Fatalf("database url: %v", err)
	}
	cfg.MaxConns = int32(dbPool)
	cfg.MinConns = 1
	cfg.AfterConnect = func(ctx context.Context, conn *pgx.Conn) error {
		_, err := conn.Exec(ctx, "SET TIME ZONE 'UTC'")
		return err
	}
	pool, err := pgxpool.NewWithConfig(context.Background(), cfg)
	if err != nil {
		log.Fatalf("pool: %v", err)
	}
	defer pool.Close()
	if err := pool.Ping(context.Background()); err != nil {
		log.Fatalf("ping: %v", err)
	}
	server := &http.Server{
		Addr:              "127.0.0.1:" + port,
		Handler:           (&app{pool: pool}).routes(),
		ReadHeaderTimeout: 10 * time.Second,
	}
	log.Printf("listening on %s pool=%d gomaxprocs=%d", server.Addr, dbPool, runtime.GOMAXPROCS(0))
	log.Fatal(server.ListenAndServe())
}

func env(key, fallback string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return fallback
}

func (a *app) routes() http.Handler {
	r := chi.NewRouter()
	r.Get("/healthz", a.health)
	r.Get("/api/user/profile/", a.profile)
	r.MethodFunc(http.MethodPut, "/api/user/profile/", a.profileMethod)
	r.MethodFunc(http.MethodPatch, "/api/user/profile/", a.profileMethod)
	r.MethodFunc(http.MethodPost, "/api/user/profile/", a.profileMethod)
	r.MethodFunc(http.MethodDelete, "/api/user/profile/", a.profileMethod)
	r.Get("/api/bookmarks/", a.bookmarkList)
	r.Post("/api/bookmarks/", a.bookmarkCreate)
	r.Get("/api/bookmarks/archived/", a.bookmarkArchived)
	r.Get("/api/bookmarks/shared/", a.bookmarkShared)
	r.Get("/api/bookmarks/check/", a.bookmarkCheck)
	r.Get("/api/bookmarks/{id}/", a.bookmarkGet)
	r.Put("/api/bookmarks/{id}/", a.bookmarkWrite)
	r.Patch("/api/bookmarks/{id}/", a.bookmarkWrite)
	r.Delete("/api/bookmarks/{id}/", a.bookmarkDelete)
	r.Post("/api/bookmarks/{id}/archive/", a.bookmarkArchive)
	r.Post("/api/bookmarks/{id}/unarchive/", a.bookmarkUnarchive)
	r.Get("/api/tags/", a.tagList)
	r.Post("/api/tags/", a.tagCreate)
	r.Get("/api/tags/{id}/", a.tagGet)
	r.Delete("/api/tags/{id}/", a.tagDelete)
	r.Get("/api/bundles/", a.bundleList)
	r.Post("/api/bundles/", a.bundleCreate)
	r.Get("/api/bundles/{id}/", a.bundleGet)
	r.Put("/api/bundles/{id}/", a.bundleWrite)
	r.Patch("/api/bundles/{id}/", a.bundleWrite)
	r.Delete("/api/bundles/{id}/", a.bundleDelete)
	return r
}

func (a *app) health(w http.ResponseWriter, r *http.Request) {
	if err := a.pool.Ping(r.Context()); err != nil {
		a.fail(w, err)
		return
	}
	w.Header().Set("Content-Type", "text/plain")
	w.WriteHeader(http.StatusOK)
	_, _ = w.Write([]byte("ok"))
}

func (a *app) writeJSON(w http.ResponseWriter, status int, payload any, headers map[string]string) {
	body, err := marshalJSON(payload)
	if err != nil {
		http.Error(w, "server error", 500)
		return
	}
	for key, value := range headers {
		w.Header().Set(key, value)
	}
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_, _ = w.Write(body)
}

func marshalJSON(payload any) ([]byte, error) {
	var buf bytes.Buffer
	enc := json.NewEncoder(&buf)
	enc.SetEscapeHTML(false)
	if err := enc.Encode(payload); err != nil {
		return nil, err
	}
	return buf.Bytes(), nil
}

func (a *app) fail(w http.ResponseWriter, err error) {
	log.Printf("request error: %v", err)
	a.writeJSON(w, 500, map[string]any{"detail": "Server error."}, nil)
}

func (a *app) authFail(w http.ResponseWriter, kind string) {
	a.writeJSON(w, 401, map[string]string{"detail": authDetail(kind)}, map[string]string{"WWW-Authenticate": "Token"})
}

func (a *app) notFound(w http.ResponseWriter, kind string) {
	message := map[string]string{
		"bookmark": "No Bookmark matches the given query.",
		"tag":      "No Tag matches the given query.",
		"bundle":   "No BookmarkBundle matches the given query.",
	}[kind]
	a.writeJSON(w, 404, map[string]string{"detail": message}, nil)
}

func (a *app) authenticate(w http.ResponseWriter, r *http.Request, required bool) (*userRow, bool) {
	kind, token := classifyAuth(r.Header.Get("Authorization"))
	if kind == "absent" {
		if required {
			a.authFail(w, kind)
			return nil, false
		}
		return nil, true
	}
	if kind != "token" {
		a.authFail(w, kind)
		return nil, false
	}
	user, err := a.loadUser(r.Context(), token)
	if err != nil {
		a.fail(w, err)
		return nil, false
	}
	if user == nil {
		a.authFail(w, "bad")
		return nil, false
	}
	return user, true
}

func queryMap(r *http.Request) map[string]string {
	out := map[string]string{}
	for key, values := range r.URL.Query() {
		if len(values) > 0 {
			out[key] = values[len(values)-1]
		}
	}
	return out
}

func requestURL(r *http.Request) string {
	return "http://" + r.Host + r.URL.RequestURI()
}

func pathID(raw string) (int64, bool) {
	if raw == "" {
		return 0, false
	}
	for _, r := range raw {
		if !unicode.IsDigit(r) {
			return 0, false
		}
	}
	n, err := strconv.ParseInt(raw, 10, 64)
	return n, err == nil
}

func (a *app) readBody(w http.ResponseWriter, r *http.Request) (map[string]any, bool) {
	media := strings.ToLower(strings.TrimSpace(strings.Split(r.Header.Get("Content-Type"), ";")[0]))
	if media == "" {
		return map[string]any{}, true
	}
	if media != "application/json" {
		a.writeJSON(w, 415, map[string]string{"detail": "Unsupported media type \"" + media + "\" in request."}, nil)
		return nil, false
	}
	raw, err := io.ReadAll(r.Body)
	if err != nil {
		a.fail(w, err)
		return nil, false
	}
	if len(raw) == 0 {
		return map[string]any{}, true
	}
	dec := json.NewDecoder(bytes.NewReader(raw))
	dec.UseNumber()
	var value any
	if err := dec.Decode(&value); err != nil {
		a.writeJSON(w, 400, map[string]string{"detail": jsonDetail(raw, err)}, nil)
		return nil, false
	}
	if value == nil {
		a.writeJSON(w, 400, map[string]any{"non_field_errors": []string{"No data provided"}}, nil)
		return nil, false
	}
	data, ok := value.(map[string]any)
	if !ok {
		a.writeJSON(w, 400, map[string]any{"non_field_errors": []string{"Invalid data. Expected a dictionary, but got " + pyTypeName(value) + "."}}, nil)
		return nil, false
	}
	return data, true
}

func jsonDetail(raw []byte, err error) string {
	trimmed := bytes.TrimSpace(raw)
	// CPython reports "Expecting value" for text that is not an object, array, or string.
	// "not-json" is the conformance case. Object and array errors keep the decoder text.
	if len(trimmed) == 0 || (trimmed[0] != '{' && trimmed[0] != '[' && trimmed[0] != '"') {
		pos := 0
		for pos < len(raw) && (raw[pos] == ' ' || raw[pos] == '\t' || raw[pos] == '\n' || raw[pos] == '\r') {
			pos++
		}
		line, col := 1, 1
		for i := 0; i < pos && i < len(raw); i++ {
			if raw[i] == '\n' {
				line++
				col = 1
			} else {
				col++
			}
		}
		return "JSON parse error - Expecting value: line " + strconv.Itoa(line) + " column " + strconv.Itoa(col) + " (char " + strconv.Itoa(pos) + ")"
	}
	return "JSON parse error - " + err.Error()
}

func (a *app) profile(w http.ResponseWriter, r *http.Request) {
	user, ok := a.authenticate(w, r, true)
	if !ok {
		return
	}
	a.writeJSON(w, 200, profileJSON(*user), nil)
}

func (a *app) profileMethod(w http.ResponseWriter, r *http.Request) {
	a.writeJSON(w, 405, map[string]string{"detail": "Method \"" + r.Method + "\" not allowed."}, map[string]string{"Allow": "GET, HEAD, OPTIONS"})
}

func (a *app) bookmarkList(w http.ResponseWriter, r *http.Request) {
	a.listKind(w, r, "active", true)
}

func (a *app) bookmarkArchived(w http.ResponseWriter, r *http.Request) {
	a.listKind(w, r, "archived", true)
}

func (a *app) bookmarkShared(w http.ResponseWriter, r *http.Request) {
	a.listKind(w, r, "shared", false)
}

func (a *app) listKind(w http.ResponseWriter, r *http.Request, kind string, required bool) {
	user, ok := a.authenticate(w, r, required)
	if !ok {
		return
	}
	payload, err := a.listBookmarks(r.Context(), kind, user, user == nil, requestURL(r), queryMap(r))
	if err != nil {
		a.fail(w, err)
		return
	}
	a.writeJSON(w, 200, payload, nil)
}

func (a *app) bookmarkCreate(w http.ResponseWriter, r *http.Request) {
	user, ok := a.authenticate(w, r, true)
	if !ok {
		return
	}
	data, ok := a.readBody(w, r)
	if !ok {
		return
	}
	errs, cleaned := validateBookmark(data, false)
	if len(errs) > 0 {
		a.writeJSON(w, 400, errs, nil)
		return
	}
	row, err := a.createBookmark(r.Context(), user.ID, cleaned)
	if err != nil {
		a.fail(w, err)
		return
	}
	payload, err := a.serialize(r.Context(), a.pool, row)
	if err != nil {
		a.fail(w, err)
		return
	}
	a.writeJSON(w, 201, payload, map[string]string{"Location": row.URL})
}

func (a *app) bookmarkCheck(w http.ResponseWriter, r *http.Request) {
	user, ok := a.authenticate(w, r, true)
	if !ok {
		return
	}
	qp := queryMap(r)
	var bookmark any
	var metaURL any
	if raw, present := qp["url"]; present {
		metaURL = raw
		row, err := a.findExisting(r.Context(), a.pool, user.ID, raw)
		if err != nil {
			a.fail(w, err)
			return
		}
		if row != nil {
			payload, err := a.serialize(r.Context(), a.pool, *row)
			if err != nil {
				a.fail(w, err)
				return
			}
			bookmark = payload
		}
	}
	a.writeJSON(w, 200, map[string]any{
		"bookmark":  bookmark,
		"metadata":  map[string]any{"url": metaURL, "title": nil, "description": nil, "preview_image": nil},
		"auto_tags": []any{},
	}, nil)
}

func (a *app) bookmarkGet(w http.ResponseWriter, r *http.Request) {
	user, ok := a.authenticate(w, r, true)
	if !ok {
		return
	}
	id, good := pathID(chi.URLParam(r, "id"))
	if !good {
		a.notFound(w, "bookmark")
		return
	}
	row, err := a.getOwned(r.Context(), a.pool, user.ID, id)
	if err != nil {
		a.fail(w, err)
		return
	}
	if row == nil {
		a.notFound(w, "bookmark")
		return
	}
	payload, err := a.serialize(r.Context(), a.pool, *row)
	if err != nil {
		a.fail(w, err)
		return
	}
	a.writeJSON(w, 200, payload, nil)
}

func (a *app) bookmarkWrite(w http.ResponseWriter, r *http.Request) {
	user, ok := a.authenticate(w, r, true)
	if !ok {
		return
	}
	id, good := pathID(chi.URLParam(r, "id"))
	if !good {
		a.notFound(w, "bookmark")
		return
	}
	existing, err := a.getOwned(r.Context(), a.pool, user.ID, id)
	if err != nil {
		a.fail(w, err)
		return
	}
	if existing == nil {
		a.notFound(w, "bookmark")
		return
	}
	data, ok := a.readBody(w, r)
	if !ok {
		return
	}
	errs, cleaned := validateBookmark(data, r.Method == http.MethodPatch)
	if len(errs) > 0 {
		a.writeJSON(w, 400, errs, nil)
		return
	}
	row, problem, err := a.updateBookmark(r.Context(), user.ID, id, cleaned)
	if err != nil {
		a.fail(w, err)
		return
	}
	if problem == "duplicate" {
		a.writeJSON(w, 400, map[string]any{"url": []string{"A bookmark with this URL already exists."}}, nil)
		return
	}
	if row == nil {
		a.notFound(w, "bookmark")
		return
	}
	payload, err := a.serialize(r.Context(), a.pool, *row)
	if err != nil {
		a.fail(w, err)
		return
	}
	a.writeJSON(w, 200, payload, nil)
}

func (a *app) bookmarkDelete(w http.ResponseWriter, r *http.Request) {
	user, ok := a.authenticate(w, r, true)
	if !ok {
		return
	}
	id, good := pathID(chi.URLParam(r, "id"))
	if !good {
		a.notFound(w, "bookmark")
		return
	}
	deleted, err := a.deleteBookmark(r.Context(), user.ID, id)
	if err != nil {
		a.fail(w, err)
		return
	}
	if !deleted {
		a.notFound(w, "bookmark")
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (a *app) bookmarkArchive(w http.ResponseWriter, r *http.Request) {
	a.archive(w, r, true)
}

func (a *app) bookmarkUnarchive(w http.ResponseWriter, r *http.Request) {
	a.archive(w, r, false)
}

func (a *app) archive(w http.ResponseWriter, r *http.Request, archived bool) {
	user, ok := a.authenticate(w, r, true)
	if !ok {
		return
	}
	id, good := pathID(chi.URLParam(r, "id"))
	if !good {
		a.notFound(w, "bookmark")
		return
	}
	row, err := a.setArchived(r.Context(), user.ID, id, archived)
	if err != nil {
		a.fail(w, err)
		return
	}
	if row == nil {
		a.notFound(w, "bookmark")
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (a *app) tagList(w http.ResponseWriter, r *http.Request) {
	user, ok := a.authenticate(w, r, true)
	if !ok {
		return
	}
	payload, err := a.listTags(r.Context(), user.ID, requestURL(r), queryMap(r))
	if err != nil {
		a.fail(w, err)
		return
	}
	a.writeJSON(w, 200, payload, nil)
}

func (a *app) tagCreate(w http.ResponseWriter, r *http.Request) {
	user, ok := a.authenticate(w, r, true)
	if !ok {
		return
	}
	data, ok := a.readBody(w, r)
	if !ok {
		return
	}
	errs, name := validateTag(data)
	if len(errs) > 0 {
		a.writeJSON(w, 400, errs, nil)
		return
	}
	row, err := a.createTag(r.Context(), user.ID, name)
	if err != nil {
		a.fail(w, err)
		return
	}
	a.writeJSON(w, 201, tagJSON(row), nil)
}

func (a *app) tagGet(w http.ResponseWriter, r *http.Request) {
	user, ok := a.authenticate(w, r, true)
	if !ok {
		return
	}
	id, good := pathID(chi.URLParam(r, "id"))
	if !good {
		a.notFound(w, "tag")
		return
	}
	row, err := a.getTag(r.Context(), user.ID, id)
	if err != nil {
		a.fail(w, err)
		return
	}
	if row == nil {
		a.notFound(w, "tag")
		return
	}
	a.writeJSON(w, 200, tagJSON(*row), nil)
}

func (a *app) tagDelete(w http.ResponseWriter, r *http.Request) {
	user, ok := a.authenticate(w, r, true)
	if !ok {
		return
	}
	id, good := pathID(chi.URLParam(r, "id"))
	if !good {
		a.notFound(w, "tag")
		return
	}
	deleted, err := a.deleteTag(r.Context(), user.ID, id)
	if err != nil {
		a.fail(w, err)
		return
	}
	if !deleted {
		a.notFound(w, "tag")
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (a *app) bundleList(w http.ResponseWriter, r *http.Request) {
	user, ok := a.authenticate(w, r, true)
	if !ok {
		return
	}
	payload, err := a.listBundles(r.Context(), user.ID, requestURL(r), queryMap(r))
	if err != nil {
		a.fail(w, err)
		return
	}
	a.writeJSON(w, 200, payload, nil)
}

func (a *app) bundleCreate(w http.ResponseWriter, r *http.Request) {
	user, ok := a.authenticate(w, r, true)
	if !ok {
		return
	}
	data, ok := a.readBody(w, r)
	if !ok {
		return
	}
	errs, cleaned := validateBundle(data, false)
	if len(errs) > 0 {
		a.writeJSON(w, 400, errs, nil)
		return
	}
	row, err := a.createBundle(r.Context(), user.ID, cleaned)
	if err != nil {
		a.fail(w, err)
		return
	}
	a.writeJSON(w, 201, bundleJSON(row), nil)
}

func (a *app) bundleGet(w http.ResponseWriter, r *http.Request) {
	user, ok := a.authenticate(w, r, true)
	if !ok {
		return
	}
	id, good := pathID(chi.URLParam(r, "id"))
	if !good {
		a.notFound(w, "bundle")
		return
	}
	row, err := a.getBundle(r.Context(), a.pool, user.ID, id)
	if err != nil {
		a.fail(w, err)
		return
	}
	if row == nil {
		a.notFound(w, "bundle")
		return
	}
	a.writeJSON(w, 200, bundleJSON(*row), nil)
}

func (a *app) bundleWrite(w http.ResponseWriter, r *http.Request) {
	user, ok := a.authenticate(w, r, true)
	if !ok {
		return
	}
	id, good := pathID(chi.URLParam(r, "id"))
	if !good {
		a.notFound(w, "bundle")
		return
	}
	existing, err := a.getBundle(r.Context(), a.pool, user.ID, id)
	if err != nil {
		a.fail(w, err)
		return
	}
	if existing == nil {
		a.notFound(w, "bundle")
		return
	}
	data, ok := a.readBody(w, r)
	if !ok {
		return
	}
	errs, cleaned := validateBundle(data, r.Method == http.MethodPatch)
	if len(errs) > 0 {
		a.writeJSON(w, 400, errs, nil)
		return
	}
	row, err := a.updateBundle(r.Context(), user.ID, id, cleaned)
	if err != nil {
		a.fail(w, err)
		return
	}
	if row == nil {
		a.notFound(w, "bundle")
		return
	}
	a.writeJSON(w, 200, bundleJSON(*row), nil)
}

func (a *app) bundleDelete(w http.ResponseWriter, r *http.Request) {
	user, ok := a.authenticate(w, r, true)
	if !ok {
		return
	}
	id, good := pathID(chi.URLParam(r, "id"))
	if !good {
		a.notFound(w, "bundle")
		return
	}
	deleted, err := a.deleteBundle(r.Context(), user.ID, id)
	if err != nil {
		a.fail(w, err)
		return
	}
	if !deleted {
		a.notFound(w, "bundle")
		return
	}
	w.WriteHeader(http.StatusNoContent)
}
