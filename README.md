# derby-webdriverio

> Webdriver.io for Derby.js

## Installation

```
npm i --save derby-webdriverio
```

## Usage

In your derby app index file:

```coffee
# app/index.coffee

app = require('derby').createApp 'foobar', __filename

window.app = app if window? # app must be accessible from the client
app.use require('derby-webdriverio/renderReady')
```

Create `wdio.conf.js` in project's root folder:

```js
// wdio.conf.js
exports.config = require('derby-webdriverio')({
  // Specify multiple browsers to run.
  // If it's 1 then will be created a single 'remote' instance.
  // If it's >=2 then 'multiremote' will be created; the whole group will be
  // called with the specified name; and each browser in this group will
  // have a singular form of that name + number, i.e. 'student0', 'student1', ...
  // http://webdriver.io/guide/usage/multiremote.html
  browsers: {
    browser: 1,
    prof: 1,
    students: 10
  },
  // selenium settings to use for each browser specified above
  desiredCapabilities: {
    browserName: 'chrome'
  },
  // base url which will be used for .url() methods
  baseUrl: 'http://localhost:3003',
  // timeout to wait until test fails
  waitforTimeout: 30000,
  // path to save screenshots (by default it's /test/screenshots/, don't forget
  // to add it to your .gitignore)
  screenshotPath: __dirname + '/test/screenshots/',
  // files with tests
  specs: [
    './test/e2e/**/*.js',
    './test/e2e/**/*.coffee'
  ],
  // files to ignore
  exclude: [
    './test/e2e/**/_*.js',
    './test/e2e/**/_*.coffee'
  ]
})
```

To run your tests:

```
./node_modules/.bin/wdio
```

If you want to run it as `npm test` you can add the following script to your `package.json`:

```
"scripts": {
  "test": "wdio",
},
```

---

### `.*AndWait()`

These methods accept the same arguments as the original methods.
They do the same action and wait for derby page to fully load after that.

##### `.urlAndWait()`
##### `.clickAndWait()`
##### `.submitFormAndWait()`

---

### model

All racer `get-` and `set-` methods are available.

Couple of examples:

##### `.modelGet()`

```coffee
browser
.modelGet '_session.userId'
.then (userId) ->
  @urlAndWait '/profile/' + userId
```

##### `.modelSet()`

```coffee
it 'check title', ->
  newTitle = 'New Title'
  prevTitle = yield browser.modelSet '_page.title', newTitle
  browser.getTitle()
  .then (title) ->
    title.should.not.equal prevTitle
    title.should.equal newTitle
```

##### all other get/set methods are supported -- `.modelAdd`, `.modelPop`, etc.

---

### history

##### `.historyPush(path)`

Do `app.history.push` on the client and wait for the page to fully load.

```coffee
browser
.historyPush '/profile'
.getTitle()
.should.eventually.equal 'My Profile'
```

##### `.historyRefresh()`

Refresh the page using `app.history.refresh` on the client.

---

### `X()` - XPath function

XPath helper function, provides better support for querying text nodes.
Available globally as `X`

##### `X([selector], text)`

Returns an XPath selector to find a node which holds `text`.
Optionally you can specify a CSS3 selector to narrow the lookup.

```coffee
browser
# Click on a `<button>` within `<form class='main'>` that has `Submit` text.
.click X 'form.main button', 'Submit'
```

---

### Chai shorthands

A bunch of useful shorthand methods to test things.
All of them accept the arguments which will be passed to `X()` function.

##### `shouldExist()`

```coffee
browser
# Note that the arguments passed here are `X()` function arguments
.shouldExist 'form.main button *= Submit'
.shouldExist '*= Welcome to my Website'
```

##### `shouldNotExist()`
##### `shouldBeVisible()`
##### `shouldNotBeVisible()`

##### `shouldExecute`

Accepts the same arguments as `.execute()` and checks that its return value
equals `true`

