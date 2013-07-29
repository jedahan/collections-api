###
  The object parser takes html, and returns an error and id object
  the html body must be a string
  the callback passes an error or parsed object object

  for example:

    parseobject = require 'lib/parsers/objects'

    http.get 'http://metmuseum.org/collections/190022757', (response) ->
      parseids response, (err, obj) ->
        console.log err or obj
###

cheerio = require 'cheerio'
_ = require '../util'

parseObject = (body, cb) ->
  throw new Error "missing body" unless body?
  throw new Error "missing callback" unless cb?

  $ = cheerio.load body
  object = {}
  object['title'] = $('.art-object .first h2').text() or null
  object['id'] = + $('.artObjectZoomId').text() or null

  # Add all definition lists as properties
  object[_.process $($('dt')[i]).text()] = _.process $(v).text() for v,i in $('dd')

  # make sure Where always returns an array
  object['Where'] = [object['Where']] if typeof(object['Where']) is 'string'
  object['id'] = + id
  object['gallery-id'] = _.a_to_id($('.gallery-id a')) or null
  object['image'] = $('a[name="art-object-fullscreen"] > img').attr('src')?.match(/(^http.*)/)?[0]?.replace('web-large','original')
  object['related-images'] = ($(img).attr('src')?.replace('web-additional','original') for img in $('.tab-content.visible .object img') when $(img).attr('src').match(/images.metmuseum.org/)) or null

  # add description and provenance
  $('.promo-accordion > li').each (i, e) ->
    category = _.process $(e).find('.category').text()
    content = $(e).find('.accordion-inner > p').text().trim()
    switch category
      when 'Description' then object[category] = content
      # Split on ; that are not inside ()
      when 'Provenance' then object[category] = _.remove_empty _.trim content.split(/;(?!((?![\(\)]).)*\))/)

  delete object[key] for key,value of object when value is null or value?.length is 0
  object['_links'] = "related-artworks": (href: (_.a_to_a $(a)) for a in $('.related-content-container .object-info a')) or null

  cb null, object

module.exports = parseObject