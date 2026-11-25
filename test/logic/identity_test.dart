// EN: Name, maker and links. The name is provisional, so it is written once in Dart and
//     repeated only in the two native labels; this keeps them in step and makes sure no
//     earlier name or maker is still shown to anyone.
// FR: Nom, auteur et liens. Le nom est provisoire : il est écrit une fois en Dart et
//     répété seulement dans les deux libellés natifs ; ceci les garde d'accord et vérifie
//     qu'aucun ancien nom ou auteur n'est encore montré.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:snowbird_in_usa_tracker/config/app_identity.dart';
import 'package:snowbird_in_usa_tracker/config/app_links.dart';

void main() {
  test('the native labels match the name', () {
    expect(AppIdentity.name, 'SENALOVIRA');
    expect(AppIdentity.maker, 'teagarden.net');
    final manifest =
        File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    expect(manifest, contains('android:label="${AppIdentity.name}"'));
    final plist = File('ios/Runner/Info.plist').readAsStringSync();
    for (final key in ['CFBundleDisplayName', 'CFBundleName']) {
      expect(
        plist,
        matches(
          RegExp('<key>$key</key>\\s*<string>${AppIdentity.name}</string>'),
        ),
      );
    }
  });

  test('no shown text hard-codes a name or an earlier maker', () {
    for (final locale in ['en', 'fr']) {
      final arb = jsonDecode(
        File('lib/l10n/app_$locale.arb').readAsStringSync(),
      ) as Map<String, dynamic>;
      for (final MapEntry(:key, :value) in arb.entries) {
        if (key.startsWith('@')) continue;
        for (final banned in [
          'snowbird',
          'senalovira',
          'veidima',
          'veiðima',
        ]) {
          expect(
            (value as String).toLowerCase(),
            isNot(contains(banned)),
            reason: '$locale $key',
          );
        }
      }
    }
  });

  test('public documents name the maker and not the earlier one', () {
    for (final path in [
      'README.md',
      'PRIVACY.md',
      'RELEASING.md',
      'LICENSE',
      '.github/ISSUE_TEMPLATE/config.yml',
    ]) {
      final text = File(path).readAsStringSync();
      expect(text, contains(AppIdentity.maker), reason: path);
      expect(
        text.toLowerCase(),
        isNot(matches(RegExp('vei[dð]ima[dð]ur'))),
        reason: path,
      );
    }
  });

  test('every page is on the maker site, in the app language', () {
    for (final page in AppPage.values) {
      for (final lang in ['en', 'fr']) {
        final uri = AppLinks.page(page, lang);
        expect(uri.scheme, 'https');
        expect(uri.host, AppIdentity.maker);
        expect(uri.path, startsWith('/apps/days/'));
        expect(uri.queryParameters, {'lang': lang});
        // EN: The path must survive a change of name.
        // FR: Le chemin doit survivre à un changement de nom.
        expect(
          uri.path.toLowerCase(),
          isNot(contains(AppIdentity.name.toLowerCase())),
        );
      }
    }
    expect(
      {for (final p in AppPage.values) AppLinks.page(p, 'en').path},
      hasLength(AppPage.values.length),
    );
  });

  test('the link checker covers exactly the pages the app opens', () {
    final script = File('tools/check_links.sh').readAsStringSync();
    for (final page in AppPage.values) {
      expect(script, contains(AppLinks.page(page, 'en').path));
    }
    expect('/apps/days/'.allMatches(script).length, AppPage.values.length);
  });
}
