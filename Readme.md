Here is an api built off the metropolitan museum's [collections][1] website.

#### Setup

    npm install
    npm start # you may need sudo for port 80
    npm test
    open http://localhost

#### Usage

  Opening http://localhost will give you a neat tool to browse the api.

  * `/ids/:page` List a bunch of ids, where `:page` is some number, starting with `1`
  * `/object/:id` List an objects information, where `:id` is some id from `/ids/:page`

#### Dependencies

  * node.js
  * redis [optional]
  * dtrace [optional]

#### Options

  * Set `COLLECTIONS_API_NO_CACHE` to stop trying to connect to the redis cache


This code is [CC0](http://creativecommons.org/publicdomain/zero/1.0/), and dedicated to the memory of [Aaron Swartz](http://en.wikipedia.org/wiki/Aaron_Swartz).

[1]: http://www.metmuseum.org/collections