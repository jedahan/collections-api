restify = require 'restify'
swagger = require 'swagger-doc'

scrape_url = 'http://www.metmuseum.org/Collections/search-the-collections'

# Middleware
cache = require './lib/plugins/cache' if process.env.NODE_ENV is 'production'
toobusy = require './lib/plugins/toobusy'

# Scraping and parsing to json
scrape = require './lib/scrape'
parseIds = require './lib/parsers/ids'
parseObject = require './lib/parsers/object'

_getSomething = (req, url, parser, cb) ->
  scrape url, (err, body) ->
    if err
      cb err, body
    else
      parser body, (err, result) ->
        if err
          cb err, result
        else
          result['_links'].self = href: 'http://'+req.headers.host+req.getHref()
          result['_links'].source = href: url
          # Only cache objects
          cache.redis.set req.getPath(), JSON.stringify(result) if cache? and /object/.test(req.getPath())
          cb null, result

getIds = (req, res, next) ->
  images = req.params.images or ''
  query = req.params.query or '*'
  page = req.params.page or 1
  # add the page parameter in case it doesn't exist
  req.url += (req.params.length and "&page=1" or "?page=1") unless req.params.page

  url = "#{scrape_url}?rpp=60&pg=#{page}&ft=#{query}"
  url += "&ao=on" if images?[0] is 't'
  _getSomething req, url, parseIds, (err, result) ->
    if err
      res.send err
    else
      for rel,link of result._links
        if rel in ["first", "last", "next", "prev"]
          link?.href = 'http://'+req.headers.host + req.url.replace /page=\d+/,"page=#{link?.href}"
      res.charSet 'UTF-8'
    res.send result

getObject = (req, res, next) ->
  url = "#{scrape_url}/#{req.params.id}"
  _getSomething req, url, parseObject, (err, result) ->
    res.charSet 'UTF-8'
    res.send err or result

getRandomObject = (req, res, next) ->
  client = restify.createJsonClient url: server.url
  images = if req.params.images?[0] is 't' then "images=true" else ""
  response = res

  client.get "/ids?"+images, (err, req, res, obj) ->
    if max = obj._links?.last?.href
      random_page = Math.floor(Math.random() * /\d+/.exec(max)) + 1

      client.get "/ids?page=#{random_page}&"+images, (err, req, res, obj) ->
        ids = obj.collection.items
        random_page = ids[Math.floor(Math.random() * ids.length)].href

        client.get random_page, (err, req, res, obj) ->
          response.send err or obj
    else
      res.send new restify.NotFoundError "cannot find the last page of ids"

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
  parameters: [
    { name: 'images', description: 'Only list objects that have images?', required: false, dataType: 'boolean', paramType: 'query' }
  ]

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
    { name: 'images', description: 'Only list objects that have images?', required: false, dataType: 'boolean', paramType: 'query' }
  ]

###
  Static files
###
server.get /\/*/, restify.serveStatic directory: './static', default: 'index.html', charSet: 'UTF-8'

server.listen process.env.PORT or 80, ->
  console.log "[%s] #{server.name} listening at #{server.url}", process.pid
