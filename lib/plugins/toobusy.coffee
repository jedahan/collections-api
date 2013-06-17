module.exports = ->
  toobusy = require 'toobusy'

  ((req, res, next) -> if toobusy() then res.send 503, "I'm busy right now, sorry." else next())