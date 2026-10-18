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

POST {{host}}/api/bookmarks/?disable_scraping
Authorization: Token {{alice}}
Content-Type: application/json
{
  "url": "https://example.com/beta",
  "title": "Beta",
  "date_added": "2021-06-07T08:09:10Z",
  "date_modified": "2021-06-07T08:09:10Z"
}
HTTP 201

POST {{host}}/api/bookmarks/?disable_scraping
Authorization: Token {{alice}}
Content-Type: application/json
{
  "url": "https://example.com/plain",
  "title": "Nothing special",
  "date_added": "2022-01-01T00:00:00Z",
  "date_modified": "2022-01-01T00:00:00Z"
}
HTTP 201

POST {{host}}/api/bookmarks/?disable_scraping
Authorization: Token {{alice}}
Content-Type: application/json
{
  "url": "https://example.com/both",
  "title": "alpha beta",
  "date_added": "2022-02-01T00:00:00Z",
  "date_modified": "2022-02-01T00:00:00Z"
}
HTTP 201

POST {{host}}/api/bookmarks/?disable_scraping
Authorization: Token {{alice}}
Content-Type: application/json
{
  "url": "https://example.com/bg",
  "title": "beta gamma",
  "date_added": "2022-03-01T00:00:00Z",
  "date_modified": "2022-03-01T00:00:00Z"
}
HTTP 201

POST {{host}}/api/bookmarks/?disable_scraping
Authorization: Token {{alice}}
Content-Type: application/json
{
  "url": "https://example.com/ag",
  "title": "alpha gamma",
  "date_added": "2022-04-01T00:00:00Z",
  "date_modified": "2022-04-01T00:00:00Z"
}
HTTP 201

GET {{host}}/api/bookmarks/?q=alpha
Authorization: Token {{alice}}
HTTP 200
[Asserts]
jsonpath "$.count" == 3

GET {{host}}/api/bookmarks/?q=ALPHA
Authorization: Token {{alice}}
HTTP 200
[Asserts]
jsonpath "$.count" == 3

GET {{host}}/api/bookmarks/?q=%28alpha%20or%20missing%29%20and%20not%20%28absent%20or%20unknown%29%20and%20%28example%20or%20bookmark%29%20and%20not%20%28zeta%20and%20beta%29
Authorization: Token {{alice}}
HTTP 200
[Asserts]
jsonpath "$.count" == 3

GET {{host}}/api/bookmarks/?q=%23alpha
Authorization: Token {{alice}}
HTTP 200
[Asserts]
jsonpath "$.count" == 1
jsonpath "$.results[0].id" == 1

GET {{host}}/api/bookmarks/?q=%23ZED
Authorization: Token {{alice}}
HTTP 200
[Asserts]
jsonpath "$.count" == 1
jsonpath "$.results[0].id" == 1

GET {{host}}/api/bookmarks/?q=%23missing
Authorization: Token {{alice}}
HTTP 200
[Asserts]
jsonpath "$.count" == 0

GET {{host}}/api/bookmarks/?q=%21unread
Authorization: Token {{alice}}
HTTP 200
[Asserts]
jsonpath "$.count" == 1
jsonpath "$.results[0].id" == 1

GET {{host}}/api/bookmarks/?q=%21untagged
Authorization: Token {{alice}}
HTTP 200
[Asserts]
jsonpath "$.count" == 5

GET {{host}}/api/bookmarks/?q=alpha%20or%20missing
Authorization: Token {{alice}}
HTTP 200
[Asserts]
jsonpath "$.count" == 3

GET {{host}}/api/bookmarks/?q=alpha%20and%20missing
Authorization: Token {{alice}}
HTTP 200
[Asserts]
jsonpath "$.count" == 0

GET {{host}}/api/bookmarks/?q=alpha%20beta
Authorization: Token {{alice}}
HTTP 200
[Asserts]
jsonpath "$.count" == 1
jsonpath "$.results[0].title" == "alpha beta"

GET {{host}}/api/bookmarks/?q=alpha%20or%20beta%20gamma
Authorization: Token {{alice}}
HTTP 200
[Asserts]
jsonpath "$.count" == 4

GET {{host}}/api/bookmarks/?q=%28alpha%20or%20beta%29%20gamma
Authorization: Token {{alice}}
HTTP 200
[Asserts]
jsonpath "$.count" == 2

GET {{host}}/api/bookmarks/?q=not%20%22Alpha%20Title%22
Authorization: Token {{alice}}
HTTP 200
[Asserts]
jsonpath "$.count" == 5

