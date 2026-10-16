package main

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"runtime"
	"strconv"
	"strings"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/go-chi/chi/v5/middleware"
	"github.com/golang-jwt/jwt/v5"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgxpool"
	"golang.org/x/crypto/bcrypt"
)

const jwtTTL = 60 * 24 * time.Hour

type querier interface {
	Query(ctx context.Context, sql string, args ...any) (pgx.Rows, error)
	QueryRow(ctx context.Context, sql string, args ...any) pgx.Row
	Exec(ctx context.Context, sql string, arguments ...any) (pgconn.CommandTag, error)
}

type app struct {
	pool   *pgxpool.Pool
	secret []byte
	dummy  []byte
}

type userRow struct {
	ID           int64
	Username     string
	Email        string
	Bio          *string
	Image        *string
	PasswordHash string
}

type articleRow struct {
	ID             int64
	Slug           string
	Title          string
	Description    string
	Body           string
	CreatedAt      string
	UpdatedAt      string
	AuthorUsername string
	AuthorBio      *string
	AuthorImage    *string
	FavoritesCount int
	Favorited      bool
	Following      bool
	TagList        []string
}

func main() {
	if s := os.Getenv("WEB_CONCURRENCY"); s != "" {
		if n, err := strconv.Atoi(s); err == nil && n > 0 {
			runtime.GOMAXPROCS(n)
		}
	}
	dbURL := env("DATABASE_URL", "postgres://conduit:conduit@127.0.0.1:54329/conduit")
	secret := env("JWT_SECRET", "conduit-benchmark-secret")
	port := env("PORT", "8002")
	dbPool := 8
	if s := os.Getenv("DB_POOL"); s != "" {
		if n, err := strconv.Atoi(s); err == nil && n > 0 {
			dbPool = n
		}
	}

	cfg, err := pgxpool.ParseConfig(dbURL)
	if err != nil {
		log.Fatalf("database url: %v", err)
	}
	cfg.MaxConns = int32(dbPool)
	cfg.MinConns = 1
	if cfg.MinConns > cfg.MaxConns {
		cfg.MinConns = cfg.MaxConns
	}

	ctx := context.Background()
	pool, err := pgxpool.NewWithConfig(ctx, cfg)
	if err != nil {
		log.Fatalf("pool: %v", err)
	}
	defer pool.Close()
	if err := pool.Ping(ctx); err != nil {
		log.Fatalf("ping: %v", err)
	}

	dummy, err := bcrypt.GenerateFromPassword([]byte("dummy-password-for-timing"), bcryptCost)
	if err != nil {
		log.Fatalf("dummy hash: %v", err)
	}

	a := &app{pool: pool, secret: []byte(secret), dummy: dummy}
	srv := &http.Server{
		Addr:              "127.0.0.1:" + port,
		Handler:           a.routes(),
		ReadHeaderTimeout: 10 * time.Second,
		IdleTimeout:       120 * time.Second,
	}
	log.Printf("listening on %s pool=%d gomaxprocs=%d", srv.Addr, dbPool, runtime.GOMAXPROCS(0))
	log.Fatal(srv.ListenAndServe())
}

func env(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}

func (a *app) routes() http.Handler {
	r := chi.NewRouter()
	r.Use(middleware.Recoverer)
	r.Get("/healthz", a.wrap(a.healthz))
	r.Post("/api/users", a.wrap(a.register))
	r.Post("/api/users/login", a.wrap(a.login))
	r.Get("/api/user", a.wrap(a.currentUser))
	r.Put("/api/user", a.wrap(a.updateUser))
	r.Get("/api/profiles/{username}", a.wrap(a.getProfile))
	r.Post("/api/profiles/{username}/follow", a.wrap(a.follow))
	r.Delete("/api/profiles/{username}/follow", a.wrap(a.unfollow))
	r.Get("/api/articles/feed", a.wrap(a.feed))
	r.Get("/api/articles", a.wrap(a.listArticles))
	r.Post("/api/articles", a.wrap(a.createArticle))
	r.Get("/api/articles/{slug}", a.wrap(a.getArticle))
	r.Put("/api/articles/{slug}", a.wrap(a.updateArticle))
	r.Delete("/api/articles/{slug}", a.wrap(a.deleteArticle))
	r.Get("/api/articles/{slug}/comments", a.wrap(a.listComments))
	r.Post("/api/articles/{slug}/comments", a.wrap(a.createComment))
	r.Delete("/api/articles/{slug}/comments/{commentID}", a.wrap(a.deleteComment))
	r.Post("/api/articles/{slug}/favorite", a.wrap(a.favorite))
	r.Delete("/api/articles/{slug}/favorite", a.wrap(a.unfavorite))
	r.Get("/api/tags", a.wrap(a.tags))
	return r
}

func (a *app) wrap(h func(http.ResponseWriter, *http.Request) error) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		err := h(w, r)
		if err == nil {
			return
		}
		var ae *apiError
		if errors.As(err, &ae) {
			writeAPI(w, ae)
			return
		}
		log.Printf("%s %s: %v", r.Method, r.URL.RequestURI(), err)
		writeAPI(w, errAPI(500, "server", "error"))
	}
}

func writeAPI(w http.ResponseWriter, e *apiError) {
	_ = writeJSON(w, e.Status, map[string]any{
		"errors": map[string][]string{e.Field: {e.Message}},
	})
}

