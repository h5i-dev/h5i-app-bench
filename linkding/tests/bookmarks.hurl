POST {{host}}/api/bookmarks/?disable_scraping
Authorization: Token {{alice}}
Content-Type: application/json
{
  "url": "https://example.com/alpha",
  "title": "Alpha Title",
  "description": "Desc ALPHA",
  "notes": "Notes here",
  "unread": true,
  "shared": true,
  "tag_names": ["Zed", "alpha", "foo bar"],
  "date_added": "2020-01-02T03:04:05Z",
  "date_modified": "2020-01-02T03:04:05Z"
}
HTTP 201
[Asserts]
header "Location" == "https://example.com/alpha"
jsonpath "$.id" == 1
jsonpath "$.url" == "https://example.com/alpha"
jsonpath "$.title" == "Alpha Title"
jsonpath "$.description" == "Desc ALPHA"
jsonpath "$.notes" == "Notes here"
jsonpath "$.web_archive_snapshot_url" == "https://web.archive.org/web/20200102030405/https://example.com/alpha"
jsonpath "$.favicon_url" == null
jsonpath "$.preview_image_url" == null
jsonpath "$.is_archived" == false
jsonpath "$.unread" == true
jsonpath "$.shared" == true
jsonpath "$.tag_names[0]" == "Zed"
jsonpath "$.tag_names[1]" == "alpha"
jsonpath "$.tag_names[2]" == "foo-bar"
jsonpath "$.date_added" == "2020-01-02T03:04:05Z"
jsonpath "$.date_modified" == "2020-01-02T03:04:05Z"
jsonpath "$.website_title" == null
jsonpath "$.website_description" == null

GET {{host}}/api/bookmarks/1/
Authorization: Token {{alice}}
HTTP 200
[Asserts]
jsonpath "$.id" == 1
jsonpath "$.title" == "Alpha Title"
jsonpath "$.tag_names[0]" == "Zed"

POST {{host}}/api/bookmarks/?disable_scraping
Authorization: Token {{alice}}
Content-Type: application/json
{
  "url": "https://example.com/beta",
  "title": "Beta",
  "notes": "N",
  "unread": true,
  "tag_names": ["Keep"],
  "date_added": "2021-06-07T08:09:10.123456Z"
}
HTTP 201
[Asserts]
header "Location" == "https://example.com/beta"
jsonpath "$.id" == 2
jsonpath "$.title" == "Beta"
jsonpath "$.description" == ""
jsonpath "$.notes" == "N"
jsonpath "$.unread" == true
jsonpath "$.shared" == false
jsonpath "$.is_archived" == false
jsonpath "$.tag_names[0]" == "Keep"
jsonpath "$.date_added" == "2021-06-07T08:09:10.123456Z"
jsonpath "$.web_archive_snapshot_url" == "https://web.archive.org/web/20210607080910/https://example.com/beta"
jsonpath "$.date_modified" != "2021-06-07T08:09:10.123456Z"
[Captures]
beta_modified: jsonpath "$.date_modified"

GET {{host}}/api/bookmarks/?limit=1
Authorization: Token {{alice}}
HTTP 200
[Asserts]
jsonpath "$.count" == 2
jsonpath "$.next" == "{{host}}/api/bookmarks/?limit=1&offset=1"
jsonpath "$.previous" == null
jsonpath "$.results[0].id" == 2

GET {{host}}/api/bookmarks/?limit=1&offset=1
Authorization: Token {{alice}}
HTTP 200
[Asserts]
jsonpath "$.count" == 2
jsonpath "$.next" == null
jsonpath "$.previous" == "{{host}}/api/bookmarks/?limit=1"
jsonpath "$.results[0].id" == 1

GET {{host}}/api/bookmarks/?limit=1&offset=1&q=a
Authorization: Token {{alice}}
HTTP 200
[Asserts]
jsonpath "$.count" == 2
jsonpath "$.previous" == "{{host}}/api/bookmarks/?limit=1&q=a"
jsonpath "$.results[0].id" == 1

GET {{host}}/api/bookmarks/?limit=0
Authorization: Token {{alice}}
HTTP 200
[Asserts]
jsonpath "$.count" == 2
jsonpath "$.next" == null
jsonpath "$.results[0].id" == 2

GET {{host}}/api/bookmarks/?limit=abc&offset=nope
Authorization: Token {{alice}}
HTTP 200
[Asserts]
jsonpath "$.count" == 2
jsonpath "$.results[0].id" == 2

