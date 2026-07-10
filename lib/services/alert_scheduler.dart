// EN: Abstraction between AlertRepository (pure state) and the platform
//     notification plugin. The repository computes WHAT should fire and WHEN
//     (using the pure DayCounter engine) and hands this interface a complete,
//     already-decided schedule. Only the concrete implementation
//     (NotificationService) touches flutter_local_notifications.
//
//     Why the indirection: unit tests can drive AlertRepository with a fake
//     scheduler and assert on the computed schedule without any platform
//     channel, and the scheduling policy stays in testable pure code instead of
//     inside plugin callbacks.
//
// FR: Abstraction entre AlertRepository (état pur) et le plugin de
//     notifications de la plateforme. Le dépôt calcule CE QUI doit partir et
//     QUAND (avec le moteur pur DayCounter) et remet à cette interface un
//     horaire complet, déjà décidé. Seule l'implémentation concrète
//     (NotificationService) touche flutter_local_notifications.
//
//     Pourquoi cette indirection : les tests unitaires peuvent piloter
//     AlertRepository avec un planificateur factice et vérifier l'horaire
//     calculé sans aucun canal de plateforme, et la politique de planification
//     reste dans du code pur testable plutôt que dans des rappels du plugin.

import 'package:snowbird_in_usa_tracker/models/day_alert.dart';

// EN: One fully-resolved notification to schedule: the user's alert, the
//     projected calendar date their target is reached, and the exact local
//     moment the notification should be delivered (reach date adjusted by the
//     user's chosen lead and time of day).
// FR: Une notification entièrement résolue à planifier : l'alerte de
//     l'utilisateur, la date calendaire projetée où sa cible est atteinte, et
//     l'instant local exact où la notification doit être livrée (date
//     d'atteinte ajustée du préavis et de l'heure choisis par l'utilisateur).
class ScheduledAlert {
  final DayAlert alert;
  final DateTime reachDate;
  final DateTime fireMoment;

  const ScheduledAlert({
    required this.alert,
    required this.reachDate,
    required this.fireMoment,
  });
}

abstract class AlertScheduler {
  // EN: Ask the OS for notification permission if not yet granted. Returns
  //     true when notifications are allowed. Called by the UI when the user
  //     creates their FIRST alert — never preemptively at app launch, because
  //     asking for a permission before the user has expressed any interest is
  //     both bad UX and contrary to the app's data-minimalism posture.
  // FR: Demander à l'OS la permission de notifier si pas encore accordée.
  //     Retourne true quand les notifications sont permises. Appelé par
  //     l'interface quand l'utilisateur crée sa PREMIÈRE alerte — jamais
  //     préventivement au lancement, car demander une permission avant que
  //     l'utilisateur ait exprimé un intérêt est à la fois une mauvaise
  //     expérience et contraire à la posture de minimalisme de l'appli.
  Future<bool> ensurePermissions();

  // EN: Replace the entire pending schedule with [schedule]. Implementations
  //     cancel everything previously scheduled first — the repository always
  //     recomputes the full set, so cancel-then-reschedule keeps the plugin
  //     state exactly in sync with user data with no stale-ID bookkeeping.
  // FR: Remplacer tout l'horaire en attente par [schedule]. Les implémentations
  //     annulent d'abord tout ce qui était planifié — le dépôt recalcule
  //     toujours l'ensemble complet, donc annuler-puis-replanifier garde l'état
  //     du plugin exactement synchronisé avec les données de l'utilisateur,
  //     sans comptabilité d'identifiants périmés.
  Future<void> reschedule(List<ScheduledAlert> schedule);
}
