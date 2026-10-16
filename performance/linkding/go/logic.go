package main

import (
	"encoding/json"
	"fmt"
	"net"
	"net/url"
	"sort"
	"strconv"
	"strings"
	"time"
	"unicode"
	"unicode/utf8"
)

const appVersion = "1.47.0"
const pageSize = 100

const dtError = "Datetime has wrong format. Use one of these formats instead: YYYY-MM-DDThh:mm[:ss[.uuuuuu]][+HH:MM|-HH:MM|Z]."

var trueValues = map[string]bool{
	"t": true, "T": true, "y": true, "Y": true,
	"yes": true, "YES": true, "Yes": true,
	"true": true, "True": true, "TRUE": true,
	"on": true, "On": true, "ON": true, "1": true,
}

var falseValues = map[string]bool{
	"f": true, "F": true, "n": true, "N": true,
	"no": true, "NO": true, "No": true,
	"false": true, "False": true, "FALSE": true,
	"off": true, "Off": true, "OFF": true, "0": true,
}

var filterChoices = map[string]bool{"off": true, "yes": true, "no": true}

func uniqueCI(items []string) []string {
	index := map[string]int{}
	out := make([]string, 0, len(items))
	for _, item := range items {
		key := strings.ToLower(item)
		if i, ok := index[key]; ok {
			out[i] = item
			continue
		}
		index[key] = len(out)
		out = append(out, item)
	}
	return out
}

func sanitizeTagName(name string) string {
	return strings.ReplaceAll(strings.TrimSpace(name), " ", "-")
}

func parseTagString(tagString, delimiter string) []string {
	if strings.TrimSpace(tagString) == "" {
		return nil
	}
	parts := strings.Split(strings.TrimSpace(tagString), delimiter)
	names := make([]string, 0, len(parts))
	for _, part := range parts {
		if strings.TrimSpace(part) == "" {
			continue
		}
		names = append(names, sanitizeTagName(part))
	}
	names = uniqueCI(names)
	sort.SliceStable(names, func(i, j int) bool {
		return strings.ToLower(names[i]) < strings.ToLower(names[j])
	})
	return names
}

func bookmarkTagNames(raw []string) []string {
	return parseTagString(strings.Join(raw, ","), ",")
}

func pyQuote(s string) string {
	var b strings.Builder
	for i := 0; i < len(s); i++ {
		c := s[i]
		if (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9') || c == '-' || c == '_' || c == '.' || c == '~' || c == '/' {
			b.WriteByte(c)
			continue
		}
		fmt.Fprintf(&b, "%%%02X", c)
	}
	return b.String()
}

func normalizeURL(raw string) string {
	raw = strings.TrimSpace(raw)
	if raw == "" {
		return ""
	}
	parsed, err := url.Parse(raw)
	if err != nil || parsed.Scheme == "" || parsed.Host == "" {
		return raw
	}
	host := strings.ToLower(parsed.Hostname())
	if host == "" {
		return raw
	}
	netloc := host
	if port := parsed.Port(); port != "" {
		netloc += ":" + port
	}
	if parsed.User != nil {
		auth := parsed.User.Username()
		if password, ok := parsed.User.Password(); ok {
			auth += ":" + password
		}
		netloc = auth + "@" + netloc
	}
	path := strings.TrimRight(parsed.Path, "/")
	query := ""
	if parsed.RawQuery != "" {
		values, err := url.ParseQuery(parsed.RawQuery)
		if err != nil {
			return raw
		}
		type pair struct{ k, v string }
		pairs := make([]pair, 0)
		for key, list := range values {
			for _, value := range list {
				pairs = append(pairs, pair{key, value})
			}
		}
		sort.Slice(pairs, func(i, j int) bool {
			if pairs[i].k == pairs[j].k {
				return pairs[i].v < pairs[j].v
			}
			return pairs[i].k < pairs[j].k
		})
		parts := make([]string, len(pairs))
		for i, item := range pairs {
			parts[i] = pyQuote(item.k) + "=" + pyQuote(item.v)
		}
		query = strings.Join(parts, "&")
	}
	out := strings.ToLower(parsed.Scheme) + "://" + netloc + path
	if query != "" {
		out += "?" + query
	}
	if parsed.Fragment != "" {
		out += "#" + parsed.Fragment
	}
	if parsed.RawFragment != "" && parsed.Fragment == "" {
		out += "#" + parsed.RawFragment
	}
	return out
}

