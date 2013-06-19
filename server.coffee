restify = require 'restify'
request = require 'request'
cheerio = require 'cheerio'
swagger = require 'swagger-doc'
redis = require 'redis'
async = require 'async'
os = require 'os'

cache = require './lib/plugins/cache' if process.env.NODE_ENV is 'production'
toobusy = require './lib/plugins/toobusy'

scrape = require './lib/scrape'
parse = require './lib/parse'
_ = require './lib/util'

scrape_url = 'http://www.metmuseum.org/Collections/search-the-collections'

getSomething = (url, parser, req, res, next) ->
  scrape url, (err, body) ->
    parser req, body, (err, result) ->
      if err?
        res.send new restify.ForbiddenError err.message
      else
        cache.set req.getPath(), JSON.stringify(result), redis.print if cache?
        res.send result

getIds = (req, res, next) ->
  req.params.page ?= 1
  req.params.query ?= '*'
  getSomething "#{scrape_url}?rpp=60&pg=#{req.params.page}&ft=#{req.params.query}", _parseIds, req, res, next

getObject = (req, res, next) ->
  getSomething "#{scrape_url}/#{req.params.id}", _parseObject, req, res, next

getRandomObject = (req, res, next) ->
  request "#{server.url}/ids", (err, response, body) ->
    max = JSON.parse(body)._links.last.href
    random_page = Math.floor(Math.random() * /\d+/.exec(max)) + 1

    request "#{server.url}/ids?page=#{random_page}", (err, response, body) ->
      ids = JSON.parse(body).collection.items
      request ids[Math.floor(Math.random() * ids.length) + 1].href, (err, response, body) ->
        res.send JSON.parse body

_parseObject = (req, body, cb) ->
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
  object['gallery-id'] = _.get_id($('.gallery-id a')) or null
  object['image'] = $('a[name="art-object-fullscreen"] > img').attr('src')?.match(/(^http.*)/)?[0]?.replace('web-large','original')
  object['related-artworks'] = ((_.get_id $(a)) for a in $('.related-content-container .object-info a')) or null

  # add description and provenance
  $('.promo-accordion > li').each (i, e) ->
    category = _.process $(e).find('.category').text()
    content = $(e).find('.accordion-inner > p').text().trim()
    switch category
      when 'Description' then object[category] = content
      # TODO: fix content split to only work outside of ()
      when 'Provenance' then object[category] = _.remove_empty _.trim content.split ';'

  delete object[key] for key,value of object when value is null
  object['_links'] =
    self: href: "http://#{os.hostname()+req.getHref()}"
    related: ({href: "http://#{os.hostname()}/object/#{id}"} for id in object['related-artworks'])

  cb null, object

_parseIds = (req, body, cb) ->
  throw new Error "body empty" unless body?
  throw new Error "missing callback" unless cb?
  page = + req.params.page

  id_path = "http://#{os.hostname()}/ids?page="

  $ = cheerio.load body

  idarray = ((_.get_id $(a)) for a in $('.object-image')) or null
  items = (href: "http://#{os.hostname()}/object/#{id}" for id in idarray)
  ids = collection: href: "http://#{os.hostname()+req.getHref()}", items: items

  ids['_links'] = first: href: "#{id_path}1"
  ids['_links'].last = href: "#{id_path}" + $('.pagination a').last().attr('href')?.match(/\d+$/) or 6240
  if page isnt 1 then ids['_links'].prev = href: "#{id_path}" + page-1
  if page isnt + $('.pagination a').last().attr('href')?.match(/\d+$/) or page isnt 6240 then ids['_links'].next = href: "#{id_path}" + page+1

  cb null, ids

###
  Server Options
###
server = restify.createServer()
server.pre restify.pre.userAgentConnection()
server.use toobusy()
server.use restify.acceptParser server.acceptable # respond correctly to accept headers
server.use restify.queryParser() # parse query variables
server.use restify.fullResponse() # set CORS, eTag, other common headers
server.use restify.gzipResponse()
server.use cache.check() if cache?

###
  Routes
###
server.get  "/random", getRandomObject
server.head "/random", getRandomObject

server.get  "/object/:id", getObject
server.head "/object/:id", getObject

server.get  "/ids", getIds
server.head "/ids", getIds

###
  Documentation
###
swagger.configure server
docs = swagger.createResource '/docs'
docs.get "/random", "Gets information about a random object in the collection",
  nickname: "getRandomObject"

docs.get "/object/{id}", "Gets information about a specific object in the collection",
  nickname: "getObject"
  parameters: [
    { name: 'id', description: 'Object id as seen on collections url', required: true, dataType: 'int', paramType: 'path' }
  ]
  errorResponses: [
    { code: 404, reason: "Object not found" }
  ]

docs.get "/ids", "Gets a list of ids (60 per request) found in the collection",
  nickname: "getIds"
  parameters: [
    { name: 'query', description: 'search terms if any', required: false, dataType: 'string', paramType: 'query' }
    { name: 'page', description: 'page to return of results', required: false, dataType: 'int', paramType: 'query' }
  ]

###
  Static files
###
server.get /\/*/, restify.serveStatic directory: './static', default: 'index.html', charSet: 'UTF-8'

server.listen process.env.PORT or 80, ->
  console.log "[%s] #{server.name} listening at #{server.url}", process.pid
