q = require 'q'
request = q.denodeify require 'request'

getRandom = (next) -->
  page = yield request "scrapi.org/ids"

  if max = JSON.parse(page[0].body)._links?.last?.href
    random_page = Math.floor(Math.random() * +(/page=(\d+)/.exec(max)[1])) + 1

    random_ids = yield request "scrapi.org/ids?page=#{random_page}"
    ids = JSON.parse(random[0].body).collection.items
    random_page = ids[Math.floor(Math.random() * ids.length)].href

    @body = yield request random_page

module.exports = getRandom
