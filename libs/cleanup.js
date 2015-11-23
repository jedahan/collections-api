const traverse = require('traverse')

const cleanup = function (object) {
  delete object['$']
  traverse(object).forEach(function (e) {
    if (this.notLeaf && this.key != null && this.key.indexOf('List') > -1) {
      const prop = e[this.key.slice(0, -4)]
      return prop instanceof Array ? prop : [prop]
    }
    switch (e) {
      case '':
        return this.remove
      case 'false':
        return false
      case 'true':
        return true
      default:
        const i = parseInt(e)
        if (!isNaN(i)){
          return i
        }
    }
  })
  return object
}

module.exports = cleanup
