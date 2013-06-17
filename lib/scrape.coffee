request = require 'request'

scrape = (url, cb) ->
  request url, (err, response, body) ->
    # The museum website redirects the user instead of doing a 404
    if response.request.redirects.length
      cb new restify.ResourceNotFoundError "#{url} not found",  null
    else
      cb err, body

module.exports = scrape