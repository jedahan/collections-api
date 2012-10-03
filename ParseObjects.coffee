nodeio = require 'node.io'
fs = require 'fs'

class ParseObjects extends nodeio.JobClass
  runs = 0

  _arrify  = (str) -> str.split /\r\n/
  _remove_nums = (arr) -> str.replace(/\([0-9,]+\)|:/, '').trim() for str in arr
  _remove_null = (arr) -> arr.filter (e) -> e.length
  _flatten = (arr) -> if arr?.length is 1 then arr[0] else arr
  _process = (str) -> _flatten _remove_null _remove_nums _arrify str

  run: (id) ->
    base = 'http://www.metmuseum.org/Collections/search-the-collections/'
    object = {}

    @getHtml base+id, (err, $) =>
      @retry() if err?

      object.id = +id
      object.image = _flatten $('a[name="art-object-fullscreen"] > img')?.attr('src')?.match /(^http.*)/g
      object[_process $($('dt')[i]).text()] = _process $(v).text() for v,i in $('dd')
      object['related-artworks'] = (+($(a).attr('href').match(/[0-9]+/g)[0]) for a in $('.related-content-container .object-info a'))

      @emit id: id, object: object

  output: (rows) ->
    for row in rows
      fs.writeFileSync "objects/#{row.id}.json", JSON.stringify row.object, null, 2

@job = new ParseObjects {jsdom: true}