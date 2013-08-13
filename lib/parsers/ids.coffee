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

hostname = require('os').hostname()

parseIds = (body, cb) ->
  throw new Error "[parseIds] missing body" unless body?
  throw new Error "[parseIds] missing callback" unless cb?

  $ = cheerio.load body

  if page = + /\d+/.exec($('.pagination .hide-content+span').text())
    id_path = "http://#{hostname}/ids?page="

    items = (href: _.a_to_a($(a)) for a in $('.object-image'))
    ids = collection: href: "#{id_path}#{page}", items

    last_link = $('#phcontent_0_phfullwidthcontent_0_ObjectListPagination_rptPagination_paginationLineItem_10 > a')
    last_page = /pg=(\d+)/.exec(last_link?.attr('href'))?[1]

    ids['_links'] =
      first: href: id_path + 1
      next: href: id_path + page+1     unless page is last_page
      prev: href: id_path + page-1     unless page is 1
      last: href: id_path + last_page  if last_page?

    cb null, ids
  else
    cb new restify.NotFoundError

module.exports = parseIds