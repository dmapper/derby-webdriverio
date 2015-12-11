webdriverDefaultConf = require './webdriver.default'
_ = require 'lodash'

module.exports = (customConfig) ->

  config = _.defaults {}, customConfig, webdriverDefaultConf,
    specs: [
      './test/e2e/**/*.js'
      './test/e2e/**/*.coffee'
    ]
    exclude: [
      './test/e2e/**/_*.js'
      './test/e2e/**/_*.coffee'
    ]
    # capabilities should always be {}
    # Use 'browsers' and 'desiredCapabilities' instead
    capabilities: {}

  config.server ?= {}
  _.defaultsDeep config.server,
    startCommand: 'npm start'
    env:
      MONGO_URL: 'mongodb://localhost:27017/test'
      PORT: config.baseUrl.match(/:(\d+)/)?[1] || 80
    waitServer:
      timeout: 10 * 1000
      interval: 800
      print: true
      req: config.baseUrl

  # Check if coffee-script is being used in the main project
  hasCoffee = true
  try
    require.resolve 'coffee-script'
  catch e
    hasCoffee = false

  # Default tester settings
  _.defaults config,
    framework: 'mocha'
    reporter: 'spec'
    mochaOpts:
      ui: 'bdd'
      compilers: ['coffee:coffee-script/register'] if hasCoffee
      timeout: config.waitforTimeout
      bail: true

  # Special settings for Chrome builds on Travis
  if (process.env.TRAVIS)
    config.desiredCapabilities.chromeOptions ?= {}
    config.desiredCapabilities.chromeOptions.args ?= ['no-sandbox']
    config.desiredCapabilities.chromeOptions.binary ?= __dirname + '/chrome-linux/chrome'

  # Add custom commands and init browsers
  config.before = require('./lib/before')(config, config.before)

  # Destroy browsers
  config.after = require('./lib/after')(config, config.after)

  config
