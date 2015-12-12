Bluebird = require 'bluebird'

module.exports = (webdriverConf, customAfter) ->
  (failures, pid) ->

    Bluebird
    .resolve()
    .then ->
      Bluebird.mapSeries Object.keys(webdriverConf.browsers), (groupName) ->
        global[groupName].end()
    .then ->
      console.log 'Kill Server'
      new Bluebird (resolve, reject) ->
        return resolve() if global.__runningServerExited
        global.__runningServer.on 'exit', ->
          console.log 'Server Exited'
          resolve()
        console.log 'Send kill signal'
        global.__runningServer.kill('SIGKILL')
    .then ->
      customAfter?(failures, pid)