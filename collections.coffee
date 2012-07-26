phantom = require 'phantom'

phantom.create (ph) ->
  ph.createPage (page) ->
    page.open 'http://www.metmuseum.org/collections/', (status) ->
      console.log "opened site? #{status}"
      page.injectJs 'http://ajax.googleapis.com/ajax/libs/jquery/1.7.2/jquery.min.js', ->
        setTimeout ->
          page.evaluate ->
            h2s = []
            ps = []
            $('h2').each ->
              h2s.push $(@).html()
            $('p').each ->
              ps.push $(@).html()

            return {
              h2: h2s,
              p: ps
            }
          , (result) ->
            console.log result
            ph.exit()
        , 5000