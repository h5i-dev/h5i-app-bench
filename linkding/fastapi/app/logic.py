"""Pure linkding API decisions: URLs, tags, search, validation, pagination.

The rules follow linkding 1.47.0 (bookmarks/api, bookmarks/queries.py,
bookmarks/services/search_query_parser.py, bookmarks/utils.py). Nothing here
performs network or database I/O.
"""

from __future__ import annotations

import socket
import urllib.parse
from dataclasses import dataclass

APP_VERSION = "1.47.0"
PAGE_SIZE = 100

TRUE_VALUES = {
    True,
    1,
    "t",
    "T",
    "y",
    "Y",
    "yes",
    "YES",
    "Yes",
    "true",
    "True",
    "TRUE",
    "on",
    "On",
    "ON",
    "1",
}
FALSE_VALUES = {
    False,
    0,
    "f",
    "F",
    "n",
    "N",
    "no",
    "NO",
    "No",
    "false",
    "False",
    "FALSE",
    "off",
    "Off",
    "OFF",
    "0",
}

DT_ERROR = (
    "Datetime has wrong format. Use one of these formats instead: "
    "YYYY-MM-DDThh:mm[:ss[.uuuuuu]][+HH:MM|-HH:MM|Z]."
)

FILTER_CHOICES = ("off", "yes", "no")


def unique_ci(items: list[str]) -> list[str]:
    """First key position, last casing. Matches bookmarks.utils.unique."""
    seen: dict[str, str] = {}
    for item in items:
        seen[item.lower()] = item
    return list(seen.values())


def sanitize_tag_name(name: str) -> str:
    return name.strip().replace(" ", "-")


def parse_tag_string(tag_string: str, delimiter: str = ",") -> list[str]:
    if not tag_string:
        return []
    names = tag_string.strip().split(delimiter)
    names = [sanitize_tag_name(name) for name in names if name.strip()]
    names = unique_ci(names)
    names.sort(key=str.lower)
    return names


def build_tag_string(tag_names: list[str], delimiter: str = ",") -> str:
    return delimiter.join(tag_names)


def bookmark_tag_names(raw_names: list[str]) -> list[str]:
    return parse_tag_string(build_tag_string(raw_names))


def normalize_url(url: str) -> str:
    if not url or not isinstance(url, str):
        return ""
    url = url.strip()
    if not url:
        return ""
    try:
        parsed = urllib.parse.urlparse(url)
        scheme = parsed.scheme.lower()
        netloc = parsed.hostname.lower() if parsed.hostname else ""
        if parsed.port:
            netloc += f":{parsed.port}"
        if parsed.username:
            auth = parsed.username
            if parsed.password:
                auth += f":{parsed.password}"
            netloc = f"{auth}@{netloc}"
        path = parsed.path.rstrip("/") if parsed.path else ""
        query = ""
        if parsed.query:
            query_params = urllib.parse.parse_qsl(parsed.query, keep_blank_values=True)
            query_params.sort(key=lambda item: (item[0], item[1]))
            query = urllib.parse.urlencode(query_params, quote_via=urllib.parse.quote)
        return urllib.parse.urlunparse(
            (scheme, netloc, path, parsed.params, query, parsed.fragment)
        )
    except (ValueError, AttributeError):
        return url


def _is_ipv4(host: str) -> bool:
    parts = host.split(".")
    if len(parts) != 4:
        return False
    for part in parts:
        if not part.isdigit():
            return False
        if len(part) > 1 and part[0] == "0":
            return False
        if int(part) > 255:
            return False
    return True


def _is_ipv6(host: str) -> bool:
    if ":" not in host:
        return False
    try:
        socket.inet_pton(socket.AF_INET6, host)
    except OSError:
        return False
    return True


def _label_ok(label: str, tld: bool) -> bool:
    if not label or len(label) > 63:
        return False
    if label.startswith("-") or label.endswith("-"):
        return False
    if tld and label.startswith("xn--"):
        rest = label[4:]
        return 1 <= len(rest) <= 59 and rest.isascii() and rest.isalnum()
    for char in label:
        if char.isalnum() or char == "-" or ord(char) >= 0xA1:
            continue
        return False
    if tld and not label.startswith("xn--") and len(label) < 2:
        return False
    return True


