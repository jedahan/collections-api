r = require 'ramda'

# internal search function
thunkify = require 'thunkify'
request = thunkify require 'request'
get = (url) -> return (yield request({json: true, url}))[0]

# getRandom does 3 requests
# 1. /search, to figure out how many pages of ids there are
# 2. ?page=#{random_page}, to pick a random page of ids
# 3. /object/#{random_id}, to pick a random object

getRandom = (next) ->
  page = yield get "http://#{@host}/search"
  random_page = Math.ceil Math.random() * page.body._links?.last?.href
  ids_page = yield get "http://#{@host}/search?page=#{random_page}"
  ids = ids_page.body.collection.items
  object = yield get ids[Math.floor(Math.random() * ids.length)].href

  responseTime = (x) -> + x.headers['x-response-time-metmuseum'][...-2]
  responseTimeMetmuseum = r.sum r.map responseTime, [page,ids_page,object]
  @set 'X-Response-Time-Metmuseum', responseTimeMetmuseum + "ms"

  @body = object.body

module.exports = getRandom
