webdriverDefaultConf = require './webdriver.default'
_ = require 'lodash'

module.exports = (customConfig) ->

  config = _.defaults {}, customConfig, webdriverDefaultConf,
    specs: [
      process.cwd() + '/test/e2e/**/*.js'
      process.cwd() + '/test/e2e/**/*.coffee'
    ]
    exclude: [
      process.cwd() + '/test/e2e/**/_*.js'
      process.cwd() + '/test/e2e/**/_*.coffee'
    ]
    # capabilities should always be []
    # Use 'browsers' and 'desiredCapabilities' instead
    capabilities: []

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
  config.after = do (customAfter = config.after) ->
    (failures, pid) ->
      Bluebird = require 'bluebird'
      Bluebird.mapSeries Object.keys(config.browsers), (groupName) ->
        global[groupName].end()
      .then ->
        customAfter?(failures, pid)

  config
