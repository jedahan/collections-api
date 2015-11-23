const getEndpoint = require('./getEndpoint')
const cleanup = require('./cleanup')
const q = require('q')
const xml2js = require('xml2js')

const firstCharLowerCase = (string) =>
  string.charAt(0).toLowerCase() + string.slice(1)

const parser = new xml2js.Parser({
  trim: true,
  explicitArray: false,
  explicitRoot: false,
  tagNameProcessors: [firstCharLowerCase]
})

const parseString = q.denodeify(parser.parseString)

const getObject = function *(next) {
  const xml = (yield getEndpoint('/' + this.params['id'] + '?xml=1'))
  const object = (yield parseString(xml[0].body))
  this.body = cleanup(object)
  return this.body
}

module.exports = getObject
