package main

import (
	"strconv"
	"unicode/utf8"
)

const (
	bcryptCost  = 12
	minPassword = 8
)

type apiError struct {
	Status  int
	Field   string
	Message string
}

func (e *apiError) Error() string { return e.Message }

func errAPI(status int, field, message string) *apiError {
	return &apiError{Status: status, Field: field, Message: message}
}

func slugify(title string) string {
	raw := []byte(title)
	out := make([]byte, 0, len(raw))
	prevHyphen := true
	for _, c := range raw {
		if c >= 'A' && c <= 'Z' {
			c += 32
		}
		if (c >= 'a' && c <= 'z') || (c >= '0' && c <= '9') {
			out = append(out, c)
			prevHyphen = false
		} else if c == ' ' || c == '\t' || c == '\n' || c == '\r' || c == '-' || c == '_' {
			if !prevHyphen {
				out = append(out, '-')
				prevHyphen = true
			}
		}
	}
	for len(out) > 0 && out[len(out)-1] == '-' {
		out = out[:len(out)-1]
	}
	if len(out) == 0 {
		return "article"
	}
	return string(out)
}

func withSuffix(base string, n int) string {
	if n == 0 {
		return base
	}
	return base + "-" + strconv.Itoa(n)
}

func classify(obj map[string]any, key string) (string, string, error) {
	raw, ok := obj[key]
	if !ok {
		return "absent", "", nil
	}
	if raw == nil {
		return "null", "", nil
	}
	s, ok := raw.(string)
	if !ok {
		return "", "", errAPI(422, key, "is invalid")
	}
	if s == "" {
		return "blank", "", nil
	}
	return "value", s, nil
}

func requireNewText(obj map[string]any, key string) (string, error) {
	kind, val, err := classify(obj, key)
	if err != nil {
		return "", err
	}
	if kind != "value" {
		return "", errAPI(422, key, "can't be blank")
	}
	return val, nil
}

func optionalText(obj map[string]any, key string) (string, string, error) {
	kind, val, err := classify(obj, key)
	if err != nil {
		return "", "", err
	}
	if kind == "absent" {
		return "absent", "", nil
	}
	if kind == "null" || kind == "blank" {
		return "clear", "", nil
	}
	return "set", val, nil
}

func optionalRequiredText(obj map[string]any, key string) (string, string, error) {
	kind, val, err := classify(obj, key)
	if err != nil {
		return "", "", err
	}
	if kind == "absent" {
		return "absent", "", nil
	}
	if kind != "value" {
		return "", "", errAPI(422, key, "can't be blank")
	}
	return "set", val, nil
}

func checkPasswordValue(password string) error {
	if utf8.RuneCountInString(password) < minPassword && len(password) < minPassword {
		return errAPI(422, "password", "is too short (minimum is 8 characters)")
	}
	if len(password) < minPassword {
		return errAPI(422, "password", "is too short (minimum is 8 characters)")
	}
	return nil
}

func registerFields(user map[string]any) (string, string, string, error) {
	username, err := requireNewText(user, "username")
	if err != nil {
		return "", "", "", err
	}
	email, err := requireNewText(user, "email")
	if err != nil {
		return "", "", "", err
	}
	password, err := requireNewText(user, "password")
	if err != nil {
		return "", "", "", err
	}
	if err := checkPasswordValue(password); err != nil {
		return "", "", "", err
	}
	return username, email, password, nil
}

func loginFields(user map[string]any) (string, string, error) {
	email, err := requireNewText(user, "email")
	if err != nil {
		return "", "", err
	}
	kind, val, err := classify(user, "password")
	if err != nil {
		return "", "", err
	}
	if kind != "value" {
		return "", "", errAPI(422, "password", "can't be blank")
	}
	return email, val, nil
}

type fieldVal struct {
	Kind string
	Val  string
}

type userUpdate struct {
	Username fieldVal
	Email    fieldVal
	Password fieldVal
	Bio      fieldVal
	Image    fieldVal
}

