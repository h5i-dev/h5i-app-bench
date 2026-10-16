POST {{host}}/api/bookmarks/?disable_scraping
Authorization: Token {{alice}}
Content-Type: application/json
{
  "url": "https://example.com/m",
  "title": "m",
  "date_added": "2020-01-01T00:00:00Z",
  "date_modified": "2020-01-01T00:00:00Z"
}
HTTP 201

POST {{host}}/api/bookmarks/?disable_scraping
Authorization: Token {{alice}}
Content-Type: application/json
{
  "url": "https://example.com/a",
  "title": "",
  "date_added": "2020-01-02T00:00:00Z",
  "date_modified": "2020-01-02T00:00:00Z"
}
HTTP 201

POST {{host}}/api/bookmarks/?disable_scraping
Authorization: Token {{alice}}
Content-Type: application/json
{
  "url": "https://example.com/z",
  "title": "z",
  "date_added": "2020-01-03T00:00:00Z",
  "date_modified": "2020-01-03T00:00:00Z"
}
HTTP 201

GET {{host}}/api/bookmarks/?limit=1&offset=2
Authorization: Token {{alice}}
HTTP 200
[Asserts]
jsonpath "$.count" == 3
jsonpath "$.next" == null
jsonpath "$.previous" == "{{host}}/api/bookmarks/?limit=1&offset=1"
jsonpath "$.results[0].title" == "m"

GET {{host}}/api/bookmarks/?sort=title_asc
Authorization: Token {{alice}}
HTTP 200
[Asserts]
jsonpath "$.results[0].url" == "https://example.com/a"
jsonpath "$.results[1].title" == "m"
jsonpath "$.results[2].title" == "z"

GET {{host}}/api/bookmarks/?sort=title_desc
Authorization: Token {{alice}}
HTTP 200
[Asserts]
jsonpath "$.results[0].title" == "z"
jsonpath "$.results[2].url" == "https://example.com/a"

GET {{host}}/api/bookmarks/?sort=added_asc
Authorization: Token {{alice}}
HTTP 200
[Asserts]
jsonpath "$.results[0].title" == "m"
jsonpath "$.results[2].title" == "z"

GET {{host}}/api/bookmarks/?sort=modified_desc
Authorization: Token {{alice}}
HTTP 200
[Asserts]
jsonpath "$.results[0].title" == "z"

GET {{host}}/api/bookmarks/?added_since=2020-01-02T00:00:00Z
Authorization: Token {{alice}}
HTTP 200
[Asserts]
jsonpath "$.count" == 1
jsonpath "$.results[0].title" == "z"

GET {{host}}/api/bookmarks/?modified_since=2020-01-01T00:00:00Z
Authorization: Token {{alice}}
HTTP 200
[Asserts]
jsonpath "$.count" == 2