func writeJSON(w http.ResponseWriter, status int, v any) error {
	var buf bytes.Buffer
	enc := json.NewEncoder(&buf)
	enc.SetEscapeHTML(false)
	if err := enc.Encode(v); err != nil {
		return err
	}
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	w.WriteHeader(status)
	_, _ = w.Write(buf.Bytes())
	return nil
}

func readObject(r *http.Request, key string) (map[string]any, error) {
	raw, err := io.ReadAll(io.LimitReader(r.Body, 1<<20))
	if err != nil || len(bytes.TrimSpace(raw)) == 0 {
		return nil, errAPI(422, "body", "is invalid")
	}
	var data any
	if err := json.Unmarshal(raw, &data); err != nil {
		return nil, errAPI(422, "body", "is invalid")
	}
	m, ok := data.(map[string]any)
	if !ok {
		return nil, errAPI(422, key, "is invalid")
	}
	obj, ok := m[key].(map[string]any)
	if !ok {
		return nil, errAPI(422, key, "is invalid")
	}
	return obj, nil
}

func (a *app) userID(r *http.Request, required bool) (int64, error) {
	header := r.Header.Get("Authorization")
	if strings.TrimSpace(header) == "" {
		if required {
			return 0, errAPI(401, "token", "is missing")
		}
		return 0, nil
	}
	if !strings.HasPrefix(header, "Token ") {
		return 0, errAPI(401, "token", "is invalid")
	}
	raw := strings.TrimSpace(header[len("Token "):])
	if raw == "" {
		return 0, errAPI(401, "token", "is invalid")
	}
	var claims jwt.RegisteredClaims
	tok, err := jwt.ParseWithClaims(raw, &claims, func(t *jwt.Token) (any, error) {
		if t.Method != jwt.SigningMethodHS256 {
			return nil, fmt.Errorf("algorithm")
		}
		return a.secret, nil
	}, jwt.WithValidMethods([]string{"HS256"}))
	if err != nil || !tok.Valid {
		return 0, errAPI(401, "token", "is invalid")
	}
	uid, err := strconv.ParseInt(claims.Subject, 10, 64)
	if err != nil || uid <= 0 {
		return 0, errAPI(401, "token", "is invalid")
	}
	return uid, nil
}

func (a *app) signToken(userID int64) (string, error) {
	claims := jwt.RegisteredClaims{
		Subject:   strconv.FormatInt(userID, 10),
		ExpiresAt: jwt.NewNumericDate(time.Now().Add(jwtTTL)),
	}
	return jwt.NewWithClaims(jwt.SigningMethodHS256, claims).SignedString(a.secret)
}

func uniqueField(err error) (string, bool) {
	var pgErr *pgconn.PgError
	if !errors.As(err, &pgErr) || pgErr.Code != "23505" {
		return "", false
	}
	name := pgErr.ConstraintName
	switch {
	case strings.Contains(name, "username"):
		return "username", true
	case strings.Contains(name, "email"):
		return "email", true
	case strings.Contains(name, "slug"):
		return "slug", true
	default:
		return "username", true
	}
}

func ts(col string) string {
	return fmt.Sprintf(`to_char(%s AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"')`, col)
}

func articleSelect(includeBody bool) string {
	body := ""
	if includeBody {
		body = "a.body,"
	}
	return fmt.Sprintf(`
SELECT
  a.id,
  a.slug,
  a.title,
  a.description,
  %s
  %s AS created_at,
  %s AS updated_at,
  u.username AS author_username,
  u.bio AS author_bio,
  u.image AS author_image,
  (SELECT count(*)::int FROM favorites f WHERE f.article_id = a.id) AS favorites_count,
  EXISTS(SELECT 1 FROM favorites f WHERE f.article_id = a.id AND f.user_id = $1) AS favorited,
  EXISTS(SELECT 1 FROM follows fl WHERE fl.follower_id = $1 AND fl.followee_id = a.author_id) AS following,
  COALESCE(
    (SELECT array_agg(t.name ORDER BY at.position)
     FROM article_tags at
     JOIN tags t ON t.id = at.tag_id
     WHERE at.article_id = a.id),
    ARRAY[]::text[]
  ) AS tag_list
FROM articles a
JOIN users u ON u.id = a.author_id`, body, ts("a.created_at"), ts("a.updated_at"))
}

func scanArticle(row pgx.Row, includeBody bool) (*articleRow, error) {
	var a articleRow
	var tags []string
	var err error
	if includeBody {
		err = row.Scan(
			&a.ID, &a.Slug, &a.Title, &a.Description, &a.Body,
			&a.CreatedAt, &a.UpdatedAt,
			&a.AuthorUsername, &a.AuthorBio, &a.AuthorImage,
			&a.FavoritesCount, &a.Favorited, &a.Following, &tags,
		)
	} else {
		err = row.Scan(
			&a.ID, &a.Slug, &a.Title, &a.Description,
			&a.CreatedAt, &a.UpdatedAt,
			&a.AuthorUsername, &a.AuthorBio, &a.AuthorImage,
			&a.FavoritesCount, &a.Favorited, &a.Following, &tags,
		)
	}
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	if tags == nil {
		tags = []string{}
	}
	a.TagList = tags
	return &a, nil
}

