# Warm reads must follow API writes, including updates and deletions.
POST {{host}}/api/bookmarks/?disable_scraping
Authorization: Token {{alice}}
Content-Type: application/json
{"url":"https://example.com/resident", "title":"residentbefore"}
HTTP 201
[Captures]
bookmark_id: jsonpath "$.id"

GET {{host}}/api/bookmarks/?q=residentbefore
Authorization: Token {{alice}}
HTTP 200
[Asserts]
jsonpath "$.count" == 1

GET {{host}}/api/bookmarks/?q=residentbefore
Authorization: Token {{bob}}
HTTP 200
[Asserts]
jsonpath "$.count" == 0

PATCH {{host}}/api/bookmarks/{{bookmark_id}}/
Authorization: Token {{alice}}
Content-Type: application/json
{"title":"residentafter"}
HTTP 200

GET {{host}}/api/bookmarks/?q=residentbefore
Authorization: Token {{alice}}
HTTP 200
[Asserts]
jsonpath "$.count" == 0

GET {{host}}/api/bookmarks/?q=residentafter
Authorization: Token {{alice}}
HTTP 200
[Asserts]
jsonpath "$.count" == 1

# A valid API field exceeding the device capacity must still be searchable.
PATCH {{host}}/api/bookmarks/{{bookmark_id}}/
Authorization: Token {{alice}}
Content-Type: application/json
{"title":"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa capacitysentinel"}
HTTP 200

GET {{host}}/api/bookmarks/?q=capacitysentinel
Authorization: Token {{alice}}
HTTP 200
[Asserts]
jsonpath "$.count" == 1
jsonpath "$.results[0].id" == {{bookmark_id}}

DELETE {{host}}/api/bookmarks/{{bookmark_id}}/
Authorization: Token {{alice}}
HTTP 204

GET {{host}}/api/bookmarks/?q=capacitysentinel
Authorization: Token {{alice}}
HTTP 200
[Asserts]
jsonpath "$.count" == 0
