restify = require 'restify'
request = require 'request'
cheerio = require 'cheerio'
swagger = require 'swagger-doc'
redis = require 'redis'
url = require 'url'
async = require 'async'

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
_exists = (item, cb) -> cb item?

_scrape = (type, url, parser, req, res, next) ->
  id = +req.params.id
  cache_id = "#{type}:#{id}"
  next new restify.UnprocessableEntityError "id missing" unless id?
  next new restify.UnprocessableEntityError "#{type} #{id} is not a number" if isNaN id

  console.log "Scraping #{type} #{id}"
  cache.exists cache_id, (err, reply) ->
    console.error err if err?
    if reply
      cache.get cache_id, (err, reply) ->
        console.error err if err?
        res.send JSON.parse reply
    else
      request url+id, (err, response, body) ->
        console.error err if err?
        # if there is a redirect, we can't find that id
        if response.request.redirects.length
          next new restify.ResourceNotFoundError "#{type} #{id} not found"
        else
          parser req.getPath(), body, (err, result) ->
            if err?
              next new restify.ForbiddenError err.message
              # should this be `throw err` or should it throw 1 deeper?
            else
              cache.set cache_id, JSON.stringify(result), redis.print
              res.send result

getIds = (req, res, next) ->
  _scrape 'ids', "#{scrape_url}?rpp=60&pg=", _parseIds, req, res, next

getObject = (req, res, next) ->
  _scrape 'object', "#{scrape_url}/", _parseObject, req, res, next


_parseObject = (path, body, cb) ->
  throw new Error "body empty" unless body?
  throw new Error "missing callback" unless cb?

  $ = cheerio.load body
  object = {}

  # Add all definition lists as properties
  object[_process $($('dt')[i]).text()] = _process $(v).text() for v,i in $('dd')

  object['Where'] = [object['Where']] if typeof(object['Where']) is 'string'
  object['id'] = path.match(/[0-9]+/g)[0]
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
  object['links'] = [{'rel':'self', 'href':path}]

  cb null, object

_parseIds = (path, body, cb) ->
  page = + /(\d+)/.exec(path)[0]
  throw new Error "body empty" unless body?
  throw new Error "missing callback" unless cb?

  $ = cheerio.load body
  ids = {}

  ids['ids'] = (+($(a).attr('href').match(/[0-9]+/g)[0]) for a in $('.object-image')) or null

  self = {'rel':'self', 'href':path}

  if $('.pagination .next a').attr('href')?
    next = {'rel':'next', 'href': path.replace /(\d+)/, page+1 }
  if $('.pagination .prev a').attr('href')?
    prev = {'rel':'prev', 'href': path.replace /(\d+)/, page-1 }

  async.filter [self, next, prev], _exists , (results) ->
    ids['links'] = results

    cb null, ids

###
  Server Options
###
server = restify.createServer()
server.use restify.acceptParser server.acceptable
server.use restify.authorizationParser()
server.use restify.queryParser()

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
  IDs API
###

server.get  "/ids/:id", getIds
server.head "/ids/:id", getIds
docs = swagger.createResource '/ids'
docs.get "/object/{id}", "Gets a list of ids found in the collection",
  nickname: "getIds"
  parameters: [
    {name: 'id', description: 'Page number of ids, as used on website collections section. Will return 60 at a time.', required: true, dataType: 'int', paramType: 'path'}
  ]


server.listen process.env.PORT or 8080, ->
  console.log "#{server.name} listening at #{server.url}"