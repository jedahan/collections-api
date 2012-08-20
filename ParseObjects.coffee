usage = '''
Usage: `$ node.io parseobject [raw_object_id|array.json]`
  Grab an objects info from metmuseum.org
'''

nodeio = require 'node.io'

class ParseObjects extends nodeio.JobClass
  runs = 0
  queue = []
  objects = []

  init: ->
    arg = @options.args[0]
    if arg is 'help' then @status usage
    queue = require arg if arg? and arg.search(/json$/) isnt -1
    queue ?= +arg or [40000448, 40000449]
    queue = [queue] unless queue.length

  input: (start, num, callback) ->
    callback false if start > queue.length
    return queue[start..start+num-1]

  run: (id) ->
    @status "run #{++runs}, page #{page}"
    base = 'http://www.metmuseum.org/Collections/search-the-collections/'

    @getHtml base+id, (err, $) =>
      if err?
        @status err
        @retry()
      else
        object = {}
        flatten = (arr) -> if arr.length is 1 then arr[0] else arr
        trim = (arr) -> text = text.trim() for text in arr
        clean = (arr) -> arr.filter (e) -> e.length
        object[$($('dt')[i]).text().trim()] = flatten clean trim $(k).text().trim().split /\r\n/ for k,i in $('dd')
        objects.push object
      @emit objects

@job = new ParseObjects {jsdom: true}