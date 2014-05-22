traverse = require 'traverse'

cleanup = (object) ->
  delete object['$']
  traverse(object).forEach (e) ->
    switch e
      when "" then @remove
      when "false" then false
      when "true" then true
      else
        unless isNaN +e then +e
  return object

module.exports = cleanup
