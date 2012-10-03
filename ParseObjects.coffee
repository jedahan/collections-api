nodeio = require 'node.io'
fs = require 'fs'

class ParseObjects extends nodeio.JobClass
  runs = 0

  run: (id) ->
    base = 'http://www.metmuseum.org/Collections/search-the-collections/'

    @getHtml base+id, (err, $) ->
      @retry() if err?

      object = {}
      arrify  = (str) -> str.split /\r\n/
      remove_nums = (arr) -> str.replace(/\([0-9,]+\)|:/, '').trim() for str in arr
      remove_null = (arr) -> arr.filter (e) -> e.length
      flatten = (arr) -> if arr.length is 1 then arr[0] else arr
      process = (str) -> flatten remove_null remove_nums arrify str
      object.id = +id
      object.image = $('a[name="art-object-fullscreen"] > img').attr('src')
      object.image = null unless /^http/.test object.image
      object[process $($('dt')[i]).text()] = process $(v).text() for v,i in $('dd')
      object['related-artworks'] = (+($(a).attr('href').match(/[0-9]+/g)[0]) for a in $('.object-info a'))
      @emit id: id, object: object

  output: (rows) ->
    for row in rows
      fs.writeFileSync "objects/#{row.id}.json", JSON.stringify row.object, null, 2

@job = new ParseObjects {jsdom: true}