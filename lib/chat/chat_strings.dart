import 'package:cm_app/app/strings.dart';

/// French copy that only the chat screen uses.
abstract class ChatStrings {
  static const statusActive = 'Actif';
  static const statusBot = 'Bot';
  static const assistantBot = 'Assistant Z-Bot';
  static const you = 'Vous';
  static const macros = 'Macros';
  static const latestMessages = 'Derniers messages';

  static String _channel(String platform) => switch (platform) {
    'facebook' => Strings.facebook,
    'whatsapp' => Strings.whatsapp,
    _ => platform,
  };

  /// "WhatsApp • …1234": the channel and the last 4 characters of the sender
  /// id. The full id (a phone number on WhatsApp) is never shown.
  static String channelLine(String platform, String senderId) {
    final tail = senderId.length > 4
        ? senderId.substring(senderId.length - 4)
        : senderId;
    return '${_channel(platform)} • …$tail';
  }

  /// Sender label above a customer message: "Client (WhatsApp)".
  static String customerSender(String platform) =>
      '${Strings.customer} (${_channel(platform)})';

  /// Footer under the composer: "Envoi via WhatsApp".
  static String sendVia(String platform) => 'Envoi via ${_channel(platform)}';
}
