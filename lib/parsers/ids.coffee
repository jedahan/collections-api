cheerio = require 'cheerio'
os = require 'os'
_ = require '../util'

parseIds = (page, body, cb) ->
  throw new Error "body empty" unless body?
  throw new Error "missing callback" unless cb?
  page = + page

  id_path = "http://#{os.hostname()}/ids?page="

  $ = cheerio.load body

  idarray = ((_.a_to_id $(a)) for a in $('.object-image'))
  if idarray.length is 0
    cb new restify.NotFoundError
  else
    items = (href: id_to_a(id) for id in idarray)
    ids = collection: href: "#{id_path}+#{page}", items: items

    ids['_links'] = first: href: "#{id_path}1"
    ids['_links'].last = href: "#{id_path}" _.a_to_id $('.pagination a').last() or 6240
    if page isnt 1 then ids['_links'].prev = href: "#{id_path}" + page-1
    if page isnt _.a_to_id $('.pagination a').last() or page isnt 6240 then ids['_links'].next = href: "#{id_path}" + page+1

    cb null, ids

module.exports = parseIds