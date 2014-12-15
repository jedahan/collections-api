q = require 'q'
fs = q.denodeify require 'fs'
request = require 'request'

cache = ->
  (next) ->
    body = JSON.parse @body

    return if (@method isnt 'GET') or (@status isnt 200) or not body

    cacheName = "cache/#{body.CRDID}.jpg"
    return if yield fs.exists cacheName

    request body.mainImageUrl, (err, res, body) -> fs.write cacheName, body

    yield next

module.exports = cache
