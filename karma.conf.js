const path = require('path');
const webpack = require('webpack');

process.env["NODE_ENV"] = "test";

module.exports = function(config) {
    let webpackConfig = require('./webpack.config.js');

    // We want inline source maps with jasmine/karma
    webpackConfig.devtool = "inline-source-map";

    config.set({
        // These might be useful to run without the origin checking:
        //browsers: ["ChromeHeadless", "Chrome_without_security", "ChromiumHeadless", "Chromium_without_security"],

        browsers: ["ChromeHeadless",  "ChromiumHeadless"],

        customLaunchers: {
            Chrome_without_security: {
                base: "ChromeHeadless",
                flags: ['--disable-web-security']
            },
            Chromium_without_security: {
                base: "ChromiumHeadless",
                flags: ['--disable-web-security']
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
            outputFile: 'spec/js/karma-result.json'
        },

        files: [
            'spec/js/**/*_spec.js'
        ],

        preprocessors: {
            'spec/js/**/*_spec.js':  ['webpack', 'sourcemap'],
        },

        coverageIstanbulReporter: {
            reports: ['html'],
            dir: path.join(__dirname, "public", "coverage", "js"),
        },

        coverageReporter: {
            instrumenterOptions: {
                istanbul: { noCompact: true }
            }
        }
    });
}
