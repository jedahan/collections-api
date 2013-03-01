restify = require 'restify'
request = require 'request'
cheerio = require 'cheerio'
swagger = require 'swagger-doc'
redis = require 'redis'
async = require 'async'
toobusy = require 'toobusy'

cache = CACHE = not process.env.COLLECTIONS_API_NO_CACHE?

scrape_url = 'http://www.metmuseum.org/Collections/search-the-collections'

_arrify  = (str) -> str.split /\r\n/
_remove_count = (arr) -> str.replace(/\([0-9,]+\)|:/, '').trim() for str in arr
_remove_empty = (arr) -> arr.filter (e) -> e.length
_flatten = (arr) -> if arr?.length is 1 then arr[0] else arr
_process = (str) -> _flatten _remove_empty _remove_count _arrify str
_trim = (arr) -> str.trim() for str in arr
_exists = (item, cb) -> cb item?
_get_id = (el) -> +(el.attr('href')?.match(/\d+/)?[0])

_check_if_busy = (req, res, next) ->
  if toobusy()
    res.send 503, "I'm busy right now, sorry."
  else next()

_check_cache = (options) ->
  redis_url = require("url").parse(process.env.REDISTOGO_URL or 'http://0.0.0.0:6379')
  cache = require("redis").createClient redis_url.port, redis_url.hostname
  cache.auth redis_url.auth.split(":")[1] if redis_url.auth?

  cache.on 'error', (err) ->
    console.error err

  (req, res, next) ->
    if req.method is 'GET'
      cache.get req.getPath(), (err, reply) ->
        console.error err if err?
        if reply?
          res.send JSON.parse reply
        else
          next()
    else
      next()

_scrape = (url, parser, req, res, next) ->
  console.log "Scraping #{url}"
  request url, (err, response, body) ->
    console.error err if err?
    # if there is a redirect, we can't find that url
    if response.request.redirects.length
      next new restify.ResourceNotFoundError "#{url} not found"
    else
      parser req.getHref(), body, (err, result) ->
        if err?
          next new restify.ForbiddenError err.message
          # should this be `throw err` or should it throw 1 deeper?
        else
          cache.set req.getPath(), JSON.stringify(result), redis.print if CACHE
          res.send result

queryIds = (req, res, next) ->
  _scrape "#{scrape_url}?rpp=60&pg=#{req.params.page}&ft=#{req.params.query}", _parseIds, req, res, next

getIds = (req, res, next) ->
  _scrape "#{scrape_url}?rpp=60&pg=#{req.params.id}", _parseIds, req, res, next

getObject = (req, res, next) ->
  _scrape "#{scrape_url}/#{req.params.id}", _parseObject, req, res, next

getRandomObject = (req, res, next) ->
  request "#{server.url}/ids/1", (err, response, body) ->
    max = JSON.parse(body)._links.last.href
    random_page = Math.floor(Math.random() * /\d+/.exec(max)) + 1

    request "#{server.url}/ids/#{random_page}", (err, response, body) ->
      ids = JSON.parse(body).ids
      random_id = ids[Math.floor(Math.random() * ids.length) + 1]
      request "#{server.url}/object/#{random_id}", (err, response, body) ->
        res.send JSON.parse body

_parseObject = (path, body, cb) ->
  throw new Error "body empty" unless body?
  throw new Error "missing callback" unless cb?
  throw new Error "empty path" unless path?

  $ = cheerio.load body
  object = {}

  # Add all definition lists as properties
  object[_process $($('dt')[i]).text()] = _process $(v).text() for v,i in $('dd')

  # make sure Where always returns an array
  object['Where'] = [object['Where']] if typeof(object['Where']) is 'string'
  object['id'] = + /\d+/.exec(path)[0]
  object['gallery-id'] = _get_id($('.gallery-id a')) or null
  object['image'] = $('a[name="art-object-fullscreen"] > img').attr('src')?.match(/(^http.*)/)?[0]
  object['related-artworks'] = ((_get_id $(a)) for a in $('.related-content-container .object-info a')) or null

  # add description and provenance
  $('.promo-accordion > li').each (i, e) ->
    category = _process $(e).find('.category').text()
    content = $(e).find('.accordion-inner > p').text().trim()
    switch category
      when 'Description' then object[category] = content
      when 'Provenance' then object[category] = _remove_empty _trim content.split ';'

  delete object[key] for key,value of object when value is null
  object['_links'] = self: href: path

  cb null, object

_parseIds = (path, body, cb) ->
  page = +(/page=(\d+)/.exec(path)?[1] or 1)

  throw new Error "body empty" unless body?
  throw new Error "missing callback" unless cb?

  $ = cheerio.load body
  ids = {}

  ids['ids'] = ((_get_id $(a)) for a in $('.object-image')) or null

  self = self: href: path

  first = first: href: path.replace(/page=(\d+)/, "page=#{1}")

  if $('.pagination .next a').attr('href')?
    next = next: href: path.replace(/page=(\d+)/, "page=#{page+1}")
  if $('.pagination .prev a').attr('href')?
    prev = prev: href: path.replace(/page=(\d+)/, "page=#{page-1}")

  if id = $('.pagination a').last().attr('href').match(/\d+$/)
    last = last: href: path.replace(/page=(\d+)/, "page=#{id}")

  async.filter [self, first, prev, next, last], _exists,  (results) ->
    ids['_links'] = results

    cb null, ids

###
  Server Options
###
server = restify.createServer()
server.pre restify.pre.userAgentConnection()
server.use _check_if_busy
server.use restify.acceptParser server.acceptable # respond correctly to accept headers
server.use restify.queryParser() # parse query variables
server.use restify.fullResponse() # set CORS, eTag, other common headers
server.use _check_cache() if CACHE

swagger.configure server

###
  Object API
###
server.get  "/random", getRandomObject
server.head "/random", getRandomObject

server.get "/search", queryIds

server.get  "/object/:id", getObject
server.head "/object/:id", getObject

docs = swagger.createResource '/object'
docs.get "/random", "Gets information about a random object in the collection",
  nickname: "getRandom"
docs.get "/object/{id}", "Gets information about a specific object in the collection",
  nickname: "getObject"
  parameters: [
    { name: 'id', description: 'Object id as seen on collections url', required: true, dataType: 'int', paramType: 'path' }
  ]
  errorResponses: [
    { code: 404, reason: "Object not found" }
  ]

###
  Search API
###
docs = swagger.createResource '/query'
docs.get "/search", "Gets a list of ids based on a search query",
  nickname: "getQuery"
  parameters: [
    { name: 'query', description: 'search terms', required: true, dataType: 'string', paramType: 'query' }
    { name: 'page', description: 'page to return of results', required: false, dataType: 'int', paramType: 'query' }
  ]

###
  IDs API
###

server.get  "/ids/:id", getIds
server.head "/ids/:id", getIds
docs = swagger.createResource '/ids'
docs.get "/ids/{id}", "Gets a list of ids (60 per request) found in the collection",
  nickname: "getIds"
  parameters: [
    {name: 'id', description: 'Page number of ids, as used on website collections section.', required: true, dataType: 'int', paramType: 'path'}
  ]

###
  Documentation
###
server.get /\/*/, restify.serveStatic directory: './static', default: 'index.html'


server.listen process.env.PORT or 8080, ->
  console.log "[%s] #{server.name} listening at #{server.url}", process.pid