func isIPv4(host string) bool {
	parts := strings.Split(host, ".")
	if len(parts) != 4 {
		return false
	}
	for _, part := range parts {
		if part == "" || strings.IndexFunc(part, func(r rune) bool { return r < '0' || r > '9' }) >= 0 {
			return false
		}
		if len(part) > 1 && part[0] == '0' {
			return false
		}
		n, err := strconv.Atoi(part)
		if err != nil || n > 255 {
			return false
		}
	}
	return true
}

func isIPv6(host string) bool {
	if !strings.Contains(host, ":") {
		return false
	}
	ip := net.ParseIP(host)
	return ip != nil && ip.To4() == nil
}

func labelOK(label string, tld bool) bool {
	if label == "" || len([]rune(label)) > 63 {
		return false
	}
	runes := []rune(label)
	if runes[0] == '-' || runes[len(runes)-1] == '-' {
		return false
	}
	if tld && strings.HasPrefix(strings.ToLower(label), "xn--") {
		rest := label[4:]
		if len(rest) < 1 || len(rest) > 59 {
			return false
		}
		for i := 0; i < len(rest); i++ {
			c := rest[i]
			if !((c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9')) {
				return false
			}
		}
		return true
	}
	for _, r := range runes {
		if r >= 0xA1 || r == '-' || unicode.IsLetter(r) || unicode.IsDigit(r) {
			continue
		}
		return false
	}
	if tld && len(runes) < 2 {
		return false
	}
	return true
}

func isDomain(host string) bool {
	if strings.HasSuffix(host, ".") {
		host = host[:len(host)-1]
	}
	if host == "" || len(host) > 253 {
		return false
	}
	labels := strings.Split(host, ".")
	if len(labels) < 2 {
		return false
	}
	for i, label := range labels {
		if !labelOK(label, i == len(labels)-1) {
			return false
		}
	}
	return true
}

func validURL(value string) bool {
	if len(value) > 2048 {
		return false
	}
	if strings.ContainsAny(value, "\t\r\n") {
		return false
	}
	if !strings.Contains(value, "://") {
		return false
	}
	scheme := strings.ToLower(strings.SplitN(value, "://", 2)[0])
	if scheme != "http" && scheme != "https" && scheme != "ftp" && scheme != "ftps" {
		return false
	}
	parsed, err := url.Parse(value)
	if err != nil {
		return false
	}
	host := parsed.Hostname()
	if host == "" || len(host) > 253 {
		return false
	}
	hostLower := strings.ToLower(host)
	if hostLower != "localhost" && !isIPv4(hostLower) && !isIPv6(host) && !isDomain(hostLower) {
		return false
	}
	if port := parsed.Port(); port != "" {
		n, err := strconv.Atoi(port)
		if err != nil || n < 0 || n > 65535 {
			return false
		}
	}
	return true
}

func parseQuery(raw string) map[string][]string {
	out := map[string][]string{}
	if raw == "" {
		return out
	}
	for _, part := range strings.Split(raw, "&") {
		if part == "" {
			continue
		}
		key, val, _ := strings.Cut(part, "=")
		key, _ = url.QueryUnescape(key)
		val, _ = url.QueryUnescape(val)
		out[key] = append(out[key], val)
	}
	return out
}

func encodeQuery(values map[string][]string) string {
	keys := make([]string, 0, len(values))
	for key := range values {
		keys = append(keys, key)
	}
	sort.Strings(keys)
	parts := make([]string, 0)
	for _, key := range keys {
		for _, value := range values[key] {
			parts = append(parts, url.QueryEscape(key)+"="+url.QueryEscape(value))
		}
	}
	return strings.Join(parts, "&")
}

func replaceQueryParam(raw, key, val string) string {
	base, query, fragment := splitRaw(raw)
	values := parseQuery(query)
	values[key] = []string{val}
	out := base
	if encoded := encodeQuery(values); encoded != "" {
		out += "?" + encoded
	}
	if fragment != "" {
		out += "#" + fragment
	}
	return out
}

func removeQueryParam(raw, key string) string {
	base, query, fragment := splitRaw(raw)
	values := parseQuery(query)
	delete(values, key)
	out := base
	if encoded := encodeQuery(values); encoded != "" {
		out += "?" + encoded
	}
	if fragment != "" {
		out += "#" + fragment
	}
	return out
}

func splitRaw(raw string) (base, query, fragment string) {
	if i := strings.Index(raw, "#"); i >= 0 {
		fragment = raw[i+1:]
		raw = raw[:i]
	}
	if i := strings.Index(raw, "?"); i >= 0 {
		query = raw[i+1:]
		raw = raw[:i]
	}
	return raw, query, fragment
}

func resolveLimit(raw string, ok bool) int {
	if !ok || raw == "" {
		return pageSize
	}
	n, err := strconv.Atoi(raw)
	if err != nil || n <= 0 {
		return pageSize
	}
	return n
}

func resolveOffset(raw string, ok bool) int {
	if !ok || raw == "" {
		return 0
	}
	n, err := strconv.Atoi(raw)
	if err != nil || n < 0 {
		return 0
	}
	return n
}

func pageLinks(raw string, limit, offset, count int) (next, prev *string) {
	if offset+limit < count {
		value := replaceQueryParam(replaceQueryParam(raw, "limit", strconv.Itoa(limit)), "offset", strconv.Itoa(offset+limit))
		next = &value
	}
	if offset > 0 {
		base := replaceQueryParam(raw, "limit", strconv.Itoa(limit))
		var value string
		if offset-limit <= 0 {
			value = removeQueryParam(base, "offset")
		} else {
			value = replaceQueryParam(base, "offset", strconv.Itoa(offset-limit))
		}
		prev = &value
	}
	return next, prev
}

func classifyAuth(header string) (kind, token string) {
	if strings.TrimSpace(header) == "" {
		return "absent", ""
	}
	parts := strings.Fields(header)
	if len(parts) == 0 {
		return "absent", ""
	}
	keyword := strings.ToLower(parts[0])
	if keyword != "token" && keyword != "bearer" {
		return "absent", ""
	}
	if len(parts) == 1 {
		return "nocreds", ""
	}
	if len(parts) > 2 {
		return "spaces", ""
	}
	return "token", parts[1]
}

func authDetail(kind string) string {
	switch kind {
	case "nocreds":
		return "Invalid token header. No credentials provided."
	case "spaces":
		return "Invalid token header. Token string should not contain spaces."
	case "bad":
		return "Invalid token."
	default:
		return "Authentication credentials were not provided."
	}
}

func parseBool(value any) (bool, bool) {
	switch typed := value.(type) {
	case bool:
		return typed, true
	case json.Number:
		if typed.String() == "1" {
			return true, true
		}
		if typed.String() == "0" {
			return false, true
		}
		return false, false
	case string:
		if trueValues[typed] {
			return true, true
		}
		if falseValues[typed] {
			return false, true
		}
		return false, false
	default:
		return false, false
	}
}

func parseTime(value string) (time.Time, bool) {
	value = strings.TrimSpace(value)
	if value == "" {
		return time.Time{}, false
	}
	if strings.HasSuffix(value, "Z") {
		value = value[:len(value)-1] + "+00:00"
	}
	layouts := []string{
		"2006-01-02T15:04:05.999999999Z07:00",
		"2006-01-02T15:04:05Z07:00",
		"2006-01-02T15:04Z07:00",
		"2006-01-02T15:04:05.999999999",
		"2006-01-02T15:04:05",
		"2006-01-02T15:04",
	}
	for _, layout := range layouts {
		if parsed, err := time.Parse(layout, value); err == nil {
			return parsed.UTC(), true
		}
	}
	return time.Time{}, false
}

func fmtTime(value time.Time) string {
	value = value.UTC()
	if value.Nanosecond() == 0 {
		return value.Format("2006-01-02T15:04:05Z")
	}
	micro := value.Nanosecond() / 1000
	return value.Format("2006-01-02T15:04:05.") + fmt.Sprintf("%06dZ", micro)
}

func archiveURL(raw string, when time.Time) string {
	when = when.UTC()
	return "https://web.archive.org/web/" + when.Format("20060102150405") + "/" + raw
}

func addError(errors map[string][]string, field, message string) {
	errors[field] = append(errors[field], message)
}

type bookmarkIn struct {
	present      map[string]bool
	URL          string
	Title        string
	Description  string
	Notes        string
	Unread       bool
	Shared       bool
	IsArchived   bool
	TagNames     []string
	DateAdded    time.Time
	DateModified time.Time
}

func takeText(data map[string]any, field string, errors map[string][]string, required, allowBlank bool, maxLen int) (string, bool) {
	value, ok := data[field]
	if !ok {
		if required {
			addError(errors, field, "This field is required.")
		}
		return "", false
	}
	if value == nil {
		addError(errors, field, "This field may not be null.")
		return "", true
	}
	text, ok := value.(string)
	if !ok {
		addError(errors, field, "Not a valid string.")
		return "", true
	}
	text = strings.TrimSpace(text)
	if text == "" && !allowBlank {
		addError(errors, field, "This field may not be blank.")
		return "", true
	}
	if maxLen > 0 && len([]rune(text)) > maxLen {
		addError(errors, field, fmt.Sprintf("Ensure this field has no more than %d characters.", maxLen))
		return "", true
	}
	return text, true
}

func takeURL(data map[string]any, errors map[string][]string, required bool) (string, bool) {
	value, ok := data["url"]
	if !ok {
		if required {
			addError(errors, "url", "This field is required.")
		}
		return "", false
	}
	if value == nil {
		addError(errors, "url", "This field may not be null.")
		return "", true
	}
	text, ok := value.(string)
	if !ok {
		addError(errors, "url", "Enter a valid URL.")
		return "", true
	}
	text = strings.TrimSpace(text)
	if text == "" {
		addError(errors, "url", "This field may not be blank.")
		return "", true
	}
	var messages []string
	if len(text) > 2048 || !validURL(text) {
		messages = append(messages, "Enter a valid URL.")
	}
	if len(text) > 2048 {
		messages = append(messages, "Ensure this field has no more than 2048 characters.")
	}
	if len(messages) > 0 {
		errors["url"] = messages
		return "", true
	}
	return text, true
}

func pyTypeName(value any) string {
	switch typed := value.(type) {
	case string:
		return "str"
	case bool:
		return "bool"
	case []any:
		return "list"
	case map[string]any:
		return "dict"
	case json.Number:
		if strings.Contains(typed.String(), ".") {
			return "float"
		}
		return "int"
	default:
		return "str"
	}
}

func validateBookmark(data map[string]any, partial bool) (map[string][]string, bookmarkIn) {
	errors := map[string][]string{}
	cleaned := bookmarkIn{present: map[string]bool{}}
	if url, present := takeURL(data, errors, !partial); present && errors["url"] == nil {
		cleaned.present["url"] = true
		cleaned.URL = url
	}
	for _, field := range []struct {
		name   string
		maxLen int
	}{{"title", 512}, {"description", 0}, {"notes", 0}} {
		text, present := takeText(data, field.name, errors, false, true, field.maxLen)
		if present && errors[field.name] == nil {
			cleaned.present[field.name] = true
			switch field.name {
			case "title":
				cleaned.Title = text
			case "description":
				cleaned.Description = text
			case "notes":
				cleaned.Notes = text
			}
		}
	}
	for _, field := range []string{"unread", "shared", "is_archived"} {
		value, ok := data[field]
		if !ok {
			continue
		}
		if value == nil {
			addError(errors, field, "This field may not be null.")
			continue
		}
		flag, good := parseBool(value)
		if !good {
			addError(errors, field, "Must be a valid boolean.")
			continue
		}
		cleaned.present[field] = true
		switch field {
		case "unread":
			cleaned.Unread = flag
		case "shared":
			cleaned.Shared = flag
		case "is_archived":
			cleaned.IsArchived = flag
		}
	}
	if value, ok := data["tag_names"]; ok {
		if value == nil {
			addError(errors, "tag_names", "This field may not be null.")
		} else if list, ok := value.([]any); ok {
			names := make([]string, 0, len(list))
			bad := false
			for _, item := range list {
				text, ok := item.(string)
				if !ok {
					addError(errors, "tag_names", "Not a valid string.")
					bad = true
					break
				}
				names = append(names, text)
			}
			if !bad {
				cleaned.present["tag_names"] = true
				cleaned.TagNames = names
			}
		} else {
			addError(errors, "tag_names", fmt.Sprintf("Expected a list of items but got type \"%s\".", pyTypeName(value)))
		}
	}
	for _, field := range []string{"date_added", "date_modified"} {
		value, ok := data[field]
		if !ok {
			continue
		}
		if value == nil {
			addError(errors, field, "This field may not be null.")
			continue
		}
		text, ok := value.(string)
		parsed, good := time.Time{}, false
		if ok {
			parsed, good = parseTime(text)
		}
		if !good {
			addError(errors, field, dtError)
			continue
		}
		cleaned.present[field] = true
		if field == "date_added" {
			cleaned.DateAdded = parsed
		} else {
			cleaned.DateModified = parsed
		}
	}
	return errors, cleaned
}

func validateTag(data map[string]any) (map[string][]string, string) {
	errors := map[string][]string{}
	name, _ := takeText(data, "name", errors, true, false, 64)
	if len(errors) > 0 {
		return errors, ""
	}
	return nil, name
}

type bundleIn struct {
	present      map[string]bool
	Name         string
	Search       string
	AnyTags      string
	AllTags      string
	ExcludedTags string
	FilterUnread string
	FilterShared string
	Order        int
}

func validateBundle(data map[string]any, partial bool) (map[string][]string, bundleIn) {
	errors := map[string][]string{}
	cleaned := bundleIn{present: map[string]bool{}}
	if name, present := takeText(data, "name", errors, !partial, false, 256); present && errors["name"] == nil {
		cleaned.present["name"] = true
		cleaned.Name = name
	}
	for _, field := range []struct {
		name   string
		maxLen int
	}{{"search", 256}, {"any_tags", 1024}, {"all_tags", 1024}, {"excluded_tags", 1024}} {
		text, present := takeText(data, field.name, errors, false, true, field.maxLen)
		if present && errors[field.name] == nil {
			cleaned.present[field.name] = true
			switch field.name {
			case "search":
				cleaned.Search = text
			case "any_tags":
				cleaned.AnyTags = text
			case "all_tags":
				cleaned.AllTags = text
			case "excluded_tags":
				cleaned.ExcludedTags = text
			}
		}
	}
	for _, field := range []string{"filter_unread", "filter_shared"} {
		value, ok := data[field]
		if !ok {
			continue
		}
		if value == nil {
			addError(errors, field, "This field may not be null.")
			continue
		}
		text, ok := value.(string)
		if !ok || !filterChoices[text] {
			shown := fmt.Sprint(value)
			addError(errors, field, fmt.Sprintf("\"%s\" is not a valid choice.", shown))
			continue
		}
		cleaned.present[field] = true
		if field == "filter_unread" {
			cleaned.FilterUnread = text
		} else {
			cleaned.FilterShared = text
		}
	}
	if value, ok := data["order"]; ok {
		if value == nil {
			addError(errors, "order", "This field may not be null.")
		} else if _, isBool := value.(bool); isBool {
			addError(errors, "order", "A valid integer is required.")
		} else if number, ok := value.(json.Number); ok {
			parsed, err := number.Int64()
			if err != nil {
				addError(errors, "order", "A valid integer is required.")
			} else {
				cleaned.present["order"] = true
				cleaned.Order = int(parsed)
			}
		} else {
			addError(errors, "order", "A valid integer is required.")
		}
	}
	return errors, cleaned
}

type expr interface{ expr() }

type termExpr struct{ term string }
type tagExpr struct{ tag string }
type keywordExpr struct{ keyword string }
type andExpr struct{ left, right expr }
type orExpr struct{ left, right expr }
type notExpr struct{ operand expr }

func (termExpr) expr()    {}
func (tagExpr) expr()     {}
func (keywordExpr) expr() {}
func (andExpr) expr()     {}
func (orExpr) expr()      {}
func (notExpr) expr()     {}

type searchTok struct{ kind, value string }

type tokenizer struct {
	query   string
	pos     int
	current rune
	width   int
	done    bool
}

func newTokenizer(query string) *tokenizer {
	t := &tokenizer{query: strings.TrimSpace(query)}
	t.pull()
	return t
}

func (t *tokenizer) pull() {
	if t.pos >= len(t.query) {
		t.done = true
		t.current = 0
		return
	}
	r, w := utf8.DecodeRuneInString(t.query[t.pos:])
	t.current = r
	t.width = w
}

func (t *tokenizer) advance() {
	if t.done {
		return
	}
	t.pos += t.width
	t.pull()
}

func (t *tokenizer) skip() {
	for !t.done && unicode.IsSpace(t.current) {
		t.advance()
	}
}

func (t *tokenizer) readTerm() string {
	var b strings.Builder
	for !t.done && !unicode.IsSpace(t.current) && !strings.ContainsRune("()\"'#!", t.current) {
		b.WriteRune(t.current)
		t.advance()
	}
	return b.String()
}

func (t *tokenizer) readQuoted(quote rune) string {
	var b strings.Builder
	t.advance()
	for !t.done && t.current != quote {
		if t.current == '\\' {
			t.advance()
			if t.done {
				break
			}
			switch t.current {
			case 'n':
				b.WriteRune('\n')
			case 't':
				b.WriteRune('\t')
			case 'r':
				b.WriteRune('\r')
			case '\\':
				b.WriteRune('\\')
			default:
				if t.current == quote {
					b.WriteRune(quote)
				} else {
					b.WriteRune(t.current)
				}
			}
			t.advance()
			continue
		}
		b.WriteRune(t.current)
		t.advance()
	}
	if !t.done && t.current == quote {
		t.advance()
	}
	return b.String()
}

func (t *tokenizer) readMarked() string {
	var b strings.Builder
	t.advance()
	for !t.done && !unicode.IsSpace(t.current) && !strings.ContainsRune("()\"'", t.current) {
		b.WriteRune(t.current)
		t.advance()
	}
	return b.String()
}

func (t *tokenizer) tokenize() []searchTok {
	tokens := make([]searchTok, 0)
	for !t.done {
		t.skip()
		if t.done {
			break
		}
		switch t.current {
		case '(':
			tokens = append(tokens, searchTok{"LPAREN", "("})
			t.advance()
		case ')':
			tokens = append(tokens, searchTok{"RPAREN", ")"})
			t.advance()
		case '"', '\'':
			tokens = append(tokens, searchTok{"TERM", t.readQuoted(t.current)})
		case '#':
			tag := t.readMarked()
			if tag != "" {
				tokens = append(tokens, searchTok{"TAG", tag})
			}
		case '!':
			keyword := t.readMarked()
			if keyword != "" {
				tokens = append(tokens, searchTok{"KEYWORD", keyword})
			}
		default:
			term := t.readTerm()
			switch strings.ToLower(term) {
			case "and":
				tokens = append(tokens, searchTok{"AND", term})
			case "or":
				tokens = append(tokens, searchTok{"OR", term})
			case "not":
				tokens = append(tokens, searchTok{"NOT", term})
			default:
				tokens = append(tokens, searchTok{"TERM", term})
			}
		}
	}
	tokens = append(tokens, searchTok{"EOF", ""})
	return tokens
}

type parser struct {
	tokens  []searchTok
	pos     int
	current searchTok
}

func (p *parser) advance() {
	if p.pos < len(p.tokens)-1 {
		p.pos++
		p.current = p.tokens[p.pos]
	}
}

func parseSearchQuery(query string) (expr, error) {
	if strings.TrimSpace(query) == "" {
		return nil, nil
	}
	tokens := newTokenizer(query).tokenize()
	p := &parser{tokens: tokens, current: tokens[0]}
	if len(tokens) == 1 {
		return nil, nil
	}
	node, err := p.parseOr()
	if err != nil {
		return nil, err
	}
	if p.current.kind != "EOF" {
		return nil, fmt.Errorf("parse")
	}
	return node, nil
}

func (p *parser) parseOr() (expr, error) {
	left, err := p.parseAnd()
	if err != nil {
		return nil, err
	}
	for p.current.kind == "OR" {
		p.advance()
		right, err := p.parseAnd()
		if err != nil {
			return nil, err
		}
		left = orExpr{left, right}
	}
	return left, nil
}

func (p *parser) parseAnd() (expr, error) {
	left, err := p.parseNot()
	if err != nil {
		return nil, err
	}
	for p.current.kind == "AND" || p.current.kind == "TERM" || p.current.kind == "TAG" || p.current.kind == "KEYWORD" || p.current.kind == "LPAREN" || p.current.kind == "NOT" {
		if p.current.kind == "AND" {
			p.advance()
		}
		right, err := p.parseNot()
		if err != nil {
			return nil, err
		}
		left = andExpr{left, right}
	}
	return left, nil
}

func (p *parser) parseNot() (expr, error) {
	if p.current.kind == "NOT" {
		p.advance()
		operand, err := p.parseNot()
		if err != nil {
			return nil, err
		}
		return notExpr{operand}, nil
	}
	return p.parsePrimary()
}

func (p *parser) parsePrimary() (expr, error) {
	switch p.current.kind {
	case "TERM":
		value := p.current.value
		p.advance()
		return termExpr{value}, nil
	case "TAG":
		value := p.current.value
		p.advance()
		return tagExpr{value}, nil
	case "KEYWORD":
		value := p.current.value
		p.advance()
		return keywordExpr{value}, nil
	case "LPAREN":
		p.advance()
		node, err := p.parseOr()
		if err != nil {
			return nil, err
		}
		if p.current.kind != "RPAREN" {
			return nil, fmt.Errorf("parse")
		}
		p.advance()
		return node, nil
	default:
		return nil, fmt.Errorf("parse")
	}
}

type legacyQuery struct {
	terms    []string
	tags     []string
	untagged bool
	unread   bool
}

func parseQueryString(query string) legacyQuery {
	words := strings.Split(strings.TrimSpace(query), " ")
	out := legacyQuery{}
	for _, word := range words {
		if word == "" {
			continue
		}
		switch {
		case strings.HasPrefix(word, "#"):
			out.tags = append(out.tags, word[1:])
		case strings.HasPrefix(word, "!"):
			if word == "!untagged" {
				out.untagged = true
			}
			if word == "!unread" {
				out.unread = true
			}
		default:
			out.terms = append(out.terms, word)
		}
	}
	out.tags = uniqueCI(out.tags)
	return out
}

func likeContains(text string) string {
	escaped := strings.ReplaceAll(text, `\`, `\\`)
	escaped = strings.ReplaceAll(escaped, "%", `\%`)
	escaped = strings.ReplaceAll(escaped, "_", `\_`)
	return "%" + escaped + "%"
}

func bind(params *[]any, value any) string {
	*params = append(*params, value)
	return fmt.Sprintf("$%d", len(*params))
}

const untaggedSQL = "NOT EXISTS (SELECT 1 FROM bookmark_tags bt WHERE bt.bookmark_id = b.id)"

func termSQL(term string, lax bool, params *[]any) string {
	placeholder := bind(params, likeContains(term))
	sql := fmt.Sprintf("(b.title ILIKE %s ESCAPE '\\' OR b.description ILIKE %s ESCAPE '\\' OR b.notes ILIKE %s ESCAPE '\\' OR b.url ILIKE %s ESCAPE '\\'", placeholder, placeholder, placeholder, placeholder)
	if lax {
		tagPlaceholder := bind(params, strings.ToLower(term))
		sql += " OR EXISTS (SELECT 1 FROM bookmark_tags bt JOIN tags t ON t.id = bt.tag_id WHERE bt.bookmark_id = b.id AND t.name_lower = " + tagPlaceholder + ")"
	}
	return sql + ")"
}

func tagSQL(tag string, params *[]any) string {
	placeholder := bind(params, strings.ToLower(tag))
	return "EXISTS (SELECT 1 FROM bookmark_tags bt JOIN tags t ON t.id = bt.tag_id WHERE bt.bookmark_id = b.id AND t.name_lower = " + placeholder + ")"
}

func compileExpr(node expr, lax bool, params *[]any) string {
	switch typed := node.(type) {
	case termExpr:
		return termSQL(typed.term, lax, params)
	case tagExpr:
		return tagSQL(typed.tag, params)
	case keywordExpr:
		switch strings.ToLower(typed.keyword) {
		case "unread":
			return "b.unread"
		case "untagged":
			return untaggedSQL
		default:
			return "TRUE"
		}
	case andExpr:
		return "(" + compileExpr(typed.left, lax, params) + " AND " + compileExpr(typed.right, lax, params) + ")"
	case orExpr:
		return "(" + compileExpr(typed.left, lax, params) + " OR " + compileExpr(typed.right, lax, params) + ")"
	case notExpr:
		return "(NOT (" + compileExpr(typed.operand, lax, params) + "))"
	default:
		return "TRUE"
	}
}

func compileLegacy(query string, lax bool, params *[]any) string {
	parts := parseQueryString(query)
	conds := make([]string, 0)
	for _, term := range parts.terms {
		conds = append(conds, termSQL(term, lax, params))
	}
	for _, tag := range parts.tags {
		conds = append(conds, tagSQL(tag, params))
	}
	if parts.untagged {
		conds = append(conds, untaggedSQL)
	}
	if parts.unread {
		conds = append(conds, "b.unread")
	}
	if len(conds) == 0 {
		return ""
	}
	return "(" + strings.Join(conds, " AND ") + ")"
}

func searchSQL(query string, legacy, lax bool, params *[]any) string {
	if legacy {
		return compileLegacy(query, lax, params)
	}
	ast, err := parseSearchQuery(query)
	if err != nil {
		return "FALSE"
	}
	if ast == nil {
		return ""
	}
	return compileExpr(ast, lax, params)
}

func bundleSearchSQL(search string, params *[]any) string {
	parts := parseQueryString(search)
	if len(parts.terms) == 0 {
		return ""
	}
	conds := make([]string, 0, len(parts.terms))
	for _, term := range parts.terms {
		conds = append(conds, termSQL(term, false, params))
	}
	return "(" + strings.Join(conds, " AND ") + ")"
}

func orderSQL(sortKey string) string {
	switch sortKey {
	case "added_asc":
		return "b.date_added ASC"
	case "added_desc":
		return "b.date_added DESC"
	case "modified_asc":
		return "b.date_modified ASC"
	case "modified_desc":
		return "b.date_modified DESC"
	case "title_asc":
		return "lower(CASE WHEN b.title <> '' THEN b.title ELSE b.url END) ASC"
	case "title_desc":
		return "lower(CASE WHEN b.title <> '' THEN b.title ELSE b.url END) DESC"
	default:
		return "b.date_added DESC"
	}
}
