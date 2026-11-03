import 'package:cm_app/api/cm_api.dart';

/// All French UI copy for the escalation and chat screens.
abstract class Strings {
  static const escalationsTitle = 'Escalades';
  static const noEscalations = 'Aucune escalade';
  static const noConnection = 'Pas de connexion';
  static const otherError = 'Erreur, réessayez';
  static const sendFailed = 'Envoi impossible';
  static const retry = 'Réessayer';
  static const logout = 'Se déconnecter';
  static const chatTitle = 'Conversation';
  static const reasonPrefix = 'Motif : ';
  static const replyHint = 'Votre réponse';
  static const send = 'Envoyer';
  static const botAnswersAgain = 'Le bot répond de nouveau';
  static const giveBack = 'Rendre au bot';
  static const giveBackTitle = 'Rendre au bot ?';
  static const giveBackBody = 'Le bot répondra de nouveau à ce client.';
  static const draftLost = 'Le texte non envoyé sera perdu.';
  static const cancel = 'Annuler';
  static const confirm = 'Confirmer';
  static const customer = 'Client';
  static const bot = 'Bot ou community manager';
  static const open = 'ouverte';
  static const closed = 'fermée';
  static const facebook = 'Facebook';
  static const whatsapp = 'WhatsApp';
  static const justNow = "à l'instant";
  static const newAlert = 'Nouvelle alerte client';
  static const notificationsOff = 'Notifications désactivées';

  /// Error text for a failed call.
  static String errorFor(Object error) => switch (error) {
    NetworkException() => noConnection,
    SendFailedException() => sendFailed,
    _ => otherError,
  };

  /// Customer name, or `Client …<last 4 of senderId>` when unknown.
  static String customerLabel(String? name, String senderId) {
    final trimmed = name?.trim() ?? '';
    if (trimmed.isNotEmpty) return trimmed;
    final tail = senderId.length > 4
        ? senderId.substring(senderId.length - 4)
        : senderId;
    return '$customer …$tail';
  }

  /// "il y a 5 min", "il y a 2 h", "il y a 3 j".
  static String relativeTime(DateTime at, {DateTime? now}) {
    final diff = (now ?? DateTime.now()).difference(at);
    if (diff.inMinutes < 1) return justNow;
    if (diff.inHours < 1) return 'il y a ${diff.inMinutes} min';
    if (diff.inDays < 1) return 'il y a ${diff.inHours} h';
    return 'il y a ${diff.inDays} j';
  }
}
