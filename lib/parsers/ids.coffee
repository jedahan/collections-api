###
  The id parser takes a page number and html, and returns an error and id object
  the page number can be an int or string (int preferred), and is used for hyperlinking
  the html body must be a string, where the ids are extracted
  the callback passes an error (404 not found), or parsed id object

  for example:

    request = require 'request'
    parseids = require 'lib/parsers/ids'

    request 'http://metmuseum.org/search-the-collections/3', (error, response, body) ->
      parseids 3, '<img class="object-image" href="metmuseum.org/blah.jpg" />', (err, ids) ->
        console.log err or ids
###

cheerio = require 'cheerio'
_ = require '../util'

hostname = require('os').hostname()

parseIds = (page, body, cb) ->
  throw new Error "[parseIds] missing page" unless page? # TODO: extract page from body
  throw new Error "[parseIds] missing body" unless body?
  throw new Error "[parseIds] missing callback" unless cb?

  page = + page
  id_path = "http://#{hostname}/ids?page="
  $ = cheerio.load body

  if $('.object-image').length is 0
    cb new restify.NotFoundError
  else
    items = (href: _.a_to_a($(a)) for a in $('.object-image'))
    ids = collection: href: "#{id_path}#{page}", items: items
    ids['_links'] = first: href: "#{id_path}" + 1

    last_link = $('#phcontent_0_phfullwidthcontent_0_ObjectListPagination_rptPagination_paginationLineItem_10 > a')
    last_page = last_link.attr('href').match(/pg=(\d+)/)[1] unless last_link.length is 0

    ids['_links'].prev = href: "#{id_path}" + page-1 unless page is 1
    ids['_links'].next = href: "#{id_path}" + page+1 unless page is last_page
    ids['_links'].last = href: "#{id_path}" + last_page

    cb null, ids

module.exports = parseIds