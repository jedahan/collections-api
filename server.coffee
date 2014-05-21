getObject = require 'libs/getObject'
getIds = require 'libs/getIds'

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
