q = require 'q'
request = q.denodeify require 'request'

firstCharLowerCase = (str) ->
  if /^[A-Z]+$/.test str then str else str.charAt(0).toLowerCase() + str.slice(1)

xml2js = require 'xml2js'
parser = new xml2js.Parser(
  trim: true
  explicitArray: false
  explicitRoot: false
  tagNameProcessors: [ firstCharLowerCase ]
)
parseString = q.denodeify parser.parseString

api = "http://www.metmuseum.org/collection/the-collection-online/search"

traverse = require 'traverse'

getObject = (next) -->
  xml = yield request api+'/'+@params['id']+'?xml=1'
  object = yield parseString xml[0].body
  delete object['$']
  traverse(object).forEach (e) ->
    switch e
      when "" then @remove
      when "false" then false
      when "true" then true
      else
        unless isNaN +e then +e

  @body = object

cheerio = require 'cheerio'

getSearch = (next) -->
  search = yield request api+'?rpp=90&ft='+@params['term']
  $ = cheerio.load search[0].body
  hostname = 'scrapi.org'
  @body = (e for e in $('.list-view-object-info > a').map ->
    "http://#{hostname}/object/#{+($(@).attr('href')?.match(/\d+/)?[0])}")

koa = require 'koa'
response_time = require 'koa-response-time'
logger = require 'koa-logger'
etag = require 'koa-etag'
fresh = require 'koa-fresh'
compress = require 'koa-compress'
mask = require 'koa-json-mask'
router = require 'koa-router'
markdown = require 'koa-markdown'

app = koa()
app.use response_time()
app.use logger()
app.use etag()
app.use fresh()
app.use compress()
app.use mask()
app.use router(app)
app.get '/', markdown({ baseUrl: '/', root: __dirname, indexName: 'Readme'})
app.get '/object/:id', getObject
app.get '/search/:term', getSearch

app.listen process.env.PORT or 5000, ->
  console.log "[#{process.pid}] listening on port #{+@_connectionKey.split(':')[2]}"
