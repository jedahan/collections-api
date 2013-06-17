parse = (body, parser, cb) ->
  parser 'http://'+os.hostname()+req.getHref(), body, (err, result) ->
    if err?
      cb new restify.ForbiddenError err.message , null
    else
      cb result

module.exports = parse