func (a *app) acquire(ctx context.Context) (*pgxpool.Conn, error) {
	return a.pool.Acquire(ctx)
}

func (a *app) loadUser(ctx context.Context, q querier, id int64) (userRow, error) {
	var u userRow
	err := q.QueryRow(ctx, `
		SELECT id, username, email, bio, image, password_hash
		FROM users WHERE id = $1`, id).Scan(
		&u.ID, &u.Username, &u.Email, &u.Bio, &u.Image, &u.PasswordHash,
	)
	if errors.Is(err, pgx.ErrNoRows) {
		return u, errAPI(401, "token", "is invalid")
	}
	return u, err
}

func (a *app) isFollowing(ctx context.Context, q querier, viewer, author int64) (bool, error) {
	if viewer <= 0 {
		return false, nil
	}
	var ok bool
	err := q.QueryRow(ctx, `
		SELECT EXISTS(
		  SELECT 1 FROM follows WHERE follower_id = $1 AND followee_id = $2
		)`, viewer, author).Scan(&ok)
	return ok, err
}

func (a *app) addTags(ctx context.Context, q querier, articleID int64, tags []string) error {
	for pos, name := range tags {
		var tagID int64
		err := q.QueryRow(ctx, `
			INSERT INTO tags (name) VALUES ($1)
			ON CONFLICT (name) DO UPDATE SET name = EXCLUDED.name
			RETURNING id`, name).Scan(&tagID)
		if err != nil {
			return err
		}
		if _, err = q.Exec(ctx, `
			INSERT INTO article_tags (article_id, tag_id, position)
			VALUES ($1, $2, $3)`, articleID, tagID, pos); err != nil {
			return err
		}
	}
	return nil
}

func (a *app) uniqueSlug(ctx context.Context, q querier, title string, excludeID int64) (string, error) {
	base := slugify(title)
	for n := 0; n < 100000; n++ {
		slug := withSuffix(base, n)
		var id int64
		err := q.QueryRow(ctx, `SELECT id FROM articles WHERE slug = $1`, slug).Scan(&id)
		if errors.Is(err, pgx.ErrNoRows) {
			return slug, nil
		}
		if err != nil {
			return "", err
		}
		if excludeID != 0 && id == excludeID {
			return slug, nil
		}
	}
	return "", errAPI(409, "slug", "has already been taken")
}

func (a *app) fetchArticle(ctx context.Context, q querier, viewer int64, slug string, includeBody bool) (*articleRow, error) {
	sql := articleSelect(includeBody) + " WHERE a.slug = $2"
	return scanArticle(q.QueryRow(ctx, sql, viewer, slug), includeBody)
}

func listFilters(viewer int64, tag, author, favorited *string, feed bool) (string, []any) {
	args := []any{viewer}
	conds := []string{"$1::bigint >= 0"}
	bind := func(v any) string {
		args = append(args, v)
		return fmt.Sprintf("$%d", len(args))
	}
	if feed {
		conds = append(conds, `EXISTS (SELECT 1 FROM follows fl WHERE fl.follower_id = $1 AND fl.followee_id = a.author_id)`)
	}
	if tag != nil {
		ph := bind(*tag)
		conds = append(conds, fmt.Sprintf(`EXISTS (
			SELECT 1 FROM article_tags at
			JOIN tags t ON t.id = at.tag_id
			WHERE at.article_id = a.id AND t.name = %s)`, ph))
	}
	if author != nil {
		conds = append(conds, "u.username = "+bind(*author))
	}
	if favorited != nil {
		ph := bind(*favorited)
		conds = append(conds, fmt.Sprintf(`EXISTS (
			SELECT 1 FROM favorites fv
			JOIN users fu ON fu.id = fv.user_id
			WHERE fv.article_id = a.id AND fu.username = %s)`, ph))
	}
	return " WHERE " + strings.Join(conds, " AND "), args
}

func userJSON(u userRow, token string) map[string]any {
	return map[string]any{
		"email":    u.Email,
		"token":    token,
		"username": u.Username,
		"bio":      u.Bio,
		"image":    u.Image,
	}
}

func profileJSON(username string, bio, image *string, following bool) map[string]any {
	return map[string]any{
		"username":  username,
		"bio":       bio,
		"image":     image,
		"following": following,
	}
}

func articleJSON(a *articleRow, includeBody bool) map[string]any {
	tags := a.TagList
	if tags == nil {
		tags = []string{}
	}
	out := map[string]any{
		"slug":           a.Slug,
		"title":          a.Title,
		"description":    a.Description,
		"tagList":        tags,
		"createdAt":      a.CreatedAt,
		"updatedAt":      a.UpdatedAt,
		"favorited":      a.Favorited,
		"favoritesCount": a.FavoritesCount,
		"author":         profileJSON(a.AuthorUsername, a.AuthorBio, a.AuthorImage, a.Following),
	}
	if includeBody {
		out["body"] = a.Body
	}
	return out
}

func commentJSON(id int64, created, updated, body, username string, bio, image *string, following bool) map[string]any {
	return map[string]any{
		"id":        id,
		"createdAt": created,
		"updatedAt": updated,
		"body":      body,
		"author":    profileJSON(username, bio, image, following),
	}
}

func optionalQuery(r *http.Request, key string) *string {
	q := r.URL.Query()
	if _, ok := q[key]; !ok {
		return nil
	}
	v := q.Get(key)
	return &v
}

