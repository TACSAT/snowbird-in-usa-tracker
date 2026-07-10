// EN: Unit tests for the DayAlert model — construction validation (the hard
//     input caps are a security boundary), JSON round-tripping, untrusted-input
//     rejection, and the fire-moment arithmetic used to schedule notifications.
//
// FR: Tests unitaires du modèle DayAlert — validation à la construction (les
//     plafonds stricts sont une frontière de sécurité), aller-retour JSON,
//     rejet des entrées non fiables, et l'arithmétique de l'instant d'envoi
//     utilisée pour planifier les notifications.

import 'package:flutter_test/flutter_test.dart';
import 'package:snowbird_in_usa_tracker/logic/input_limits.dart';
import 'package:snowbird_in_usa_tracker/models/day_alert.dart';

void main() {
  // EN: Helper — a valid alert matching the PLAN.md example: notify at 75 days
  //     within the last 36 months (~1095 days), delivered at 09:00.
  // FR: Aide — une alerte valide correspondant à l'exemple du PLAN.md : aviser
  //     à 75 jours dans les 36 derniers mois (~1095 jours), livrée à 9 h.
  DayAlert valid({
    int thresholdDays = 75,
    int windowDays = 1095,
    int hour = 9,
    int minute = 0,
    int leadDays = 0,
    int leadHours = 0,
  }) {
    return DayAlert(
      id: 'test-alert',
      thresholdDays: thresholdDays,
      windowDays: windowDays,
      hour: hour,
      minute: minute,
      leadDays: leadDays,
      leadHours: leadHours,
    );
  }

  group('construction validation', () {
    test('the PLAN.md example alert (75 days / 36 months / 09:00) is valid',
        () {
      final alert = valid();
      expect(alert.thresholdDays, 75);
      expect(alert.windowDays, 1095);
      expect(alert.hour, 9);
      expect(alert.enabled, isTrue);
    });

    test('every out-of-cap numeric field is rejected at construction', () {
      expect(() => valid(thresholdDays: 0), throwsArgumentError);
      expect(() => valid(thresholdDays: InputLimits.maxThresholdDays + 1),
          throwsArgumentError,);
      expect(() => valid(windowDays: 0), throwsArgumentError);
      expect(() => valid(windowDays: InputLimits.maxWindowDays + 1),
          throwsArgumentError,);
      expect(() => valid(hour: -1), throwsArgumentError);
      expect(() => valid(hour: 24), throwsArgumentError);
      expect(() => valid(minute: 60), throwsArgumentError);
      expect(() => valid(leadDays: -1), throwsArgumentError);
      expect(() => valid(leadDays: InputLimits.maxLeadDays + 1),
          throwsArgumentError,);
      expect(() => valid(leadHours: 24), throwsArgumentError);
    });

    test('label is trimmed, blank becomes null, and length is capped', () {
      expect(
        DayAlert.create(
          thresholdDays: 10,
          windowDays: 365,
          hour: 9,
          minute: 0,
          label: '   ',
        ).label,
        isNull,
      );
      final longLabel = 'x' * 500;
      expect(
        DayAlert.create(
          thresholdDays: 10,
          windowDays: 365,
          hour: 9,
          minute: 0,
          label: longLabel,
        ).label!.length,
        kMaxAlertLabelLength,
      );
    });
  });

  group('JSON round trip', () {
    test('toJson → fromJson preserves every field', () {
      final original = DayAlert(
        id: 'abc',
        thresholdDays: 75,
        windowDays: 1095,
        hour: 9,
        minute: 30,
        leadDays: 2,
        leadHours: 3,
        enabled: false,
        label: 'Margin check',
      );
      final restored = DayAlert.fromJson(original.toJson());
      expect(restored.id, original.id);
      expect(restored.thresholdDays, original.thresholdDays);
      expect(restored.windowDays, original.windowDays);
      expect(restored.hour, original.hour);
      expect(restored.minute, original.minute);
      expect(restored.leadDays, original.leadDays);
      expect(restored.leadHours, original.leadHours);
      expect(restored.enabled, original.enabled);
      expect(restored.label, original.label);
    });

    test('out-of-range values in stored/imported JSON are rejected', () {
      // EN: A backup file is untrusted input — a crafted thresholdDays must
      //     throw FormatException, never construct.
      // FR: Un fichier de sauvegarde est une entrée non fiable — un
      //     thresholdDays forgé doit lancer FormatException, jamais construire.
      final crafted = valid().toJson()..['thresholdDays'] = 999999999;
      expect(() => DayAlert.fromJson(crafted), throwsFormatException);
    });

    test('non-integer numeric fields (doubles, strings) are rejected', () {
      expect(
        () => DayAlert.fromJson(valid().toJson()..['windowDays'] = 1e300),
        throwsFormatException,
      );
      expect(
        () => DayAlert.fromJson(valid().toJson()..['hour'] = '9'),
        throwsFormatException,
      );
    });

    test('missing id or enabled is rejected', () {
      expect(
        () => DayAlert.fromJson(valid().toJson()..remove('id')),
        throwsFormatException,
      );
      expect(
        () => DayAlert.fromJson(valid().toJson()..remove('enabled')),
        throwsFormatException,
      );
    });
  });

  group('fireMomentFor', () {
    test('zero lead fires on the reach day at the chosen time', () {
      final alert = valid(hour: 9, minute: 0);
      expect(
        alert.fireMomentFor(DateTime(2025, 3, 16)),
        DateTime(2025, 3, 16, 9, 0),
      );
    });

    test('lead days move the fire moment whole days earlier, same clock time',
        () {
      final alert = valid(hour: 9, minute: 0, leadDays: 2);
      expect(
        alert.fireMomentFor(DateTime(2025, 3, 16)),
        DateTime(2025, 3, 14, 9, 0),
      );
    });

    test('lead hours shift within the day and roll into the previous day', () {
      // EN: 09:00 minus 12 hours = 21:00 the previous day.
      // FR: 9 h moins 12 heures = 21 h la veille.
      final alert = valid(hour: 9, minute: 0, leadHours: 12);
      expect(
        alert.fireMomentFor(DateTime(2025, 3, 16)),
        DateTime(2025, 3, 15, 21, 0),
      );
    });

    test('lead across DST keeps wall-clock semantics', () {
      // EN: Reach date Mar 10 2025, lead 2 days → Mar 8 at 09:00 WALL CLOCK,
      //     regardless of the Mar 9 spring-forward between them.
      // FR: Date d'atteinte 10 mars 2025, préavis 2 jours → 8 mars à 9 h À
      //     L'HORLOGE, malgré l'avance d'heure du 9 mars entre les deux.
      final alert = valid(hour: 9, minute: 0, leadDays: 2);
      final fire = alert.fireMomentFor(DateTime(2025, 3, 10));
      expect(fire.year, 2025);
      expect(fire.month, 3);
      expect(fire.day, 8);
      expect(fire.hour, 9);
    });
  });
}
