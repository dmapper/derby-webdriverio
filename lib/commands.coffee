module.exports = (browser) ->

  # Assertions
  # -----------------------------------------------------

  browser.addCommand 'shouldExist', ->
    @waitForExist.apply(this, arguments).should.eventually.be.true

  browser.addCommand 'shouldNotExist', (selector) ->
    @waitForExist(selector, undefined, true).should.eventually.be.true

  browser.addCommand 'shouldBeVisible', ->
    @waitForVisible.apply(this, arguments).should.eventually.be.true

  browser.addCommand 'shouldNotBeVisible', (selector) ->
    @waitForVisible(selector, undefined, true).should.eventually.be.true

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
    .waitUntil =>
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
    .waitUntil =>
      @execute ->
        window._rendered
      .then (ret) ->
        ret.value

  # Wait for page load
  # -----------------------------------------------------

  makeWaitForPageLoad = (fnName) ->
    ->
      args = arguments
      isReact = null
      @execute ->
        return true if window.IS_REACT
        delete window._rendered
        false
      .then (ret) ->
        isReact = ret.value
      .then =>
        @[fnName].apply(this, args)
      .then =>
        @waitUntil =>
          return @pause(5000).then(-> true) if isReact
          @execute ->
            window._rendered
          .then (ret) ->
            ret.value

  browser.addCommand 'urlAndWait', ->
    isReact = null
    @url.apply this, arguments
    .execute ->
      window.IS_REACT
    .then (ret) ->
      isReact = ret.value
    .then =>
      @waitUntil =>
        return @pause(5000).then(-> true) if isReact
        @execute ->
          window._rendered
        .then (ret) ->
          ret.value
  browser.addCommand 'clickAndWait', makeWaitForPageLoad('click')
  browser.addCommand 'elementIdClickAndWait', makeWaitForPageLoad('elementIdClick')
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