func (a *app) healthz(w http.ResponseWriter, r *http.Request) error {
	var one int
	if err := a.pool.QueryRow(r.Context(), "SELECT 1").Scan(&one); err != nil {
		return err
	}
	return writeJSON(w, http.StatusOK, map[string]any{"ok": true})
}

func (a *app) register(w http.ResponseWriter, r *http.Request) error {
	obj, err := readObject(r, "user")
	if err != nil {
		return err
	}
	username, email, password, err := registerFields(obj)
	if err != nil {
		return err
	}
	hash, err := bcrypt.GenerateFromPassword([]byte(password), bcryptCost)
	if err != nil {
		return err
	}
	ctx := r.Context()
	conn, err := a.acquire(ctx)
	if err != nil {
		return err
	}
	defer conn.Release()

	var takenUser, takenEmail string
	err = conn.QueryRow(ctx, `SELECT username, email FROM users WHERE username = $1 OR email = $2`, username, email).
		Scan(&takenUser, &takenEmail)
	if err == nil {
		if takenUser == username {
			return errAPI(409, "username", "has already been taken")
		}
		return errAPI(409, "email", "has already been taken")
	}
	if !errors.Is(err, pgx.ErrNoRows) {
		return err
	}
	var u userRow
	err = conn.QueryRow(ctx, `
		INSERT INTO users (username, email, password_hash)
		VALUES ($1, $2, $3)
		RETURNING id, username, email, bio, image`, username, email, string(hash)).
		Scan(&u.ID, &u.Username, &u.Email, &u.Bio, &u.Image)
	if field, ok := uniqueField(err); ok {
		return errAPI(409, field, "has already been taken")
	}
	if err != nil {
		return err
	}
	token, err := a.signToken(u.ID)
	if err != nil {
		return err
	}
	return writeJSON(w, http.StatusCreated, map[string]any{"user": userJSON(u, token)})
}

func (a *app) login(w http.ResponseWriter, r *http.Request) error {
	obj, err := readObject(r, "user")
	if err != nil {
		return err
	}
	email, password, err := loginFields(obj)
	if err != nil {
		return err
	}
	ctx := r.Context()
	var u userRow
	err = a.pool.QueryRow(ctx, `
		SELECT id, username, email, bio, image, password_hash
		FROM users WHERE email = $1`, email).
		Scan(&u.ID, &u.Username, &u.Email, &u.Bio, &u.Image, &u.PasswordHash)
	found := true
	hash := []byte(u.PasswordHash)
	if errors.Is(err, pgx.ErrNoRows) {
		found = false
		hash = a.dummy
		err = nil
	}
	if err != nil {
		return err
	}
	if bcrypt.CompareHashAndPassword(hash, []byte(password)) != nil || !found {
		return errAPI(401, "credentials", "invalid")
	}
	token, err := a.signToken(u.ID)
	if err != nil {
		return err
	}
	return writeJSON(w, http.StatusOK, map[string]any{"user": userJSON(u, token)})
}

func (a *app) currentUser(w http.ResponseWriter, r *http.Request) error {
	uid, err := a.userID(r, true)
	if err != nil {
		return err
	}
	u, err := a.loadUser(r.Context(), a.pool, uid)
	if err != nil {
		return err
	}
	token, err := a.signToken(u.ID)
	if err != nil {
		return err
	}
	return writeJSON(w, http.StatusOK, map[string]any{"user": userJSON(u, token)})
}

func (a *app) updateUser(w http.ResponseWriter, r *http.Request) error {
	uid, err := a.userID(r, true)
	if err != nil {
		return err
	}
	obj, err := readObject(r, "user")
	if err != nil {
		return err
	}
	fields, err := updateUserFields(obj)
	if err != nil {
		return err
	}
	var passwordHash string
	if fields.Password.Kind == "set" {
		hashed, err := bcrypt.GenerateFromPassword([]byte(fields.Password.Val), bcryptCost)
		if err != nil {
			return err
		}
		passwordHash = string(hashed)
	}
	ctx := r.Context()
	conn, err := a.acquire(ctx)
	if err != nil {
		return err
	}
	defer conn.Release()
	tx, err := conn.Begin(ctx)
	if err != nil {
		return err
	}
	defer tx.Rollback(ctx)

	if _, err = a.loadUser(ctx, tx, uid); err != nil {
		return err
	}
	if fields.Username.Kind == "set" {
		var clash int
		err = tx.QueryRow(ctx, `SELECT 1 FROM users WHERE username = $1 AND id <> $2`, fields.Username.Val, uid).Scan(&clash)
		if err == nil {
			return errAPI(409, "username", "has already been taken")
		}
		if !errors.Is(err, pgx.ErrNoRows) {
			return err
		}
	}
	if fields.Email.Kind == "set" {
		var clash int
		err = tx.QueryRow(ctx, `SELECT 1 FROM users WHERE email = $1 AND id <> $2`, fields.Email.Val, uid).Scan(&clash)
		if err == nil {
			return errAPI(409, "email", "has already been taken")
		}
		if !errors.Is(err, pgx.ErrNoRows) {
			return err
		}
	}

	sets := make([]string, 0, 5)
	args := make([]any, 0, 6)
	bind := func(column string, value any) {
		args = append(args, value)
		sets = append(sets, fmt.Sprintf("%s = $%d", column, len(args)))
	}
	if fields.Username.Kind == "set" {
		bind("username", fields.Username.Val)
	}
	if fields.Email.Kind == "set" {
		bind("email", fields.Email.Val)
	}
	if fields.Password.Kind == "set" {
		bind("password_hash", passwordHash)
	}
	if fields.Bio.Kind == "set" {
		bind("bio", fields.Bio.Val)
	} else if fields.Bio.Kind == "clear" {
		sets = append(sets, "bio = NULL")
	}
	if fields.Image.Kind == "set" {
		bind("image", fields.Image.Val)
	} else if fields.Image.Kind == "clear" {
		sets = append(sets, "image = NULL")
	}
	args = append(args, uid)
	var u userRow
	err = tx.QueryRow(ctx, fmt.Sprintf(`
		UPDATE users SET %s WHERE id = $%d
		RETURNING id, username, email, bio, image`, strings.Join(sets, ", "), len(args)), args...).
		Scan(&u.ID, &u.Username, &u.Email, &u.Bio, &u.Image)
	if field, ok := uniqueField(err); ok {
		return errAPI(409, field, "has already been taken")
	}
	if err != nil {
		return err
	}
	if err := tx.Commit(ctx); err != nil {
		return err
	}
	token, err := a.signToken(u.ID)
	if err != nil {
		return err
	}
	return writeJSON(w, http.StatusOK, map[string]any{"user": userJSON(u, token)})
}

