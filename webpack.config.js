const webpack = require('webpack');
const path = require('path');
const MiniCssExtractPlugin = require("mini-css-extract-plugin");
const OptimizeCssAssetsPlugin = require("optimize-css-assets-webpack-plugin");
const UglifyJsPlugin = require('uglifyjs-webpack-plugin');

/* This describes the behavior of webpack.
 */
module.exports = {
  /* The main javascript file for the application
   */
  entry: {
    rawrs: ["./assets/js/app.js"],
    xterm: ["./assets/js/vendor-xterm.js", "./assets/js/vendor-xterm.scss"]
  },

  /* The eventual transpiled output file.
   */
  output: {
    path: __dirname + "/assets/js",
    filename: "compiled-[name].js",
    sourceMapFilename: "compiled-[name].js.map"
  },

  mode: "production",

  /* We want source maps!
   */
  devtool: "source-map",

  /* What file types to filter.
   */
  resolve: {
    extensions: ['.js', '.jsx', '.css', '.scss']
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
      },
      {
        test: /\.s?css$/,
        use: [
          {
            loader: 'style-loader'
          },
          {
            loader: MiniCssExtractPlugin.loader,
            options: {
              publicPath: '/public/css',
            },
          },
          {
            loader: 'css-loader'
          },
          {
            loader: "sass-loader",
            options: {
              sassOptions: (loaderContext) => {
                // More information about available properties https://webpack.js.org/api/loaders/
                const { resourcePath, rootContext } = loaderContext;
                const relativePath = path.relative(rootContext, resourcePath);

                return {
                  includePaths: path.resolve(__dirname, 'node_modules'),
                };
              }
            }
          },
          //{
          //  loader: MiniCssExtractPlugin.loader,
          //}
        ]
      },
    ]
  },

  /* Minimize all vendored css/js */
  optimization: {
    minimizer: [
      new OptimizeCssAssetsPlugin({}),
      new UglifyJsPlugin()
    ]
  },

  /* What plugins to use.
   */
  plugins: [
    //new webpack.HotModuleReplacementPlugin()
    new MiniCssExtractPlugin({
      // Options similar to the same options in webpackOptions.output
      // both options are optional
      filename: "../css/[name].css",
      chunkFilename: "[id].css"
    }),
  ]
}
