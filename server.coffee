Q = require 'q'
request = Q.denodeify require 'request'

firstCharLowerCase = (str) -> str.charAt(0).toLowerCase() + str.slice(1)

xml2js = require 'xml2js'
parser = new xml2js.Parser(
  normalize: true
  firstCharLowerCase: true
  trim: true
  tagNameProcessors: [ firstCharLowerCase ]
)
parseString = Q.denodeify parser.parseString

koa = require 'koa'
router = require 'koa-router'
response_time = require 'koa-response-time'

api = "http://www.metmuseum.org/collection/the-collection-online/search/"

getObject = (next) -->
  xml = yield request api+@params['id']+'?xml=1'
  json = yield parseString xml[0].body
  object = json.collectionArtObjectXMLModel
  delete object['$']
  for key, value of object when value.length is 1
    object[key] = value[0]
    if object[key] is '' then delete object[key]

  @body = object

app = koa()
app.use(response_time())
app.use(router(app))
app.get '/object/:id', getObject

app.listen process.env.PORT or 5000, ->
  console.log "[%s] listening", process.pid
