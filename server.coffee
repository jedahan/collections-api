q = require 'q'
request = q.denodeify require 'request'

xml2js = require 'xml2js'
firstCharLowerCase = (str) -> if /^[A-Z]+$/.test str then str else str.charAt(0).toLowerCase() + str.slice(1)
parser = new xml2js.Parser(trim: true, explicitArray: false, explicitRoot: false, tagNameProcessors: [ firstCharLowerCase ])
parseString = q.denodeify parser.parseString

api = "http://www.metmuseum.org/collection/the-collection-online/search"

traverse = require 'traverse'

getEndpoint = (endpoint) ->
  (next) -->
    start = Date.now()
    yield request api+endpoint
    delta = Math.ceil(Date.now() - start)
    @set 'X-Response-Time-Metmuseum', delta + 'ms'

getObject = (next) -->
  xml = yield getEndpoint "/#{@params['id']}?xml=1"
  object = yield parseString xml
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

getIds = (next) -->
  page = yield getEndpoint "?rpp=90&ft=#{@params['term']}"
  $ = cheerio.load page

  ids = collection: items: (e for e in $('.list-view-object-info').map ->
    title: $(@).find('.objtitle').text().trim()
    id = + $(@).find('a').attr('href')?.match(/\d+/)?[0]
    href: "http://#{hostname}/object/#{id}"
  )
  get_id = (selector) -> /pg=(\d+)/.exec($(selector)?[0]?.attribs?.href)?[1]

  ids['_links'] =
    first: href: 1
    next: href: get_id $('.prev a')
    prev: href: get_id $('.next a')
    last: href: get_id $('.collection-online-pages li:not(.next) a').last()

  for link,href of ids['_links']
    if /undefined/.test href.href
      delete ids['_links'][link]

  @body = ids

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
app.get '/search/:term', getIds

app.listen process.env.PORT or 5000, ->
  console.log "[#{process.pid}] listening on port #{+@_connectionKey.split(':')[2]}"
