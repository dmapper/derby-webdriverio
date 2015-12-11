_ = require('lodash')
cssToXPath = require('css-to-xpath')

module.exports = exports = function() { // (text) or (selector, text) or (selector, text, returnSelectorNode)
  var selector, text

  // Returns XPath as a CasperJS XPath instance (NOT a string, if you want to get a string
  // from it - get the .path field)

  // Return text nodes which contain 'text'
  // @param {string} text
  if (arguments.length === 1) {
    // Don't do anything if already is XPath (starts with //)
    if ( /^\(?\/\//.test(arguments[0]) ) {
      return arguments[0]
    // If text starts with
    // . # [ *
    // treat it as css selector
    } else if ( /^[\.#\[\*]/.test(arguments[0]) ) {
      return cssToXPath(arguments[0])
    } else {
      text = xPathStringLiteral(arguments[0])
      return "(//*[not(self::script)][contains(., " + text + ")])[last()]"
    }
  }

  // Return the 'selector' nodes which contain 'text' anywhere in them
  // @param {string} selector
  // @param {string} text
  // @param {boolean} returnSelectorNode
  else if (arguments.length === 2) {
    selector = arguments[0]
    text = xPathStringLiteral(arguments[1])
    return cssToXPath(selector).slice(1) + "[contains(., " + text + ")]"
  }

  else {
    throw new Error("Invalid amount of arguments provided - #{ arguments.length }")
  }
}

// http://stackoverflow.com/a/3425925
function xPathStringLiteral(s) {
  if (s.indexOf('"') === -1)
    return '"'+s+'"'
  if (s.indexOf("'") === -1)
    return "'"+s+"'"
  return 'concat("'+s.replace(/"/g, '",\'"\',"')+'")'
}

exports.stringLiteral = xPathStringLiteral
exports.fromCss = function() {
  return cssToXPath.apply(this, arguments).slice(1)
}
