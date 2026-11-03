/// Push notification subscription for the logged-in CM.
abstract class PushService {
  /// Registers this device for alerts.
  Future<void> subscribe();

  /// Stops alerts for this device.
  Future<void> unsubscribe();
}

/// Does nothing. Used until the real push service exists.
class NoopPushService implements PushService {
  /// Creates a [NoopPushService].
  const new();

  @override
  Future<void> subscribe() async {}

  @override
  Future<void> unsubscribe() async {}
}
