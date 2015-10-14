;(function () {
  var cache, fs, q, request

  q = require('q')

  fs = q.denodeify(require('fs'))

  request = require('request')

  cache = function () {
    return function *(next) {
      var body, cacheName
      body = JSON.parse(this.body)
      if ((this.method !== 'GET') || (this.status !== 200) || !body) {
        return
      }
      cacheName = 'cache/' + body.CRDID + '.jpg'
      if ((yield fs.exists(cacheName))) {
        return
      }
      request(body.mainImageUrl, function (err, res, body) {
        if (err) { console.log(err) }
        return fs.write(cacheName, body)
      })
      return (yield next)
    }
  }

  module.exports = cache
}).call(this)
