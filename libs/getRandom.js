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
  var object, _ref, _ref1
  const page = (yield get('http://' + this.host + '/search'))
  const max_page = /page=(\d+)$/.exec((_ref = page.body._links) != null ? (_ref1 = _ref.last) != null ? _ref1.href : void 0 : void 0)
  const random_page = Math.ceil(Math.random() * parseInt(max_page[1]))
  const ids_page = (yield get('http://' + this.host + '/search?page=' + random_page))
  const ids = ids_page.body.collection.items
  if (ids !== 0) {
    object = (yield get(ids[Math.floor(Math.random() * ids.length)].href))
  }
  const responseTime = function (x) {
    if (x) {
      return +(x.headers['x-response-time-metmuseum'].slice(0, -2))
    }
    return 0
  }
  const responseTimeMetmuseum = r.sum(r.map(responseTime, [page, ids_page, object]))
  this.set('X-Response-Time-Metmuseum', responseTimeMetmuseum + 'ms')
  if (object) {
    this.body = object.body
  } else {
    this.body = {}
  }
  return this.body
}

module.exports = getRandom
