chai = require "chai"
should = chai.should()

handleThat = require "../src/handle-that.coffee"
output = []
testOutput = (parse) => (worker) => 
  std = worker.stdout
  std.setEncoding("utf8")
  std.on "data", (data) =>
    lines = data.split("\n")
    lines.pop() if lines[lines.length-1] == ""
    for line in lines
      if parse 
        output.push Number(line.replace(/[\s\[\]']/g,""))
      else
        output.push line.replace(/[\s\[\]']/g,"")

describe "handle-that", =>
  it "should work", =>
    handleThat [1,2,3], worker:"./test/_worker.js", onFork: testOutput(true), silent: true
    .then =>
      for val, i in output.sort()
        val.should.equal i+1
  it "should work with object", =>
    output = []
    handleThat [{count:5},{count:1}], object:"count", worker:"./test/_worker.js", onFork: testOutput(false), silent: true
    .then =>
      output[0].should.equal "{length:1,count:1,_count:4}"
      output[1].should.equal "{length:2,count:2,_count:2,3}"
      output[2].should.equal "{length:2,count:2,_count:0,1}"
      output[3].should.equal "{count:1,length:1,_count:0}"