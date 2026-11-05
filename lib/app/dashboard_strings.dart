/// French copy of the dashboard (Serene Operations design).
abstract class DashboardStrings {
  static String hello(String name) => 'Bonjour, $name 👋';
  static const helloAnonymous = 'Bonjour 👋';
  static String totalLine(int n) =>
      '$n conversation${n > 1 ? 's' : ''} · en direct';

  static const openConversations = 'Conversations ouvertes';
  static String overLimit(int n) => '$n > 15 min';

  static const byBot = 'Par le bot';
  static const activeUnit = 'actives';
  static const handledToday = 'Traitées ajd.';
  static const conversationsUnit = 'conversations';
  static const averageWait = 'Attente moyenne';
  static const minuteUnit = 'min';
  static const underFifteen = '< 15 min';
  static const openUnit = 'ouvertes';

  static const priorityTitle = 'File prioritaire';
  static const waitingOrder = "Ordre d'attente";
  static const reply = 'Répondre';
  static const sendBackToBot = 'Renvoyer au bot';
  static const viewAll = 'Tout afficher';

  static const urgent = 'Urgent';
  static String triage(int n) => 'Voir les $n à traiter';

  static const errorTitle = 'Erreur';
}
