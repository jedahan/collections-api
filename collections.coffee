phantom = require 'phantom'

phantom.create (ph) ->
  ph.createPage (page) ->
    page.open 'http://www.metmuseum.org/collections/search-the-collections?whenfunc=before&amp;whento=2050&amp;ft=*', (status) ->
      console.log "opened site? #{status}"
      page.injectJs 'http://ajax.googleapis.com/ajax/libs/jquery/1.7.2/jquery.min.js', ->
        setTimeout ->
          page.evaluate ->
            nextpage = $('.next > a').attr('href')
            titles = []
            $('.hover-content > a').each ->
              a = {}
              a[$(@).attr('href')] = $(@).html()
              titles.push a

            return {
              objects: titles
              next: nextpage
            }
          , (result) ->
            console.log result
            ph.exit()
        , 5000