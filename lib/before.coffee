Bluebird = require 'bluebird'
natural = require 'natural'
nounInflector = new natural.NounInflector()
_ = require 'lodash'
chai = require 'chai'
chaiAsPromised = require 'chai-as-promised'
webdriverio = require 'webdriverio'
global.X = require './xpath'
addCustomCommands = require './commands'
waitServer = require './waitServer'
exec = require('child_process').exec

module.exports = (webdriverConf, customBefore) ->
  ->
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

    chai.Should()
    chai.use chaiAsPromised

    # Transfer promiseness
    # This has to happen on 'global.browser' because webdriverio has
    # a bunch of hardcoded stuff for it.
    unless 'browser' in Object.keys(webdriverConf.browsers)
      global.browser = global[ Object.keys(webdriverConf.browsers)[0] ]
    chaiAsPromised.transferPromiseness = global.browser.transferPromiseness

    for groupName, value of webdriverConf.browsers
      addCustomCommands global[groupName]

    Bluebird
    .resolve()
    # Clean test DB
    .then ->
      dbName = webdriverConf.server.env.MONGO_URL.match(/\/([^\/]*)$/)?[1]
      new Bluebird (resolve, reject) ->
        exec "mongo #{ dbName } --eval \"db.dropDatabase();\"", ->
          resolve()
    # Run custom before hook
    .then ->
      customBefore?()
    # Run application
    .then ->
      envStr = for key, value of webdriverConf.server.env
        "#{ key }=#{ value }"
      envStr = envStr.join ' '
      global.__runningServer = exec "#{ envStr } #{ webdriverConf.server.startCommand }"
      global.__runningServer.stdout.on 'data', (data) ->
        console.log data
      global.__runningServer.stderr.on 'data', (data) ->
        console.log data
      global.__runningServer.on 'exit', (code) ->
        'Server exited with code ' + code
        global.__runningServerExited = true
      undefined
    # Wait for server to start
    .then ->
      waitServer webdriverConf.server.waitServer
    .then ->
      Bluebird.mapSeries Object.keys(webdriverConf.browsers), (groupName) ->
        global[groupName].init()
        .timeoutsAsyncScript webdriverConf.waitforTimeout