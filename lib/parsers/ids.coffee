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
restify = require 'restify'
_ = require '../util'

parseIds = (body, cb) ->
  throw new Error "[parseIds] missing body" unless body?
  throw new Error "[parseIds] missing callback" unless cb?

  $ = cheerio.load body

  if $('.artefact-listing li').length
    items = (href: _.a_to_a($(a)) for a in $('.object-image'))
    ids = collection: {items}

    get_id = (selector) -> /pg=(\d+)/.exec($(selector)?[0]?.attribs?.href)?[1]
    [prev, next, last] = (get_id sel for sel in ['.prev a', '.next a', '.pagination li:last-child a'])

    ids['_links'] =
      first: href: 1
      next: href: next
      prev: href: prev
      last: href: last

    for link,href of ids['_links']
      if /undefined/.test href.href
        delete ids['_links'][link]

    cb null, ids
  else
    cb new restify.NotFoundError

module.exports = parseIds
