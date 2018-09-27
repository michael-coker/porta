/* global module */
var webpackConfig = require('./config/webpack/test.js')
module.exports = function (config) {
  'use strict'

  config.set({
    autoWatch: true,
    singleRun: true,

    frameworks: ['jquery-3.2.1', 'jasmine-jquery', 'jasmine', 'fixture'],

    preprocessors: {
      'app/javascript/src/**/*.spec.js': [ 'webpack' ]
    },

    files: [
      'app/javascript/karma/jasmine.js',
      'app/javascript/karma/fixtures.js',
      { pattern: 'app/javascript/src/**/*spec.js', watched: false }
    ],

    webpack: webpackConfig,

    webpackMiddleware: {
    },

    plugins: [
      'karma-jasmine',
      'karma-jasmine-jquery',
      'karma-jquery',
      'karma-fixture',
      'karma-webpack',
      'karma-chrome-launcher',
      'karma-firefox-launcher',
      'karma-junit-reporter'
    ],

    browserNoActivityTimeout: 60000,

    browsers: ['Chrome'],

    reporters: ['progress'],

    junitReporter: {
      outputDir: 'tmp/junit/karma'
    }

  })
}
