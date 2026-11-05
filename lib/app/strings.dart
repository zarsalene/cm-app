import 'package:cm_app/api/cm_api.dart';

/// All French UI copy for the escalation and chat screens.
abstract class Strings {
  static const inboxTitle = 'Boîte de réception';
  static const noConversations = 'Aucune conversation';
  static const noConversationsBody =
      'Les conversations WhatsApp et Facebook apparaîtront ici.';
  static const humanSection = 'À traiter';
  static const botSection = 'Bot actif';
  static const closedConversations = 'Fermées';
  static const takeOver = 'Prendre la main';
  static const activateBot = 'Activer le bot';
  static const humanHandler = 'Humain';
  static const botHandler = 'Bot';
  static const noRecentMessage = 'Aucun message récent';
  static const allConversations = 'Toutes';
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
  static const appName = 'Z-Smart-CM';
  static const version = 'Version';
  static const pushActive = 'Alertes actives';
  static const pushUnavailable =
      'Alertes indisponibles (version sans Firebase)';
  static const pushOff = 'Alertes désactivées dans les réglages du téléphone';
  static const backToMenu = 'Retour au menu';
  static const back = 'Retour';
  static const liveLabel = 'En direct';
  static const refresh = 'Actualiser';
  static const pauseLive = 'Mettre le direct en pause';
  static const resumeLive = 'Reprendre le direct';
  static const searchHint = 'Rechercher un client…';
  static const allChannels = 'Tous';
  static const noResults = 'Aucun résultat';
  static const quickRepliesLabel = 'Réponses rapides';
  static const quickReplies = [
    'Bonjour, je m’en occupe tout de suite.',
    'Pouvez-vous préciser votre numéro de commande ?',
    'Merci pour votre patience, je vérifie.',
    'Votre demande est résolue. Bonne journée !',
  ];
  static const tagline = 'Gérez vos conversations clients en un seul endroit';
  static const developedBy = 'Développé par';
  static const developedByMicrozed = 'Développé par Microzed';
  static const microzed = 'Microzed';
  static const connectionLost = 'Connexion perdue, nouvelle tentative…';
  static const openSection = 'Ouvertes';
  static const closedSection = 'Fermées';
  static const openAlerts = 'Ouvertes';
  static const closedAlerts = 'Fermées';
  static const activate = 'Activer';
  static const openChat = 'Ouvrir';
  static const reasonCardLabel = 'Motif';
  static const expand = 'Développer';
  static const collapse = 'Réduire';
  static const scrollToLatest = 'Aller au plus récent';
  static const today = 'Aujourd’hui';
  static const yesterday = 'Hier';
  static const selectableCopy = 'Copier';
  static const loginTitle = 'Z-Smart-CM';
  static const loginHintUsername = 'Identifiant';
  static const loginHintPassword = 'Mot de passe';
  static const loginButton = 'Se connecter';
  static const loginLoading = 'Connexion en cours';
  static const loginError = 'Identifiant ou mot de passe incorrect';
  static const loginNoConnection = 'Pas de connexion';
  static const loginOtherError = 'Erreur, réessayez';
  static const forgetPassword = 'Mot de passe oublié ?';
  static const rememberMe = 'Se souvenir de moi';
  static const dontHaveAccount = 'Vous n\'avez pas de compte ?';
  static const createAccount = 'Créer un compte';
  static const welcomeBack = 'Bon retour,';
  static const dashboardTitle = 'Tableau de bord';
  static const openEscalations = 'Ouvertes';
  static const closedEscalations = 'Fermées';
  static const avgResponseTime = 'Temps de réponse moyen';
  static const activeChats = 'Discussions actives';
  static const newEscalation = 'Nouvelle escalade';
  static const viewAll = 'Voir tout';
  static const recentActivity = 'Activité récente';
  static const noData = 'Aucune donnée';
  static const profile = 'Profil';
  static const settings = 'Paramètres';
  static const help = 'Aide';

  // Shell (Serene Operations)
  static const navDashboard = 'Tableau';
  static const navInbox = 'Boîte';
  static const navSettings = 'Paramètres';
  static const directTag = 'DIRECT';
  static const online = 'En ligne';
  static const botAuto = 'Bot auto';
  static const youActive = 'Vous (Actif)';

  // Session reset
  static const resetSession = 'Réinitialiser la session';
  static const resetSessionSubtitle = 'Efface le token stocké et déconnecte';

  // Priority queue
  static const priorityQueue = 'À traiter en priorité';
  static const priorityQueueSubtitle =
      'Les conversations les plus anciennes en premier';

  // Sort
  static const trier = 'Trier';
  static const sortNewestFirst = 'Plus r\u00e9centes d\u2019abord';
  static const sortOldestFirst = 'Plus anciennes d\u2019abord';

  // Settings
  static const appearance = 'Apparence';
  static const themeMode = 'Thème';
  static const themeLight = 'Clair';
  static const themeDark = 'Sombre';
  static const themeSystem = 'Système';
  static const language = 'Langue';
  static const notifications = 'Notifications';
  static const pushNotifications = 'Notifications push';
  static const account = 'Compte';
  static const about = 'À propos';

  // Help
  static const faqTitle = 'Questions fréquentes';
  static const contactTitle = 'Besoin d’aide ?';
  static const contactBody =
      'Écrivez-nous à support@z-smart-cm.tn ou ouvrez une conversation depuis l’app.';

  /// Error text for a failed call.
  static String errorFor(Object error) => switch (error) {
    NetworkException() => noConnection,
    SendFailedException() => sendFailed,
    _ => otherError,
  };

  /// Customer name, or `Client <channel> …<last 4 of senderId>` when unknown.
  /// [platform] is `facebook` or `whatsapp` — used for a better fallback label.
  static String customerLabel(
    String? name,
    String senderId, {
    String? platform,
  }) {
    final trimmed = name?.trim() ?? '';
    if (trimmed.isNotEmpty) return trimmed;
    final channel = switch (platform) {
      'facebook' => Strings.facebook,
      'whatsapp' => Strings.whatsapp,
      _ => 'client',
    };
    final tail = senderId.length > 4
        ? senderId.substring(senderId.length - 4)
        : senderId;
    return '$customer $channel …$tail';
  }

  /// First letter of [name], upper case, or `?` when empty. Works on runes:
  /// `name[0]` would cut an emoji in half.
  static String initial(String name) =>
      name.isEmpty ? '?' : String.fromCharCode(name.runes.first).toUpperCase();

  /// Up to two initials: "Sana Ben Ali" gives "SB".
  static String initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    return parts.length >= 2
        ? initial(parts[0]) + initial(parts[1])
        : initial(parts[0]);
  }

  /// "18m d'attente", "1h05 d'attente".
  static String waiting(int minutes) {
    final m = minutes < 0 ? 0 : minutes;
    final span = m < 60
        ? '${m}m'
        : '${m ~/ 60}h${(m % 60).toString().padLeft(2, '0')}';
    return "$span d'attente";
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
