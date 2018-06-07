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

chunkify = (arr, n) =>
  return [arr] if n < 2
  len = arr.length
  out = []
  i = 0
  if len % n == 0
    size = Math.floor(len / n)
    while (i < len) 
      out.push(arr.slice(i, i += size))
  else
    while (i < len) 
      size = Math.ceil((len - i) / n--)
      out.push(arr.slice(i, i += size))
  return out

chunkifyObj = (prop, arr, n) =>
  if n < 2
    o = arr[0]
    tmp = o.length = o[prop]
    o["_"+prop] = [0...tmp]
    return [o]
  len = arr.reduce ((acc, cur) => acc + cur[prop]), 0
  sorted = arr.sort (a,b) => a[prop] - b[prop]
  out = []
  for piece in sorted
    size = Math.ceil(len / n)
    len -= (tmp = piece[prop])
    if piece[prop] <= size 
      piece.length = tmp
      piece["_"+prop] = [0...tmp]
      n--
      out.push piece
    else
      count = Math.ceil(tmp / size)
      n -= count
      size = Math.ceil(tmp / count) 
      for i in [0...count]
        tmp2 = [size*i...Math.min(tmp,size*(i+1))]
        curr = Object.assign length: tmp2.length, piece
        curr["_"+prop] = tmp2
        curr[prop] = tmp2.length
        out.push curr
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

processWork = (work, options) =>
  work = flatten(work) unless options.flatten == false
  getLen = (arr) =>
    if (prop = options.object)
      arr.reduce ((acc, cur) => acc + cur[prop]), 0
    else
      arr.length
  if (remaining = getLen(work)) > 0
    unless options.shuffle == false
      work = shuffle(work)
    else
      work.reverse()
    neededWorkers = Math.min(remaining, (options.concurrency or require("os").cpus().length))
    c = options.chunkify
    unless c?
      if options.object
        c = chunkifyObj.bind(null,options.object)
      else
        c = chunkify
    work = c(work, Math.max(neededWorkers, remaining / Math.sqrt(2)) )
  return [remaining, neededWorkers, work]

module.exports = (work, options) => new Promise (resolve, reject) =>
  reject new Error "handle-that: no worker defined" unless options?.worker
  [remaining, neededWorkers, work] = processWork(work, options)
  if (total = remaining) > 0
    current = 0
    if options.onText?
      options.silent = true
    options.cwd ?= process.cwd()
    options.end ?= process.env
    for i in [0...neededWorkers]
      worker = fork(_worker, [path.resolve(options.worker), "--colors"], options)
      if (onText = options.onText)?
        ["stdout","stderr"].forEach (std) =>
          std = worker[std]
          std.setEncoding("utf8")
          std.on "data", (data) =>
            lines = data.split("\n")
            lines.pop() if lines[lines.length-1] == ""
            onText(lines, remaining)
      options.onFork?(worker)
      worker.on "message", ((w, {done, cancel}) =>
        if cancel
          w.disconnect()
          if --neededWorkers == 0
            options.onFinish?()
            resolve()
        else if done?
          pieces = work.pop()
          if done
            remaining -= done
            options.onProgress?(remaining) if remaining > 0
            if remaining == 0
              options.onFinish?()
              resolve()
          if pieces
            w.send pieces: pieces, current: current, length: total
            current += pieces.length
          else
            --neededWorkers
            w.disconnect()
        ).bind(null, worker)
      worker.on "exit", (code) =>
        if code == 1
          reject(new Error "Worker exited unexpectedly")
  else
    finish()

module.exports.shuffle = shuffle
module.exports.chunkify = chunkify
module.exports.chunkifyObj = chunkifyObj
module.exports.flatten = flatten
module.exports.processWork = processWork