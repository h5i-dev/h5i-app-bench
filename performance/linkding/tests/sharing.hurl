POST {{host}}/api/bookmarks/?disable_scraping
Authorization: Token {{alice}}
Content-Type: application/json
{
  "url": "https://example.com/alice-public",
  "title": "Alice Public",
  "shared": true,
  "date_added": "2021-01-01T00:00:00Z",
  "date_modified": "2021-01-01T00:00:00Z"
}
HTTP 201
[Captures]
alice_public: jsonpath "$.id"

POST {{host}}/api/bookmarks/?disable_scraping
Authorization: Token {{alice}}
Content-Type: application/json
{
  "url": "https://example.com/alice-private",
  "title": "Alice Private",
  "shared": false,
  "date_added": "2021-02-01T00:00:00Z",
  "date_modified": "2021-02-01T00:00:00Z"
}
HTTP 201

POST {{host}}/api/bookmarks/?disable_scraping
Authorization: Token {{alice}}
Content-Type: application/json
{
  "url": "https://example.com/alice-archived-shared",
  "title": "Alice Archived Shared",
  "shared": true,
  "is_archived": true,
  "date_added": "2021-03-01T00:00:00Z",
  "date_modified": "2021-03-01T00:00:00Z"
}
HTTP 201
[Captures]
alice_archived: jsonpath "$.id"

POST {{host}}/api/bookmarks/?disable_scraping
Authorization: Token {{bob}}
Content-Type: application/json
{
  "url": "https://example.com/bob-shared",
  "title": "Bob Shared",
  "shared": true,
  "date_added": "2019-01-01T00:00:00Z",
  "date_modified": "2019-01-01T00:00:00Z"
}
HTTP 201
[Captures]
bob_shared: jsonpath "$.id"

POST {{host}}/api/bookmarks/?disable_scraping
Authorization: Token {{bob}}
Content-Type: application/json
{
  "url": "https://example.com/bob-private",
  "title": "Bob Private",
  "shared": false,
  "date_added": "2019-02-01T00:00:00Z",
  "date_modified": "2019-02-01T00:00:00Z"
}
HTTP 201
[Captures]
bob_private: jsonpath "$.id"

POST {{host}}/api/bookmarks/?disable_scraping
Authorization: Token {{cara}}
Content-Type: application/json
{
  "url": "https://example.com/cara-shared",
  "title": "Cara Shared",
  "shared": true,
  "date_added": "2018-01-01T00:00:00Z",
  "date_modified": "2018-01-01T00:00:00Z"
}
HTTP 201
[Captures]
cara_shared: jsonpath "$.id"

GET {{host}}/api/bookmarks/shared/
HTTP 200
[Asserts]
jsonpath "$.count" == 2

GET {{host}}/api/bookmarks/shared/?user=alice
HTTP 200
[Asserts]
jsonpath "$.count" == 2

GET {{host}}/api/bookmarks/shared/?user=bob
HTTP 200
[Asserts]
jsonpath "$.count" == 0

GET {{host}}/api/bookmarks/shared/?user=nobody
HTTP 200
[Asserts]
jsonpath "$.count" == 2

GET {{host}}/api/bookmarks/shared/
Authorization: Token {{alice}}
HTTP 200
[Asserts]
jsonpath "$.count" == 3

GET {{host}}/api/bookmarks/shared/?user=bob
Authorization: Token {{alice}}
HTTP 200
[Asserts]
jsonpath "$.count" == 1
jsonpath "$.results[0].id" == {{bob_shared}}

GET {{host}}/api/bookmarks/shared/?user=cara
Authorization: Token {{alice}}
HTTP 200
[Asserts]
jsonpath "$.count" == 0

GET {{host}}/api/bookmarks/shared/?user=nobody
Authorization: Token {{alice}}
HTTP 200
[Asserts]
jsonpath "$.count" == 3

GET {{host}}/api/bookmarks/?q=Bob
Authorization: Token {{alice}}
HTTP 200
[Asserts]
jsonpath "$.count" == 0

GET {{host}}/api/bookmarks/{{bob_shared}}/
Authorization: Token {{alice}}
HTTP 404
[Asserts]
jsonpath "$.detail" == "No Bookmark matches the given query."

GET {{host}}/api/bookmarks/{{bob_private}}/
Authorization: Token {{alice}}
HTTP 404

DELETE {{host}}/api/bookmarks/{{cara_shared}}/
Authorization: Token {{alice}}
HTTP 404

GET {{host}}/api/bookmarks/
Authorization: Token {{alice}}
HTTP 200
[Asserts]
jsonpath "$.count" == 2

GET {{host}}/api/bookmarks/archived/
Authorization: Token {{alice}}
HTTP 200
[Asserts]
jsonpath "$.count" == 1
jsonpath "$.results[0].id" == {{alice_archived}}

GET {{host}}/api/bookmarks/shared/?q=alpha%20or%20Alice
HTTP 200
[Asserts]
jsonpath "$.count" == 2

GET {{host}}/api/bookmarks/shared/?q=alpha%20and%20missing
HTTP 200
[Asserts]
jsonpath "$.count" == 0
