// Generated by CoffeeScript 1.8.0
(function() {
  var getEndpoint, q, request;

  q = require('q');
  var limit = require("simple-rate-limiter");
//  request = q.denodeify(require('request'));
  request = q.denodeify(limit(require('request')).to(1).per(1000));

  getEndpoint = function(endpoint) {
    console.log("calling "+ endpoint);
    return function*(next) {
      var api, delta, res, start;
      api = "http://www.metmuseum.org/collection/the-collection-online/search";
      start = Date.now();
      res = (yield request({
        followRedirect: false,
        url: api + endpoint
      }));
      delta = Math.ceil(Date.now() - start);
      this.set('X-Response-Time-Metmuseum', delta + 'ms');
      if (res[0].statusCode === 302) {
        this["throw"](404);
      }
      return res;
    };
  };

  module.exports = getEndpoint;

}).call(this);
