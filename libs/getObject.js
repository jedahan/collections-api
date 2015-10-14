;(function () {
  var cleanup, firstCharLowerCase, getEndpoint, getObject, parseString, parser, q, xml2js

  getEndpoint = require('./getEndpoint')

  cleanup = require('./cleanup')

  q = require('q')

  xml2js = require('xml2js')

  firstCharLowerCase = function (str) {
    if (/^[A-Z]+$/.test(str)) {
      return str
    } else {
      return str.charAt(0).toLowerCase() + str.slice(1)
    }
  }

  parser = new xml2js.Parser({
    trim: true,
    explicitArray: false,
    explicitRoot: false,
    tagNameProcessors: [firstCharLowerCase]
  })

  parseString = q.denodeify(parser.parseString)

  getObject = function *(next) {
    var object, xml
    xml = (yield getEndpoint('/' + this.params['id'] + '?xml=1'))
    object = (yield parseString(xml[0].body))
    this.body = cleanup(object)
    return this.body
  }

  module.exports = getObject
}).call(this)
