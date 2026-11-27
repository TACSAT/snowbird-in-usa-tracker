// EN: The reference page carries no figures (owner's decision 10): no number
//     that could go stale, in either language. Only the dated source lines may
//     hold digits, and those are dates. It also keeps the CNT-8 statement that
//     no legal exclusion is applied.
// FR: La page de référence ne porte aucun chiffre (décision 10 du
//     propriétaire) : aucun nombre qui pourrait devenir périmé, dans aucune des
//     deux langues. Seules les lignes de source datées peuvent contenir des
//     chiffres, et ce sont des dates. Elle garde aussi l'énoncé de CNT-8 selon
//     lequel aucune exclusion légale n'est appliquée.

import 'dart:ui' show Locale;

import 'package:flutter_test/flutter_test.dart';
import 'package:snowbird_in_usa_tracker/l10n/app_localizations.dart';

void main() {
  for (final locale in ['en', 'fr']) {
    final s = lookupAppLocalizations(Locale(locale));
    test('no figures on the reference page: $locale', () {
      final texts = [
        s.referenceIntro('APP'),
        s.referenceHowBody('APP'),
        s.referenceMythBody('APP'),
        s.referenceSptBody('APP'),
        s.referenceSptExclusions('APP'),
        s.referenceEntryBody,
        s.referenceTerritoriesBody,
        s.referenceCanadaTaxBody,
        s.referenceHealthBody,
        s.referenceMexicoBody('APP'),
        s.referenceSpmBody('APP'),
      ];
      for (final t in texts) {
        // EN: "I-94" is the name of a US record, and the "180-day rule" the
        //     name of the myth the page refutes: names, not figures.
        // FR: « I-94 » est le nom d'un relevé américain, et la « règle des 180
        //     jours » le nom du mythe que la page réfute : des noms, pas des
        //     chiffres.
        final named = t
            .replaceAll('I-94', '')
            .replaceAll('180-day rule', '')
            .replaceAll('règle des 180 jours', '');
        expect(
          RegExp(r'\d').hasMatch(named),
          isFalse,
          reason: t,
        );
      }
      expect(s.referenceHowBody('APP').toLowerCase(), contains('transit'));
    });
  }
}
