// EN: The phone's own unlock check (face, fingerprint or device code), used by
//     the optional app lock (WRK-11): phones in shared housing are handled by
//     others, and a travel and work history is revealing. The check runs on
//     the device through the system's service; nothing about it is stored by
//     the app or leaves the phone, and no network is involved.
//
//     An interface, so tests use a fake and never reach the platform.
// FR: La vérification de déverrouillage du téléphone lui-même (visage,
//     empreinte ou code de l'appareil), utilisée par le verrouillage
//     facultatif de l'appli (WRK-11) : dans un logement partagé, les téléphones
//     passent entre plusieurs mains, et un historique de voyages et de travail
//     en dit long. La vérification se fait sur l'appareil par le service du
//     système ; l'appli n'en conserve rien, rien ne quitte le téléphone, et
//     aucun réseau n'intervient.
//
//     Une interface, afin que les tests utilisent une imitation et
//     n'atteignent jamais la plateforme.

import 'package:local_auth/local_auth.dart';

abstract class DeviceAuth {
  const DeviceAuth();

  // EN: True when the phone has a face, fingerprint or code set up to check.
  // FR: Vrai quand le téléphone a un visage, une empreinte ou un code configuré.
  Future<bool> isAvailable();

  // EN: Shows the phone's own prompt. True only when the person passed it;
  //     any error (cancelled, locked out, unavailable) is false, never a crash.
  // FR: Affiche l'invite du téléphone. Vrai seulement si la personne l'a
  //     réussie ; toute erreur (annulation, blocage, indisponibilité) donne
  //     faux, jamais un plantage.
  Future<bool> check(String reason);
}

class LocalDeviceAuth extends DeviceAuth {
  const LocalDeviceAuth();

  @override
  Future<bool> isAvailable() async {
    try {
      return await LocalAuthentication().isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> check(String reason) async {
    try {
      // EN: biometricOnly false: the device code is accepted too, so a person
      //     without a fingerprint or face set up can still use the lock.
      // FR: biometricOnly faux : le code de l'appareil est aussi accepté, afin
      //     qu'une personne sans empreinte ni visage configuré puisse quand
      //     même utiliser le verrouillage.
      return await LocalAuthentication().authenticate(
        localizedReason: reason,
        persistAcrossBackgrounding: true,
      );
    } catch (_) {
      return false;
    }
  }
}
