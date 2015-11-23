const r = require('ramda')

const thunkify = require('thunkify')
const request = thunkify(require('request'))

const get = function *(url) {
  return ((yield request({
    json: true,
    url: url
  })))[0]
}

const getHeader = (headerName) =>
  (page) => page && page.headers[headerName] ? page.headers[headerName] : null

const getRandom = function *(next) {
  const page = (yield get('http://' + this.host + '/search'))
  if (page.body && page.body._links && page.body._links.last) {
    const max_page = +(page.body._links.last.href.match(/(\d+)/)[0])
    const random_page = Math.ceil(Math.random() * max_page)
    const ids_page = (yield get('http://' + this.host + '/search?page=' + random_page))

    if (ids_page.body && ids_page.body.collection && ids_page.body.collection.items) {
      const ids = ids_page.body.collection.items
      if (ids.length) {
        const object = (yield get(ids[Math.floor(Math.random() * ids.length)].href))
        this.body = object ? object.body : {}

        const responseTime = function (x) {
          if (x) {
            return +(x.headers['x-response-time-metmuseum'].slice(0, -2))
          }
          return 0
        }
        const responseTimeMetmuseum = r.sum(r.map(responseTime, [page, ids_page, object]))
        this.set('X-Response-Time-Metmuseum', responseTimeMetmuseum + 'ms')
      }
    }
  }
  return this.body
}

module.exports = getRandom
