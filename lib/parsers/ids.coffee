###
  The id parser takes html, and returns an error and id object
  the html body must be a string
  the callback passes an error or parsed id object

  for example:

    parseids = require 'lib/parsers/ids'

    http.get 'http://metmuseum.org/search-the-collections/3', (response) ->
      parseids response, (err, ids) ->
        console.log err or ids
###

cheerio = require 'cheerio'
_ = require '../util'

parseIds = (body, cb) ->
  throw new Error "[parseIds] missing body" unless body?
  throw new Error "[parseIds] missing callback" unless cb?

  $ = cheerio.load body
  
  if page = + /\d+/.exec($('.pagination .hide-content+span').text())
    id_path = "/ids?page="

    items = (href: _.a_to_a($(a)) for a in $('.object-image'))
    ids = collection: {href: "#{id_path}#{page}", items}

    prev_id = /pg=(\d+)/.exec($('.prev a')?.attr('href'))?[1]
    next_id = /pg=(\d+)/.exec($('.next a')?.attr('href'))?[1]
    last_id = /pg=(\d+)/.exec($('.pagination li:last-child a')?.attr('href'))?[1]

    ids['_links'] =
      first: href: id_path + 1
      next: href: id_path + next_id if next_id?
      prev: href: id_path + prev_id if prev_id?
      last: href: id_path + last_id if last_id?

    cb null, ids
  else
    cb new restify.NotFoundError

module.exports = parseIds