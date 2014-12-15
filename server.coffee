koa = require 'koa'
response_time = require 'koa-response-time'
logger = require 'koa-logger'
cors = require 'koa-cors'
etag = require 'koa-etag'
fresh = require 'koa-fresh'
compress = require 'koa-compress'
mask = require 'koa-json-mask'
router = require 'koa-router'
markdown = require 'koa-markdown'
serve = require 'koa-static'
getIds = require './libs/getIds'
getObject = require './libs/getObject'

app = koa()

# Default middleware
cache = ratelimit = -> (next) -> yield next

if app.env isnt 'development'
  console.log 'cache ON'
  cache = require 'koa-redis-cache'
  oneDay = 60*60*24
  oneMonth = oneDay * 30

  console.log 'limits ON'
  limit = require 'koa-better-ratelimit'
  ratelimit = (next) -> limit(
    duration: 1000 * 60,
    max: 8
  )

app.use response_time()
app.use logger()
app.use cors()
app.use etag()
app.use fresh()
app.use compress()
app.use serve 'static'
app.use mask()
app.use router(app)
app.get '/', markdown baseUrl: '/', root: __dirname, indexName: 'Readme'
app.get '/object/:id', cache(expire: oneMonth), ratelimit(), getObject
app.get '/search/:term', cache(expire: oneDay), ratelimit(), getIds
app.get '/search', cache(expire: oneDay), ratelimit(), getIds
app.get '/random', require './libs/getRandom'

app.listen process.env.PORT or 5000, ->
  console.log "[#{process.pid}] listening on :#{+@_connectionKey.split(':')[2]}"