def _is_domain(host: str) -> bool:
    if host.endswith("."):
        host = host[:-1]
    if not host or len(host) > 253:
        return False
    labels = host.split(".")
    if len(labels) < 2:
        return False
    for index, label in enumerate(labels):
        if not _label_ok(label, index == len(labels) - 1):
            return False
    return True


def valid_url(value: str) -> bool:
    """Django URLValidator for http, https, ftp, and ftps, without lookaround."""
    if not isinstance(value, str) or len(value) > 2048:
        return False
    if any(char in value for char in "\t\r\n"):
        return False
    if "://" not in value:
        return False
    scheme = value.split("://", 1)[0].lower()
    if scheme not in ("http", "https", "ftp", "ftps"):
        return False
    try:
        parts = urllib.parse.urlsplit(value)
    except ValueError:
        return False
    host = parts.hostname
    if host is None or len(host) > 253:
        return False
    host_l = host.lower()
    if host_l != "localhost" and not _is_ipv4(host_l) and not _is_ipv6(host) and not _is_domain(host_l):
        return False
    try:
        if parts.port is not None and not 0 <= parts.port <= 65535:
            return False
    except ValueError:
        return False
    return True


def replace_query_param(url: str, key: str, val) -> str:
    scheme, netloc, path, query, fragment = urllib.parse.urlsplit(url)
    query_dict = urllib.parse.parse_qs(query, keep_blank_values=True)
    query_dict[str(key)] = [str(val)]
    query = urllib.parse.urlencode(sorted(query_dict.items()), doseq=True)
    return urllib.parse.urlunsplit((scheme, netloc, path, query, fragment))


def remove_query_param(url: str, key: str) -> str:
    scheme, netloc, path, query, fragment = urllib.parse.urlsplit(url)
    query_dict = urllib.parse.parse_qs(query, keep_blank_values=True)
    query_dict.pop(key, None)
    query = urllib.parse.urlencode(sorted(query_dict.items()), doseq=True)
    return urllib.parse.urlunsplit((scheme, netloc, path, query, fragment))


def resolve_limit(raw: str | None) -> int:
    if raw is None or raw == "":
        return PAGE_SIZE
    try:
        number = int(raw)
    except ValueError:
        return PAGE_SIZE
    if number <= 0:
        return PAGE_SIZE
    return number


def resolve_offset(raw: str | None) -> int:
    if raw is None or raw == "":
        return 0
    try:
        number = int(raw)
    except ValueError:
        return 0
    if number < 0:
        return 0
    return number


def page_links(url: str, limit: int, offset: int, count: int) -> tuple[str | None, str | None]:
    if offset + limit < count:
        nxt = replace_query_param(replace_query_param(url, "limit", limit), "offset", offset + limit)
    else:
        nxt = None
    if offset > 0:
        base = replace_query_param(url, "limit", limit)
        if offset - limit <= 0:
            prev = remove_query_param(base, "offset")
        else:
            prev = replace_query_param(base, "offset", offset - limit)
    else:
        prev = None
    return nxt, prev


def classify_auth(header: str | None) -> tuple[str, str | None]:
    """Return (kind, token). kind is absent, nocreds, spaces, or token."""
    if not header or not header.strip():
        return ("absent", None)
    parts = header.split()
    if not parts or parts[0].lower() not in ("token", "bearer"):
        return ("absent", None)
    if len(parts) == 1:
        return ("nocreds", None)
    if len(parts) > 2:
        return ("spaces", None)
    return ("token", parts[1])


AUTH_DETAIL = {
    "absent": "Authentication credentials were not provided.",
    "nocreds": "Invalid token header. No credentials provided.",
    "spaces": "Invalid token header. Token string should not contain spaces.",
    "bad": "Invalid token.",
}


def parse_bool(value):
    if value in TRUE_VALUES:
        return True
    if value in FALSE_VALUES:
        return False
    return None


def _py_type_name(value) -> str:
    if isinstance(value, bool):
        return "bool"
    if isinstance(value, int):
        return "int"
    if isinstance(value, float):
        return "float"
    if isinstance(value, str):
        return "str"
    if isinstance(value, list):
        return "list"
    if isinstance(value, dict):
        return "dict"
    return type(value).__name__


