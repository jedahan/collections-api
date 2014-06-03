traverse = require 'traverse'

cleanup = (object) ->
  delete object['$']
  traverse(object).forEach (e) ->
    if @notLeaf and @key?.contains "List"
      prop = e[@key.slice 0, -4]
      if prop instanceof Array then return prop
      return [prop]
    switch e
      when "" then @remove
      when "false" then false
      when "true" then true
      else
        unless isNaN +e then +e
  return object

module.exports = cleanup
