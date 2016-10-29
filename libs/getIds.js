'use strict'

const getEndpoint = require('./getEndpoint')

const buildQueryString = function (context) {
  let queryString = ''
  const conversions = {
    'term': { query: 'q', defaults: '*' },
    'page': { query: 'page', defaults: '1' },
    'gallery': { query: 'gallerynos' }
  }

  for (let key in conversions) {
    const value = context[key] || conversions[key].defaults
    if (value) {
      queryString += `${key}=${value}&`
    }
  }

  return queryString.slice(0, -1)
}

const getIds = function *(next) {
  const response = (yield getEndpoint('/collectionlisting?' + buildQueryString(this.params)))
  const stuff = JSON.parse(response[0].body)
  this.body = stuff
  return this.body
}

module.exports = getIds
