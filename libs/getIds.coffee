getEndpoint = require './getEndpoint'

cheerio = require 'cheerio'

getIds = (next) -->
  page = yield getEndpoint "?rpp=90&ft=#{@params['term'] or '*'}&pg=#{@query['page'] or '1'}"
  $ = cheerio.load page[0].body

  ids = collection: items: (e for e in $('.list-view-object-info').map ->
    title: $(@).find('.objtitle').text().trim()
    id = + $(@).find('a').attr('href')?.match(/\d+/)?[0]
    href: "http://scrapi.org/object/#{id}"
  )
  get_id = (selector) -> /pg=(\d+)/.exec($(selector)?[0]?.attribs?.href)?[1]

  ids['_links'] =
    first: href: 1
    next: href: get_id $('.next a')
    prev: href: get_id $('.prev a')
    last: href: get_id $('.collection-online-pages li:not(.next) a').last()

  for link,href of ids['_links']
    if /undefined/.test href.href
      delete ids['_links'][link]

  cleanup = require './cleanup'
  @body = cleanup ids

module.exports = getIds
