import 'package:connectivity_plus/connectivity_plus.dart';

/// Monitors network connectivity and exposes whether the device is online.
///
/// Results are best-effort: "online" means a network interface is up, not
/// that the API server is reachable.
class ConnectivityService {
  const new();

  /// Whether the device currently has a network connection.
  Future<bool> get isConnected async {
    final results = await Connectivity().checkConnectivity();
    return results.any((r) => r != ConnectivityResult.none);
  }

  /// A stream that emits whenever connectivity changes.
  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      Connectivity().onConnectivityChanged;
}
