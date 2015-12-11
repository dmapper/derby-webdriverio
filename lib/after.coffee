Bluebird = require 'bluebird'
kill = require './kill'

module.exports = (webdriverConf, customAfter) ->
  ->
    Bluebird
    .resolve()
    .then ->
      Bluebird.mapSeries Object.keys(webdriverConf.browsers), (groupName) ->
        global[groupName].end()
    .then ->
      kill global.__runningServer
    .then ->
      customAfter?()