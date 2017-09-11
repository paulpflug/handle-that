# handle-that

handles pieces of work in parallel.
A small wrapper around `child_process.fork`.

Features:
  - chunkifys the work in pieces to minimize communication
  - shuffles the workpieces for a better load balance


### Install

```sh
npm install --save handle-that
```

### Usage

```js
handleThat = require("handle-that")

// handleThat(work:Array, options:Object)
// note, that only serializable data can be passed to workers.
handleThat(["work1","work2"],{
  worker: "./someWorker.js"
}).then(=>
  // finished
)

// ./someWorker.js
// expects a function which is called with an array of work pieces
// should return a Promise
module.exports = (work, current, altogetherWorkCount) => { return Promise.all(work.map(async (piece,i) => {
  currentWorkIndex = current+i
  // piece is either "work1" or "work2"
  return await doSomething(piece)
}))}
```

#### Options
Name | type | default | description
---:| --- | ---| ---
worker | String | - | (required) path to worker source file
shuffle | Boolean | true | should the work get shuffled
flatten | Boolean | true | the work array will be flattened
concurrency | Number | #CPUS | how many workers should get spawned
onFork | Function | - | will be called on process forking with the worker unit
onProgress | Function | - | will be called on progress with the remaining work count
onFinish | Function | - | will be called once all work is done
onText | Function | - | will set children to silent and instead call this function with all output

The options object will also get passed down to [`child_process.fork`](https://nodejs.org/api/child_process.html#child_process_child_process_fork_modulepath_args_options).

#### Example with ora

```js
path = require("path")
ora = require("ora")
handleThat = require("handle-that")

spinner = ora(work.length + " workpieces remaining...").start()

handleThat(work,{
  worker: path.resolve(__dirname, "_worker"),
  onText: (lines, remaining) => {
    spinner.stop()
    console.log(lines.join("\n"))
    spinner.start(remaining + " workpieces remaining...")
  },
  onProgress: (remaining) => { spinner.text = remaining  + " workpieces remaining..." }
  onFinish: => { spinner.succeed("finished") }
})
```

## License
Copyright (c) 2017 Paul Pflugradt
Licensed under the MIT license.
