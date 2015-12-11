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
      kill global.__runningServer
    .then ->
      customAfter?(failures, pid)