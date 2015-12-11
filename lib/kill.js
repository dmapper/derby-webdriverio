/**
 * https://github.com/quietshu/shelljs/commit/6a43094a7c54d3e02b26e7a702c55e53ff343afe
 */

// Send the kill signal to child_process
// Returns true if killed successfully
function _kill(process, callback) {
    if (!process || !process.constructor) {
        return process;
    }

    // Trick to get constructor name
    // See issue: https://github.com/nodejs/node/issues/1751
    // There's no quick way to get the ChildProcess constructor to check the class of `process` object
    var constructorName;
    try {
        constructorName = /function (.{1,})\(/.exec(process.constructor.toString())[1];
    } catch (err) {
        return process;
    }
    if (constructorName !== 'ChildProcess') {
        return process;
    }

    if (process.killed || process.exitCode || process.signalCode) {
        // Already stopped
        return process;
    }

    if (!process.on || !process.kill) {
        return process;
    }

    process.on('close', function () {
        callback && callback(arguments);
    });

    return process.kill();
}

module.exports = _kill;