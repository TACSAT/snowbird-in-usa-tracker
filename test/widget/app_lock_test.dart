// EN: Tests for the optional app lock (WRK-11), with a fake phone check: it
//     locks only when on; a failed check can be retried; going to the
//     background locks, the prompt's own "inactive" does not; locked content
//     is hidden from screen readers; and switching it on or off needs the
//     check, and is refused on a phone with nothing set up.
// FR: Tests du verrouillage facultatif de l'appli (WRK-11), avec une
//     vérification imitée : il ne verrouille que s'il est activé ; une
//     vérification échouée peut être reprise ; passer en arrière-plan
//     verrouille, l'état « inactive » de l'invite non ; le contenu verrouillé
//     est caché aux lecteurs d'écran ; et l'activer ou le désactiver demande la
//     vérification, et est refusé sur un téléphone sans rien de configuré.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:snowbird_in_usa_tracker/app.dart';
import 'package:snowbird_in_usa_tracker/screens/settings_screen.dart';
import 'package:snowbird_in_usa_tracker/services/device_auth.dart';
import 'package:snowbird_in_usa_tracker/services/storage_service.dart';
import 'package:snowbird_in_usa_tracker/state/presence_settings.dart';
import 'package:snowbird_in_usa_tracker/state/settings_controller.dart';
import 'package:snowbird_in_usa_tracker/state/trip_repository.dart';

class _FakeAuth extends DeviceAuth {
  bool available = true;
  final List<bool> answers = [];
  int checks = 0;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<bool> check(String reason) async {
    checks++;
    return answers.isEmpty ? true : answers.removeAt(0);
  }
}

Future<(_FakeAuth, SettingsController)> _launch(
  WidgetTester tester, {
  required bool lock,
  _FakeAuth? auth,
}) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({
    'snowbird.flags.disclaimerAck.v1': true,
    'snowbird.flags.backupReminderShown.v1': true,
    'snowbird.settings.locale.v1': 'en',
    'snowbird.settings.appLock.v1': lock,
  });
  final storage = StorageService(await SharedPreferences.getInstance());
  final fake = auth ?? _FakeAuth();
  final settings = SettingsController(storage);
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        Provider<StorageService>.value(value: storage),
        ChangeNotifierProvider.value(value: settings),
        ChangeNotifierProvider.value(value: TripRepository(storage)),
        ChangeNotifierProvider.value(value: PresenceSettings(storage)),
      ],
      child: SnowBirdApp(deviceAuth: fake),
    ),
  );
  await tester.pumpAndSettle();
  return (fake, settings);
}

const _locked = 'SENALOVIRA is locked';
const _content = 'No trips recorded yet';

void main() {
  testWidgets('off by default: never locks, never asks', (tester) async {
    final (auth, _) = await _launch(tester, lock: false);
    expect(find.text(_locked), findsNothing);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pumpAndSettle();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.text(_locked), findsNothing);
    expect(auth.checks, 0);
  });

  testWidgets('on: locked at start; a failed check can be retried',
      (tester) async {
    final fake = _FakeAuth()..answers.addAll([false, true]);
    final handle = tester.ensureSemantics();
    await _launch(tester, lock: true, auth: fake);
    expect(fake.checks, 1, reason: 'asked once, on its own, at start');
    expect(find.text(_locked), findsOneWidget);
    expect(find.text('Not unlocked. You can try again.'), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp(_content)),
      findsNothing,
      reason: 'locked content is hidden from screen readers',
    );
    await tester.tap(find.text('Unlock'));
    await tester.pumpAndSettle();
    expect(find.text(_locked), findsNothing);
    expect(find.bySemanticsLabel(RegExp(_content)), findsWidgets);
    handle.dispose();
  });

  testWidgets('the background locks; the prompt\'s "inactive" does not',
      (tester) async {
    final (auth, _) = await _launch(tester, lock: true);
    expect(find.text(_locked), findsNothing, reason: 'unlocked at start');
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.text(_locked), findsNothing);
    expect(auth.checks, 1, reason: 'a prompt or shade asks nothing new');

    // EN: No frame is drawn in the background; the first frame back is
    //     already locked. A failed check keeps the lock visible to test.
    // FR: Aucune image n'est dessinée en arrière-plan ; la première image au
    //     retour est déjà verrouillée. Une vérification échouée garde le
    //     verrou visible pour le test.
    auth.answers.add(false);
    for (final state in [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(state);
    }
    await tester.pumpAndSettle();
    expect(auth.checks, 2);
    expect(find.text(_locked), findsOneWidget);
    await tester.tap(find.text('Unlock'));
    await tester.pumpAndSettle();
    expect(find.text(_locked), findsNothing);
  });

  group('the setting', () {
    Future<void> openSettings(WidgetTester tester) async {
      tester
          .state<NavigatorState>(find.byType(Navigator).first)
          .push(MaterialPageRoute<void>(builder: (_) => const SettingsScreen()))
          .ignore();
      await tester.pumpAndSettle();
    }

    testWidgets('refused on a phone with nothing set up', (tester) async {
      final fake = _FakeAuth()..available = false;
      final (_, settings) = await _launch(tester, lock: false, auth: fake);
      await openSettings(tester);
      await tester.tap(find.text('Lock with face, fingerprint or code'));
      await tester.pumpAndSettle();
      expect(
        find.text('This phone has no face, fingerprint or code set up.'),
        findsOneWidget,
      );
      expect(settings.appLock, isFalse);
      expect(fake.checks, 0);
    });

    testWidgets('on and off both need the check', (tester) async {
      final fake = _FakeAuth();
      final (_, settings) = await _launch(tester, lock: false, auth: fake);
      await openSettings(tester);
      await tester.tap(find.text('Lock with face, fingerprint or code'));
      await tester.pumpAndSettle();
      expect(settings.appLock, isTrue);
      expect(
        find.text(_locked),
        findsNothing,
        reason: 'not locked on the spot',
      );

      fake.answers.add(false);
      await tester.tap(find.text('Lock with face, fingerprint or code'));
      await tester.pumpAndSettle();
      expect(settings.appLock, isTrue, reason: 'a failed check keeps it on');
      await tester.tap(find.text('Lock with face, fingerprint or code'));
      await tester.pumpAndSettle();
      expect(settings.appLock, isFalse);
      expect(fake.checks, 3);
    });
  });
}
