'use strict'

const getEndpoint = require('./getEndpoint')
const cleanup = require('./cleanup')
const cheerio = require('cheerio')

const buildQueryString = function (context) {
  let query_string = ''
  const conversions = {
    'term': { query: `ft`, defaults: '*' },
    'page': { query: `pg`, defaults: '1' },
    'gallery': { query: `gallerynos` }
  }

  for (let key in conversions) {
    const value = context[key] || conversions[key].defaults
    if (value) {
      query_string += `${key}=${value}&`
    }
  }

  return query_string.slice(0, -1)
}

const getItem = function (el, host) {
  let id
  let href = el.find('a').attr('href')
  if (href && href.match(/\d+/)) {
    id = +(href.match(/\d+/)[0])
  }

  let image_thumb = el.prev().find('img').attr('src')
  if (image_thumb && image_thumb.match(/^\//)) {
    image_thumb = 'http://metmuseum.org' + image_thumb
  }
  const title = el.find('.objtitle').text().trim()
  const artist = el.find('.artist').text().trim()
  const accession_number = el.find('.objectinfo').eq(2).text().replace(/Accession Number: /, '')
  const date = el.find('.objectinfo').eq(0).text().replace(/Date: /, '')
  const medium = el.find('.objectinfo').eq(1).text().replace(/Medium: /, '')
  let gallery = el.find('.gallery').text()
  gallery = gallery.match(/not on view/i) ? null : gallery.replace(/On view in Gallery /, '')
  return {
    id: id,
    CRDID: id,
    href: `http://${host}/object/${id}`,
    website_href: `http://www.metmuseum.org/collection/the-collection-online/search/${id}`,
    title: title,
    image_thumb: image_thumb,
    primaryArtistNameOnly: artist,
    accessionNumber: accession_number,
    dateText: date,
    medium: medium,
    gallery: gallery
  }
}

const getIds = function *(next) {
  const host = this.host
  const page = (yield getEndpoint('?' + buildQueryString(this.params) + '&rpp=90'))
  const $ = cheerio.load(page[0].body)

  const get_href = (selector) => {
    const selection = $(selector)
    if (selection && selection[0] && selection[0].attribs) {
      const extraction = /term=([\w\*]+).*pg=(\d+)/.exec(unescape(selection[0].attribs.href))
      if (extraction) {
        return `http://${host}/search/${extraction[1]}?page=${extraction[2]}`
      }
    }
    return null
  }

  const ids = {
    collection: {
      items: $('.list-view-object-info').map((_, element) => getItem($(element), host)).get()
    },
    _links: {
      first: { href: get_href($('#phcontent_0_phfullwidthcontent_0_paginationWidget_rptPagination_paginationLineItem_6 a')).replace(/\d+$/, '1') },
      next: { href: get_href($('#phcontent_0_phfullwidthcontent_0_paginationWidget_rptPagination_lnkNextPage')) },
      prev: { href: get_href($('#phcontent_0_phfullwidthcontent_0_paginationWidget_rptPagination_lnkPrevPage')) },
      last: { href: get_href($('#phcontent_0_phfullwidthcontent_0_paginationWidget_rptPagination_paginationLineItem_6 a')) }
    }
  }

  this.body = cleanup(ids)
  return this.body
}

module.exports = getIds
