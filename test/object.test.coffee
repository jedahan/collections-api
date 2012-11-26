APIeasy = require 'api-easy'
expect = require('chai').expect

APIeasy.describe('collections api')
  .discuss('When using the collections api')
  .discuss('and querying an object')
  .use('localhost', 8080)
  .setHeader('Content-Type', 'application/json')
  .discuss(' that has an invalid id type')
  .get('/object/lol')
    .expect(422)
  .discuss(' that is valid and has a well-formed date')
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
  .discuss(' that is valid and has a poorly-formed date')
  .get('/object/120006429')
    .expect(200)
  .discuss(' that may not be in the public domain')
  .get('/object/80000855')
    .expect(403)
  .discuss(' that has a valid id but does not exist')
  .get('/object/1')
    .expect(404)
  .export(module)