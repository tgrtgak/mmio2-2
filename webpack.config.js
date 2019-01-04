const webpack = require('webpack');

/* This describes the behavior of webpack.
 */
module.exports = {
  /* The main javascript file for the application
   */
  entry: [
    "./assets/js/app.js"
  ],

  /* The eventual transpiled output file.
   */
  output: {
    path: __dirname + "/assets/js",
    filename: "rars.js",
    sourceMapFilename: "rars.js.map"
  },

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
    loaders: [
      {
        test: /\.js$/,
        exclude: /(node_modules|bower_components)/,
        loaders: ["babel-loader", "jshint-loader"]
      }
    ]
  },

  /* What plugins to use.
   */
  plugins: [
    //new webpack.HotModuleReplacementPlugin()
  ]
}
