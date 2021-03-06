var defaultTimeout = process.env.TIMEOUT
  ? ~~process.env.TIMEOUT
  : process.env.BROWSER === 'firefox'
    ? 90000
    : 60000

module.exports = {
  desiredCapabilities: {
    browserName: process.env.BROWSER || 'chrome'
  },
  logLevel: 'silent',
  coloredLogs: true,
  screenshotPath: __dirname + '/test/screenshots/',
  baseUrl: 'http://localhost:3003',
  waitforTimeout: defaultTimeout,
  browsers: {
    browser: 1
  }
}