{exec, spawn} = require 'child_process'

tgthr = (fns, cb) ->
  res = {}
  out = (k) ->
    ->
      delete fns[k]
      res[k] = arguments
      cb res unless Object.keys(fns).length
  v out k for k, v of fns


output = (data) -> console.log data.toString()

print = (fn) ->
  (err, stdout, stderr) ->
    throw err if err
    console.log stdout, stderr
    fn?()


task 'build', 'Build, minify, and generate docs for oriDomi', ->
  exec 'coffee -mc oridomi.coffee', print ->
    exec 'uglifyjs -o oridomi.min.js oridomi.js', print()
    exec 'docco oridomi.coffee', print()


task 'watch', 'Build oriDomi continuously', ->
  watcher = spawn 'coffee', ['-mwc', 'oridomi.coffee']
  watcher.stdout.on 'data', output
  watcher.stderr.on 'data', output
