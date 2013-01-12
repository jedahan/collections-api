Here is an api built off the metropolitan museum's [collections][1] website.

Setup

    npm install
    npm start # you may need sudo for port 80
    npm test
    open http://localhost/index.html

Usage

  Opening http://localhost/index.html will give you a neat tool to browse the api.

  * `/ids/:page` List a bunch of ids, where `:page` is some number, starting with `1`
  * `/object/:id` List an objects information, where `:id` is some id from `/ids/:page`

Dependencies

  * node.js
  * redis [optional]
  * dtrace [optional]

Environment Variables

  * `COLLECTIONS_API_NO_CACHE` Do not attempt to connect to a redis cache


[1]: http://www.metmuseum.org/collections