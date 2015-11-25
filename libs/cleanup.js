const traverse = require('traverse')

const cleanup = function (object) {
  traverse(object).map(function (e) {
    if (this.circular) return this.remove()
    if (this.notLeaf && this.key != null && this.key.indexOf('List') > -1) {
      const prop = e[this.key.slice(0, -4)]
      return this.update((prop instanceof Array) ? prop : [prop])
    }
    if (e === '') return this.delete()
    if (e === 'false') return this.update(false)
    if (e === 'true') return this.update(true)
    if (!isNaN(parseInt(e))) return this.update(parseInt(e))
  })

  return object
}

module.exports = cleanup
