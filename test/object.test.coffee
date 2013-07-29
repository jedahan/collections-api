# Yes, we even have some tests

APIeasy = require 'api-easy'
expect = require('chai').expect

APIeasy.describe('collections api')
  .discuss('When using the collections api to query an object')
  .use('localhost:5000')
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
  .undiscuss()
  .discuss('that has a poorly-formed date')
  .get('/object/120006429')
    .expect(200)
  .undiscuss()
  .discuss('that does not exist')
  .get('/object/123456789')
    .expect(404)
  .undiscuss()
  .export(module)