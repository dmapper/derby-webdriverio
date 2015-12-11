module.exports = (app, waitTimeout = 10) ->

  app.on 'ready', ->
    setTimeout (-> window._rendered = true), waitTimeout

  app.on 'routeDone', ->
    unless app.derby.util.isServer
      setTimeout (-> window._rendered = true), waitTimeout
