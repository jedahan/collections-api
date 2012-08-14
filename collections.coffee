phantom = require 'phantom'

allObjects = []
parseCollection 'http://www.metmuseum.org/collections/search-the-collections?whenfunc=before&amp;whento=2050&amp;ft=*', 0

parseCollection = (page, recursionDepth) ->
  return if recursionDepth > 5
  parsePage page, {mapper: mapCollection, reducer: reduceCollection}

parseObject = (object) ->
  parsePage object.url, {mapper: mapObject, reducer: reduceObject}

parsePage = (uri, callback) ->
  phantom.create (ph) ->
    ph.createPage (url) ->
      page.open uri, (status) ->
        if status is 'success'
          console.log "parsing #{uri}"
          page.injectJs 'http://ajax.googleapis.com/ajax/libs/jquery/1.7.2/jquery.min.js', ->
            setTimeout ->
              page.evaluate callback.mapper, callback.reducer
              ph.exit()
              , 5000

mapObject = (object) ->
  parsePage object.url, ->
  object.title ||= $('.tombstone').siblings('h2').text().trim()
  object[$(k).text().trim()] = $($('.tombstone > dd')[i]).text().trim() for k,i in $('.tombstone > dt')

reduceObject = (result) ->
  console.log "allObjects.push #{result}"

mapCollection = ->
  nextpage = $('.next > a').attr('href')
  collection = []
  $('.hover-content > a').each ->
    collection.push { name: $(@).html(), url: $(@).attr('href') }

  return {
    objects: collection
    next: nextpage
  }

reduceCollection = (result) ->
  console.log "parseObject #{object}" for object in result.objects
  parseCollection result.next, recursionDepth+1 # DANGER WILL ROBINSON! RECURSION AHEAD
  console.log allObjects