func (a *app) getProfile(w http.ResponseWriter, r *http.Request) error {
	viewer, err := a.userID(r, false)
	if err != nil {
		return err
	}
	ctx := r.Context()
	conn, err := a.acquire(ctx)
	if err != nil {
		return err
	}
	defer conn.Release()
	if viewer > 0 {
		if _, err = a.loadUser(ctx, conn, viewer); err != nil {
			return err
		}
	}
	var username string
	var bio, image *string
	var following bool
	err = conn.QueryRow(ctx, `
		SELECT username, bio, image,
		  EXISTS(SELECT 1 FROM follows WHERE follower_id = $1 AND followee_id = users.id) AS following
		FROM users WHERE username = $2`, viewer, chi.URLParam(r, "username")).
		Scan(&username, &bio, &image, &following)
	if errors.Is(err, pgx.ErrNoRows) {
		return errAPI(404, "profile", "not found")
	}
	if err != nil {
		return err
	}
	return writeJSON(w, http.StatusOK, map[string]any{
		"profile": profileJSON(username, bio, image, following),
	})
}

func (a *app) setFollow(w http.ResponseWriter, r *http.Request, follow bool) error {
	uid, err := a.userID(r, true)
	if err != nil {
		return err
	}
	ctx := r.Context()
	conn, err := a.acquire(ctx)
	if err != nil {
		return err
	}
	defer conn.Release()
	tx, err := conn.Begin(ctx)
	if err != nil {
		return err
	}
	defer tx.Rollback(ctx)
	if _, err = a.loadUser(ctx, tx, uid); err != nil {
		return err
	}
	var id int64
	var username string
	var bio, image *string
	err = tx.QueryRow(ctx, `SELECT id, username, bio, image FROM users WHERE username = $1`, chi.URLParam(r, "username")).
		Scan(&id, &username, &bio, &image)
	if errors.Is(err, pgx.ErrNoRows) {
		return errAPI(404, "profile", "not found")
	}
	if err != nil {
		return err
	}
	if follow {
		_, err = tx.Exec(ctx, `
			INSERT INTO follows (follower_id, followee_id) VALUES ($1, $2)
			ON CONFLICT DO NOTHING`, uid, id)
	} else {
		_, err = tx.Exec(ctx, `DELETE FROM follows WHERE follower_id = $1 AND followee_id = $2`, uid, id)
	}
	if err != nil {
		return err
	}
	if err := tx.Commit(ctx); err != nil {
		return err
	}
	return writeJSON(w, http.StatusOK, map[string]any{
		"profile": profileJSON(username, bio, image, follow),
	})
}

func (a *app) follow(w http.ResponseWriter, r *http.Request) error {
	return a.setFollow(w, r, true)
}

func (a *app) unfollow(w http.ResponseWriter, r *http.Request) error {
	return a.setFollow(w, r, false)
}

func (a *app) list(w http.ResponseWriter, r *http.Request, viewer int64, feed bool) error {
	limit, offset, err := pageParams(r.URL.Query().Get("limit"), r.URL.Query().Get("offset"))
	if err != nil {
		return err
	}
	var tag, author, favorited *string
	if !feed {
		tag = optionalQuery(r, "tag")
		author = optionalQuery(r, "author")
		favorited = optionalQuery(r, "favorited")
	}
	where, args := listFilters(viewer, tag, author, favorited, feed)
	countArgs := append([]any{}, args...)
	args = append(args, limit)
	limitPh := fmt.Sprintf("$%d", len(args))
	args = append(args, offset)
	offsetPh := fmt.Sprintf("$%d", len(args))
	sql := articleSelect(false) + where + " ORDER BY a.created_at DESC, a.id DESC LIMIT " + limitPh + " OFFSET " + offsetPh
	countSQL := "SELECT count(*)::bigint FROM articles a JOIN users u ON u.id = a.author_id" + where

	ctx := r.Context()
	conn, err := a.acquire(ctx)
	if err != nil {
		return err
	}
	defer conn.Release()
	if viewer > 0 {
		if _, err = a.loadUser(ctx, conn, viewer); err != nil {
			return err
		}
	}
	rows, err := conn.Query(ctx, sql, args...)
	if err != nil {
		return err
	}
	defer rows.Close()
	articles := make([]any, 0)
	for rows.Next() {
		item, err := scanArticle(rows, false)
		if err != nil {
			return err
		}
		articles = append(articles, articleJSON(item, false))
	}
	if err := rows.Err(); err != nil {
		return err
	}
	var total int64
	if err := conn.QueryRow(ctx, countSQL, countArgs...).Scan(&total); err != nil {
		return err
	}
	return writeJSON(w, http.StatusOK, map[string]any{
		"articles":      articles,
		"articlesCount": total,
	})
}

