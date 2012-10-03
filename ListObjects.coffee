nodeio = require 'node.io'
fs = require 'fs'
_ = require 'lodash'

class ListObjects extends nodeio.JobClass
  queue = [1..6057]

  init: =>
    fs.readdir './ids/', (err, files) =>
      return 1 if err?
      pages = (file.split('.')[0] for file in files)
      queue = _.difference queue,pages
      @status queue

  input: (start,num,callback) ->
    callback false if start > queue.length
    queue[start..start+num-1]

  run: (page) ->
    base = 'http://www.metmuseum.org/collections/search-the-collections?ft=*&whento=2050&whenfunc=before&rpp=60&pg='
    ids = []

    @getHtml base+page, (err, $) =>
      if err?
        @status err
        @retry()
      else
        $('.hover-content a').each (i,v) =>
          ids.push page:page, id:/([0-9]+)/.exec($(v).attr('href'))[0]
        @emit ids

  output: (rows) ->
    for row in rows
      fs.appendFileSync "ids/#{row.page}.json", "#{row.id}\n"

@job = new ListObjects jsdom: true