def parse_datetime(value):
    from datetime import datetime, timezone

    if not isinstance(value, str):
        return None
    text = value.strip()
    if text.endswith("Z"):
        text = text[:-1] + "+00:00"
    try:
        parsed = datetime.fromisoformat(text)
    except ValueError:
        return None
    if parsed.tzinfo is None:
        parsed = parsed.replace(tzinfo=timezone.utc)
    return parsed.astimezone(timezone.utc)


def fmt_dt(value) -> str:
    from datetime import timezone

    if value.tzinfo is None:
        value = value.replace(tzinfo=timezone.utc)
    value = value.astimezone(timezone.utc)
    if value.microsecond:
        return value.strftime("%Y-%m-%dT%H:%M:%S.") + f"{value.microsecond:06d}Z"
    return value.strftime("%Y-%m-%dT%H:%M:%SZ")


def archive_url(url: str, when) -> str:
    from datetime import timezone

    if when.tzinfo is None:
        when = when.replace(tzinfo=timezone.utc)
    when = when.astimezone(timezone.utc)
    stamp = when.strftime("%Y%m%d%H%M%S")
    return f"https://web.archive.org/web/{stamp}/{url}"


def _add(errors: dict, field: str, message: str) -> None:
    errors.setdefault(field, []).append(message)


def _take_text(data, field, errors, *, required: bool, allow_blank: bool, max_len: int | None):
    if field not in data:
        if required:
            _add(errors, field, "This field is required.")
        return None, False
    value = data[field]
    if value is None:
        _add(errors, field, "This field may not be null.")
        return None, True
    if not isinstance(value, str):
        _add(errors, field, "Not a valid string.")
        return None, True
    value = value.strip()
    if value == "" and not allow_blank:
        _add(errors, field, "This field may not be blank.")
        return None, True
    if max_len is not None and len(value) > max_len:
        _add(errors, field, f"Ensure this field has no more than {max_len} characters.")
        return None, True
    return value, True


def _take_url(data, errors, *, required: bool):
    if "url" not in data:
        if required:
            _add(errors, "url", "This field is required.")
        return None, False
    value = data["url"]
    if value is None:
        _add(errors, "url", "This field may not be null.")
        return None, True
    if not isinstance(value, str):
        _add(errors, "url", "Enter a valid URL.")
        return None, True
    value = value.strip()
    if value == "":
        _add(errors, "url", "This field may not be blank.")
        return None, True
    messages = []
    if len(value) > 2048 or not valid_url(value):
        messages.append("Enter a valid URL.")
    if len(value) > 2048:
        messages.append("Ensure this field has no more than 2048 characters.")
    if messages:
        errors["url"] = messages
        return None, True
    return value, True


def _take_bool(data, field, errors):
    if field not in data:
        return None, False
    value = data[field]
    if value is None:
        _add(errors, field, "This field may not be null.")
        return None, True
    parsed = parse_bool(value)
    if parsed is None:
        _add(errors, field, "Must be a valid boolean.")
        return None, True
    return parsed, True


def _take_tags(data, errors):
    if "tag_names" not in data:
        return None, False
    value = data["tag_names"]
    if value is None:
        _add(errors, "tag_names", "This field may not be null.")
        return None, True
    if not isinstance(value, list):
        _add(
            errors,
            "tag_names",
            f'Expected a list of items but got type "{_py_type_name(value)}".',
        )
        return None, True
    names = []
    for item in value:
        if not isinstance(item, str):
            _add(errors, "tag_names", "Not a valid string.")
            return None, True
        names.append(item)
    return names, True


def _take_dt(data, field, errors):
    if field not in data:
        return None, False
    value = data[field]
    if value is None:
        _add(errors, field, "This field may not be null.")
        return None, True
    parsed = parse_datetime(value)
    if parsed is None:
        _add(errors, field, DT_ERROR)
        return None, True
    return parsed, True


