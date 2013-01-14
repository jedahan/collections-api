Here is a [CC0][] api built by scraping the metropolitan museum's [collections][] website.

A live version is available on [collections-api.herokuapp.com][].

Please submit all questions, bugs and feature requests to [the issue page][].

Dedicated to the memory of [Aaron Swartz][].

#### Setup
  
  The API requires [node.js][], recommends [redis][], and supports [dtrace][].

  Node comes with npm, so `npm install` to grab all the dependencies, and `sudo npm start` to start the server. Make sure all the tests pass with `npm test`. Try not to ignore the console errors - install redis (`brew install redis` on OSX) and reap the benefits of a much faster api. Redis also reduces the load on the metropolitan musuem's website, which is a good thing :)

#### Usage

  Visit [localhost][localhost] to browse the api, pretty UI courtesy of [swagger][swagger].

  The [restify][restify] framework has first-class support for [DTrace][dtrace], so enjoy the performance analysation tools.

#### Options

  * Set `COLLECTIONS_API_NO_CACHE` to ignore the redis cache. This is useful for development.

#### Deployment

  A Procfile is included if you want to spin up an instance up on heroku. Use RedisToGo for caching.

[CC0]: http://creativecommons.org/publicdomain/zero/1.0
[collections]: http://www.metmuseum.org/collections
[collections-api.herokuapp.com]: http://collections-api.herokuapp.com
[the issue page]: https://github.com/jedahan/collections-api/issues
[Aaron Swartz]: http://en.wikipedia.org/wiki/Aaron_Swartz

[node.js]: http://nodejs.org
[redis]: http://redis.io
[dtrace]: http://mcavage.github.com/node-restify/#DTrace

[localhost]: http://localhost
[swagger]: http://swagger.wordnik.com
[restify]: http://mcavage.github.com/node-restify