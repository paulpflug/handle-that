getItDone = require process.argv[2]

process.on "message", ({pieces, current, length}) =>
  return process.send(0) unless pieces
  try
    await getItDone(pieces, current, length)
  catch e
    console.error e
  process.send(pieces.length)
process.send(0)