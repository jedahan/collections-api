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

  if not $('.artObjectZoomId').text()?
    cb new restify.NotFoundError "#{id} not found"
  else
    object = {}
    object['title'] = $('.art-object .first h2').text() or null
    object['id'] = + $('.artObjectZoomId').text() or null

    # Add all definition lists as properties
    properties = {}
    properties[_.process($($('dt')[i]).text()).toLowerCase()] = _.process $(v).text() for v,i in $('dd')
    propertylist = ['who', 'what','when','where','date','culture','medium','dimensions','credit line','accession number','in the museum']
    object[property] = properties[property] for property in propertylist when properties[property]?

    # make sure 'where' always returns an array
    object['where'] = [object['where']] if typeof(object['where']) is 'string'
    object['gallery-id'] = _.a_to_id($('.gallery-id a')) or null
    object['image'] = $('a[name="art-object-fullscreen"] > img').attr('src')?.match(/(^http.*)/)?[0]?.replace('web-large','original')
    object['related-images'] = ($(img).attr('src')?.replace('web-additional','original') for img in $('.tab-content.visible .object img') when $(img).attr('src').match(/images.metmuseum.org/)) or null

    # make sure 'in the museum' gets renamed as 'department'
    if object['in the museum']
        object['department'] = object['in the museum']
        delete object['in the museum']

    # add description and provenance
    $('.promo-accordion > li').each (i, e) ->
      category = _.process($(e).find('.category').text()).toLowerCase()
      content = $(e).find('.accordion-inner > p').text().trim()
      switch category
        when 'description' then object[category] = content
        # Split on ; that are not inside ()
        when 'provenance' then object[category] = _.remove_empty _.trim content.split(/;(?!((?![\(\)]).)*\))/)

    delete object[key] for key,value of object when value is null or value?.length is 0
    object['_links'] = "related-artworks": (href: (_.a_to_a $(a)) for a in $('.related-content-container .object-info a')) or null
    object['_links']["related-content"] = ({rel: $(e).find('a').text().trim(), href: $(e).find('a').attr('href'), date: $(e).find('span').text().trim()} for e in $('ul.related-content-list li')) or null
    cb null, object

module.exports = parseObject