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
  const index_page = (yield get('http://' + this.host + '/search'))

  const results_per_page = index_page.body.results.length
  const max_page = parseInt(index_page.body.totalCollectionResults) / results_per_page
  const random_page = Math.ceil(Math.random() * max_page)

  const ids_page = (yield get('http://' + this.host + '/search?page=' + random_page))

  if (ids_page.body.results) {
    const ids = ids_page.body.results
    if (ids.length) {
      const url = ids[Math.floor(Math.random() * ids.length)].url
      const id = parseInt(/\d+$/.exec(url))
      const object = (yield get('http://' + this.host + '/object/' + id))
      this.body = object.body

      const responseTime = function (x) {
        if (x) {
          return +(x.headers['x-response-time-metmuseum'].slice(0, -2))
        }
        return 0
      }
      const responseTimeMetmuseum = r.sum(r.map(responseTime, [index_page, ids_page, object]))
      this.set('X-Response-Time-Metmuseum', responseTimeMetmuseum + 'ms')
    }
  }
  return this.body
}

module.exports = getRandom
