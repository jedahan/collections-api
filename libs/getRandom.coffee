q = require 'q'
request = q.denodeify require 'request'

getRandom = (next) -->
  page = yield request "/search"

  if max = JSON.parse(page[0].body)._links?.last?.href
    random_page = Math.ceil(Math.random() * max)

    random_ids = yield request "/search?page=#{random_page}"
    ids = JSON.parse(random_ids[0].body).collection.items
    random_page = ids[Math.floor(Math.random() * ids.length)].href

    @body = yield request random_page

module.exports = getRandom
