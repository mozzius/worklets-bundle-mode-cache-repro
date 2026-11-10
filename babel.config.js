module.exports = function (api) {
  api.cache(true);
  return {
    // The Worklets plugin is added below with Bundle Mode options instead.
    presets: [['babel-preset-expo', { worklets: false }]],
    plugins: [['react-native-worklets/plugin', { bundleMode: true, strictGlobal: true }]],
  };
};