POST {{host}}/api/bookmarks/?disable_scraping
Authorization: Token {{alice}}
Content-Type: application/json
{
  "url": "https://example.com/alpha",
  "title": "Only title"
}
HTTP 201
[Asserts]
jsonpath "$.id" == 1
jsonpath "$.url" == "https://example.com/alpha"
jsonpath "$.title" == "Only title"
jsonpath "$.description" == ""
jsonpath "$.notes" == ""
jsonpath "$.unread" == false
jsonpath "$.shared" == false
jsonpath "$.is_archived" == false
jsonpath "$.tag_names" count == 0
jsonpath "$.date_added" == "2020-01-02T03:04:05Z"
jsonpath "$.date_modified" != "2020-01-02T03:04:05Z"

PUT {{host}}/api/bookmarks/2/
Authorization: Token {{alice}}
Content-Type: application/json
{
  "url": "https://example.com/beta-2"
}
HTTP 200
[Asserts]
jsonpath "$.id" == 2
jsonpath "$.url" == "https://example.com/beta-2"
jsonpath "$.title" == "Beta"
jsonpath "$.notes" == "N"
jsonpath "$.unread" == true
jsonpath "$.tag_names[0]" == "Keep"
jsonpath "$.date_added" == "2021-06-07T08:09:10.123456Z"
jsonpath "$.web_archive_snapshot_url" == "https://web.archive.org/web/20210607080910/https://example.com/beta-2"
jsonpath "$.date_modified" != "{{beta_modified}}"

PATCH {{host}}/api/bookmarks/2/
Authorization: Token {{alice}}
Content-Type: application/json
{
  "notes": "patched"
}
HTTP 200
[Asserts]
jsonpath "$.notes" == "patched"
jsonpath "$.title" == "Beta"
jsonpath "$.url" == "https://example.com/beta-2"
jsonpath "$.tag_names[0]" == "Keep"
[Captures]
patched_modified: jsonpath "$.date_modified"

PATCH {{host}}/api/bookmarks/2/
Authorization: Token {{alice}}
Content-Type: application/json
{}
HTTP 200
[Asserts]
jsonpath "$.notes" == "patched"
jsonpath "$.date_added" == "2021-06-07T08:09:10.123456Z"
jsonpath "$.date_modified" != "{{patched_modified}}"

PUT {{host}}/api/bookmarks/2/
Authorization: Token {{alice}}
Content-Type: application/json
{}
HTTP 400
[Asserts]
jsonpath "$.url[0]" == "This field is required."

POST {{host}}/api/bookmarks/?disable_scraping
Authorization: Token {{alice}}
Content-Type: application/json
{}
HTTP 400
[Asserts]
jsonpath "$.url[0]" == "This field is required."

POST {{host}}/api/bookmarks/?disable_scraping
Authorization: Token {{alice}}
Content-Type: application/json
{
  "url": ""
}
HTTP 400
[Asserts]
jsonpath "$.url[0]" == "This field may not be blank."

POST {{host}}/api/bookmarks/?disable_scraping
Authorization: Token {{alice}}
Content-Type: application/json
{
  "url": "not a url"
}
HTTP 400
[Asserts]
jsonpath "$.url[0]" == "Enter a valid URL."

POST {{host}}/api/bookmarks/?disable_scraping
Authorization: Token {{alice}}
Content-Type: application/json
{
  "url": "http://example"
}
HTTP 400
[Asserts]
jsonpath "$.url[0]" == "Enter a valid URL."

POST {{host}}/api/bookmarks/?disable_scraping
Authorization: Token {{alice}}
Content-Type: application/json
{
  "url": "https://example.com/ok",
  "title": null
}
HTTP 400
[Asserts]
jsonpath "$.title[0]" == "This field may not be null."

POST {{host}}/api/bookmarks/?disable_scraping
Authorization: Token {{alice}}
Content-Type: application/json
{
  "url": "https://example.com/ok",
  "unread": "maybe"
}
HTTP 400
[Asserts]
jsonpath "$.unread[0]" == "Must be a valid boolean."

POST {{host}}/api/bookmarks/?disable_scraping
Authorization: Token {{alice}}
Content-Type: application/json
{
  "url": "https://example.com/ok",
  "tag_names": "nope"
}
HTTP 400
[Asserts]
jsonpath "$.tag_names[0]" == "Expected a list of items but got type \"str\"."

POST {{host}}/api/bookmarks/?disable_scraping
Authorization: Token {{alice}}
Content-Type: application/json
{
  "url": "https://example.com/ok",
  "date_added": "nope"
}
HTTP 400
[Asserts]
jsonpath "$.date_added[0]" == "Datetime has wrong format. Use one of these formats instead: YYYY-MM-DDThh:mm[:ss[.uuuuuu]][+HH:MM|-HH:MM|Z]."

POST {{host}}/api/bookmarks/?disable_scraping
Authorization: Token {{alice}}
Content-Type: application/json
{
  "url": "https://example.com/tlong",
  "title": "tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt"
}
HTTP 400
[Asserts]
jsonpath "$.title[0]" == "Ensure this field has no more than 512 characters."

