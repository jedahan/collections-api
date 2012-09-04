nodeio = require 'node.io'

class ListObjects extends nodeio.JobClass
  input: [1]

  run: (page) ->
    base = 'http://www.metmuseum.org/collections/search-the-collections?ft=*&whento=2050&whenfunc=before&rpp=60&pg='

    @getHtml base+page, (err, $) =>
      if err?
        @status err
        @retry()
      else
        $('.hover-content a').each (i,v) =>
          @emit /([0-9]+)/.exec($(v).attr('href'))[0]

    @add ++page

@job = new ListObjects jsdom: true