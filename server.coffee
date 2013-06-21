restify = require 'restify'
request = require 'request'
swagger = require 'swagger-doc'

# Middleware
cache = require './lib/plugins/cache' if process.env.NODE_ENV is 'production'
toobusy = require './lib/plugins/toobusy'

# Scraping to json
parseIds = require './lib/parsers/ids'
parseObject = require './lib/parsers/object'
scrape = require './lib/scrape'

scrape_url = 'http://www.metmuseum.org/Collections/search-the-collections'

_getSomething = (req, url, parser, cb) ->
  scrape url, (err, body) ->
    if err
      cb err, body
    else
      parser req.params.page or req.params.id, body, (err, result) ->
        if err
          cb err, result
        else
          cache.set req.getPath(), JSON.stringify(result), console.log if cache?
          result['_links'].self = href: "http://#{req.headers.host+req.getHref()}"
          result['_links'].source = href: url
          cb null, result

getIds = (req, res, next) ->
  req.params.page ?= 1
  req.params.query ?= '*'
  url = "#{scrape_url}?rpp=60&pg=#{req.params.page}&ft=#{req.params.query}"
  _getSomething req, url, parseIds, (err, result) ->
    res.charSet 'UTF-8'
    res.send err or result

getObject = (req, res, next) ->
  url = "#{scrape_url}/#{req.params.id}"
  _getSomething req, url, parseObject, (err, result) ->
    res.charSet 'UTF-8'
    res.send err or result

getRandomObject = (req, res, next) ->
  request "#{server.url}/ids", (err, response, body) ->
    max = JSON.parse(body)._links.last.href
    random_page = Math.floor(Math.random() * /\d+/.exec(max)) + 1

    request "#{server.url}/ids?page=#{random_page}", (err, response, body) ->
      ids = JSON.parse(body).collection.items
      random_page = ids[Math.floor(Math.random() * ids.length) + 1].href
      request random_page, (err, response, body) ->
        res.send err or JSON.parse body

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

server.get  "/object", getRandomObject
server.head "/object", getRandomObject

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