POST {{host}}/api/bookmarks/
Authorization: Token {{alice}}
Content-Type: application/json
```
not-json
```
HTTP 400
[Asserts]
jsonpath "$.detail" == "JSON parse error - Expecting value: line 1 column 1 (char 0)"

POST {{host}}/api/bookmarks/
Authorization: Token {{alice}}
Content-Type: application/json
HTTP 400
[Asserts]
jsonpath "$.url[0]" == "This field is required."

POST {{host}}/api/bookmarks/
Authorization: Token {{alice}}
Content-Type: application/json
```
[]
```
HTTP 400
[Asserts]
jsonpath "$.non_field_errors[0]" == "Invalid data. Expected a dictionary, but got list."

POST {{host}}/api/bookmarks/
Authorization: Token {{alice}}
Content-Type: application/json
```
null
```
HTTP 400
[Asserts]
jsonpath "$.non_field_errors[0]" == "No data provided"

POST {{host}}/api/bookmarks/
Authorization: Token {{alice}}
Content-Type: text/plain
```
not-json
```
HTTP 415
[Asserts]
jsonpath "$.detail" == "Unsupported media type \"text/plain\" in request."

POST {{host}}/api/bookmarks/?disable_scraping
Authorization: Token {{alice}}
Content-Type: application/json
{
  "url": "ftp://example.com/file",
  "title": "ftp",
  "date_added": "2020-04-01T00:00:00Z",
  "date_modified": "2020-04-01T00:00:00Z"
}
HTTP 201
[Asserts]
jsonpath "$.url" == "ftp://example.com/file"
jsonpath "$.web_archive_snapshot_url" == "https://web.archive.org/web/20200401000000/ftp://example.com/file"

POST {{host}}/api/bookmarks/?disable_scraping
Authorization: Token {{alice}}
Content-Type: application/json
{
  "url": "http://127.0.0.1:9/blocked",
  "date_added": "2020-05-01T00:00:00Z",
  "date_modified": "2020-05-01T00:00:00Z"
}
HTTP 201
[Asserts]
jsonpath "$.website_title" == null
jsonpath "$.website_description" == null
jsonpath "$.favicon_url" == null
jsonpath "$.preview_image_url" == null
jsonpath "$.title" == ""

POST {{host}}/api/bookmarks/?disable_scraping
Authorization: Token {{alice}}
Content-Type: application/json
{
  "url": "HTTPS://Example.COM/gamma/?b=2&a=1",
  "title": "Gamma",
  "date_added": "2020-06-01T00:00:00Z",
  "date_modified": "2020-06-01T00:00:00Z"
}
HTTP 201
[Asserts]
jsonpath "$.url" == "HTTPS://Example.COM/gamma/?b=2&a=1"
jsonpath "$.title" == "Gamma"
[Captures]
gamma: jsonpath "$.id"

POST {{host}}/api/bookmarks/?disable_scraping
Authorization: Token {{alice}}
Content-Type: application/json
{
  "url": "https://example.com/gamma?a=1&b=2",
  "title": "Gamma2"
}
HTTP 201
[Asserts]
jsonpath "$.id" == {{gamma}}
jsonpath "$.url" == "HTTPS://Example.COM/gamma/?b=2&a=1"
jsonpath "$.title" == "Gamma2"
jsonpath "$.date_added" == "2020-06-01T00:00:00Z"
jsonpath "$.date_modified" != "2020-06-01T00:00:00Z"

POST {{host}}/api/bookmarks/?disable_scraping
Authorization: Token {{alice}}
Content-Type: application/json
{
  "url": "https://example.com/slash/",
  "title": "Slash",
  "date_added": "2020-07-01T00:00:00Z",
  "date_modified": "2020-07-01T00:00:00Z"
}
HTTP 201
[Captures]
slash: jsonpath "$.id"

POST {{host}}/api/bookmarks/?disable_scraping
Authorization: Token {{alice}}
Content-Type: application/json
{
  "url": "https://example.com/slash",
  "title": "Slash2"
}
HTTP 201
[Asserts]
jsonpath "$.id" == {{slash}}
jsonpath "$.url" == "https://example.com/slash/"
jsonpath "$.title" == "Slash2"

POST {{host}}/api/bookmarks/?disable_scraping
Authorization: Token {{alice}}
Content-Type: application/json
{
  "url": "https://example.com/archflag",
  "title": "Arch",
  "is_archived": true,
  "date_added": "2020-08-01T00:00:00Z",
  "date_modified": "2020-08-01T00:00:00Z"
}
HTTP 201
[Asserts]
jsonpath "$.is_archived" == true
[Captures]
arch: jsonpath "$.id"

