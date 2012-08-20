usage = '''
Usage: `$ node.io parseobject [raw_object_id|array.json]`
  Grab an objects info from metmuseum.org
'''

nodeio = require 'node.io'
queue = []

class ParseObject extends nodeio.JobClass
  init: ->
    if @options.args[0] is 'help'
      @status usage
      @exit()

  input: ->
    arg = @options.args[0]
    # if the argument contains .json, load it as an object
    objects = require arg if arg? and arg.search(/json$/) isnt -1
    # if the argument is a number, use that as the object id
    # if there are no arguments, pick two objects for testing
    objects ?= +arg or [40000448, 40000449]
    # make sure to wrap the +arg as an array
    objects = [objects] unless objects.length
    objects

  run: (id) ->
    return if ~queue.indexOf id
    base = 'http://www.metmuseum.org/Collections/search-the-collections/'

    @getHtml base+id, (err, $) =>
      if err?
        @status err
        @retry()
      else
        object = {}
        object[$($('dt')[i]).text().trim()] = $(k).text().trim() for k,i in $('dd')
        @emit object
        queue.push id

@job = new ParseObject {timeout: 60, jsdom: true}