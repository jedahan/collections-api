APIeasy = require 'api-easy'
expect = require('chai').expect

APIeasy.describe('collections api')
  .discuss('When using the collections api to query an object')
  .use('localhost')
  .setHeader('Content-Type', 'application/json')
  .discuss('that is clean as a whistle')
  .get('/object/190022757')
    .expect(200)
    .expect('should have no errors', (err, res, body) ->
      expect(err).to.not.exist
    )
    .expect('should return a body', (err, res, body) ->
      expect(body).to.exist
    )
    .expect('the id to be what we asked for', (err, res, body) ->
      id = JSON.parse(body).id
      expect(id).to.equal 190022757
    )
  .undiscuss()
  .discuss('that has a poorly-formed date')
  .get('/object/120006429')
    .expect(200)
  .undiscuss()
  .discuss('that does not exist')
  .get('/object/1')
    .expect(404)
  .undiscuss()
  .export(module)