POST {{host}}/api/bookmarks/?disable_scraping
Authorization: Token {{alice}}
Content-Type: application/json
{
  "url": "https://example.com/archflag",
  "title": "Arch2",
  "is_archived": false
}
HTTP 201
[Asserts]
jsonpath "$.id" == {{arch}}
jsonpath "$.title" == "Arch2"
jsonpath "$.is_archived" == true

POST {{host}}/api/bookmarks/?disable_scraping
Authorization: Token {{alice}}
Content-Type: application/json
{
  "url": "https://example.com/yes",
  "unread": "yes",
  "shared": "off",
  "date_added": "2020-03-01T00:00:00Z",
  "date_modified": "2020-03-01T00:00:00Z"
}
HTTP 201
[Asserts]
jsonpath "$.unread" == true
jsonpath "$.shared" == false

POST {{host}}/api/bookmarks/?disable_scraping
Authorization: Token {{bob}}
Content-Type: application/json
{
  "url": "https://example.com/alpha",
  "title": "Bob copy",
  "date_added": "2019-01-01T00:00:00Z",
  "date_modified": "2019-01-01T00:00:00Z"
}
HTTP 201
[Asserts]
jsonpath "$.url" == "https://example.com/alpha"
jsonpath "$.title" == "Bob copy"
jsonpath "$.id" != 1

GET {{host}}/api/bookmarks/1/
Authorization: Token {{bob}}
HTTP 404
[Asserts]
jsonpath "$.detail" == "No Bookmark matches the given query."

PUT {{host}}/api/bookmarks/1/
Authorization: Token {{bob}}
Content-Type: application/json
{
  "url": "https://example.com/nope"
}
HTTP 404
[Asserts]
jsonpath "$.detail" == "No Bookmark matches the given query."

POST {{host}}/api/bookmarks/?disable_scraping
Authorization: Token {{alice}}
Content-Type: application/json
{
  "url": "https://example.com/left",
  "title": "Left",
  "date_added": "2020-09-01T00:00:00Z",
  "date_modified": "2020-09-01T00:00:00Z"
}
HTTP 201
[Captures]
left: jsonpath "$.id"

POST {{host}}/api/bookmarks/?disable_scraping
Authorization: Token {{alice}}
Content-Type: application/json
{
  "url": "https://example.com/right",
  "title": "Right",
  "date_added": "2020-09-02T00:00:00Z",
  "date_modified": "2020-09-02T00:00:00Z"
}
HTTP 201
[Captures]
right: jsonpath "$.id"

PUT {{host}}/api/bookmarks/{{right}}/
Authorization: Token {{alice}}
Content-Type: application/json
{
  "url": "https://example.com/left"
}
HTTP 400
[Asserts]
jsonpath "$.url[0]" == "A bookmark with this URL already exists."

PUT {{host}}/api/bookmarks/{{right}}/
Authorization: Token {{alice}}
Content-Type: application/json
{
  "url": "HTTPS://Example.COM/left",
  "title": "Y"
}
HTTP 200
[Asserts]
jsonpath "$.url" == "HTTPS://Example.COM/left"
jsonpath "$.title" == "Y"

POST {{host}}/api/bookmarks/{{left}}/archive/
Authorization: Token {{alice}}
HTTP 204

GET {{host}}/api/bookmarks/?q=Left
Authorization: Token {{alice}}
HTTP 200
[Asserts]
jsonpath "$.count" == 1
jsonpath "$.results[0].id" == {{right}}
jsonpath "$.results[0].is_archived" == false

GET {{host}}/api/bookmarks/archived/?q=Left
Authorization: Token {{alice}}
HTTP 200
[Asserts]
jsonpath "$.count" == 1
jsonpath "$.results[0].id" == {{left}}
jsonpath "$.results[0].is_archived" == true

POST {{host}}/api/bookmarks/{{left}}/unarchive/
Authorization: Token {{alice}}
HTTP 204

GET {{host}}/api/bookmarks/{{left}}/
Authorization: Token {{alice}}
HTTP 200
[Asserts]
jsonpath "$.is_archived" == false

DELETE {{host}}/api/bookmarks/{{left}}/
Authorization: Token {{alice}}
HTTP 204

GET {{host}}/api/bookmarks/{{left}}/
Authorization: Token {{alice}}
HTTP 404
[Asserts]
jsonpath "$.detail" == "No Bookmark matches the given query."

GET {{host}}/api/bookmarks/999999/
Authorization: Token {{alice}}
HTTP 404
[Asserts]
jsonpath "$.detail" == "No Bookmark matches the given query."

POST {{host}}/api/bookmarks/999999/archive/
Authorization: Token {{alice}}
HTTP 404
[Asserts]
jsonpath "$.detail" == "No Bookmark matches the given query."
