###
  Toobusy is a mozilla module that checks if the server is under too much load to complete a request.
  Much better than having an unending queue and having to restart
###

module.exports = ->
  toobusy = require 'toobusy'

  (req, res, next) -> if toobusy() then res.send 503, "I'm busy right now, sorry." else next()