usage = '''
Usage: `$ node.io listobjects [startpage] [endpage]`
  Grab all object links in a range of pages from metmuseum.org/collections
'''

nodeio = require 'node.io'

class ListObjects extends nodeio.JobClass
  runs = 0
  queue = []

  init: ->
    if @options.args[0] is 'help' then @status usage
    start = +@options.args[0] or 1
    end = +@options.args[1] or start+4
    queue = [start..end]

  input: (start, num, callback) ->
    callback false if start > queue.length
    return queue[start..start+num-1]

  run: (page) ->
    ids = []
    @status "run #{++runs}, page #{page}"
    base = 'http://www.metmuseum.org/collections/search-the-collections?ft=*&whento=2050&whenfunc=before&rpp=60&pg='

    @getHtml base+page, (err, $) =>
      if err?
        @retry()
      else
        $('.hover-content a').each ->
          ids.push /([0-9]+)/.exec($(@).attr('href'))[0]
      @emit ids

  output: './ids.json'

@job = new ListObjects {jsdom: true}