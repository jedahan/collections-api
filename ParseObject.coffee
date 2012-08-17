usage = '''
Usage: `$ node.io parseobject [raw_object_id|array.json]`
  Grab an objects info from metmuseum.org
'''

nodeio = require 'node.io'

class ParseObject extends nodeio.JobClass
  init: ->
    if @options.args[0] is 'help'
      @status usage
      @exit()
  
  input: ->
    arg = @options.args[0]
    objects = require arg if arg? and arg.search(/json$/) isnt -1
    objects ?= +arg or 40000448
    objects = [objects] unless objects.length
    objects

  run: (id) ->
    base = 'http://www.metmuseum.org/Collections/search-the-collections/'

    @getHtml base+id, (err, $) =>
      if err?
        @status err
        @retry()
      else
        object = {}
        object[$($('dt')[i]).text().trim()] = $(k).text().trim() for k,i in $('dd')
        @emit object

@job = new ParseObject {timeout: 60, jsdom: true}