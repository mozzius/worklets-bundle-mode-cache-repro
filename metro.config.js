const fs = require('fs');
const path = require('path');
const { getDefaultConfig } = require('expo/metro-config');
const { getBundleModeMetroConfig } = require('react-native-worklets/bundleMode');

const config = getBundleModeMetroConfig(getDefaultConfig(__dirname));

/*
 * Proposed fix, enabled with FIX=1: treat a cache hit as a miss when any of its
 * generated worklet files is missing, so Metro transforms that file again and
 * the Worklets plugin writes them back.
 */
if (process.env.FIX) {
  const workletsDir = path.join(
    path.dirname(require.resolve('react-native-worklets/package.json')),
    '.worklets'
  );
  const prefix = 'react-native-worklets/.worklets/';
  config.cacheStores = config.cacheStores.map((store) => ({
    name: store.name,
    async get(key) {
      const result = await store.get(key);
      const missing = result?.dependencies.some(
        (dep) =>
          dep.name.startsWith(prefix) &&
          !fs.existsSync(path.join(workletsDir, dep.name.slice(prefix.length)))
      );
      return missing ? null : result;
    },
    set: (key, value) => store.set(key, value),
    clear: () => store.clear(),
  }));
}

module.exports = config;
