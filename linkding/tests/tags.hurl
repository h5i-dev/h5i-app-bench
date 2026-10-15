POST {{host}}/api/tags/
Authorization: Token {{alice}}
Content-Type: application/json
{
  "name": "alpha"
}
HTTP 201
[Asserts]
jsonpath "$.id" == 1
jsonpath "$.name" == "alpha"
[Captures]
added: jsonpath "$.date_added"

POST {{host}}/api/tags/
Authorization: Token {{alice}}
Content-Type: application/json
{
  "name": "ALPHA"
}
HTTP 201
[Asserts]
jsonpath "$.id" == 1
jsonpath "$.name" == "alpha"
jsonpath "$.date_added" == "{{added}}"

POST {{host}}/api/tags/
Authorization: Token {{alice}}
Content-Type: application/json
{
  "name": "  "
}
HTTP 400
[Asserts]
jsonpath "$.name[0]" == "This field may not be blank."

POST {{host}}/api/tags/
Authorization: Token {{alice}}
Content-Type: application/json
{}
HTTP 400
[Asserts]
jsonpath "$.name[0]" == "This field is required."

POST {{host}}/api/tags/
Authorization: Token {{alice}}
Content-Type: application/json
{
  "name": "abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklm"
}
HTTP 400
[Asserts]
jsonpath "$.name[0]" == "Ensure this field has no more than 64 characters."

POST {{host}}/api/tags/
Authorization: Token {{alice}}
Content-Type: application/json
{
  "name": "has space"
}
HTTP 201
[Asserts]
jsonpath "$.name" == "has space"
jsonpath "$.id" == 2

POST {{host}}/api/tags/
Authorization: Token {{alice}}
Content-Type: application/json
{
  "name": "  zed  "
}
HTTP 201
[Asserts]
jsonpath "$.name" == "zed"
jsonpath "$.id" == 3

GET {{host}}/api/tags/?limit=1
Authorization: Token {{alice}}
HTTP 200
[Asserts]
jsonpath "$.count" == 3
jsonpath "$.next" == "{{host}}/api/tags/?limit=1&offset=1"
jsonpath "$.results[0].id" == 1
jsonpath "$.results[0].name" == "alpha"

GET {{host}}/api/tags/?limit=1&offset=1
Authorization: Token {{alice}}
HTTP 200
[Asserts]
jsonpath "$.previous" == "{{host}}/api/tags/?limit=1"
jsonpath "$.results[0].name" == "has space"

POST {{host}}/api/tags/
Authorization: Token {{bob}}
Content-Type: application/json
{
  "name": "bobtag"
}
HTTP 201
[Captures]
bobtag: jsonpath "$.id"

GET {{host}}/api/tags/{{bobtag}}/
Authorization: Token {{alice}}
HTTP 404
[Asserts]
jsonpath "$.detail" == "No Tag matches the given query."

DELETE {{host}}/api/tags/{{bobtag}}/
Authorization: Token {{alice}}
HTTP 404

GET {{host}}/api/tags/{{bobtag}}/
Authorization: Token {{bob}}
HTTP 200
[Asserts]
jsonpath "$.name" == "bobtag"

DELETE {{host}}/api/tags/{{bobtag}}/
Authorization: Token {{bob}}
HTTP 204

GET {{host}}/api/tags/{{bobtag}}/
Authorization: Token {{bob}}
HTTP 404
[Asserts]
jsonpath "$.detail" == "No Tag matches the given query."

GET {{host}}/api/tags/
Authorization: Token {{alice}}
HTTP 200
[Asserts]
jsonpath "$.count" == 3
jsonpath "$.results[0].name" == "alpha"
jsonpath "$.results[1].name" == "has space"
jsonpath "$.results[2].name" == "zed"