def validate_bookmark(data: dict, *, partial: bool) -> tuple[dict, dict]:
    """Return (errors, cleaned). cleaned includes only fields that were present and valid.

    On create (partial False) url is required. Omitted optional fields are absent
    from cleaned; the caller applies model defaults.
    """
    if not isinstance(data, dict):
        return {"non_field_errors": ["Invalid data. Expected a dictionary, but got list."]}, {}
    errors: dict = {}
    cleaned: dict = {}
    url, present = _take_url(data, errors, required=not partial)
    if present and "url" not in errors:
        cleaned["url"] = url
    for field, max_len in (("title", 512), ("description", None), ("notes", None)):
        text, present = _take_text(
            data, field, errors, required=False, allow_blank=True, max_len=max_len
        )
        if present and field not in errors:
            cleaned[field] = text
    for field in ("unread", "shared", "is_archived"):
        flag, present = _take_bool(data, field, errors)
        if present and field not in errors:
            cleaned[field] = flag
    tags, present = _take_tags(data, errors)
    if present and "tag_names" not in errors:
        cleaned["tag_names"] = tags
    for field in ("date_added", "date_modified"):
        when, present = _take_dt(data, field, errors)
        if present and field not in errors:
            cleaned[field] = when
    return errors, cleaned


def validate_tag(data: dict) -> tuple[dict, str | None]:
    if not isinstance(data, dict):
        return {"non_field_errors": ["Invalid data. Expected a dictionary, but got list."]}, None
    errors: dict = {}
    name, _present = _take_text(
        data, "name", errors, required=True, allow_blank=False, max_len=64
    )
    if errors:
        return errors, None
    return {}, name


def _choice(data, field, errors, *, required: bool):
    if field not in data:
        if required:
            _add(errors, field, "This field is required.")
        return None, False
    value = data[field]
    if value is None:
        _add(errors, field, "This field may not be null.")
        return None, True
    if not isinstance(value, str):
        _add(errors, field, f'"{value}" is not a valid choice.')
        return None, True
    if value not in FILTER_CHOICES:
        _add(errors, field, f'"{value}" is not a valid choice.')
        return None, True
    return value, True


def validate_bundle(data: dict, *, partial: bool) -> tuple[dict, dict]:
    if not isinstance(data, dict):
        return {"non_field_errors": ["Invalid data. Expected a dictionary, but got list."]}, {}
    errors: dict = {}
    cleaned: dict = {}
    name, present = _take_text(
        data, "name", errors, required=not partial, allow_blank=False, max_len=256
    )
    if present and "name" not in errors:
        cleaned["name"] = name
    for field, max_len in (("search", 256), ("any_tags", 1024), ("all_tags", 1024), ("excluded_tags", 1024)):
        text, present = _take_text(
            data, field, errors, required=False, allow_blank=True, max_len=max_len
        )
        if present and field not in errors:
            cleaned[field] = text
    for field in ("filter_unread", "filter_shared"):
        choice, present = _choice(data, field, errors, required=False)
        if present and field not in errors:
            cleaned[field] = choice
    if "order" in data:
        value = data["order"]
        if value is None:
            _add(errors, "order", "This field may not be null.")
        elif isinstance(value, bool) or not isinstance(value, int):
            _add(errors, "order", "A valid integer is required.")
        else:
            cleaned["order"] = value
    return errors, cleaned


# --- search query -----------------------------------------------------------

class SearchQueryParseError(Exception):
    pass


@dataclass
class TermExpr:
    term: str


@dataclass
class TagExpr:
    tag: str


@dataclass
class KeywordExpr:
    keyword: str


@dataclass
class AndExpr:
    left: object
    right: object


@dataclass
class OrExpr:
    left: object
    right: object


@dataclass
class NotExpr:
    operand: object


class _Tok:
    def __init__(self, kind: str, value: str):
        self.kind = kind
        self.value = value


def _is_space(char: str) -> bool:
    return char.isspace()