func (a *app) feed(w http.ResponseWriter, r *http.Request) error {
	uid, err := a.userID(r, true)
	if err != nil {
		return err
	}
	return a.list(w, r, uid, true)
}

func (a *app) listArticles(w http.ResponseWriter, r *http.Request) error {
	viewer, err := a.userID(r, false)
	if err != nil {
		return err
	}
	return a.list(w, r, viewer, false)
}

func (a *app) createArticle(w http.ResponseWriter, r *http.Request) error {
	uid, err := a.userID(r, true)
	if err != nil {
		return err
	}
	obj, err := readObject(r, "article")
	if err != nil {
		return err
	}
	title, description, body, tags, err := articleCreateFields(obj)
	if err != nil {
		return err
	}
	if tags == nil {
		tags = []string{}
	}
	ctx := r.Context()
	conn, err := a.acquire(ctx)
	if err != nil {
		return err
	}
	defer conn.Release()
	author, err := a.loadUser(ctx, conn, uid)
	if err != nil {
		return err
	}
	var createdID int64
	var createdAt, updatedAt, slug string
	inserted := false
	for attempt := 0; attempt < 8; attempt++ {
		slug, err = a.uniqueSlug(ctx, conn, title, 0)
		if err != nil {
			return err
		}
		tx, err := conn.Begin(ctx)
		if err != nil {
			return err
		}
		err = tx.QueryRow(ctx, fmt.Sprintf(`
			INSERT INTO articles (author_id, slug, title, description, body)
			VALUES ($1, $2, $3, $4, $5)
			RETURNING id, %s, %s`, ts("created_at"), ts("updated_at")),
			uid, slug, title, description, body).Scan(&createdID, &createdAt, &updatedAt)
		if err != nil {
			_ = tx.Rollback(ctx)
			if _, ok := uniqueField(err); ok {
				continue
			}
			return err
		}
		if err = a.addTags(ctx, tx, createdID, tags); err != nil {
			_ = tx.Rollback(ctx)
			if _, ok := uniqueField(err); ok {
				continue
			}
			return err
		}
		if err = tx.Commit(ctx); err != nil {
			_ = tx.Rollback(ctx)
			if _, ok := uniqueField(err); ok {
				continue
			}
			return err
		}
		inserted = true
		break
	}
	if !inserted {
		return errAPI(409, "slug", "has already been taken")
	}
	following, err := a.isFollowing(ctx, conn, uid, uid)
	if err != nil {
		return err
	}
	return writeJSON(w, http.StatusCreated, map[string]any{
		"article": map[string]any{
			"slug":           slug,
			"title":          title,
			"description":    description,
			"body":           body,
			"tagList":        tags,
			"createdAt":      createdAt,
			"updatedAt":      updatedAt,
			"favorited":      false,
			"favoritesCount": 0,
			"author":         profileJSON(author.Username, author.Bio, author.Image, following),
		},
	})
}

func (a *app) getArticle(w http.ResponseWriter, r *http.Request) error {
	viewer, err := a.userID(r, false)
	if err != nil {
		return err
	}
	ctx := r.Context()
	conn, err := a.acquire(ctx)
	if err != nil {
		return err
	}
	defer conn.Release()
	if viewer > 0 {
		if _, err = a.loadUser(ctx, conn, viewer); err != nil {
			return err
		}
	}
	row, err := a.fetchArticle(ctx, conn, viewer, chi.URLParam(r, "slug"), true)
	if err != nil {
		return err
	}
	if row == nil {
		return errAPI(404, "article", "not found")
	}
	return writeJSON(w, http.StatusOK, map[string]any{"article": articleJSON(row, true)})
}

