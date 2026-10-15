GET {{host}}/api/bookmarks/
HTTP 401
[Asserts]
jsonpath "$.detail" == "Authentication credentials were not provided."
header "WWW-Authenticate" == "Token"

GET {{host}}/api/bookmarks/
Authorization: Token nope
HTTP 401
[Asserts]
jsonpath "$.detail" == "Invalid token."
header "WWW-Authenticate" == "Token"

GET {{host}}/api/bookmarks/
Authorization: Token
HTTP 401
[Asserts]
jsonpath "$.detail" == "Invalid token header. No credentials provided."

GET {{host}}/api/bookmarks/
Authorization: Token abc def
HTTP 401
[Asserts]
jsonpath "$.detail" == "Invalid token header. Token string should not contain spaces."

GET {{host}}/api/bookmarks/
Authorization: Basic abc
HTTP 401
[Asserts]
jsonpath "$.detail" == "Authentication credentials were not provided."

GET {{host}}/api/bookmarks/
Authorization: Bearer {{alice}}
HTTP 200
[Asserts]
jsonpath "$.count" == 0
jsonpath "$.next" == null
jsonpath "$.previous" == null

GET {{host}}/api/bookmarks/
Authorization: token {{alice}}
HTTP 200
[Asserts]
jsonpath "$.count" == 0

GET {{host}}/api/bookmarks/1/
HTTP 401
[Asserts]
jsonpath "$.detail" == "Authentication credentials were not provided."

GET {{host}}/api/bookmarks/shared/
HTTP 200
[Asserts]
jsonpath "$.count" == 0

GET {{host}}/api/user/profile/
Authorization: Token {{alice}}
HTTP 200
[Asserts]
jsonpath "$.theme" == "auto"
jsonpath "$.bookmark_date_display" == "relative"
jsonpath "$.bookmark_link_target" == "_blank"
jsonpath "$.web_archive_integration" == "disabled"
jsonpath "$.tag_search" == "strict"
jsonpath "$.enable_sharing" == true
jsonpath "$.enable_public_sharing" == true
jsonpath "$.enable_favicons" == false
jsonpath "$.display_url" == false
jsonpath "$.permanent_notes" == false
jsonpath "$.version" == "1.47.0"

GET {{host}}/api/user/profile/
Authorization: Token {{bob}}
HTTP 200
[Asserts]
jsonpath "$.enable_sharing" == true
jsonpath "$.enable_public_sharing" == false
jsonpath "$.tag_search" == "strict"

GET {{host}}/api/user/profile/
Authorization: Token {{cara}}
HTTP 200
[Asserts]
jsonpath "$.enable_sharing" == false

GET {{host}}/api/user/profile/
Authorization: Token {{dave}}
HTTP 200
[Asserts]
jsonpath "$.tag_search" == "lax"

PUT {{host}}/api/user/profile/
Authorization: Token {{alice}}
Content-Type: application/json
{}
HTTP 405
[Asserts]
jsonpath "$.detail" == "Method \"PUT\" not allowed."
