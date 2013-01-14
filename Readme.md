Here is an api built off the metropolitan museum's [collections][collections] website

Questions, bug reports and feature requests are appreciated, please submit them to [github issues][issues]

#### Setup

    npm install
    npm start # you may need sudo for port 80
    npm test

#### Tools

  A nice graphical api browser is included [http://localhost][localhost]

#### URLs

  * `/ids/:page` List a bunch of ids, where `:page` is some number, starting with `1`
  * `/object/:id` List an objects information, where `:id` is some id from `/ids/:page`

#### Dependencies

  * node.js
  * redis [optional]
  * dtrace [optional]

#### Options

  * Set `COLLECTIONS_API_NO_CACHE` to stop trying to connect to the redis cache

#### Deployment

  *Heroku*

  A Procfile is included if you want to spin an instance up on heroku. It has support for RedisToGo for caching. There is a testing server on [http://collections-api.herokuapp.com][testing]


This code is [CC0][CC0] and dedicated to the memory of [Aaron Swartz][Aaron Swartz].

[collections]: http://www.metmuseum.org/collections
[issues]: https://github.com/jedahan/collections-api/issues
[localhost]: http://localhost
[CC0]: http://creativecommons.org/publicdomain/zero/1.0
[Aaron Swartz]: http://en.wikipedia.org/wiki/Aaron_Swartz
[testing]: http://collections-api.herokuapp.com