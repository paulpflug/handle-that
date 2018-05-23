{test} = require "snapy"
handleThat = require "!./src/handle-that.coffee"

test (snap) =>
  # tests basic function
  stdouts = []
  handleThat [1,2,3], worker:"./test/_worker.js", silent: true, onFork: (worker) =>
    stdouts.push worker.stdout
  # should have 1,2,3
  snap obj: stdouts, stream:["0","1","2"], transform: (arr) =>
    return arr.map((str) => str[1]).sort()

test (snap) =>
  # tests object option
  stdouts = []
  handleThat [{count:5},{count:1}], object:"count", worker:"./test/_worker.js", shuffle: false, silent: true, onFork: (worker) =>
    stdouts.push worker.stdout
  # should have count & length 6 and twice 0
  snap obj: stdouts, stream:["0","1","2","3"], transform: (arr) =>
    arr = arr.map((str) => JSON.parse(str))
    obj = {count:0,length:0,objs:[]}
    for o in arr
      obj.count += o.count
      obj.length += o.length
      Array.prototype.push.apply obj.objs, o._count
    obj.objs.sort()
    return obj