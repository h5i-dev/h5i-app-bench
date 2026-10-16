"""Pure Conduit decisions shared by the FastAPI shell.

Slug rules match performance/realworld/rust-h5i/kernel (ASCII, hyphen-collapsed).
Validation matches the RealWorld Hurl suite: blank fields are rejected,
empty bio/image become null, passwords are at least 8 bytes when set.
"""

from __future__ import annotations

BCRYPT_COST = 12
MIN_PASSWORD = 8


class ApiError(Exception):
    def __init__(self, status: int, field: str, message: str):
        super().__init__(f"{status} {field}: {message}")
        self.status = status
        self.field = field
        self.message = message


def slugify(title: str) -> str:
    raw = title.encode("utf-8")
    out: list[str] = []
    prev_hyphen = True
    for c in raw:
        if 65 <= c <= 90:
            c += 32
        if (97 <= c <= 122) or (48 <= c <= 57):
            out.append(chr(c))
            prev_hyphen = False
        elif c in (32, 9, 10, 13, 45, 95):
            if not prev_hyphen:
                out.append("-")
                prev_hyphen = True
    while out and out[-1] == "-":
        out.pop()
    if not out:
        return "article"
    return "".join(out)


def with_suffix(base: str, n: int) -> str:
    if n == 0:
        return base
    return f"{base}-{n}"


def _text(obj: dict, key: str) -> tuple[str, object]:
    """Classify a JSON field: absent, null, blank, value, or bad type."""
    if key not in obj:
        return ("absent", None)
    val = obj[key]
    if val is None:
        return ("null", None)
    if not isinstance(val, str):
        raise ApiError(422, key, "is invalid")
    if val == "":
        return ("blank", "")
    return ("value", val)


def require_new_text(obj: dict, key: str) -> str:
    kind, val = _text(obj, key)
    if kind != "value":
        raise ApiError(422, key, "can't be blank")
    return str(val)


def optional_text(obj: dict, key: str) -> tuple[str, str | None]:
    """absent | clear | set. Null and empty string both clear."""
    kind, val = _text(obj, key)
    if kind == "absent":
        return ("absent", None)
    if kind in ("null", "blank"):
        return ("clear", None)
    return ("set", str(val))


def optional_required_text(obj: dict, key: str) -> tuple[str, str | None]:
    """For title/description/body/username/email on update. Absent is keep."""
    kind, val = _text(obj, key)
    if kind == "absent":
        return ("absent", None)
    if kind != "value":
        raise ApiError(422, key, "can't be blank")
    return ("set", str(val))


def check_password_value(password: str) -> None:
    if len(password.encode("utf-8")) < MIN_PASSWORD:
        raise ApiError(422, "password", "is too short (minimum is 8 characters)")


def register_fields(user: dict) -> tuple[str, str, str]:
    username = require_new_text(user, "username")
    email = require_new_text(user, "email")
    password = require_new_text(user, "password")
    check_password_value(password)
    return username, email, password


def login_fields(user: dict) -> tuple[str, str]:
    email = require_new_text(user, "email")
    # A non-empty wrong password is an auth failure, not a validation error.
    kind, val = _text(user, "password")
    if kind != "value":
        raise ApiError(422, "password", "can't be blank")
    return email, str(val)


def update_user_fields(user: dict) -> dict:
    username = optional_required_text(user, "username")
    email = optional_required_text(user, "email")
    pw_kind, pw_val = _text(user, "password")
    if pw_kind == "absent":
        password = ("absent", None)
    elif pw_kind != "value":
        raise ApiError(422, "password", "can't be blank")
    else:
        check_password_value(str(pw_val))
        password = ("set", str(pw_val))
    bio = optional_text(user, "bio")
    image = optional_text(user, "image")
    if all(item[0] == "absent" for item in (username, email, password, bio, image)):
        raise ApiError(422, "user", "is invalid")
    return {
        "username": username,
        "email": email,
        "password": password,
        "bio": bio,
        "image": image,
    }


def article_create_fields(article: dict) -> tuple[str, str, str, list[str] | None]:
    title = require_new_text(article, "title")
    description = require_new_text(article, "description")
    body = require_new_text(article, "body")
    tags = parse_tag_list(article, required=False)
    return title, description, body, tags


def article_update_fields(article: dict) -> dict:
    title = optional_required_text(article, "title")
    description = optional_required_text(article, "description")
    body = optional_required_text(article, "body")
    if "tagList" not in article:
        tags: tuple[str, list[str] | None] = ("absent", None)
    elif article["tagList"] is None:
        raise ApiError(422, "tagList", "is invalid")
    else:
        tags = ("replace", parse_tag_list(article, required=True) or [])
    if all(item[0] == "absent" for item in (title, description, body, tags)):
        raise ApiError(422, "article", "is invalid")
    return {"title": title, "description": description, "body": body, "tags": tags}


def parse_tag_list(article: dict, required: bool) -> list[str] | None:
    if "tagList" not in article:
        return None
    raw = article["tagList"]
    if raw is None:
        if required:
            raise ApiError(422, "tagList", "is invalid")
        raise ApiError(422, "tagList", "is invalid")
    if not isinstance(raw, list):
        raise ApiError(422, "tagList", "is invalid")
    out: list[str] = []
    seen: set[str] = set()
    for item in raw:
        if not isinstance(item, str):
            raise ApiError(422, "tagList", "is invalid")
        if item == "" or item in seen:
            continue
        seen.add(item)
        out.append(item)
    return out


def comment_body(comment: dict) -> str:
    return require_new_text(comment, "body")


def page_params(limit_raw: str | None, offset_raw: str | None) -> tuple[int, int]:
    if limit_raw is None or limit_raw == "":
        limit = 20
    else:
        try:
            limit = int(limit_raw)
        except ValueError:
            raise ApiError(422, "limit", "is invalid") from None
        if limit < 1:
            raise ApiError(422, "limit", "is invalid")
        if limit > 100:
            limit = 100
    if offset_raw is None or offset_raw == "":
        offset = 0
    else:
        try:
            offset = int(offset_raw)
        except ValueError:
            raise ApiError(422, "offset", "is invalid") from None
        if offset < 0:
            raise ApiError(422, "offset", "is invalid")
    return limit, offset
