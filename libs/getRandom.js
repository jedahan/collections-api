const r = require('ramda')

const thunkify = require('thunkify')
const request = thunkify(require('request'))

const get = function *(url) {
  return ((yield request({
    json: true,
    url: url
  })))[0]
}

const getRandom = function *(next) {
  var ids, ids_page, object, page, random_page, responseTime, responseTimeMetmuseum, _ref, _ref1
  page = (yield get('http://' + this.host + '/search'))
  random_page = Math.ceil(Math.random() * ((_ref = page.body._links) != null ? (_ref1 = _ref.last) != null ? _ref1.href : void 0 : void 0))
  ids_page = (yield get('http://' + this.host + '/search?page=' + random_page))
  ids = ids_page.body.collection.items
  if (ids !== 0) {
    object = (yield get(ids[Math.floor(Math.random() * ids.length)].href))
  }
  responseTime = function (x) {
    if (x) {
      return x.headers['x-response-time-metmuseum'].slice(0, -2)
    }
    return 0
  }
  responseTimeMetmuseum = r.sum(r.map(responseTime, [page, ids_page, object]))
  this.set('X-Response-Time-Metmuseum', responseTimeMetmuseum + 'ms')
  if (object) {
    this.body = object.body
  } else {
    this.body = {}
  }
  return this.body
}

module.exports = getRandom