func (a *app) updateArticle(w http.ResponseWriter, r *http.Request) error {
	uid, err := a.userID(r, true)
	if err != nil {
		return err
	}
	obj, err := readObject(r, "article")
	if err != nil {
		return err
	}
	fields, err := articleUpdateFields(obj)
	if err != nil {
		return err
	}
	ctx := r.Context()
	conn, err := a.acquire(ctx)
	if err != nil {
		return err
	}
	defer conn.Release()
	tx, err := conn.Begin(ctx)
	if err != nil {
		return err
	}
	defer tx.Rollback(ctx)
	if _, err = a.loadUser(ctx, tx, uid); err != nil {
		return err
	}
	var currentID, authorID int64
	err = tx.QueryRow(ctx, `SELECT id, author_id FROM articles WHERE slug = $1`, chi.URLParam(r, "slug")).
		Scan(&currentID, &authorID)
	if errors.Is(err, pgx.ErrNoRows) {
		return errAPI(404, "article", "not found")
	}
	if err != nil {
		return err
	}
	if authorID != uid {
		return errAPI(403, "article", "forbidden")
	}
	sets := []string{"updated_at = GREATEST(statement_timestamp(), updated_at + interval '1 millisecond')"}
	args := make([]any, 0, 6)
	bind := func(column string, value any) {
		args = append(args, value)
		sets = append(sets, fmt.Sprintf("%s = $%d", column, len(args)))
	}
	if fields.Title.Kind == "set" {
		newSlug, err := a.uniqueSlug(ctx, tx, fields.Title.Val, currentID)
		if err != nil {
			return err
		}
		bind("title", fields.Title.Val)
		bind("slug", newSlug)
	}
	if fields.Description.Kind == "set" {
		bind("description", fields.Description.Val)
	}
	if fields.Body.Kind == "set" {
		bind("body", fields.Body.Val)
	}
	args = append(args, currentID)
	_, err = tx.Exec(ctx, fmt.Sprintf(`UPDATE articles SET %s WHERE id = $%d`, strings.Join(sets, ", "), len(args)), args...)
	if field, ok := uniqueField(err); ok {
		return errAPI(409, field, "has already been taken")
	}
	if err != nil {
		return err
	}
	if fields.Tags.Kind == "replace" {
		if _, err = tx.Exec(ctx, `DELETE FROM article_tags WHERE article_id = $1`, currentID); err != nil {
			return err
		}
		if err = a.addTags(ctx, tx, currentID, fields.Tags.Tags); err != nil {
			return err
		}
	}
	var freshSlug string
	if err = tx.QueryRow(ctx, `SELECT slug FROM articles WHERE id = $1`, currentID).Scan(&freshSlug); err != nil {
		return err
	}
	if err = tx.Commit(ctx); err != nil {
		return err
	}
	row, err := a.fetchArticle(ctx, conn, uid, freshSlug, true)
	if err != nil {
		return err
	}
	if row == nil {
		return errAPI(404, "article", "not found")
	}
	return writeJSON(w, http.StatusOK, map[string]any{"article": articleJSON(row, true)})
}

func (a *app) deleteArticle(w http.ResponseWriter, r *http.Request) error {
	uid, err := a.userID(r, true)
	if err != nil {
		return err
	}
	ctx := r.Context()
	conn, err := a.acquire(ctx)
	if err != nil {
		return err
	}
	defer conn.Release()
	if _, err = a.loadUser(ctx, conn, uid); err != nil {
		return err
	}
	var id, authorID int64
	err = conn.QueryRow(ctx, `SELECT id, author_id FROM articles WHERE slug = $1`, chi.URLParam(r, "slug")).
		Scan(&id, &authorID)
	if errors.Is(err, pgx.ErrNoRows) {
		return errAPI(404, "article", "not found")
	}
	if err != nil {
		return err
	}
	if authorID != uid {
		return errAPI(403, "article", "forbidden")
	}
	if _, err = conn.Exec(ctx, `DELETE FROM articles WHERE id = $1`, id); err != nil {
		return err
	}
	w.WriteHeader(http.StatusNoContent)
	return nil
}

func (a *app) listComments(w http.ResponseWriter, r *http.Request) error {
	viewer, err := a.userID(r, false)
	if err != nil {
		return err
	}
	ctx := r.Context()
	conn, err := a.acquire(ctx)
	if err != nil {
		return err
	}
	defer conn.Release()
	if viewer > 0 {
		if _, err = a.loadUser(ctx, conn, viewer); err != nil {
			return err
		}
	}
	var articleID int64
	err = conn.QueryRow(ctx, `SELECT id FROM articles WHERE slug = $1`, chi.URLParam(r, "slug")).Scan(&articleID)
	if errors.Is(err, pgx.ErrNoRows) {
		return errAPI(404, "article", "not found")
	}
	if err != nil {
		return err
	}
	rows, err := conn.Query(ctx, fmt.Sprintf(`
		SELECT c.id, c.body, %s, %s,
		  u.username, u.bio, u.image,
		  EXISTS(
		    SELECT 1 FROM follows fl
		    WHERE fl.follower_id = $1 AND fl.followee_id = c.author_id
		  )
		FROM comments c
		JOIN users u ON u.id = c.author_id
		WHERE c.article_id = $2
		ORDER BY c.created_at ASC, c.id ASC`, ts("c.created_at"), ts("c.updated_at")), viewer, articleID)
	if err != nil {
		return err
	}
	defer rows.Close()
	comments := make([]any, 0)
	for rows.Next() {
		var id int64
		var body, created, updated, username string
		var bio, image *string
		var following bool
		if err := rows.Scan(&id, &body, &created, &updated, &username, &bio, &image, &following); err != nil {
			return err
		}
		comments = append(comments, commentJSON(id, created, updated, body, username, bio, image, following))
	}
	if err := rows.Err(); err != nil {
		return err
	}
	return writeJSON(w, http.StatusOK, map[string]any{"comments": comments})
}

