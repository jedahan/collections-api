###
 This utility function just wraps some of the common idiosyncracies of
 the museum's server config
###

request = require 'request'
restify = require 'restify'

scrape = (url, cb) ->
  request url, (err, response, body) ->
    # The museum website redirects the user instead of doing a 404
    if response.request.redirects.length
      cb new restify.NotFoundError "#{url} not found"
    else
      cb err, body

module.exports = scrape