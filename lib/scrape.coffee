###
 This utility function just wraps some of the common idiosyncracies of
 the museum's server config
###

restify = require 'restify'

scrape = (url, cb) ->
  client = restify.createStringClient {url}
  client.get url, (err, req, res, body) ->
    # The museum website redirects the user to / instead of doing a 404
    if res.statusCode is 302
      if /\d+/.test res.headers.location
        client.get res.headers.location, (err, req, res, body) -> cb err, body
      else
        cb new restify.NotFoundError "#{url} not found"
    else
      cb err, body

module.exports = scrape