func (a *app) createComment(w http.ResponseWriter, r *http.Request) error {
	uid, err := a.userID(r, true)
	if err != nil {
		return err
	}
	obj, err := readObject(r, "comment")
	if err != nil {
		return err
	}
	body, err := commentBody(obj)
	if err != nil {
		return err
	}
	ctx := r.Context()
	conn, err := a.acquire(ctx)
	if err != nil {
		return err
	}
	defer conn.Release()
	author, err := a.loadUser(ctx, conn, uid)
	if err != nil {
		return err
	}
	var articleID int64
	err = conn.QueryRow(ctx, `SELECT id FROM articles WHERE slug = $1`, chi.URLParam(r, "slug")).Scan(&articleID)
	if errors.Is(err, pgx.ErrNoRows) {
		return errAPI(404, "article", "not found")
	}
	if err != nil {
		return err
	}
	var id int64
	var created, updated string
	err = conn.QueryRow(ctx, fmt.Sprintf(`
		INSERT INTO comments (article_id, author_id, body)
		VALUES ($1, $2, $3)
		RETURNING id, %s, %s`, ts("created_at"), ts("updated_at")), articleID, uid, body).
		Scan(&id, &created, &updated)
	if err != nil {
		return err
	}
	following, err := a.isFollowing(ctx, conn, uid, uid)
	if err != nil {
		return err
	}
	return writeJSON(w, http.StatusCreated, map[string]any{
		"comment": commentJSON(id, created, updated, body, author.Username, author.Bio, author.Image, following),
	})
}

func (a *app) deleteComment(w http.ResponseWriter, r *http.Request) error {
	uid, err := a.userID(r, true)
	if err != nil {
		return err
	}
	commentID, err := strconv.ParseInt(chi.URLParam(r, "commentID"), 10, 64)
	if err != nil || commentID <= 0 {
		return errAPI(422, "comment", "is invalid")
	}
	ctx := r.Context()
	conn, err := a.acquire(ctx)
	if err != nil {
		return err
	}
	defer conn.Release()
	if _, err = a.loadUser(ctx, conn, uid); err != nil {
		return err
	}
	var articleID int64
	err = conn.QueryRow(ctx, `SELECT id FROM articles WHERE slug = $1`, chi.URLParam(r, "slug")).Scan(&articleID)
	if errors.Is(err, pgx.ErrNoRows) {
		return errAPI(404, "article", "not found")
	}
	if err != nil {
		return err
	}
	var authorID int64
	err = conn.QueryRow(ctx, `SELECT author_id FROM comments WHERE id = $1 AND article_id = $2`, commentID, articleID).Scan(&authorID)
	if errors.Is(err, pgx.ErrNoRows) {
		return errAPI(404, "comment", "not found")
	}
	if err != nil {
		return err
	}
	if authorID != uid {
		return errAPI(403, "comment", "forbidden")
	}
	if _, err = conn.Exec(ctx, `DELETE FROM comments WHERE id = $1`, commentID); err != nil {
		return err
	}
	w.WriteHeader(http.StatusNoContent)
	return nil
}

func (a *app) setFavorite(w http.ResponseWriter, r *http.Request, on bool) error {
	uid, err := a.userID(r, true)
	if err != nil {
		return err
	}
	slug := chi.URLParam(r, "slug")
	ctx := r.Context()
	conn, err := a.acquire(ctx)
	if err != nil {
		return err
	}
	defer conn.Release()
	tx, err := conn.Begin(ctx)
	if err != nil {
		return err
	}
	defer tx.Rollback(ctx)
	if _, err = a.loadUser(ctx, tx, uid); err != nil {
		return err
	}
	var articleID int64
	err = tx.QueryRow(ctx, `SELECT id FROM articles WHERE slug = $1`, slug).Scan(&articleID)
	if errors.Is(err, pgx.ErrNoRows) {
		return errAPI(404, "article", "not found")
	}
	if err != nil {
		return err
	}
	if on {
		_, err = tx.Exec(ctx, `
			INSERT INTO favorites (user_id, article_id) VALUES ($1, $2)
			ON CONFLICT DO NOTHING`, uid, articleID)
	} else {
		_, err = tx.Exec(ctx, `DELETE FROM favorites WHERE user_id = $1 AND article_id = $2`, uid, articleID)
	}
	if err != nil {
		return err
	}
	if err = tx.Commit(ctx); err != nil {
		return err
	}
	row, err := a.fetchArticle(ctx, conn, uid, slug, true)
	if err != nil {
		return err
	}
	if row == nil {
		return errAPI(404, "article", "not found")
	}
	return writeJSON(w, http.StatusOK, map[string]any{"article": articleJSON(row, true)})
}

func (a *app) favorite(w http.ResponseWriter, r *http.Request) error {
	return a.setFavorite(w, r, true)
}

func (a *app) unfavorite(w http.ResponseWriter, r *http.Request) error {
	return a.setFavorite(w, r, false)
}

func (a *app) tags(w http.ResponseWriter, r *http.Request) error {
	rows, err := a.pool.Query(r.Context(), `SELECT name FROM tags ORDER BY name ASC`)
	if err != nil {
		return err
	}
	defer rows.Close()
	names := make([]string, 0)
	for rows.Next() {
		var name string
		if err := rows.Scan(&name); err != nil {
			return err
		}
		names = append(names, name)
	}
	if err := rows.Err(); err != nil {
		return err
	}
	return writeJSON(w, http.StatusOK, map[string]any{"tags": names})
}
