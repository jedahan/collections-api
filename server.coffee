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

_root_redirect = (req, res, next) ->
  req.url = '/index.html' if req.url is '/'
  next()

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
  id = +req.params.id
  next new restify.UnprocessableEntityError "id missing" unless id?
  next new restify.UnprocessableEntityError "#{id} is not a number" if isNaN id

  console.log "Scraping #{id}"
  request url+id, (err, response, body) ->
    console.error err if err?
    # if there is a redirect, we can't find that id
    if response.request.redirects.length
      next new restify.ResourceNotFoundError "#{id} not found"
    else
      parser req.getPath(), body, (err, result) ->
        if err?
          next new restify.ForbiddenError err.message
          # should this be `throw err` or should it throw 1 deeper?
        else
          cache.set req.getPath(), JSON.stringify(result), redis.print if CACHE
          res.send result

getIds = (req, res, next) ->
  _scrape "#{scrape_url}?rpp=60&pg=", _parseIds, req, res, next

getObject = (req, res, next) ->
  _scrape "#{scrape_url}/", _parseObject, req, res, next


_parseObject = (path, body, cb) ->
  throw new Error "body empty" unless body?
  throw new Error "missing callback" unless cb?

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
  object['links'] = [{'rel':'self', 'href':path}]

  cb null, object

_parseIds = (path, body, cb) ->
  page = + /\d+/.exec(path)[0]
  throw new Error "body empty" unless body?
  throw new Error "missing callback" unless cb?

  $ = cheerio.load body
  ids = {}

  ids['ids'] = ((_get_id $(a)) for a in $('.object-image')) or null

  self = {'rel':'self', 'href':path}

  if $('.pagination .next a').attr('href')?
    next = {'rel':'next', 'href': path.replace /\d+/, page+1 }
  if $('.pagination .prev a').attr('href')?
    prev = {'rel':'prev', 'href': path.replace /\d+/, page-1 }

  async.filter [self, next, prev], _exists , (results) ->
    ids['links'] = results

    cb null, ids

###
  Server Options
###
server = restify.createServer()
server.pre _root_redirect
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

server.get  "/object/:id", getObject
server.head "/object/:id", getObject
docs = swagger.createResource '/object'
docs.get "/object/{id}", "Gets information about a specific object in the collection",
  nickname: "getObject"
  parameters: [
    {name: 'id', description: 'Object id as seen on collections url', required: true, dataType: 'int', paramType: 'path'}
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
server.get /\/*/, restify.serveStatic directory: './static'


server.listen process.env.PORT or 80, ->
  console.log "#{server.name} listening at #{server.url}"