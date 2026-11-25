// EN: What NotificationService actually sends to the platform, checked at the method
//     channel. It guards plugin upgrades, whose API changes are otherwise only seen on
//     a device.
// FR: Ce que NotificationService envoie réellement à la plateforme, vérifié au canal de
//     méthodes. Protège les mises à jour du plugin, dont les changements ne se verraient
//     autrement que sur un appareil.

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snowbird_in_usa_tracker/models/day_alert.dart';
import 'package:snowbird_in_usa_tracker/services/alert_scheduler.dart';
import 'package:snowbird_in_usa_tracker/services/notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('dexterous.com/flutter/local_notifications');
  const zoneChannel = MethodChannel('flutter_timezone');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final calls = <MethodCall>[];
  var zone = 'America/Toronto';
  var refuseFirst = false;

  setUp(() {
    calls.clear();
    zone = 'America/Toronto';
    refuseFirst = false;
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      if (call.method == 'zonedSchedule' && refuseFirst) {
        refuseFirst = false;
        throw PlatformException(code: 'refused');
      }
      return call.method == 'initialize' ||
              call.method == 'requestNotificationsPermission' ||
              call.method == 'requestPermissions'
          ? true
          : null;
    });
    messenger.setMockMethodCallHandler(
      zoneChannel,
      (call) async => {'identifier': zone},
    );
  });

  tearDown(() {
    messenger
      ..setMockMethodCallHandler(channel, null)
      ..setMockMethodCallHandler(zoneChannel, null);
    debugDefaultTargetPlatformOverride = null;
  });

  final fire = DateTime.now().add(const Duration(days: 3));
  ScheduledAlert entry() => ScheduledAlert(
        alert: DayAlert.create(
          thresholdDays: 75,
          windowDays: 365,
          hour: 9,
          minute: 0,
          label: 'Coverage',
        ),
        reachDate: fire,
        fireMoment: fire,
      );

  void use(TargetPlatform platform) {
    debugDefaultTargetPlatformOverride = platform;
    if (platform == TargetPlatform.iOS) {
      IOSFlutterLocalNotificationsPlugin.registerWith();
    } else {
      AndroidFlutterLocalNotificationsPlugin.registerWith();
    }
  }

  List<MethodCall> scheduled() =>
      calls.where((c) => c.method == 'zonedSchedule').toList();

  for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
    test('$platform: pending are replaced, delivered are left alone', () async {
      use(platform);
      final service = NotificationService();
      await service.reschedule([entry(), entry()]);
      final names = [for (final c in calls) c.method];
      expect(names, isNot(contains('cancelAll')));
      expect(names.indexOf('cancelAllPendingNotifications'), greaterThan(-1));
      expect(
        names.indexOf('cancelAllPendingNotifications'),
        lessThan(names.indexOf('zonedSchedule')),
      );
      expect(scheduled(), hasLength(2));
      final args = scheduled().first.arguments as Map;
      expect(args['title'], 'Coverage');
      expect(args['timeZoneName'], 'America/Toronto');
      expect(args['id'], isNonNegative);
    });

    test('$platform: starting asks for no permission', () async {
      use(platform);
      await NotificationService().init();
      expect(
        calls.where((c) => c.method.startsWith('request')),
        isEmpty,
      );
      final init = calls.singleWhere((c) => c.method == 'initialize');
      if (platform == TargetPlatform.iOS) {
        final args = init.arguments as Map;
        expect(args['requestAlertPermission'], isFalse);
        expect(args['requestSoundPermission'], isFalse);
        expect(args['requestBadgePermission'], isFalse);
      }
    });

    test('$platform: one refused notification does not stop the next',
        () async {
      use(platform);
      refuseFirst = true;
      await NotificationService().reschedule([entry(), entry()]);
      expect(scheduled(), hasLength(2));
    });

    test('$platform: permission is requested on demand', () async {
      use(platform);
      expect(await NotificationService().ensurePermissions(), isTrue);
      expect(calls.where((c) => c.method.startsWith('request')), hasLength(1));
    });
  }

  test('an unknown zone falls back to UTC at the same instant', () async {
    use(TargetPlatform.android);
    zone = 'Nowhere/Invalid';
    await NotificationService().reschedule([entry()]);
    final args = scheduled().single.arguments as Map;
    expect(args['timeZoneName'], contains('UTC'));
    final utc = fire.toUtc();
    expect(
      args['scheduledDateTime'].toString(),
      contains(utc.toIso8601String().substring(0, 19)),
    );
  });

  test('Android uses inexact delivery, so no exact-alarm permission', () async {
    use(TargetPlatform.android);
    await NotificationService().reschedule([entry()]);
    final specifics = (scheduled().single.arguments as Map)['platformSpecifics']
        as Map<Object?, Object?>;
    expect(specifics['scheduleMode'], 'inexactAllowWhileIdle');
  });
}
