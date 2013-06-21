cheerio = require 'cheerio'
_ = require '../util'

hostname = require('os').hostname()

parseIds = (page, body, cb) ->
  throw new Error "[parseIds] missing page" unless page?
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

    last_id = +$('#phcontent_0_phfullwidthcontent_0_ObjectListPagination_rptPagination_paginationLineItem_10 > a').attr('href').match(/pg=(\d+)/)[1]
    ids['_links'] = first: href: "#{id_path}" + 1
    ids['_links'] = last: href: "#{id_path}" + last_id

    if page isnt 1 then ids['_links'].prev = href: "#{id_path}" + page-1
    if page isnt last_id or page isnt 6240 then ids['_links'].next = href: "#{id_path}" + page+1

    cb null, ids

module.exports = parseIds