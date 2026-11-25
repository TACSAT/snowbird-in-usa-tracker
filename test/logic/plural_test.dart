// EN: A count must always show its own number. French treats zero as singular, so a fixed
//     "1" in a singular text would show one day where there are none.
// FR: Un compte doit toujours afficher son propre nombre. Le français traite zéro comme
//     un singulier : un « 1 » figé afficherait un jour là où il n'y en a aucun.

import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_test/flutter_test.dart';
import 'package:snowbird_in_usa_tracker/l10n/app_localizations.dart';

void main() {
  for (final locale in ['en', 'fr']) {
    test('counts show their own number: $locale', () {
      final s = lookupAppLocalizations(Locale(locale));
      for (final n in [0, 1, 2, 11, 21, 101, 365, 1000000]) {
        expect(s.daysCount(n), startsWith('$n '));
        expect(s.assumeStalePlanned(n), contains(' $n '));
      }
    });
  }

  test('wording for 0, 1 and 2 days', () {
    final en = lookupAppLocalizations(const Locale('en'));
    final fr = lookupAppLocalizations(const Locale('fr'));
    expect(
      [
        for (final n in [0, 1, 2]) en.daysCount(n),
      ],
      ['0 days', '1 day', '2 days'],
    );
    expect(
      [
        for (final n in [0, 1, 2]) fr.daysCount(n),
      ],
      ['0 jour', '1 jour', '2 jours'],
    );
  });
}
