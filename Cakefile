{exec, spawn} = require 'child_process'


output = (data) ->
  console.log data.toString()


task 'build', 'Build and minify oriDomi', ->
  exec 'coffee -c oriDomi.coffee', (err, stdout, stderr) ->
    throw err if err
    console.log stdout, stderr
    exec 'uglifyjs -o oriDomi.min.js oriDomi.js', (err, stdout, stderr) ->
      throw err if err
      console.log stdout, stderr


task 'watch', 'Build oriDomi continuously', ->
  coffee = spawn 'coffee', ['-wc', 'oriDomi.coffee']
  coffee.stdout.on 'data', output
  coffee.stderr.on 'data', output

