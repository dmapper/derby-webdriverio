###
 * Original: grunt-wait-server
 * https://github.com/imyelo/grunt-wait-server
###

net = require 'net'
request = require 'request'
once = require 'once'
_ = require 'lodash'
Bluebird = require 'bluebird'

module.exports = (options) ->
  new Bluebird (resolve, reject) ->
    options = _.defaults {}, options,
      timeout: 10 * 1000
      interval: 800
      print: true

    if not options.req or not options.net
      return reject '[derby-webdriverio] requires the req or net option'

    client = null

    callback = once (isTimeout) ->
      if isTimeout
        return reject '[derby-webdriverio] server timeout'
      console.log '[derby-webdriverio] Server is ready.' if options.print
      resolve()

    wait = (callback) ->
      tryConnection = ->
        console.log '[derby-webdriverio] Waiting for the server ...' if options.print
        if options.req
          # if options.req use request
          request options.req, (err) ->
            return callback() unless err
            setTimeout tryConnection, options.interval
        else if options.net
          # if options.net use net.connect
          client = net.connect options.net, ->
            client.destroy()
            callback()
          client.on 'error', ->
            client.destroy()
            setTimeout tryConnection, options.interval

      tryConnection()

    wait(callback)
    if options.timeout > 0
      setTimeout(callback.bind(null, true), options.timeout)
