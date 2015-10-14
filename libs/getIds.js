const getEndpoint = require('./getEndpoint')

const cheerio = require('cheerio')

const getIds = function *(next) {
  var $, cleanup, e, get_id, host, href, ids, link, page, _ref
  page = (yield getEndpoint('?ft=' + (this.params['term'] || '*') + '&pg=' + (this.query['page'] || '1') + (this.query['gallerynos'] ? '&gallerynos=' + this.query['gallerynos'] : '') + '&rpp=90'))
  $ = cheerio.load(page[0].body)
  host = this.host
  ids = {
    collection: {
      items: (function () {
        var _i, _len, _ref, _results
        _ref = $('.list-view-object-info').map(function () {
          var id, _ref, _ref1, image_thumb
            ;({
              title: $(this).find('.objtitle').text().trim()
            })
          id = +((_ref = $(this).find('a').attr('href')) != null ? (_ref1 = _ref.match(/\d+/)) != null ? _ref1[0] : void 0 : void 0)
          image_thumb = $(this).prev().find('img').attr('src')
          if (image_thumb.match(/^\//)) {
            image_thumb = 'http://metmuseum.org' + image_thumb
          }
          var artist = $(this).find('.artist').text().trim()
          var accession_number = $(this).find('.objectinfo').eq(2).text().replace(/Accession Number: /, '')
          var date = $(this).find('.objectinfo').eq(0).text().replace(/Date: /, '')
          var medium = $(this).find('.objectinfo').eq(1).text().replace(/Medium: /, '')
          var gallery = $(this).find('.gallery').text()
          // On view in Gallery
          if (gallery.match(/not on view/i)) {
          }
          gallery = gallery.replace(/On view in Gallery /, '')
          return {
            id: id,
            CRDID: id,
            href: 'http://' + host + '/object/' + id,
            website_href: 'http://www.metmuseum.org/collection/the-collection-online/search/' + id,
            title: $(this).find('.objtitle').text().trim(),
            image_thumb: image_thumb,
            primaryArtistNameOnly: artist,
            accessionNumber: accession_number,
            dateText: date,
            medium: medium,
            gallery: gallery

          }
        })
        _results = []
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          e = _ref[_i]
          _results.push(e)
        }
        return _results
      })()
    }
  }
  get_id = function (selector) {
    var _ref, _ref1, _ref2, _ref3
    return (_ref = /pg=(\d+)/.exec((_ref1 = $(selector)) != null ? (_ref2 = _ref1[0]) != null ? (_ref3 = _ref2.attribs) != null ? _ref3.href : void 0 : void 0 : void 0)) != null ? _ref[1] : void 0
  }
  ids['_links'] = {
    first: {
      href: 1
    },
    next: {
      href: get_id($('#phcontent_0_phfullwidthcontent_0_paginationWidget_rptPagination_lnkNextPage'))
    },
    prev: {
      href: get_id($('#phcontent_0_phfullwidthcontent_0_paginationWidget_rptPagination_lnkPrevPage'))
    },
    last: {
      href: get_id($('#phcontent_0_phfullwidthcontent_0_paginationWidget_rptPagination_paginationLineItem_6 a'))
    }
  }
  _ref = ids['_links']
  for (link in _ref) {
    href = _ref[link]
    if (/undefined/.test(href.href)) {
      delete ids['_links'][link]
    } else {
      ids['_links'][link].href = 'http://' + host + '/search/' + this.params['term'] + '?page=' + ids['_links'][link].href
    }
  }
  cleanup = require('./cleanup')
  this.body = cleanup(ids)
  return this.body
}

module.exports = getIds
