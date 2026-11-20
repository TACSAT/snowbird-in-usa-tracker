// EN: Concrete AlertScheduler backed by flutter_local_notifications. This is
//     the ONLY file that talks to the notification plugin.
//
//     Privacy invariants upheld here (PLAN.md):
//       • Everything is LOCAL: notifications are computed and scheduled on the
//         device. There is no push service, no token, no network call.
//       • Wording is neutral — "the target you set" — never a warning, verdict,
//         or "over the limit" judgment.
//       • Permission is requested only when the user creates their first alert,
//         never preemptively at launch.
//
//     Scheduling notes:
//       • Times are wall-clock local: "09:00" means 09:00 wherever the device
//         is. The timezone package + flutter_timezone give us the device's IANA
//         zone so the OS fires at the right absolute instant even across DST.
//       • Android uses INEXACT scheduling on purpose: a day-count notice does
//         not need second-level precision, and inexact mode avoids demanding
//         the invasive SCHEDULE_EXACT_ALARM permission — fewer permissions is
//         part of the product's trust story.
//       • Strategy is cancel-all-then-reschedule (see AlertScheduler docs).
//
// FR: AlertScheduler concret appuyé sur flutter_local_notifications. C'est le
//     SEUL fichier qui parle au plugin de notifications.
//
//     Invariants de confidentialité respectés ici (PLAN.md) :
//       • Tout est LOCAL : les notifications sont calculées et planifiées sur
//         l'appareil. Aucun service push, aucun jeton, aucun appel réseau.
//       • Libellé neutre — « la cible que vous avez fixée » — jamais un
//         avertissement, un verdict ou un jugement « au-dessus de la limite ».
//       • La permission n'est demandée que lorsque l'utilisateur crée sa
//         première alerte, jamais préventivement au lancement.
//
//     Notes de planification :
//       • Les heures sont locales à l'horloge : « 9 h » signifie 9 h là où se
//         trouve l'appareil. timezone + flutter_timezone fournissent le fuseau
//         IANA de l'appareil pour que l'OS déclenche au bon instant absolu,
//         même à travers les changements d'heure.
//       • Android utilise la planification INEXACTE à dessein : un avis de
//         compte de jours n'exige pas une précision à la seconde, et le mode
//         inexact évite la permission invasive SCHEDULE_EXACT_ALARM — moins de
//         permissions fait partie de l'histoire de confiance du produit.
//       • Stratégie annuler-tout-puis-replanifier (voir la doc AlertScheduler).

import 'dart:ui' show Locale, PlatformDispatcher;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'package:snowbird_in_usa_tracker/l10n/app_localizations.dart';
import 'package:snowbird_in_usa_tracker/models/day_alert.dart';
import 'package:snowbird_in_usa_tracker/services/alert_scheduler.dart';

class NotificationService implements AlertScheduler {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  // EN: One-time setup: load the IANA timezone database, point tz.local at the
  //     device's current zone, and initialise the plugin WITHOUT requesting any
  //     permission (both platforms are configured to stay silent here).
  //     Failures are swallowed into a "not initialized" state rather than
  //     crashing the app — the trip log must keep working even if the
  //     notification stack is unavailable.
  // FR: Mise en place unique : charger la base de fuseaux IANA, pointer
  //     tz.local vers le fuseau courant de l'appareil, et initialiser le plugin
  //     SANS demander de permission (les deux plateformes sont configurées pour
  //     rester silencieuses ici). Les échecs sont absorbés dans un état « non
  //     initialisé » plutôt que de planter l'appli — le journal des séjours
  //     doit continuer de fonctionner même si la pile de notifications est
  //     indisponible.
  Future<void> init() async {
    if (_initialized) return;
    try {
      tzdata.initializeTimeZones();
      // EN: getLocalTimezone() returns the device's IANA zone name (e.g.
      //     "America/Toronto") as a plain String in flutter_timezone 4.x.
      // FR: getLocalTimezone() retourne le nom de fuseau IANA de l'appareil
      //     (p. ex. « America/Toronto ») comme simple String dans
      //     flutter_timezone 4.x.
      final zone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zone));

