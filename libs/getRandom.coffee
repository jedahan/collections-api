q = require 'q'
request = q.denodeify require 'request'

getRandom = (next) -->
  page = yield request "http://#{@host}/search"

  if max = JSON.parse(page[0].body)._links?.last?.href
    random_page = Math.ceil(Math.random() * max)
    random_ids = yield request "http://#{@host}/search?page=#{random_page}"

    ids = JSON.parse(random_ids[0].body).collection.items
    random_page = ids[Math.floor(Math.random() * ids.length)].href
    random_page = yield request random_page

    responseTimeMetmuseum = [page,random_ids,random_page]
      .map (e) -> + e[0].headers['x-response-time-metmuseum'].slice(0,-2)
      .reduce (a,b) -> a+b
    @set 'X-Response-Time-Metmuseum', responseTimeMetmuseum + "ms"
    @body = JSON.parse(random_page[0].body)

module.exports = getRandom
