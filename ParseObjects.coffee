usage = '''
Usage: `$ node.io parseobjects [raw_object_id|array.json]`
  Grab an objects info from metmuseum.org
'''

nodeio = require 'node.io'

class ParseObjects extends nodeio.JobClass
  runs = 0
  queue = []

  init: ->
    arg = @options.args[0]
    if arg is 'help' then @status usage
    queue = require arg if arg? and arg.search(/json$/) isnt -1
    queue = @options.args unless queue.length
    queue = [40000448, 40000449] unless queue.length

  input: (start, num, callback) ->
    callback false if start > queue.length
    queue[start..start+num-1]

  run: (id) ->
    @status "run #{++runs}, object #{id}"
    base = 'http://www.metmuseum.org/Collections/search-the-collections/'

    @getHtml base+id, (err, $) =>
      if err?
        @status err
        @retry()
      else
        object = {}
        arrify  = (str) -> str.split /\r\n/
        remove_nums = (arr) -> str.replace(/\([0-9,]+\)|:/, '').trim() for str in arr
        remove_null = (arr) -> arr.filter (e) -> e.length
        flatten = (arr) -> if arr.length is 1 then arr[0] else arr
        process = (str) -> flatten remove_null remove_nums arrify str
        object[process $($('dt')[i]).text()] = process $(v).text() for v,i in $('dd')
        @emit object

  output: './objects.json'

@job = new ParseObjects {jsdom: true}