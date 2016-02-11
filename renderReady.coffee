module.exports = (app, waitTimeout = 10) ->

  waitWds = (cb) ->
    _waitWds = ->
      if document.documentElement.dataset.wds
        cb()
      else
        setTimeout _waitWds, 50
    _waitWds()

  setPageRendered = (initial) ->
    return if app.derby.util.isServer
    _setPageRendered =
      setTimeout ->
        window._rendered = true
        document.documentElement.classList.add '__rendered'
      , waitTimeout
    # When running tests in dev, wait until webpack dev server loads styles
    if initial and window.env?.NODE_ENV isnt 'production'
      waitWds _setPageRendered
    else
      _setPageRendered()

  removePageRendered = ->
    return if app.derby.util.isServer
    delete window._rendered
    document.documentElement.classList.remove '__rendered'

  app.on 'ready', setPageRendered.bind(@, true)
  app.on 'route', removePageRendered
  app.on 'routeDone', setPageRendered

