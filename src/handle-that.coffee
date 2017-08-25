{fork} = require "child_process"
path = require "path"
flatten = (arrs) =>
  target = []
  for arr in arrs
    if Array.isArray(arr)
      for obj in flatten(arr)
        target.push obj
    else
      target.push arr
  return target

chunkify = (a, n) =>
  return [a] if n < 2
  len = a.length
  out = []
  i = 0
  if len % n == 0
    size = Math.floor(len / n)
    while (i < len) 
      out.push(a.slice(i, i += size))
  else
    while (i < len) 
      size = Math.ceil((len - i) / n--)
      out.push(a.slice(i, i += size))
  return out

shuffle = (array) =>
  counter = array.length
  while (0 < counter) 
    index = Math.floor(Math.random() * counter)
    counter--
    temp = array[counter]
    array[counter] = array[index]
    array[index] = temp
  return array
if path.extname(__filename) == ".coffee"
  _worker = "#{__dirname}/_worker.coffee"
else
  _worker = "#{__dirname}/_worker.js"

module.exports = (work, options) => new Promise (resolve, reject) =>
  reject new Error "handle-that: no worker defined" unless options?.worker
  work = flatten(work) unless options.flatten == false
  if (remaining = work.length) > 0
    workers = Math.min(remaining, (options.concurrency or require("os").cpus().length))
    work = shuffle(work) unless options.shuffle == false
    chunks = chunkify(work, Math.max(workers, remaining / Math.sqrt(2)) )
    if options.onText?
      options.silent ?= true
    for i in [0..workers]
      worker = fork(_worker, [path.resolve(options.worker)], options)
      if (onText = options.onText)?
        std = worker.stdout
        std.setEncoding("utf8")
        std.on "data", (data) =>
          lines = data.split("\n")
          lines.pop() if lines[lines.length-1] == ""
          onText(lines)
      options.onFork?(worker)
      worker.on "message", ((w, count) => 
        pieces = chunks.shift()
        if count
          remaining -= count
          options.onProgress?(remaining)
        if pieces
          w.send pieces
        else
          i--
          w.disconnect()
          if i == 0
            options.onFinish?()
            resolve()
        ).bind(null, worker)
  else
    options.onFinish?()
    resolve()

module.exports.shuffle = shuffle
module.exports.chunkify = chunkify
module.exports.flatten = flatten
