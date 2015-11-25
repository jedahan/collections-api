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
      query_string += `${key}=${value}`
    }
  }
  return query_string
}

const getItem = function (el, host) {
  let id
  let href = el.find('a').attr('href')
  if (href && href.match(/\d+/)) {
    id = +(href.match(/\d+/)[0])
  }

  let image_thumb = el.prev().find('img').attr('src')
  if (image_thumb.match(/^\//)) {
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
  const page = (yield getEndpoint('?' + buildQueryString(this.params) + '&rpp=90'))[0].body
  const $ = cheerio.load(page[0].body)
  const ids = {
    collection: {
      items: $('.list-view-object-info').map((element) => getItem($(element), host))
    },
    _links: {
      first: { href: 1 },
      next: { href: get_id($('#phcontent_0_phfullwidthcontent_0_paginationWidget_rptPagination_lnkNextPage')) },
      prev: { href: get_id($('#phcontent_0_phfullwidthcontent_0_paginationWidget_rptPagination_lnkPrevPage')) },
      last: { href: get_id($('#phcontent_0_phfullwidthcontent_0_paginationWidget_rptPagination_paginationLineItem_6 a')) }
    }
  }
  const get_id = function (selector) {
    const selection = $(selector)
    if (selection && selection[0] && selection[0].attribs) {
      const extraction = /pg=(\d+)/.exec(selection[0].attribs.href)
      if (extraction) {
        return extraction[1]
      }
    }
    return null
  }
  // TODO: put this in cleanup?
  for (let link in ids['_links']) {
    const href = ids['_links'][link]
    if (href.href) {
      ids['_links'][link].href = `http://${host}/search/${this.params['term']}?page=${href.href}`
    } else {
      delete ids['_links'][link]
    }
  }

  this.body = cleanup(ids)
  return this.body
}

module.exports = getIds
