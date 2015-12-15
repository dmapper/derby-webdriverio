module.exports = (browser) ->

  # Assertions
  # -----------------------------------------------------

  browser.addCommand 'shouldExist', ->
    @waitForExist(X.apply(null, arguments)).should.eventually.be.true

  browser.addCommand 'shouldNotExist', ->
    @waitForExist(X.apply(null, arguments), undefined, true).should.eventually.be.true

  browser.addCommand 'shouldBeVisible', ->
    @waitForVisible(X.apply(null, arguments)).should.eventually.be.true

  browser.addCommand 'shouldNotBeVisible', ->
    @waitForVisible(X.apply(null, arguments), undefined, true).should.eventually.be.true

  browser.addCommand 'shouldExecute', ->
    @execute.apply this, arguments
    .then (ret) ->
      ret.value
    .should.eventually.be.true

  # History
  # -----------------------------------------------------

  browser.addCommand 'historyPush', (url) ->
    @execute (url) ->
      delete window._rendered
      _push = (url) ->
        if app.history?
          app.history.push url
        else
          history.pushState {}, '', url
      _push url
    , url
    .waitUntil ->
      @execute ->
        window._rendered
      .then (ret) ->
        ret.value

  browser.addCommand 'historyRefresh', ->
    @execute ->
      delete window._rendered
      _refresh = ->
        if app.history?
          app.history.refresh()
        else
          history.pushState {}, '', (location.pathname + location.search)
      _refresh()
    .waitUntil ->
      @execute ->
        window._rendered
      .then (ret) ->
        ret.value

  # Wait for page load
  # -----------------------------------------------------

  makeWaitForPageLoad = (fnName) ->
    # Adds additional last argument -- timeout in ms (time to wait for the page to load)
    ->
      timeout = arguments[arguments.length - 1]
      args = arguments
      isReact = null
      if typeof timeout is 'number'
        args = Array.prototype.slice.call arguments, 1
      else
        timeout = undefined
      @execute ->
        return true if window.IS_REACT
        delete window._rendered
        false
      .then((ret) ->
        isReact = ret.value
      )[fnName].apply(this, args)
      .waitUntil ->
        return @pause(5000).then(-> true) if isReact
        @execute ->
          window._rendered
        .then (ret) ->
          ret.value
      , timeout

  browser.addCommand 'urlAndWait', ->
    @url.apply this, arguments
    .waitUntil ->
      @execute ->
        window._rendered
      .then (ret) ->
        ret.value
  browser.addCommand 'clickAndWait', makeWaitForPageLoad('click')
  browser.addCommand 'submitFormAndWait', makeWaitForPageLoad('submitForm')

  # Racer Model
  # -----------------------------------------------------

  modelMethod = (method, isAsync) ->
    ->
      @[if isAsync then 'executeAsync' else 'execute']
      .apply this, [(method, isAsync) ->
        done = undefined
        lastArgIndex = arguments.length
        if isAsync
          done = arguments[arguments.length - 1]
          lastArgIndex = arguments.length - 1
        args = Array.prototype.slice.call(arguments, 2, lastArgIndex)
        res = (app.model || model)[method].apply (app.model || model), args.concat [->
          done? res
        ]
      , method, !!isAsync].concat(Array.prototype.slice.call(arguments))
      .then (ret) ->
        ret.value

  [ # Getters (sync)
    'get',
    'getCopy',
    'getDeepCopy'
  ].forEach (method) ->
    browser.addCommand 'model' + method.charAt(0).toUpperCase() + method.slice(1)
    , modelMethod(method)

  [ # Setters (async)
    'set',
    'del',
    'setNull',
    'setDiff',
    'setDiffDeep',
    'add',
    'increment',
    'push',
    'unshift',
    'insert',
    'pop',
    'shift',
    'remove',
    'move',
    'stringInsert',
    'stringRemove'
  ].forEach (method) ->
    browser.addCommand 'model' + method.charAt(0).toUpperCase() + method.slice(1)
    , modelMethod(method, true)

  browser.addCommand 'waitForModel', ->
    @executeAsync (cb) ->
      _pingId = '__ping_' + (app.model || model).id()
      (app.model || model).add 'service', {id: _pingId}, cb
    .then (ret) ->
      ret.value