POST {{host}}/api/bundles/
Authorization: Token {{alice}}
Content-Type: application/json
{
  "name": "First"
}
HTTP 201
[Asserts]
jsonpath "$.id" == 1
jsonpath "$.name" == "First"
jsonpath "$.search" == ""
jsonpath "$.any_tags" == ""
jsonpath "$.all_tags" == ""
jsonpath "$.excluded_tags" == ""
jsonpath "$.filter_unread" == "off"
jsonpath "$.filter_shared" == "off"
jsonpath "$.order" == 0
[Captures]
first_created: jsonpath "$.date_created"
first_modified: jsonpath "$.date_modified"

POST {{host}}/api/bundles/
Authorization: Token {{alice}}
Content-Type: application/json
{
  "name": "Second",
  "search": "alpha",
  "any_tags": "zed alpha",
  "filter_unread": "yes",
  "filter_shared": "no"
}
HTTP 201
[Asserts]
jsonpath "$.order" == 1
jsonpath "$.search" == "alpha"
jsonpath "$.any_tags" == "zed alpha"
jsonpath "$.filter_unread" == "yes"
jsonpath "$.filter_shared" == "no"
[Captures]
second: jsonpath "$.id"
second_modified: jsonpath "$.date_modified"

POST {{host}}/api/bundles/
Authorization: Token {{alice}}
Content-Type: application/json
{
  "name": "Third",
  "order": 10
}
HTTP 201
[Asserts]
jsonpath "$.order" == 10
[Captures]
third: jsonpath "$.id"
third_modified: jsonpath "$.date_modified"

GET {{host}}/api/bundles/
Authorization: Token {{alice}}
HTTP 200
[Asserts]
jsonpath "$.count" == 3
jsonpath "$.results[0].name" == "First"
jsonpath "$.results[1].name" == "Second"
jsonpath "$.results[2].name" == "Third"
jsonpath "$.results[2].order" == 10

POST {{host}}/api/bundles/
Authorization: Token {{alice}}
Content-Type: application/json
{}
HTTP 400
[Asserts]
jsonpath "$.name[0]" == "This field is required."

POST {{host}}/api/bundles/
Authorization: Token {{alice}}
Content-Type: application/json
{
  "name": "Bad",
  "filter_unread": "maybe"
}
HTTP 400
[Asserts]
jsonpath "$.filter_unread[0]" == "\"maybe\" is not a valid choice."

PUT {{host}}/api/bundles/{{second}}/
Authorization: Token {{alice}}
Content-Type: application/json
{
  "name": "Second renamed"
}
HTTP 200
[Asserts]
jsonpath "$.name" == "Second renamed"
jsonpath "$.search" == "alpha"
jsonpath "$.any_tags" == "zed alpha"
jsonpath "$.filter_unread" == "yes"
jsonpath "$.order" == 1
jsonpath "$.date_modified" != "{{second_modified}}"

PATCH {{host}}/api/bundles/{{second}}/
Authorization: Token {{alice}}
Content-Type: application/json
{
  "search": "beta"
}
HTTP 200
[Asserts]
jsonpath "$.name" == "Second renamed"
jsonpath "$.search" == "beta"
jsonpath "$.filter_shared" == "no"
[Captures]
second_modified: jsonpath "$.date_modified"

PUT {{host}}/api/bundles/{{second}}/
Authorization: Token {{alice}}
Content-Type: application/json
{}
HTTP 400
[Asserts]
jsonpath "$.name[0]" == "This field is required."

POST {{host}}/api/bundles/
Authorization: Token {{bob}}
Content-Type: application/json
{
  "name": "Bob bundle"
}
HTTP 201
[Captures]
bob_bundle: jsonpath "$.id"

GET {{host}}/api/bundles/{{bob_bundle}}/
Authorization: Token {{alice}}
HTTP 404
[Asserts]
jsonpath "$.detail" == "No BookmarkBundle matches the given query."

GET {{host}}/api/bundles/
Authorization: Token {{bob}}
HTTP 200
[Asserts]
jsonpath "$.count" == 1
jsonpath "$.results[0].name" == "Bob bundle"

DELETE {{host}}/api/bundles/1/
Authorization: Token {{alice}}
HTTP 204

