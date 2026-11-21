/// Application secrets configuration.
///
/// For official production builds, the default API key is injected via:
/// `--dart-define=NVIDIA_API_KEY=...` or `--dart-define-from-file=secrets.json`.
class AppSecrets {
  static const String defaultNvidiaApiKey = String.fromEnvironment(
    'NVIDIA_API_KEY',
    defaultValue: '',
  );
}
