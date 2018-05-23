path = require "path"
importCwd = require "import-cwd"
importCwd.silent "coffee-script/register"
importCwd.silent "coffeescript/register"
importCwd.silent "ts-node/register"
importCwd.silent "babel-register"

getItDone = require process.argv[2]

process.on "message", ({pieces, current, length}) =>
  if pieces
    try
      await getItDone(pieces, current, length)
    catch e
      console.error e
    process.send(done: pieces.length)
process.send(done: 0)