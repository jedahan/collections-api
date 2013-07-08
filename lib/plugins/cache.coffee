###
  The cache is a piece of middleware that expects urls to resolve to parsed objects
###

redis_url = require("url").parse(process.env.REDIS_URL or 'http://127.0.0.1:6379')
cache = require("redis").createClient redis_url.port, redis_url.hostname
cache.auth redis_url.auth.split(":")[1] if redis_url.auth?

cache.on 'error', (err) -> console.error err

check = (req, res, next) ->
    if req.method is 'GET'
      cache.get req.getPath(), (err, reply) ->
        console.error err if err?
        if reply?
          res.send JSON.parse reply
        else
          next()
    else
      next()

set = cache.set

module.exports = {check, set}