const path = require('path');
const webpack = require('webpack');

process.env["NODE_ENV"] = "test";

module.exports = function(config) {
    let webpackConfig = require('./webpack.config.js');

    // We want inline source maps with jasmine/karma
    webpackConfig.devtool = "inline-source-map";

    let browsers = ["ChromeHeadless",  "ChromiumHeadless"];
    if (process.env["SELENIUM_URL"]) {
        browsers = ["Chrome_selenium"];
    }
    config.set({
        // These might be useful to run without the origin checking:
        //browsers: ["ChromeHeadless", "Chrome_without_security", "ChromiumHeadless", "Chromium_without_security"],

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
                base: 'SeleniumWebdriver',
                browserName: 'Chrome',
                getDriver: function() {
                    return new webdriver.Builder()
                        .forBrowser('chrome')
                        .usingServer(process.env["SELENIUM_URL"] || 'http://localhost:4444/wd/hub')
                        .build()
                }
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
