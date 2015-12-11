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
      app.history.push(url)
    , url
    .waitUntil ->
      @execute ->
        window._rendered
      .then (ret) ->
        ret.value

  browser.addCommand 'historyRefresh', ->
    @execute ->
      delete window._rendered
      app.history.refresh()
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
      if typeof timeout is 'number'
        args = Array.prototype.slice.call arguments, 1
      else
        timeout = undefined
      @execute(->
        delete window._rendered
      )[fnName].apply(this, args)
      .waitUntil ->
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
        res = app.model[method].apply app.model, args.concat [->
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
      _pingId = '__ping_' + app.model.id()
      app.model.add 'service', {id: _pingId}, cb
    .then (ret) ->
      ret.value