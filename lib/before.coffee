Bluebird = require 'bluebird'
natural = require 'natural'
nounInflector = new natural.NounInflector()

module.exports = (webdriverConf, customBefore) ->
  ->
    _ = require 'lodash'
    chai = require 'chai'
    chaiAsPromised = require 'chai-as-promised'
    webdriverio = require 'webdriverio'
    global.X = require './xpath'
    addCustomCommands = require './commands'

    chai.Should()
    chai.use chaiAsPromised
    chaiAsPromised.transferPromiseness = browser.transferPromiseness

    for groupName, value of webdriverConf.browsers
      if value in [1, true]
        global[groupName] = webdriverio.remote webdriverConf
      else if _.isNumber(value) and value > 0
        global[groupName] = webdriverio.multiremote do ->
          res = {}
          singularName = nounInflector.singularize groupName
          for i in [0 ... value]
            res[singularName + i] = webdriverConf
          res
      else
        throw new Error "Wrong number of instances specified for '#{ groupName }' browser group. It must be a number (for multiremote testing) or 'true' (for a single browser)"

    for groupName, value of webdriverConf.browsers
      addCustomCommands global[groupName]

    Bluebird
    .resolve customBefore?()
    .then ->
      Bluebird.mapSeries Object.keys(webdriverConf.browsers), (groupName) ->
        global[groupName].init()
        .timeoutsAsyncScript webdriverConf.waitforTimeout