;(function () {
  var cleanup, traverse

  traverse = require('traverse')

  cleanup = function (object) {
    delete object['$']
    traverse(object).forEach(function (e) {
      var prop, _ref
      if (this.notLeaf && ((_ref = this.key) != null ? _ref.indexOf('List') !== -1 : void 0)) {
        prop = e[this.key.slice(0, -4)]
        if (prop instanceof Array) {
          return prop
        }
        return [prop]
      }
      switch (e) {
        case '':
          return this.remove
        case 'false':
          return false
        case 'true':
          return true
        default:
          if (!isNaN(+e)) {
            return +e
          }
      }
    })
    return object
  }

  module.exports = cleanup
}).call(this)
