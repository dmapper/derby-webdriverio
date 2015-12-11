module.exports = (webdriverConf, customAfter) ->
  (failures, pid) ->
    Bluebird = require 'bluebird'
    kill = require './kill'

    Bluebird
    .resolve()
    .then ->
      Bluebird.mapSeries Object.keys(webdriverConf.browsers), (groupName) ->
        global[groupName].end()
    .then ->
      new Bluebird (resolve, reject) ->
        console.log 'Kill Server'
        kill global.__runningServer, (code, signal) ->
          console.log 'KILLED SERVER!'
          resolve()
    .then ->
      customAfter?(failures, pid)