GET {{host}}/api/bundles/{{second}}/
Authorization: Token {{alice}}
HTTP 200
[Asserts]
jsonpath "$.order" == 0
jsonpath "$.date_modified" == "{{second_modified}}"

GET {{host}}/api/bundles/{{third}}/
Authorization: Token {{alice}}
HTTP 200
[Asserts]
jsonpath "$.order" == 1
jsonpath "$.date_modified" == "{{third_modified}}"

POST {{host}}/api/bookmarks/?disable_scraping
Authorization: Token {{alice}}
Content-Type: application/json
{
  "url": "https://example.com/alpha",
  "title": "Alpha hit",
  "unread": true,
  "shared": false,
  "tag_names": ["zed"],
  "date_added": "2020-01-01T00:00:00Z",
  "date_modified": "2020-01-01T00:00:00Z"
}
HTTP 201

POST {{host}}/api/bookmarks/?disable_scraping
Authorization: Token {{alice}}
Content-Type: application/json
{
  "url": "https://example.com/other",
  "title": "Alpha shared",
  "unread": true,
  "shared": true,
  "tag_names": ["zed"],
  "date_added": "2020-02-01T00:00:00Z",
  "date_modified": "2020-02-01T00:00:00Z"
}
HTTP 201

POST {{host}}/api/bookmarks/?disable_scraping
Authorization: Token {{alice}}
Content-Type: application/json
{
  "url": "https://example.com/read",
  "title": "Alpha read",
  "unread": false,
  "tag_names": ["zed"],
  "date_added": "2020-03-01T00:00:00Z",
  "date_modified": "2020-03-01T00:00:00Z"
}
HTTP 201

POST {{host}}/api/bundles/
Authorization: Token {{alice}}
Content-Type: application/json
{
  "name": "Filter",
  "search": "alpha or missing",
  "any_tags": "zed",
  "filter_unread": "yes",
  "filter_shared": "no"
}
HTTP 201
[Captures]
filter_bundle: jsonpath "$.id"

GET {{host}}/api/bookmarks/?bundle={{filter_bundle}}
Authorization: Token {{alice}}
HTTP 200
[Asserts]
jsonpath "$.count" == 0

POST {{host}}/api/bundles/
Authorization: Token {{alice}}
Content-Type: application/json
{
  "name": "Filter2",
  "search": "alpha",
  "any_tags": "zed nope",
  "filter_unread": "yes",
  "filter_shared": "no"
}
HTTP 201
[Captures]
filter2: jsonpath "$.id"

GET {{host}}/api/bookmarks/?bundle={{filter2}}
Authorization: Token {{alice}}
HTTP 200
[Asserts]
jsonpath "$.count" == 1
jsonpath "$.results[0].title" == "Alpha hit"

GET {{host}}/api/bookmarks/?bundle=99999
Authorization: Token {{alice}}
HTTP 200
[Asserts]
jsonpath "$.count" == 3

POST {{host}}/api/bookmarks/?disable_scraping
Authorization: Token {{alice}}
Content-Type: application/json
{
  "url": "https://example.com/both-tags",
  "title": "Both",
  "tag_names": ["foo", "bar"],
  "date_added": "2020-04-01T00:00:00Z",
  "date_modified": "2020-04-01T00:00:00Z"
}
HTTP 201

POST {{host}}/api/bookmarks/?disable_scraping
Authorization: Token {{alice}}
Content-Type: application/json
{
  "url": "https://example.com/foo-only",
  "title": "Foo only",
  "tag_names": ["foo"],
  "date_added": "2020-05-01T00:00:00Z",
  "date_modified": "2020-05-01T00:00:00Z"
}
HTTP 201

POST {{host}}/api/bundles/
Authorization: Token {{alice}}
Content-Type: application/json
{
  "name": "All",
  "all_tags": "foo bar",
  "excluded_tags": "zed"
}
HTTP 201
[Captures]
all_bundle: jsonpath "$.id"

GET {{host}}/api/bookmarks/?bundle={{all_bundle}}
Authorization: Token {{alice}}
HTTP 200
[Asserts]
jsonpath "$.count" == 1
jsonpath "$.results[0].title" == "Both"
