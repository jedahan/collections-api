usage = '''
Usage: `$ node.io listobjects [startpage] [endpage]`
  Grab all object links in a range of pages from metmuseum.org/collections
'''

nodeio = require 'node.io'

class ListObjects extends nodeio.JobClass
  init: ->
    if @options.args[0] is 'help'
      @status usage
      @exit()

  input: ->
    start = +@options.args[0] or 1
    end = +@options.args[1] or start+4
    [start..end]

  run: (page) ->
    base = 'http://www.metmuseum.org/collections/search-the-collections?ft=*&whento=2050&whenfunc=before&rpp=60&pg='

    @getHtml base+page, (err, $) =>
      if err?
        @retry()
      else
        ids = []
        $('.hover-content a').each ->
          ids.push /([0-9]+)/.exec($(@).attr('href'))[0]
        @emit ids

@job = new ListObjects {timeout: 10, jsdom: true}