GET {{host}}/api/bookmarks/?q=%28alpha
Authorization: Token {{alice}}
HTTP 200
[Asserts]
jsonpath "$.count" == 0

GET {{host}}/api/bookmarks/?q=%21nope
Authorization: Token {{alice}}
HTTP 200
[Asserts]
jsonpath "$.count" == 6

GET {{host}}/api/bookmarks/?q=%22foo%20bar%22
Authorization: Token {{alice}}
HTTP 200
[Asserts]
jsonpath "$.count" == 0

GET {{host}}/api/bookmarks/?q=%22Desc%20ALPHA%22
Authorization: Token {{alice}}
HTTP 200
[Asserts]
jsonpath "$.count" == 1
jsonpath "$.results[0].id" == 1

GET {{host}}/api/bookmarks/?unread=yes
Authorization: Token {{alice}}
HTTP 200
[Asserts]
jsonpath "$.count" == 1

GET {{host}}/api/bookmarks/?unread=no
Authorization: Token {{alice}}
HTTP 200
[Asserts]
jsonpath "$.count" == 5

GET {{host}}/api/bookmarks/?shared=yes
Authorization: Token {{alice}}
HTTP 200
[Asserts]
jsonpath "$.count" == 1

GET {{host}}/api/bookmarks/?shared=garbage
Authorization: Token {{alice}}
HTTP 200
[Asserts]
jsonpath "$.count" == 6

GET {{host}}/api/bookmarks/?modified_since=2030-01-01T00:00:00Z
Authorization: Token {{alice}}
HTTP 200
[Asserts]
jsonpath "$.count" == 0

GET {{host}}/api/bookmarks/?modified_since=not-a-date
Authorization: Token {{alice}}
HTTP 200
[Asserts]
jsonpath "$.count" == 6

GET {{host}}/api/bookmarks/?added_since=2022-01-01T00:00:00Z
Authorization: Token {{alice}}
HTTP 200
[Asserts]
jsonpath "$.count" == 3

GET {{host}}/api/bookmarks/?sort=title_asc
Authorization: Token {{alice}}
HTTP 200
[Asserts]
jsonpath "$.results[0].title" == "alpha beta"
jsonpath "$.results[1].title" == "alpha gamma"

GET {{host}}/api/bookmarks/?sort=added_asc
Authorization: Token {{alice}}
HTTP 200
[Asserts]
jsonpath "$.results[0].id" == 1
jsonpath "$.results[5].title" == "alpha gamma"

GET {{host}}/api/bookmarks/?sort=nope
Authorization: Token {{alice}}
HTTP 200
[Asserts]
jsonpath "$.results[0].title" == "alpha gamma"

POST {{host}}/api/bookmarks/?disable_scraping
Authorization: Token {{dave}}
Content-Type: application/json
{
  "url": "https://example.com/dave",
  "title": "Nothing",
  "tag_names": ["python"],
  "date_added": "2020-01-01T00:00:00Z",
  "date_modified": "2020-01-01T00:00:00Z"
}
HTTP 201

GET {{host}}/api/bookmarks/?q=python
Authorization: Token {{dave}}
HTTP 200
[Asserts]
jsonpath "$.count" == 1
jsonpath "$.results[0].title" == "Nothing"

GET {{host}}/api/bookmarks/?q=py
Authorization: Token {{dave}}
HTTP 200
[Asserts]
jsonpath "$.count" == 0

GET {{host}}/api/bookmarks/?q=python
Authorization: Token {{alice}}
HTTP 200
[Asserts]
jsonpath "$.count" == 0

POST {{host}}/api/bookmarks/?disable_scraping
Authorization: Token {{erin}}
Content-Type: application/json
{
  "url": "https://example.com/erin",
  "title": "Legacy Word",
  "tag_names": ["leg"],
  "date_added": "2020-01-01T00:00:00Z",
  "date_modified": "2020-01-01T00:00:00Z"
}
HTTP 201

GET {{host}}/api/bookmarks/?q=legacy%20%23leg
Authorization: Token {{erin}}
HTTP 200
[Asserts]
jsonpath "$.count" == 1

GET {{host}}/api/bookmarks/?q=legacy%20or%20missing
Authorization: Token {{erin}}
HTTP 200
[Asserts]
jsonpath "$.count" == 0

GET {{host}}/api/bookmarks/?q=%21nope
Authorization: Token {{erin}}
HTTP 200
[Asserts]
jsonpath "$.count" == 1
