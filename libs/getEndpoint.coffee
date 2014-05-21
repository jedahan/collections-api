q = require 'q'
request = q.denodeify require 'request'

getEndpoint = (endpoint) ->
  (next) -->
    api = "http://www.metmuseum.org/collection/the-collection-online/search"
    start = Date.now()
    res = yield request {followRedirect:false, url: api+endpoint}
    @throw 404 if res[0].statusCode is 302
    return res
    delta = Math.ceil(Date.now() - start)
    @set 'X-Response-Time-Metmuseum', delta + 'ms'

module.exports = getEndpoint
