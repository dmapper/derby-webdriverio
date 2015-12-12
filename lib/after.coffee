Bluebird = require 'bluebird'

module.exports = (webdriverConf, customAfter) ->
  (failures, pid) ->

    Bluebird
    .resolve()
    .then ->
      Bluebird.mapSeries Object.keys(webdriverConf.browsers), (groupName) ->
        global[groupName].end()
    .then ->
      new Bluebird (resolve, reject) ->
        console.log 'Kill Server'
        global.__runningServer.kill()
    .then ->
      customAfter?(failures, pid)