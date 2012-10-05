nodeio = require 'node.io'
fs = require 'fs'

class ListObjects extends nodeio.JobClass
  queue: [1..6072]

  input: (start,num,callback) ->
    return false if start > @queue.length
    return @queue[start...@length] if start+num-1 > @queue.length
    @status "#{@queue[start...start+num]}"
    @queue[start...start+num]

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

  reduce: (lines) ->
    @emit page:lines[0].page, ids:lines.map (pairs) -> pairs.id

  output: (rows) ->
    fs.writeFile "./ids/#{rows.page}.json", JSON.stringify(rows.ids, null, 2), (err) ->
      @exit err if err?

@job = new ListObjects jsdom: true, max: 10