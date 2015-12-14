module.exports = (app, waitTimeout = 10) ->

  setPageRendered = ->
    return if app.derby.util.isServer
    setTimeout ->
      window._rendered = true
      document.documentElement.classList.add '__rendered'
    , 10

  removePageRendered = ->
    return if app.derby.util.isServer
    delete window._rendered
    document.documentElement.classList.remove '__rendered'

  app.on 'ready', setPageRendered
  app.on 'route', removePageRendered
  app.on 'routeDone', setPageRendered

