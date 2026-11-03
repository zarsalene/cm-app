import 'package:equatable/equatable.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// The conversation a tapped alert points to.
final class const PushTarget({
  required final String senderId,
  required final String platform,
}) extends Equatable {
  @override
  List<Object> get props => [senderId, platform];
}

final _senderId = RegExp(r'^\d{5,32}$');

/// Reads the target from push data. Push data is untrusted: anything that is
/// not a numeric sender id and a known platform gives null.
PushTarget? parsePushTarget(Map<String, dynamic> data) {
  final senderId = data['sender_id'];
  final platform = data['platform'];
  if (senderId is! String || !_senderId.hasMatch(senderId)) return null;
  if (platform != 'facebook' && platform != 'whatsapp') return null;
  return PushTarget(senderId: senderId, platform: platform as String);
}

/// Push notification subscription for the logged-in CM.
abstract class PushService {
  /// Registers this device for alerts.
  Future<void> subscribe();

  /// Stops alerts for this device.
  Future<void> unsubscribe();

  /// Alerts the user tapped (app in background or closed).
  Stream<PushTarget> get opened;

  /// Alerts received while the app is in the foreground.
  Stream<void> get foreground;

  /// False when the user refused (or turned off) notifications.
  Future<bool> get notificationsEnabled;

  /// False in a build without Firebase: no alert can ever arrive.
  bool get available;
}

/// Does nothing. Used when Firebase is not available (local build).
class NoopPushService implements PushService {
  /// Creates a [NoopPushService].
  const new();

  @override
  Future<void> subscribe() async {}

  @override
  Future<void> unsubscribe() async {}

  @override
  Stream<PushTarget> get opened => const Stream.empty();

  @override
  Stream<void> get foreground => const Stream.empty();

  @override
  Future<bool> get notificationsEnabled async => true;

  @override
  bool get available => false;
}

/// Firebase Cloud Messaging on the `cm_bosphore` topic.
/// Needs `Firebase.initializeApp()` first.
class FcmPushService implements PushService {
  /// Creates a [FcmPushService].
  new() : _messaging = FirebaseMessaging.instance;

  static const _topic = 'cm_bosphore';

  final FirebaseMessaging _messaging;

  @override
  Future<void> subscribe() async {
    // Android 13+ asks for POST_NOTIFICATIONS. A refusal still subscribes:
    // the user can allow notifications later in the settings.
    await _messaging.requestPermission();
    await _messaging.subscribeToTopic(_topic);
  }

  @override
  Future<void> unsubscribe() => _messaging.unsubscribeFromTopic(_topic);

  @override
  Stream<PushTarget> get opened async* {
    // Cold start: the tap that launched the app.
    RemoteMessage? initial;
    try {
      initial = await _messaging.getInitialMessage();
    } on Object {
      initial = null;
    }
    if (initial != null) {
      if (parsePushTarget(initial.data) case final target?) yield target;
    }
    await for (final message in FirebaseMessaging.onMessageOpenedApp) {
      if (parsePushTarget(message.data) case final target?) yield target;
    }
  }

  @override
  Stream<void> get foreground => FirebaseMessaging.onMessage.map((_) {});

  @override
  bool get available => true;

  @override
  Future<bool> get notificationsEnabled async {
    final settings = await _messaging.getNotificationSettings();
    return switch (settings.authorizationStatus) {
      AuthorizationStatus.authorized || AuthorizationStatus.provisional => true,
      _ => false,
    };
  }
}
