phantom = require 'phantom'

recursionDepth = 0
allObjects = []

parseCollection = (page) ->
  console.log page
  parsePage page, {mapper: mapCollection, reducer: reduceCollection}

parseObject = (object) ->
  console.log object
  parsePage object.url, {mapper: mapObject, reducer: reduceObject}

parsePage = (uri, callback) ->
  phantom.create (ph) ->
    ph.createPage (page) ->
      page.open uri, (status) ->
        if status is 'success'
          console.log "parsing #{uri}"
          page.injectJs 'http://ajax.googleapis.com/ajax/libs/jquery/1.7.2/jquery.min.js', ->
            setTimeout ->
              page.evaluate callback.mapper, callback.reducer
              ph.exit()
            , 5000

mapObject = ->
  object = {title: $('.tombstone').siblings('h2').text().trim()}
  object[$(k).text().trim()] = $($('.tombstone > dd')[i]).text().trim() for k,i in $('.tombstone > dt')
  return object

reduceObject = (result) ->
  console.log result
  allObjects.push result


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
  console.log result
  parseObject object.url for object in result.objects
  parseCollection result.next unless recursionDepth++ > 5
  console.log allObjects

parseCollection 'http://www.metmuseum.org/collections/search-the-collections?whenfunc=before&amp;whento=2050&amp;ft=*', 0