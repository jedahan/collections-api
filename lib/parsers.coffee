parseObject = (req, body, cb) ->
  throw new Error "missing body" unless body?
  throw new Error "missing callback" unless cb?
  throw new Error "missing req" unless req?

  $ = cheerio.load body
  object = {}

  # Add all definition lists as properties
  object[_.process $($('dt')[i]).text()] = _.process $(v).text() for v,i in $('dd')

  # make sure Where always returns an array
  object['Where'] = [object['Where']] if typeof(object['Where']) is 'string'
  object['id'] = + req.params.id
  object['gallery-id'] = _.a_to_id($('.gallery-id a')) or null
  object['image'] = $('a[name="art-object-fullscreen"] > img').attr('src')?.match(/(^http.*)/)?[0]?.replace('web-large','original')
  object['related-artworks'] = ((_.a_to_a $(a)) for a in $('.related-content-container .object-info a')) or null
  object['related-images'] = ($(img).attr('src')?.replace('web-additional','original') for img in $('.tab-content.visible .object img') when $(img).attr('src').match(/images.metmuseum.org/)) or null

  # add description and provenance
  $('.promo-accordion > li').each (i, e) ->
    category = _.process $(e).find('.category').text()
    content = $(e).find('.accordion-inner > p').text().trim()
    switch category
      when 'Description' then object[category] = content
      # Split on ; that are not inside ()
      when 'Provenance' then object[category] = _.remove_empty _.trim content.split(/;(?!((?![\(\)]).)*\))/)

  delete object[key] for key,value of object when value is null
  object['_links'] =
    self: href: "http://#{os.hostname()+req.getHref()}"
    related: (href: _.id_to_a id for id in object['related-artworks'])

  cb null, object

parseIds = (req, body, cb) ->
  throw new Error "body empty" unless body?
  throw new Error "missing callback" unless cb?
  page = + req.params.page

  id_path = "http://#{os.hostname()}/ids?page="

  $ = cheerio.load body

  idarray = ((_.a_to_id $(a)) for a in $('.object-image'))
  if idarray.length is 0
    cb new restify.NotFoundError "No results for #{req.params.query}"
  else
    items = (href: id_to_a(id) for id in idarray)
    ids = collection: href: "http://#{os.hostname()+req.getHref()}", items: items

    ids['_links'] = first: href: "#{id_path}1"
    ids['_links'].last = href: "#{id_path}" _.a_to_id $('.pagination a').last() or 6240
    if page isnt 1 then ids['_links'].prev = href: "#{id_path}" + page-1
    if page isnt _.a_to_id $('.pagination a').last() or page isnt 6240 then ids['_links'].next = href: "#{id_path}" + page+1

    cb null, ids

module.exports {parseIds, parseObject}