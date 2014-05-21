modules.export = getObject

traverse = require 'traverse'
getEndpoint = require 'libs/getEndpoint'

xml2js = require 'xml2js'
firstCharLowerCase = (str) -> if /^[A-Z]+$/.test str then str else str.charAt(0).toLowerCase() + str.slice(1)
parser = new xml2js.Parser(trim: true, explicitArray: false, explicitRoot: false, tagNameProcessors: [ firstCharLowerCase ])
parseString = q.denodeify parser.parseString

getObject = (next) -->
  xml = yield getEndpoint "/#{@params['id']}?xml=1"
  object = yield parseString xml[0].body
  delete object['$']
  traverse(object).forEach (e) ->
    switch e
      when "" then @remove
      when "false" then false
      when "true" then true
      else
        unless isNaN +e then +e

  @body = object
