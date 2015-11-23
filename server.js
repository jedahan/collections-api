'use strict'

var ratelimit, oneDay, oneMonth, oneYear, limit

const koa = require('koa')
const response_time = require('koa-response-time')
const logger = require('koa-logger')
const cors = require('koa-cors')
const etag = require('koa-etag')
const fresh = require('koa-fresh')
const compress = require('koa-compress')
const mask = require('koa-json-mask')
const router = require('koa-router')()
const markdown = require('koa-markdown')
const serve = require('koa-static')
const getIds = require('./libs/getIds')
const getObject = require('./libs/getObject')
const app = koa()

console.log('Environment:' + app.env)

var cache = ratelimit = function () {
  return function * (next) {
    return (yield next)
  }
}

if (app.env !== 'development') {
  console.log('cache ON')
  cache = require('koa-redis-cache')
  oneDay = 60 * 60 * 24
  oneMonth = oneDay * 30
  oneYear = oneDay * 365
  console.log('limits ON')
  limit = require('koa-better-ratelimit')
  ratelimit = function (next) {
    return limit({
      duration: 1000 * 60,
      max: 8
    })
  }
}

app.use(response_time())
app.use(logger())
app.use(cors())
app.use(etag())
app.use(fresh())
app.use(compress())
app.use(serve('static'))
app.use(mask())

router.get('/', markdown({
  baseUrl: '/',
  root: __dirname,
  indexName: 'readme'
}))

router.get('/object/:id', cache({
  expire: oneYear
}), ratelimit(), getObject)

router.get('/search/:term', cache({
  expire: oneMonth
}), ratelimit(), getIds)

router.get('/search', cache({
  expire: oneMonth
}), ratelimit(), getIds)

router.get('/random', require('./libs/getRandom'))

app.use(router.routes())

app.listen(process.env.PORT || 6666, function () {
  const key = this._connectionKey.split(':')
  const port = key[key.length-1]
  return console.log(`[${process.pid}] listening on :${port}`)
})
