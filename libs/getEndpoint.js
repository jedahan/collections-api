const q = require('q')
const limit = require('simple-rate-limiter')
//  request = q.denodeify(require('request'))
const request = q.denodeify(limit(require('request')).to(2).per(1000))
const random_ua = require('random-ua')
const getEndpoint = function (endpoint, api) {
  const real = api || 'http://metmuseum.org/api/collection'
  return function *(next) {
    const start = Date.now()
    const ua = random_ua.generate()
    const res = (yield request({
      followRedirect: false,
      url: real + endpoint,
      headers: {
        'User-Agent': ua
      }
    }))
    const delta = Math.ceil(Date.now() - start)
    this.set('X-Response-Time-Metmuseum', delta + 'ms')
    if (res[0].statusCode === 302) {
      this['throw'](404)
    }
    return res
  }
}

module.exports = getEndpoint
