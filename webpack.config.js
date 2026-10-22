const path = require('path');

const BUILD_DIR = path.resolve(__dirname, 'dist');
const APP_DIR = path.resolve(__dirname, 'Components');

module.exports = (env) => {
  const isDev = env && env.development;
  return {
    mode: isDev ? 'development' : 'production',
    entry: {
      index: path.join(APP_DIR, 'index.js')
    },
    output: {
      path: BUILD_DIR,
      filename: isDev ? '[name].bundle.js' : '[name].[contenthash].bundle.js',
      library: 'udchameleon',
      libraryTarget: 'var',
      clean: true
    },
    module: {
      rules: [
        {
          test: /\.(js|jsx)$/,
          exclude: /node_modules/,
          loader: 'babel-loader'
        },
        {
          test: /\.css$/,
          use: ['style-loader', 'css-loader']
        }
      ]
    },
    externals: {
      react: 'react',
      'react-dom': 'reactdom'
      // universal-dashboard must be bundled: withComponentFeatures is not on the window.UniversalDashboard global
    },
    resolve: {
      extensions: ['.js', '.jsx', '.json']
    }
  };
};
