Here is a [CC0][] api built by scraping the metropolitan museum's [collections][] website.

A live instance is available on [scrAPI.org][]

Please submit all questions, bugs and feature requests to [the issue page][].

Dedicated to the memory of [Aaron Swartz][].

#### Setup
  
  The API requires [node.js][], recommends [redis][], and supports [dtrace][].

  Node comes with npm, so `npm install` to grab all the dependencies, and `sudo npm start` to start the server. Make sure all the tests pass with `npm test`. Try not to ignore the console errors - install redis (`brew install redis` on OSX) and reap the benefits of a much faster api. Redis also reduces the load on the metropolitan musuem's website, which is a good thing :)

#### Usage

  Visit [localhost][] to browse the api, pretty UI courtesy of [swagger][].

  The [restify][] framework has first-class support for [DTrace][], so enjoy the performance analysation tools.

#### Guidelines

  The code is [CC0][], but if you do anything interesting with the data, it would be nice to give attribution to The Metropolitan Museum of Art. If you do anything interesting with the code, it would be nice to give attribution and contribute back any modifications or improvements.

#### Options

  * Set `PRODUCTION=false` to ignore the redis cache. This is useful for development.

#### Deployment

  To spin up a heroku instance, just `heroku apps:create --addons redistogo`, `git remote add heroku YOUR_HEROKU_GIT_URI`, and `git push heroku master`.

  To deliver anywhere else, install [deliver][], edit `.deliver/config`, and run `deliver`. This has been tested on SmartOS 12, Ubuntu 12.04, and OSX 10.8.

[CC0]: http://creativecommons.org/publicdomain/zero/1.0
[collections]: http://www.metmuseum.org/collections
[scrAPI.org]: http://scrAPI.org
[the issue page]: https://github.com/jedahan/collections-api/issues
[Aaron Swartz]: http://en.wikipedia.org/wiki/Aaron_Swartz

[node.js]: http://nodejs.org
[redis]: http://redis.io
[DTrace]: http://mcavage.github.com/node-restify/#DTrace

[localhost]: http://localhost
[swagger]: http://swagger.wordnik.com
[restify]: http://mcavage.github.com/node-restify

[deliver]: https://github.com/gerhard/deliver