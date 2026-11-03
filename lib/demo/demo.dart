/// Browser preview switch: `--dart-define=DEMO=true`. Off by default, so the
/// demo code is unreachable and tree-shaken from real builds.
const bool kDemo = bool.fromEnvironment('DEMO');
