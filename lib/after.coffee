Bluebird = require 'bluebird'
natural = require 'natural'
nounInflector = new natural.NounInflector()

module.exports = (webdriverConf, customAfter) ->
  (failures, pid) ->

    Bluebird
    .resolve()
    .then ->
      # Kill browsers one by one
      Bluebird.mapSeries Object.keys(webdriverConf.browsers), (groupName) ->
        amount = webdriverConf.browsers[groupName]
        if amount in [1, true]
          global[groupName].end()
        else
          singularName = nounInflector.singularize groupName
          Bluebird.mapSeries [0 ... amount], (i) ->
            global[groupName].select(singularName + i).end()
    .then ->
      console.log 'Kill Server'
      new Bluebird (resolve, reject) ->
        return resolve() if global.__runningServerExited
        global.__runningServer.on 'exit', ->
          console.log 'Server Exited'
          resolve()
        console.log 'Send kill signal'
        process.kill(-global.__runningServer.pid)
    .then ->
      customAfter?(failures, pid)