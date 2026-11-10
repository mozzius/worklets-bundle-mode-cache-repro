# Worklets Bundle Mode: Metro cache hits skip writing `.worklets` files

Repro for https://github.com/software-mansion/react-native-reanimated/issues/11313.

A blank Expo SDK 58 app (React Native 0.88.1) with `react-native-worklets@0.13.0` in Bundle Mode (`bundleMode: true` in the Babel plugin, `getBundleModeMetroConfig` in `metro.config.js`) and one worklet in `App.tsx`.

## Run it

No device or simulator needed. The script only requests bundles from Metro.

```sh
npm install
./repro.sh             # shows the bug
FIX=1 ./repro.sh       # same steps with the proposed cache-store wrapper in metro.config.js
```

`repro.sh`:

1. Starts Metro with a private, empty cache (`TMPDIR=./.metro-tmp`) and requests the iOS bundle. This fills the cache and writes `node_modules/react-native-worklets/.worklets/*.js`.
2. Deletes the `.worklets/*.js` files and keeps the Metro cache. That's the state a second checkout sharing `$TMPDIR/metro-cache`, or a reinstall, leaves you in.
3. Starts Metro again with the same cache and requests the same bundle.

## Result

Without the fix, step 3 fails on every attempt, because each cache hit imports a worklet file that is never written again:

```
first, attempt 1: HTTP 200
worklet files written: 59
deleted them; Metro cache kept
second, attempt 1: HTTP 500
...
second, attempt 5: HTTP 500
{"type":"InternalError", ... "Failed to get the SHA-1 for: …/node_modules/react-native-worklets/.worklets/6730908547035.js. Potential causes: 1) The file is not watched. …
```

In a larger app with a warm file map, the same thing shows up as `TransformError: … .worklets/<hash>.js: ENOENT: no such file or directory`.

With `FIX=1`, the hit is treated as a miss, `App.tsx` is transformed again, its worklets are written back and the bundle succeeds:

```
second, attempt 1: HTTP 500
second, attempt 2: HTTP 200
```

The single 500 before the 200, here and sometimes on the first cold run, is a separate, smaller race. The plugin writes a `.worklets` file during a transform, and Metro's watcher hasn't added it to the file map by the time the same request resolves it, so that request fails with the SHA-1 error. A retry a moment later works.

`PLATFORM=web` and `PORT=…` are also supported (web needs `npx expo install react-dom react-native-web` first).
