server: coffee --compile --watch server.coffee
coffee: coffee --compile --watch test/*coffee
supervisor: supervisor --quiet server.js
proxy: corsproxy 0.0.0.0 80
redis: redis-server