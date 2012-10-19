restify = require 'restify'
request = require 'request'
cheerio = require 'cheerio'
swagger = require 'swagger-doc'

base = 'http://www.metmuseum.org/Collections/search-the-collections/'

_arrify  = (str) -> str.split /\r\n/
_remove_nums = (arr) -> str.replace(/\([0-9,]+\)|:/, '').trim() for str in arr
_remove_null = (arr) -> arr.filter (e) -> e.length
_flatten = (arr) -> if arr?.length is 1 then arr[0] else arr
_process = (str) -> _flatten _remove_null _remove_nums _arrify str
_trim = (arr) -> str.trim() for str in arr
_parseObject = (id, body, cb) ->
  err = null
  err ?= new Error "id missing" unless id?
  err ?= new Error "body empty" unless body?
  err ?= new Error "missing callback" unless cb?

  $ = cheerio.load body

  object = {}
  object['id'] = +id
  object['gallery-id'] = +$('.gallery-id a').text().match(/[0-9]+/g)?[0] or null
  object['image'] = _flatten $('a[name="art-object-fullscreen"] > img')?.attr('src')?.match /(^http.*)/g
  object['related-artworks'] = (+($(a).attr('href').match(/[0-9]+/g)[0]) for a in $('.related-content-container .object-info a'))

  # add any definition lists as properties
  object[_process $($('dt')[i]).text()] = _process $(v).text() for v,i in $('dd')

  # add description and provenance
  $('.promo-accordion > li').each (i, e) ->
    category = _process $(e).find('.category').text()
    content = $(e).find('.accordion-inner > p').text().trim()
    switch category
      when 'Description' then object[category] = content
      when 'Provenance' then object[category] = _trim _remove_null content.split(';')

  cb err, object

getObject = (req, response, next) ->
  id = +req.params.id
  if not id
    return next new restify.InvalidArgumentError "id is not a number"
  else
    console.log "Parsing #{id}"
    request {uri: base+id}, (err, res, body) ->
      # if there is a redirect, we can't find that object
      if res.request.redirects.length
        return next new restify.ResourceNotFoundError "object #{id} not found"
      else
        _parseObject id, body, (err, object) ->
          if err?
            return next err
          else
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
    {name:'id', description: 'Id of object', required:true, dataType: 'int', paramType: 'path'}
  ]

###
  Server Options
###

server.use restify.throttle
  burst: 100
  rate: 50
  ip: true
  overrides:
    '192.168.1.1':
      rate: 0
      burst: 0

server.listen 80, ->
  console.log "#{server.name} listening at #{server.url}"