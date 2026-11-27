// EN: The real lock check (LocalDeviceAuth, local_auth) on an iOS simulator
//     with Face ID enrolled. The host sends a matching face while this waits
//     (tools/lock_pass.sh); a pass proves the platform wiring: the Face ID
//     usage text, the plugin, and the result reaching the app.
// FR: La vraie vérification de verrouillage (LocalDeviceAuth, local_auth) sur
//     un simulateur iOS avec Face ID enrôlé. L'hôte envoie un visage
//     correspondant pendant l'attente (tools/lock_pass.sh) ; une réussite
//     prouve le câblage de la plateforme : le texte d'usage de Face ID, le
//     module, et le résultat qui parvient à l'appli.

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:snowbird_in_usa_tracker/services/device_auth.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the phone\'s own check passes with a matching face',
      (tester) async {
    const auth = LocalDeviceAuth();
    expect(await auth.isAvailable(), isTrue);
    expect(await auth.check('Unlock for the device pass'), isTrue);
  });
}
