# scrapi, a metropolitan museum collections api

[scrAPI.org](scrapi.org) is a [CC0](http://creativecommons.org/publicdomain/zero/1.0) api built by scraping the metropolitan museum's [collections](metmuseum.org/collection) website.

Please submit all questions, bugs and feature requests to [the issue page](https://github.com/jedahan/collections-api/issues).

Dedicated to the memory of [Aaron Swartz](http://en.wikipedia.org/wiki/Aaron_Swartz).

## Usage

### Object information (`/object/:id`)

The main endpoint for an object from the collection is `/object/:id`. Try `curl scrapi.org/object/123` in a terminal, or just click on [object/1234](object/123)

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

## Guidelines

The code is [CC0](http://creativecommons.org/publicdomain/zero/1.0), but if you do anything interesting with the data, it would be nice to give attribution to The Metropolitan Museum of Art. If you do anything interesting with the code, it would be nice to give attribution and contribute back any modifications or improvements.

## Installation and Deployment

The API requires [node.js](http://nodejs.org), and is built on [koa](koajs.com). Node comes with `npm`, the node package manager. Install all the libraries with `npm install`, then start the server with `npm start`.

To make deployments easy, we use  [deliver](https://github.com/gerhard/deliver). Install deliver, edit `.deliver/config`, and run `deliver` to push the latest changes to a remote server. This has been tested on OSX 10.9 and Ubuntu 14.04.