      const initSettings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      );
      await _plugin.initialize(initSettings);
      _initialized = true;
    } catch (_) {
      _initialized = false;
    }
  }

  @override
  Future<bool> ensurePermissions() async {
    if (!_initialized) return false;

    // EN: Ask the platform-specific implementation. On Android 13+ this shows
    //     the POST_NOTIFICATIONS dialog; earlier Androids return true
    //     implicitly. On iOS this shows the standard notification prompt.
    // FR: Demander à l'implémentation propre à la plateforme. Sur Android 13+
    //     cela affiche le dialogue POST_NOTIFICATIONS ; les Android antérieurs
    //     retournent true implicitement. Sur iOS cela affiche l'invite standard.
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }

    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      return await ios.requestPermissions(alert: true, sound: true) ?? false;
    }

    return false;
  }

  @override
  Future<void> reschedule(List<ScheduledAlert> schedule) async {
    if (!_initialized) return;

    // EN: Wipe and rebuild — keeps OS state exactly equal to user data.
    // FR: Effacer et reconstruire — garde l'état OS exactement égal aux
    //     données de l'utilisateur.
    await _plugin.cancelAll();

    final strings = _localizations();
    for (final entry in schedule) {
      await _scheduleOne(entry, strings);
    }
  }

  Future<void> _scheduleOne(
    ScheduledAlert entry,
    AppLocalizations strings,
  ) async {
    final alert = entry.alert;

    // EN: Neutral copy, always framed as the user's own target. When the user
    //     asked for advance notice, the body names the projected date instead
    //     of "today".
    // FR: Texte neutre, toujours présenté comme la cible de l'utilisateur.
    //     Quand l'utilisateur a demandé un préavis, le corps nomme la date
    //     projetée au lieu d'« aujourd'hui ».
    final title = alert.label ?? strings.alertNotificationTitle;
    final onReachDay = alert.leadDays == 0 && alert.leadHours == 0;
    final dateText =
        DateFormat.yMMMMd(strings.localeName).format(entry.reachDate);
    // EN: The since-last-visit kind (FR-10) has no rolling window, so it uses its
    //     own neutral wording naming the date and the elapsed-days target. The
    //     day-count kind keeps the today/advance split it always had.
    // FR: Le type « depuis le dernier séjour » (FR-10) n'a pas de fenêtre glissante,
    //     il utilise donc son propre libellé neutre nommant la date et la cible de
    //     jours écoulés. Le type compte-de-jours garde sa distinction jour-même /
    //     préavis.
    final String body;
    if (alert.kind == AlertKind.sinceLastVisit) {
      body = strings.alertNotificationBodySince(dateText, alert.thresholdDays);
    } else if (onReachDay) {
      body = strings.alertNotificationBodyToday(
        alert.thresholdDays,
        alert.windowDays,
      );
    } else {
      body = strings.alertNotificationBodyAdvance(
        dateText,
        alert.thresholdDays,
        alert.windowDays,
      );
    }

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        'snowbird_user_alerts',
        strings.alertChannelName,
        channelDescription: strings.alertChannelDescription,
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
      iOS: const DarwinNotificationDetails(),
    );

    await _plugin.zonedSchedule(
      // EN: Stable non-negative 32-bit id derived from the alert's UUID so the
      //     same alert always maps to the same OS notification slot.
      // FR: Identifiant 32 bits stable et non négatif dérivé de l'UUID de
      //     l'alerte pour que la même alerte occupe toujours le même
      //     emplacement de notification OS.
      alert.id.hashCode & 0x7fffffff,
      title,
      body,
      tz.TZDateTime.from(entry.fireMoment, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  // EN: Resolve localized strings WITHOUT a BuildContext — notifications are
  //     scheduled from the state layer, not from a widget. Falls back to
  //     English if the device locale is unsupported.
  // FR: Résoudre les chaînes localisées SANS BuildContext — les notifications
  //     sont planifiées depuis la couche d'état, pas depuis un widget. Retombe
  //     sur l'anglais si la locale de l'appareil n'est pas prise en charge.
  AppLocalizations _localizations() {
    try {
      return lookupAppLocalizations(PlatformDispatcher.instance.locale);
    } catch (_) {
      return lookupAppLocalizations(const Locale('en'));
    }
  }
}
