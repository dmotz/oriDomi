{exec, spawn} = require 'child_process'

output = (data) -> console.log data.toString()

print = (fn) ->
  (err, stdout, stderr) ->
    throw err if err
    console.log stdout, stderr
    fn?()


task 'build', 'Build, minify, and generate docs for oriDomi', ->
  exec 'coffee -c oridomi.coffee', print ->
    exec 'uglifyjs -o oridomi.min.js oridomi.js', print()
    exec 'docco oridomi.coffee', print()


task 'watch', 'Build oriDomi continuously', ->
  watcher = spawn 'coffee', ['-wc', 'oridomi.coffee']
  watcher.stdout.on 'data', output
  watcher.stderr.on 'data', output
