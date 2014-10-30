getEndpoint = require './getEndpoint'

cheerio = require 'cheerio'

getIds = (next) ->
  page = yield getEndpoint "?ft=#{@params['term'] or '*'}&pg=#{@query['page'] or '1'}&rpp=90"
  $ = cheerio.load page[0].body
  host = @host

  ids = collection: items: (e for e in $('.list-view-object-info').map ->
    title: $(@).find('.objtitle').text().trim()
    id = + $(@).find('a').attr('href')?.match(/\d+/)?[0]
    href: "http://#{host}/object/#{id}"
  )
  get_id = (selector) -> /pg=(\d+)/.exec($(selector)?[0]?.attribs?.href)?[1]

  ids['_links'] =
    first: href: 1
    next: href: get_id $('#phcontent_0_phfullwidthcontent_0_paginationWidget_rptPagination_lnkNextPage')
    prev: href: get_id $('#phcontent_0_phfullwidthcontent_0_paginationWidget_rptPagination_lnkPrevPage')
    last: href: get_id $('#phcontent_0_phfullwidthcontent_0_paginationWidget_rptPagination_paginationLineItem_6 a')

  for link,href of ids['_links']
    if /undefined/.test href.href
      delete ids['_links'][link]
    else
      ids['_links'][link].href = "http://#{host}/search/#{@params['term']}?page=#{ids['_links'][link].href}"

  cleanup = require './cleanup'
  @body = cleanup ids

module.exports = getIds
