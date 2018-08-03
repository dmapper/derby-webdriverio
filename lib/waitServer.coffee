###
 * Original: grunt-wait-server
 * https://github.com/imyelo/grunt-wait-server
###

net = require 'net'
request = require 'request'
once = require 'once'
defaults = require 'lodash/defaults'
Bluebird = require 'bluebird'

module.exports = (options) ->
  new Bluebird (resolve, reject) ->
    options = defaults {}, options,
      timeout: 10 * 1000
      interval: 800
      print: true

    if not options.req and not options.net
      err = '[derby-webdriverio] requires the req or net option'
      console.error err
      return reject err

    client = null

    callback = once (isTimeout) ->
      console.log() if options.print # print new line
      if isTimeout
        err = '[derby-webdriverio] server timeout'
        console.error err
        return reject err
      console.log '[derby-webdriverio] Server is ready.' if options.print
      resolve()

    wait = (callback) ->
      process.stdout.write '[derby-webdriverio] Waiting for the server' if options.print
      tryConnection = ->
        process.stdout.write '.' if options.print
        if options.req
          # if options.req use request
          request options.req, (err) ->
            unless err
              return callback()
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
