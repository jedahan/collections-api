const getEndpoint = require('./getEndpoint')
const cleanup = require('./cleanup')
const q = require('q')
const xml2js = require('xml2js')

const firstCharLowerCase = function (str) {
  if (/^[A-Z]+$/.test(str)) {
    return str
  } else {
    return str.charAt(0).toLowerCase() + str.slice(1)
  }
}

const parser = new xml2js.Parser({
  trim: true,
  explicitArray: false,
  explicitRoot: false,
  tagNameProcessors: [firstCharLowerCase]
})

const parseString = q.denodeify(parser.parseString)

const getObject = function *(next) {
  var object, xml
  xml = (yield getEndpoint('/' + this.params['id'] + '?xml=1'))
  object = (yield parseString(xml[0].body))
  this.body = cleanup(object)
  return this.body
}

module.exports = getObject
