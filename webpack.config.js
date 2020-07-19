const webpack = require('webpack');
const path = require('path');
const UglifyJsPlugin = require('uglifyjs-webpack-plugin');

/* This describes the behavior of webpack.
 */
module.exports = {
  /* The main javascript file for the application
   */
  entry: {
    rawrs: ["./assets/js/app.js"]
  },

  /* The eventual transpiled output file.
   */
  output: {
    path: __dirname + "/assets/js",
    filename: "rawrs.js",
    sourceMapFilename: "rawrs.js.map"
  },

  mode: "production",

  /* We want source maps!
   */
  devtool: "source-map",

  /* What file types to filter.
   */
  resolve: {
    extensions: ['.js', '.jsx']
  },

  /* How to load/import modules (for each file).
   */
  module: {
    rules: [
      {
        test: /\.js$/,
        exclude: /(node_modules|bower_components)/,
        use: [
          "babel-loader",
          "eslint-loader"
        ]
      }
    ]
  },

  /* Minimize all vendored css/js */
  optimization: {
    minimizer: [
      //new UglifyJsPlugin()
    ]
  },

  /* What plugins to use.
   */
  plugins: [
    //new webpack.HotModuleReplacementPlugin()
  ]
}
