POST {{host}}/api/bookmarks/?disable_scraping
Authorization: Token {{alice}}
Content-Type: application/json
{
  "url": "http://127.0.0.1:9/blocked",
  "title": "Blocked",
  "date_added": "2020-01-02T03:04:05Z",
  "date_modified": "2020-01-02T03:04:05Z"
}
HTTP 201

POST {{host}}/api/bookmarks/?disable_scraping
Authorization: Token {{bob}}
Content-Type: application/json
{
  "url": "http://127.0.0.1:9/bob",
  "title": "Bob blocked",
  "date_added": "2020-01-03T00:00:00Z",
  "date_modified": "2020-01-03T00:00:00Z"
}
HTTP 201

GET {{host}}/api/bookmarks/check/?url=http%3A%2F%2F127.0.0.1%3A9%2Fblocked
Authorization: Token {{alice}}
HTTP 200
[Asserts]
jsonpath "$.bookmark.title" == "Blocked"
jsonpath "$.bookmark.url" == "http://127.0.0.1:9/blocked"
jsonpath "$.metadata.url" == "http://127.0.0.1:9/blocked"
jsonpath "$.metadata.title" == null
jsonpath "$.metadata.description" == null
jsonpath "$.metadata.preview_image" == null
jsonpath "$.auto_tags" count == 0

GET {{host}}/api/bookmarks/check/?url=http%3A%2F%2F127.0.0.1%3A9%2Fmissing
Authorization: Token {{alice}}
HTTP 200
[Asserts]
jsonpath "$.bookmark" == null
jsonpath "$.metadata.url" == "http://127.0.0.1:9/missing"
jsonpath "$.metadata.title" == null
jsonpath "$.auto_tags" count == 0

GET {{host}}/api/bookmarks/check/
Authorization: Token {{alice}}
HTTP 200
[Asserts]
jsonpath "$.bookmark" == null
jsonpath "$.metadata.url" == null
jsonpath "$.metadata.title" == null
jsonpath "$.auto_tags" count == 0

GET {{host}}/api/bookmarks/check/?url=http%3A%2F%2F127.0.0.1%3A9%2Fbob
Authorization: Token {{alice}}
HTTP 200
[Asserts]
jsonpath "$.bookmark" == null
jsonpath "$.metadata.url" == "http://127.0.0.1:9/bob"
jsonpath "$.metadata.title" == null

GET {{host}}/api/bookmarks/check/
HTTP 401
[Asserts]
jsonpath "$.detail" == "Authentication credentials were not provided."
