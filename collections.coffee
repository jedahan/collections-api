phantom = require 'phantom'

allObjects = []

parseCollectionPage 'http://www.metmuseum.org/collections/search-the-collections?whenfunc=before&amp;whento=2050&amp;ft=*', 0

parseObject = (object) ->
  phantom.create (ph) ->
    ph.createPage (url) ->
      page.open object.url, (status) ->
        if status is 'success'
          console.log "parsing #{object.name}"
          page.injectJs 'http://ajax.googleapis.com/ajax/libs/jquery/1.7.2/jquery.min.js', ->
            setTimeout ->
            page.evaluate ->
              $('.definitions').each ->
                object[$(@).find(dd)] = $(@).find(dt)

              return object
            , (result) ->
              console.log "allObjects.push #{result}"
              ph.exit()
          , 5000

parseCollectionPage = (page, recursionDepth) ->
  return if recursionDepth > 5
  phantom.create (ph) ->
    ph.createPage (page) ->
    page.open page, (status) ->
      if status is 'success'
        console.log "opened #{page}"
        page.injectJs 'http://ajax.googleapis.com/ajax/libs/jquery/1.7.2/jquery.min.js', ->
          setTimeout ->
            page.evaluate ->
              nextpage = $('.next > a').attr('href')
              collection = []
              $('.hover-content > a').each ->
                collection.push { name: $(@).html(), url: $(@).attr('href') }

              return {
                objects: collection
                next: nextpage
              }
            , (result) ->
              console.log "parseObject #{object}" for object in result.objects
              parseCollectionPage result.next, recursionDepth+1 # DANGER WILL ROBINSON! RECURSION AHEAD
              console.log allObjects
              ph.exit()
          , 5000