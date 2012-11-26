restify = require 'restify'
request = require 'request'
cheerio = require 'cheerio'
swagger = require 'swagger-doc'
redis = require 'redis'
url = require 'url'

redis_url = url.parse(process.env.REDISTOGO_URL or 'http://127.0.0.1:6379')
cache = redis.createClient redis_url.port, redis_url.hostname

cache.on 'error', (err) ->
  console.log "Error #{err}"

scrape_url = 'http://www.metmuseum.org/Collections/search-the-collections'

_arrify  = (str) -> str.split /\r\n/
_remove_nums = (arr) -> str.replace(/\([0-9,]+\)|:/, '').trim() for str in arr
_remove_null = (arr) -> arr.filter (e) -> e.length
_flatten = (arr) -> if arr?.length is 1 then arr[0] else arr
_process = (str) -> _flatten _remove_null _remove_nums _arrify str
_trim = (arr) -> str.trim() for str in arr
_year_made = (str) ->
  t = str.split '–'
  t = t[t.length-1]
  year = +(t.match(/[0-9]+/)[0])
  year *= 100 if t.match(/century/gi)?
  year *= 1000 if t.match(/mill[\.]/gi)?
  year *= -1 if t.match(/b[\.]c/gi)?
  return year

# if the first character is non-numeric, its a loan item
_on_loan = (str) ->
  not str[0].match(/[0-9]/g)?

_parseObject = (id, body, cb) ->
  throw new Error "body empty" unless body?
  throw new Error "missing callback" unless cb?

  $ = cheerio.load body
  object = {}

  # Add all definition lists as properties
  object[_process $($('dt')[i]).text()] = _process $(v).text() for v,i in $('dd')

  # Check if the object is on loan
  if object['Accession Number'] is null or _on_loan object['Accession Number']
    return cb new restify.NotAuthorizedError "Object is on loan, view at #{scrape_url}/#{id}"

  # Check that the object is in the public domain (end date at least 70 years old)
  if object['Date'] is null or _year_made object['Date'] > new Date().getFullYear() - 70
    return cb new restify.NotAuthorizedError "Object may not be in public domain, view at #{scrape_url}/#{id}"

  object['Where'] = [object['Where']] if typeof(object['Where']) is 'string'

  object['id'] = id
  object['gallery-id'] = +$('.gallery-id a').text().match(/[0-9]+/g)?[0] or null
  object['image'] = _flatten $('a[name="art-object-fullscreen"] > img')?.attr('src')?.match /(^http.*)/g
  object['related-artworks'] = (+($(a).attr('href').match(/[0-9]+/g)[0]) for a in $('.related-content-container .object-info a')) or null

  # add description and provenance
  $('.promo-accordion > li').each (i, e) ->
    category = _process $(e).find('.category').text()
    content = $(e).find('.accordion-inner > p').text().trim()
    switch category
      when 'Description' then object[category] = content
      when 'Provenance' then object[category] = _trim _remove_null content.split(';')

  delete object[key] for key,value of object when value is null

  if not object.Date? or _extract_year object.Date > new Date().getFullYear() - 70
    return cb new Error "Object may not be in public domain", null

  cb null, object

getObject = (req, response, next) ->
  id = +req.params.id
  next new restify.UnprocessableEntityError "id missing" unless id?
  next new restify.UnprocessableEntityError "id '#{req.params.id}' is not a number" if id is NaN

  console.info "Parsing #{id}"
  cache.exists "objects:#{id}", (err, reply) ->
    console.error "Error #{err}" if err?
    if reply
      cache.get "objects:#{id}", (err, reply) ->
        console.error "Error #{err}" if err?
        response.send JSON.parse reply
    else
      request {uri: "#{scrape_url}/#{id}"}, (err, res, body) ->
        # if there is a redirect, we can't find that object
        if res.request.redirects.length
          next new restify.ResourceNotFoundError "object #{id} not found"
        else
          _parseObject id, body, (err, object) ->
            if err?
              next new restify.ForbiddenError err.message
              # should this be `throw err` or should it throw 1 deeper?
            else
              cache.set "objects:#{id}", JSON.stringify(object), redis.print
              response.send object

server = restify.createServer()

swagger.configure server, basePath: "http://localhost"

###
  Object API
###

server.get  "/object/:id", getObject
server.head "/object/:id", getObject
docs = swagger.createResource '/object'
docs.get "/object/{id}", "Gets information about a specific object in the collection",
  nickname: "getObject"
  parameters: [
    {name: 'id', description: 'Id of object, as used on website collections section', required: true, dataType: 'int', paramType: 'path'}
  ]

###
  Server Options
###

# look in header for accept: type
server.use restify.acceptParser server.acceptable
server.use restify.authorizationParser()
server.use restify.queryParser()

# we can set username: true and remove ip: true but then we have issues with all anon users being
# in the same bucket :/
# maybe read about x-forwarded-for?
# we want to throttle by ip except if a key is set
server.use restify.throttle
  burst: 100
  rate: 50
  ip: true
  overrides:
    '192.168.1.1':
      rate: 0
      burst: 0

server.listen process.env.PORT or 8080, ->
  console.log "#{server.name} listening at #{server.url}"
