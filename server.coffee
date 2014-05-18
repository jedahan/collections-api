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

koa = require 'koa'
router = require 'koa-router'
response_time = require 'koa-response-time'

api = "http://www.metmuseum.org/collection/the-collection-online/search/"

getObject = (next) -->
  xml = yield request api+@params['id']+'?xml=1'
  object = yield parseString xml[0].body
  delete object['$']
  delete object[key] for key, value of object when value is ""
  object[key] = +value for key, value of object when not isNaN(+value)
  @body = object

app = koa()
app.use(response_time())
app.use(router(app))
app.get '/object/:id', getObject

app.listen process.env.PORT or 5000, ->
  console.log "[#{process.pid}] listening on port #{+@_connectionKey.split(':')[2]}"
