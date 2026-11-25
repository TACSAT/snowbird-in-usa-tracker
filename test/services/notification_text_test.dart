// EN: Notification wording follows the language chosen in the app (FR-20), and falls
//     back safely. The plugin itself needs a device; the wording does not.
// FR: Le libellé des notifications suit la langue choisie dans l'appli (FR-20), avec
//     un repli sûr. Le plugin exige un appareil ; le libellé, non.

import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:snowbird_in_usa_tracker/models/day_alert.dart';
import 'package:snowbird_in_usa_tracker/services/alert_scheduler.dart';
import 'package:snowbird_in_usa_tracker/services/notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => initializeDateFormatting());

  ScheduledAlert entry({int leadDays = 0}) => ScheduledAlert(
        alert: DayAlert.create(
          thresholdDays: 75,
          windowDays: 365,
          hour: 9,
          minute: 0,
          leadDays: leadDays,
        ),
        reachDate: DateTime(2026, 3, 16),
        fireMoment: DateTime(2026, 3, 16 - leadDays, 9),
      );

  test('the in-app language wins over the phone language', () {
    var chosen = const Locale('fr');
    final service = NotificationService(locale: () => chosen);
    final (_, fr) = service.textFor(entry(leadDays: 3));
    expect(fr, contains('16 mars 2026'));
    chosen = const Locale('en');
    final (_, en) = service.textFor(entry(leadDays: 3));
    expect(en, contains('March 16, 2026'));
  });

  test('an unsupported language falls back to English', () {
    final service = NotificationService(locale: () => const Locale('de'));
    final (_, body) = service.textFor(entry(leadDays: 3));
    expect(body, contains('March 16, 2026'));
  });

  test('only the soonest notifications are kept, within the iOS limit', () {
    final many = [
      for (var i = 100; i > 0; i--)
        ScheduledAlert(
          alert: entry().alert,
          reachDate: DateTime(2026, 1, i),
          fireMoment: DateTime(2026, 1, i),
        ),
    ];
    final kept = NotificationService.withinPlatformLimit(many);
    expect(kept.length, lessThanOrEqualTo(64));
    expect(kept.first.fireMoment, DateTime(2026, 1, 1));
  });
}
