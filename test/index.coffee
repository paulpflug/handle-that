chai = require "chai"
should = chai.should()

handleThat = require "../src/handle-that.coffee"
output = []
testOutput = (worker) => 
  std = worker.stdout
  std.setEncoding("utf8")
  std.on "data", (data) =>
    lines = data.split("\n")
    lines.pop() if lines[lines.length-1] == ""
    for line in lines
      output.push Number(line.replace(/[\s\[\]']/g,""))

describe "handle-that", =>
  it "should work", =>
    handleThat [1,2,3], worker:"./test/_worker.js", onFork: testOutput, silent: true
    .then =>
      for val, i in output.sort()
        val.should.equal i+1