class _Tokenizer:
    def __init__(self, query: str):
        self.query = query.strip()
        self.position = 0
        self.current = self.query[0] if self.query else None

    def advance(self):
        self.position += 1
        if self.position >= len(self.query):
            self.current = None
        else:
            self.current = self.query[self.position]

    def skip(self):
        while self.current and _is_space(self.current):
            self.advance()

    def read_term(self) -> str:
        out = []
        while self.current and not _is_space(self.current) and self.current not in "()\"'#!":
            out.append(self.current)
            self.advance()
        return "".join(out)

    def read_quoted(self, quote: str) -> str:
        out = []
        self.advance()
        while self.current and self.current != quote:
            if self.current == "\\":
                self.advance()
                if self.current:
                    mapping = {"n": "\n", "t": "\t", "r": "\r", "\\": "\\", quote: quote}
                    out.append(mapping.get(self.current, self.current))
                    self.advance()
            else:
                out.append(self.current)
                self.advance()
        if self.current == quote:
            self.advance()
        return "".join(out)

    def read_marked(self) -> str:
        out = []
        self.advance()
        while self.current and not _is_space(self.current) and self.current not in "()\"'":
            out.append(self.current)
            self.advance()
        return "".join(out)

    def tokenize(self) -> list[_Tok]:
        tokens = []
        while self.current:
            self.skip()
            if not self.current:
                break
            char = self.current
            if char == "(":
                tokens.append(_Tok("LPAREN", "("))
                self.advance()
            elif char == ")":
                tokens.append(_Tok("RPAREN", ")"))
                self.advance()
            elif char in "\"'":
                tokens.append(_Tok("TERM", self.read_quoted(char)))
            elif char == "#":
                tag = self.read_marked()
                if tag:
                    tokens.append(_Tok("TAG", tag))
            elif char == "!":
                keyword = self.read_marked()
                if keyword:
                    tokens.append(_Tok("KEYWORD", keyword))
            else:
                term = self.read_term()
                lower = term.lower()
                if lower == "and":
                    tokens.append(_Tok("AND", term))
                elif lower == "or":
                    tokens.append(_Tok("OR", term))
                elif lower == "not":
                    tokens.append(_Tok("NOT", term))
                else:
                    tokens.append(_Tok("TERM", term))
        tokens.append(_Tok("EOF", ""))
        return tokens


class _Parser:
    def __init__(self, tokens: list[_Tok]):
        self.tokens = tokens
        self.position = 0
        self.current = tokens[0]

    def advance(self):
        if self.position < len(self.tokens) - 1:
            self.position += 1
            self.current = self.tokens[self.position]

    def parse(self):
        if len(self.tokens) == 1:
            return None
        expr = self.parse_or()
        if self.current.kind != "EOF":
            raise SearchQueryParseError(self.current.kind)
        return expr

    def parse_or(self):
        left = self.parse_and()
        while self.current.kind == "OR":
            self.advance()
            right = self.parse_and()
            left = OrExpr(left, right)
        return left

    def parse_and(self):
        left = self.parse_not()
        while self.current.kind == "AND" or self.current.kind in (
            "TERM",
            "TAG",
            "KEYWORD",
            "LPAREN",
            "NOT",
        ):
            if self.current.kind == "AND":
                self.advance()
            right = self.parse_not()
            left = AndExpr(left, right)
        return left

    def parse_not(self):
        if self.current.kind == "NOT":
            self.advance()
            return NotExpr(self.parse_not())
        return self.parse_primary()

    def parse_primary(self):
        kind = self.current.kind
        if kind == "TERM":
            value = self.current.value
            self.advance()
            return TermExpr(value)
        if kind == "TAG":
            value = self.current.value
            self.advance()
            return TagExpr(value)
        if kind == "KEYWORD":
            value = self.current.value
            self.advance()
            return KeywordExpr(value)
        if kind == "LPAREN":
            self.advance()
            expr = self.parse_or()
            if self.current.kind != "RPAREN":
                raise SearchQueryParseError("RPAREN")
            self.advance()
            return expr
        raise SearchQueryParseError(kind)


def parse_search_query(query: str):
    if not query or not query.strip():
        return None
    tokens = _Tokenizer(query).tokenize()
    return _Parser(tokens).parse()


def parse_query_string(query_string: str) -> dict:
    """Legacy splitter. Tags in the string are returned but bundle search ignores them."""
    if not query_string:
        query_string = ""
    keywords = [word for word in query_string.strip().split(" ") if word]
    search_terms = [word for word in keywords if not word.startswith("#") and not word.startswith("!")]
    tag_names = [word[1:] for word in keywords if word.startswith("#")]
    tag_names = unique_ci(tag_names)
    return {
        "search_terms": search_terms,
        "tag_names": tag_names,
        "untagged": "!untagged" in keywords,
        "unread": "!unread" in keywords,
    }


