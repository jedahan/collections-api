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
  const indexPage = (yield get('http://' + this.host + '/search'))

  const resultsPerPage = indexPage.body.results.length
  const maxPage = parseInt(indexPage.body.totalCollectionResults) / resultsPerPage
  const randomPage = Math.ceil(Math.random() * maxPage)

  const idsPage = (yield get('http://' + this.host + '/search?page=' + randomPage))

  if (idsPage.body.results) {
    const ids = idsPage.body.results
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
      const responseTimeMetmuseum = r.sum(r.map(responseTime, [indexPage, idsPage, object]))
      this.set('X-Response-Time-Metmuseum', responseTimeMetmuseum + 'ms')
    }
  }
  return this.body
}

module.exports = getRandom
