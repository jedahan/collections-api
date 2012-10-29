APIeasy = require 'api-easy'
expect = require('chai').expect

APIeasy.describe('collections api')
  .discuss('When using the collections api')
  .discuss('and querying an object')
  .use('localhost', 8080)
  .setHeader('Content-Type', 'application/json')
  .get('/object/lol')
    .expect(422)
  .get('/object/150007868')
    .expect(200)
    .expect('should have no errors', (err, res, body) ->
      expect(err).to.not.exist
    )
    .expect('should return a body', (err, res, body) ->
      expect(body).to.exist
    )
    .expect('the id to be what we asked for', (err, res, body) ->
      id = JSON.parse(body).id
      expect(id).to.equal 150007868
    )
  .get('/object/80000855')
    .expect(403)
  .get('/object/1')
    .expect(404)
  .export(module)