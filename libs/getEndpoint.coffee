q = require 'q'
request = q.denodeify require 'request'

getEndpoint = (endpoint) ->
  (next) -->
    api = "http://www.metmuseum.org/collection/the-collection-online/search"
    start = Date.now()
    return yield request api+endpoint
    delta = Math.ceil(Date.now() - start)
    @set 'X-Response-Time-Metmuseum', delta + 'ms'

module.exports = getEndpoint
