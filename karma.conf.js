const path = require('path');
const webpack = require('webpack');

var address = 'localhost';

module.exports = function(config) {
    let webpackConfig = require('./webpack.config.js');

    // We want inline source maps with jasmine/karma
    webpackConfig.devtool = "inline-source-map";

    let browsers = ["ChromeHeadless",  "ChromiumHeadless"];
    let seleniumChromeConfig = {};
    let seleniumFirefoxConfig = {};
    if (process.env["SELENIUM_URL"]) {
        var url = new URL(process.env["SELENIUM_URL"]);
        browsers = ["Chrome_selenium"];
        seleniumChromeConfig = {
            hostname: url.hostname,
            port: url.port,
            protocol: url.protocol,
            path: url.pathname
        };

        var ifaces = require('os').networkInterfaces();
        for (var dev in ifaces) {
            ifaces[dev].filter((details) => details.family === 'IPv4' && details.internal === false ? address = details.address: undefined);
        }
    }

    config.set({
        // These might be useful to run without the origin checking:
        //browsers: ["ChromeHeadless", "Chrome_without_security", "ChromiumHeadless", "Chromium_without_security"],

        hostname: address,
        browsers: browsers,

        customLaunchers: {
            Chrome_without_security: {
                base: "ChromeHeadless",
                flags: ['--disable-web-security']
            },
            Chromium_without_security: {
                base: "ChromiumHeadless",
                flags: ['--disable-web-security']
            },
            Chrome_selenium: {
                base: 'WebDriver',
                browserName: 'chrome',
                platform: 'ANY',
                version: 'ANY',
                config: seleniumChromeConfig
            }
        },

        webpack: webpackConfig,

        colors: true,

        basePath: '',
        autoWatch: true,
        singleRun: true,
        concurrency: Infinity,

        frameworks: ['jasmine'],

        reporters: ['coverage-istanbul', 'coverage', 'json'],

        jsonReporter: {
            stdout: false,
            outputFile: 'test/karma-result.json'
        },

        files: [
            'test/**/*_test.js'
        ],

        preprocessors: {
            'test/**/*_test.js':  ['webpack', 'sourcemap'],
        },

        coverageIstanbulReporter: {
            reports: ['html'],
            dir: path.join(__dirname, "coverage", "js"),
        },

        coverageReporter: {
            instrumenterOptions: {
                istanbul: { noCompact: true }
            }
        }
    });
}