def like_contains(text: str) -> str:
    escaped = text.replace("\\", "\\\\").replace("%", "\\%").replace("_", "\\_")
    return f"%{escaped}%"


def _bind(params: list, value) -> str:
    params.append(value)
    return f"${len(params)}"


UNTAGGED_SQL = "NOT EXISTS (SELECT 1 FROM bookmark_tags bt WHERE bt.bookmark_id = b.id)"


def term_sql(term: str, lax: bool, params: list) -> str:
    placeholder = _bind(params, like_contains(term))
    sql = (
        f"(b.title ILIKE {placeholder} ESCAPE '\\' OR b.description ILIKE {placeholder} ESCAPE '\\' "
        f"OR b.notes ILIKE {placeholder} ESCAPE '\\' OR b.url ILIKE {placeholder} ESCAPE '\\'"
    )
    if lax:
        tag_placeholder = _bind(params, term.lower())
        sql += (
            " OR EXISTS (SELECT 1 FROM bookmark_tags bt JOIN tags t ON t.id = bt.tag_id "
            f"WHERE bt.bookmark_id = b.id AND t.name_lower = {tag_placeholder})"
        )
    return sql + ")"


def tag_sql(tag: str, params: list) -> str:
    placeholder = _bind(params, tag.lower())
    return (
        "EXISTS (SELECT 1 FROM bookmark_tags bt JOIN tags t ON t.id = bt.tag_id "
        f"WHERE bt.bookmark_id = b.id AND t.name_lower = {placeholder})"
    )


def compile_expr(node, lax: bool, params: list) -> str:
    if isinstance(node, TermExpr):
        return term_sql(node.term, lax, params)
    if isinstance(node, TagExpr):
        return tag_sql(node.tag, params)
    if isinstance(node, KeywordExpr):
        keyword = node.keyword.lower()
        if keyword == "unread":
            return "b.unread"
        if keyword == "untagged":
            return UNTAGGED_SQL
        return "TRUE"
    if isinstance(node, AndExpr):
        return f"({compile_expr(node.left, lax, params)} AND {compile_expr(node.right, lax, params)})"
    if isinstance(node, OrExpr):
        return f"({compile_expr(node.left, lax, params)} OR {compile_expr(node.right, lax, params)})"
    if isinstance(node, NotExpr):
        return f"(NOT ({compile_expr(node.operand, lax, params)}))"
    return "TRUE"


def compile_legacy(query: str, lax: bool, params: list) -> str | None:
    parts = parse_query_string(query)
    conds = [term_sql(term, lax, params) for term in parts["search_terms"]]
    conds.extend(tag_sql(tag, params) for tag in parts["tag_names"])
    if parts["untagged"]:
        conds.append(UNTAGGED_SQL)
    if parts["unread"]:
        conds.append("b.unread")
    if not conds:
        return None
    return "(" + " AND ".join(conds) + ")"


def search_sql(query: str, *, legacy: bool, lax: bool, params: list) -> str | None:
    """SQL boolean, 'FALSE' when the query cannot be parsed, or None when it matches all."""
    if legacy:
        return compile_legacy(query or "", lax, params)
    try:
        ast = parse_search_query(query or "")
    except SearchQueryParseError:
        return "FALSE"
    if ast is None:
        return None
    return compile_expr(ast, lax, params)


def bundle_search_sql(search: str, params: list) -> str | None:
    parts = parse_query_string(search or "")
    conds = [term_sql(term, False, params) for term in parts["search_terms"]]
    if not conds:
        return None
    return "(" + " AND ".join(conds) + ")"


SORTS = {
    "added_asc": "b.date_added ASC",
    "added_desc": "b.date_added DESC",
    "modified_asc": "b.date_modified ASC",
    "modified_desc": "b.date_modified DESC",
    "title_asc": "lower(CASE WHEN b.title <> '' THEN b.title ELSE b.url END) ASC",
    "title_desc": "lower(CASE WHEN b.title <> '' THEN b.title ELSE b.url END) DESC",
}


def order_sql(sort: str | None) -> str:
    if not sort:
        return SORTS["added_desc"]
    return SORTS.get(sort, SORTS["added_desc"])
