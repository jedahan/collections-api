nodeio = require 'node.io'
fs = require 'fs'
start = require './ids/american-wing.json'
cheerio = require 'cheerio'

_arrify  = (str) -> str.split /\r\n/
_remove_nums = (arr) -> str.replace(/\([0-9,]+\)|:/, '').trim() for str in arr
_remove_null = (arr) -> arr.filter (e) -> e.length
_flatten = (arr) -> if arr?.length is 1 then arr[0] else arr
_process = (str) -> _flatten _remove_null _remove_nums _arrify str
_trim = (arr) -> str.trim() for str in arr

class ParseObjects extends nodeio.JobClass
  queue: start

  init: ->
    fs.readdir './ids/', (err, files) =>
      @exit err if err?
      for idFile in files
        if idFile.match(/json$/)?[0] and idFile isnt 'american-wing.json'
          for id in require "./ids/#{idFile}"
            @queue.push id if not fs.existsSync "./objects/#{id}.json"

  input: (start,num,callback) ->
    return false if start > @queue.length
    return @queue[start...@length] if start+num-1 > @queue.length
    @status "#{@queue[start...start+num]}"
    @queue[start...start+num]

  run: (id) ->
    base = 'http://www.metmuseum.org/Collections/search-the-collections/'
    delete object
    object = {}

    @get base+id, (err, data) =>
      $ = cheerio.load data
      @retry() if err?

      object['id'] = +id
      object['gallery-id'] = +$('.gallery-id a').text().match(/[0-9]+/g)?[0] or null
      object['image'] = _flatten $('a[name="art-object-fullscreen"] > img')?.attr('src')?.match /(^http.*)/g
      object['related-artworks'] = (+($(a).attr('href').match(/[0-9]+/g)[0]) for a in $('.related-content-container .object-info a'))

      # add any definition lists as properties
      object[_process $($('dt')[i]).text()] = _process $(v).text() for v,i in $('dd')

      # add description and provenance
      $('.promo-accordion > li').each (i, e) ->
        category = _process $(e).find('.category').text()
        content = $(e).find('.accordion-inner > p').text().trim()
        switch category
          when 'Description' then object[category] = content
          when 'Provenance' then object[category] = _trim _remove_null content.split(';')

      @emit id: id, object: object

  output: (rows) ->
    for row in rows
      fs.writeFileSync "objects/#{row.id}.json", JSON.stringify row.object, null, 2

@job = new ParseObjects jsdom: true, max: 10