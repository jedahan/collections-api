APIeasy = require 'api-easy'
assert = require 'assert'

APIeasy.describe('collections api')
  .discuss('When using the collections api')
  .discuss('and working with objects')
  .use('localhost', 8080)
  .setHeader('Content-Type', 'application/json')
  .get('/object/lol')
    .expect(409)
  .get('/object/150007868')
    .expect(200)
  .get('/object/80000855')
    .expect(403)
  .get('/object/1')
    .expect(404)
  .export(module)