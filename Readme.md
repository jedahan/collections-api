# scrapi, a metropolitan museum collections api

[scrAPI.org](scrapi.org) is an api that grabs object information from the metropolitan museum's [collections](http://metmuseum.org/collection) website.

### Get a random object (`/random`)
Try `curl scrapi.org/random` in a terminal, or just click on [/random](random)
```bash
$ curl 'scrapi.org/random'
{
  "CRDID": 12351,
  "accessionNumber": "65.211.3",
  ...
}
```

### Object information (`/object/:id`)

Try `curl scrapi.org/object/123` in a terminal, or just click on [object/1234](object/123)
```bash
$ curl 'scrapi.org/object/123'
{
  "CRDID": 123,
  "accessionNumber": "64.291.2",
  ...
}
```

### Searching for object ids (`/search/:terms`)

You can now search for terms, and get back an array of hrefs to object pages
```bash
$ curl 'scrapi.org/search/mirror'
{
  "collection": {
    "items": [
      {
          "href": "http://scrapi.org/object/156225"
      },
      {
          "href": "http://scrapi.org/object/207785"
      },
      ...
      ]
    }

}
```
### additional Params in search:

&page=X - for additional pages

&gallerynos=X for only objects in that gallery

### Filtering with the `fields` parameter

If you want to filter *any* response, use the `fields` parameter, like so:

```bash
$ curl 'scrapi.org/object/123?fields=title,whoList/who/name'
{
  "whoList": {
    "who": {
      "name": "Richard Wittingham"
    }
  },
  "title": "Andiron"
}
```

The syntax to filter out fields is loosely based on XPath:

- `a,b,c` comma-separated list will select multiple fields
- `a/b/c` path will select a field from its parent
- `a(b,c)` sub-selection will select many fields from a parent
- `a/*/c` the star `*` wildcard will select all items in a field

I like the following fields for basic object information: `fields=title,primaryArtistNameOnly,primaryImageUrl,medium,whatList/what/name,whenList/when/name,whereList/where/name,whoList/who/name`


### Guidelines

The code is [CC0](http://creativecommons.org/publicdomain/zero/1.0), but if you do anything interesting with the data, it would be nice to give attribution to The Metropolitan Museum of Art. If you do anything interesting with the code, it would be nice to give attribution and contribute back any modifications or improvements.

Please submit all questions, bugs and feature requests to [the issue page](https://github.com/jedahan/collections-api/issues).

Dedicated to the memory of [Aaron Swartz](http://en.wikipedia.org/wiki/Aaron_Swartz).

### Installation and Deployment

The API requires [node.js](http://nodejs.org), uses [redis](redis.io) for caching, and is built on the [koa](koajs.com) web framework.
Install the required libraries with `npm install`. You can start the server and redis together with `foreman start` if you have [foreman](http://ddollar.github.io/foreman/) (recommended), or if you have some other way of having redis run, just do `npm start`.

The current version on [scrapi.org](scrapi.org) is running on linode, running dokku. So `git push dokku master` just werks :).
