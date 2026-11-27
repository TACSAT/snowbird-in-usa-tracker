// EN: Host side of the device pass: saves each screenshot the app takes, and
//     each export file it reports (base64), under build/device_pass/. build/
//     is a symlink outside iCloud (see CLAUDE.md), so nothing lands in the
//     synced tree.
// FR: Côté hôte de la vérification sur appareil : enregistre chaque capture
//     prise par l'appli, et chaque fichier d'export rapporté (en base64), sous
//     build/device_pass/. build/ est un lien symbolique hors d'iCloud (voir
//     CLAUDE.md) ; rien n'arrive donc dans l'arborescence synchronisée.

import 'dart:convert';
import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() => integrationDriver(
      onScreenshot: (name, bytes, [args]) async {
        final file = File('build/device_pass/$name.png');
        file.parent.createSync(recursive: true);
        file.writeAsBytesSync(bytes);
        return true;
      },
      responseDataCallback: (data) async {
        for (final entry in (data ?? const <String, dynamic>{}).entries) {
          final value = entry.value;
          if (value is! String) continue;
          final file = File('build/device_pass/${entry.key}');
          file.parent.createSync(recursive: true);
          file.writeAsBytesSync(base64Decode(value));
        }
      },
    );