func updateUserFields(user map[string]any) (userUpdate, error) {
	var out userUpdate
	var err error
	out.Username.Kind, out.Username.Val, err = optionalRequiredText(user, "username")
	if err != nil {
		return out, err
	}
	out.Email.Kind, out.Email.Val, err = optionalRequiredText(user, "email")
	if err != nil {
		return out, err
	}
	kind, val, err := classify(user, "password")
	if err != nil {
		return out, err
	}
	switch kind {
	case "absent":
		out.Password.Kind = "absent"
	case "value":
		if err := checkPasswordValue(val); err != nil {
			return out, err
		}
		out.Password = fieldVal{Kind: "set", Val: val}
	default:
		return out, errAPI(422, "password", "can't be blank")
	}
	out.Bio.Kind, out.Bio.Val, err = optionalText(user, "bio")
	if err != nil {
		return out, err
	}
	out.Image.Kind, out.Image.Val, err = optionalText(user, "image")
	if err != nil {
		return out, err
	}
	if out.Username.Kind == "absent" && out.Email.Kind == "absent" && out.Password.Kind == "absent" && out.Bio.Kind == "absent" && out.Image.Kind == "absent" {
		return out, errAPI(422, "user", "is invalid")
	}
	return out, nil
}

type tagField struct {
	Kind string
	Tags []string
}

type articleUpdate struct {
	Title       fieldVal
	Description fieldVal
	Body        fieldVal
	Tags        tagField
}

func parseTagList(article map[string]any) (tagField, error) {
	raw, ok := article["tagList"]
	if !ok {
		return tagField{Kind: "absent"}, nil
	}
	if raw == nil {
		return tagField{}, errAPI(422, "tagList", "is invalid")
	}
	arr, ok := raw.([]any)
	if !ok {
		return tagField{}, errAPI(422, "tagList", "is invalid")
	}
	seen := map[string]struct{}{}
	tags := make([]string, 0, len(arr))
	for _, item := range arr {
		s, ok := item.(string)
		if !ok {
			return tagField{}, errAPI(422, "tagList", "is invalid")
		}
		if s == "" {
			continue
		}
		if _, dup := seen[s]; dup {
			continue
		}
		seen[s] = struct{}{}
		tags = append(tags, s)
	}
	return tagField{Kind: "replace", Tags: tags}, nil
}

func articleCreateFields(article map[string]any) (string, string, string, []string, error) {
	title, err := requireNewText(article, "title")
	if err != nil {
		return "", "", "", nil, err
	}
	description, err := requireNewText(article, "description")
	if err != nil {
		return "", "", "", nil, err
	}
	body, err := requireNewText(article, "body")
	if err != nil {
		return "", "", "", nil, err
	}
	tags, err := parseTagList(article)
	if err != nil {
		return "", "", "", nil, err
	}
	if tags.Kind == "absent" {
		tags.Tags = []string{}
	}
	return title, description, body, tags.Tags, nil
}

func articleUpdateFields(article map[string]any) (articleUpdate, error) {
	var out articleUpdate
	var err error
	out.Title.Kind, out.Title.Val, err = optionalRequiredText(article, "title")
	if err != nil {
		return out, err
	}
	out.Description.Kind, out.Description.Val, err = optionalRequiredText(article, "description")
	if err != nil {
		return out, err
	}
	out.Body.Kind, out.Body.Val, err = optionalRequiredText(article, "body")
	if err != nil {
		return out, err
	}
	out.Tags, err = parseTagList(article)
	if err != nil {
		return out, err
	}
	if out.Title.Kind == "absent" && out.Description.Kind == "absent" && out.Body.Kind == "absent" && out.Tags.Kind == "absent" {
		return out, errAPI(422, "article", "is invalid")
	}
	return out, nil
}

func commentBody(comment map[string]any) (string, error) {
	return requireNewText(comment, "body")
}

func pageParams(limitRaw, offsetRaw string) (int, int, error) {
	limit := 20
	offset := 0
	if limitRaw != "" {
		n, err := strconv.Atoi(limitRaw)
		if err != nil || n < 1 {
			return 0, 0, errAPI(422, "limit", "is invalid")
		}
		if n > 100 {
			n = 100
		}
		limit = n
	}
	if offsetRaw != "" {
		n, err := strconv.Atoi(offsetRaw)
		if err != nil || n < 0 {
			return 0, 0, errAPI(422, "offset", "is invalid")
		}
		offset = n
	}
	return limit, offset, nil
}
