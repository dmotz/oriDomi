spawn = require('child_process').spawn

output = (data) ->
  console.log data.toString()


task 'build', 'Compile oriDomi', ->
  coffee = spawn 'coffee', ['-c', 'oriDomi.coffee']
  coffee.stdout.on 'data', output
  coffee.stderr.on 'data', output

task 'watch', 'Compile oriDomi continuously', ->
  coffee = spawn 'coffee', ['-wc', 'oriDomi.coffee']
  coffee.stdout.on 'data', output
  coffee.stderr.on 'data', output

