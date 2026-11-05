/// French copy that only the inbox screen uses.
abstract class InboxStrings {
  static const liveSync = 'Synchro en direct';
  static const livePaused = 'Direct en pause';
  static const channelLabel = 'CANAL';
  static const waitingFilter = 'En attente';
  static const sortRecent = 'Récent';
  static const sortOldest = 'Ancien';
  static const sortTooltip = 'Changer le tri';
  static const watch = 'Surveiller';
  static const closedPill = 'Fermée';
  static const allAssigned = 'Toutes les conversations urgentes sont assignées';

  /// "1 fil prioritaire", "3 fils prioritaires".
  static String priorityThreads(int count) =>
      count == 1 ? '1 fil prioritaire' : '$count fils prioritaires';
}
