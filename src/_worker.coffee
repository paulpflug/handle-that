getItDone = require process.argv[2]

process.on "message", (work) =>
  return process.send(0) unless work
  try
    await getItDone(work)
  catch e
    console.error e
  process.send(work.length)
process.send(0)