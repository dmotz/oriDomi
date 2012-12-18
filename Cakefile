{exec, spawn} = require 'child_process'

output = (data) ->
  console.log data.toString()


task 'build', 'Build, minify, and generate docs for oriDomi', ->
  exec 'coffee -c oridomi.coffee', (err, stdout, stderr) ->
    throw err if err
    console.log stdout, stderr

    exec 'uglifyjs -o oridomi.min.js oriDomi.js', (err, stdout, stderr) ->
      throw err if err
      console.log stdout, stderr

      exec 'docco oridomi.coffee', (err, stdout, stderr) ->
        throw err if err
        console.log stdout, stderr


task 'watch', 'Build oriDomi continuously', ->
  coffee = spawn 'coffee', ['-wc', 'oridomi.coffee']
  coffee.stdout.on 'data', output
  coffee.stderr.on 'data', output
