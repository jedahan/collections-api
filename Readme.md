## scrapi, a metropolitan museum collections api

[scrAPI.org](scrapi.org) is a [CC0](http://creativecommons.org/publicdomain/zero/1.0) api built by scraping the metropolitan museum's [collections](metmuseum.org/collection) website.

Please submit all questions, bugs and feature requests to [the issue page](https://github.com/jedahan/collections-api/issues).

Dedicated to the memory of [Aaron Swartz](http://en.wikipedia.org/wiki/Aaron_Swartz).

#### Setup

The API requires [node.js](http://nodejs.org), and is built on [koa](koajs.com)

Node comes with npm, so `npm install` to grab all the dependencies, and `npm start` to start the server.

#### Usage

Right now the only endpoint is `/object/:id`, and the server listens on port 5000, so try `curl localhost:5000/object/1234` to see the possible response.

If you want to filter that response, try using the `fields` parameter, for example:

```bash
$ curl 'localhost:5000/object/123?fields=title,whoList/who/name'
{
  "whoList": {
    "who": {
      "name": "Richard Wittingham"
    }
  },
  "title": "Andiron"
}
```

I recommend `fields=title,primaryArtistNameOnly,primaryImageUrl,medium,whatList/what/name,whenList/when/name,whereList/where/name,whoList/who/name`

##### fields syntax

The syntax to filter out fields is loosely based on XPath:

- `a,b,c` comma-separated list will select multiple fields
- `a/b/c` path will select a field from its parent
- `a(b,c)` sub-selection will select many fields from a parent
- `a/*/c` the star `*` wildcard will select all items in a field

#### Guidelines

The code is [CC0](http://creativecommons.org/publicdomain/zero/1.0), but if you do anything interesting with the data, it would be nice to give attribution to The Metropolitan Museum of Art. If you do anything interesting with the code, it would be nice to give attribution and contribute back any modifications or improvements.

#### Deployment

To deploy, install [deliver](https://github.com/gerhard/deliver), edit `.deliver/config`, and run `deliver`. This has been tested on 10.9.
