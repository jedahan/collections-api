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
  page = + /[0-9]+/.exec($('.pagination .hide-content+span').text())
  id_path = "http://#{hostname}/ids?page="
  
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