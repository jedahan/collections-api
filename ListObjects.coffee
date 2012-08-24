nodeio = require 'node.io'

class ListObjects extends nodeio.JobClass
  queue = []

  init: ->
    start = +@options.args[0] or 1
    end = +@options.args[1] or start+4
    queue = [start..end]

  input: (start, num, callback) ->
    callback false if start > queue.length
    queue[start..start+num-1]

  run: (page) ->
    base = 'http://www.metmuseum.org/collections/search-the-collections?ft=*&whento=2050&whenfunc=before&rpp=60&pg='

    @getHtml base+page, (err, $) =>
      if err?
        @status err
        @retry()
      else
        $('.hover-content a').each (i,v) =>
          @emit /([0-9]+)/.exec($(v).attr('href'))[0]

@job = new ListObjects {jsdom: true}