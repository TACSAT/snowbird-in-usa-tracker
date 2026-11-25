// EN: Web pages opened by the About screen (FR-16), in the OS browser via url_launcher and
//     only when tapped: the app itself sends nothing and has no INTERNET permission.
//
//     The path names no app on purpose. An installed app cannot change its links, so they
//     must keep working if the name changes. Only the language is passed, so the page
//     opens in the language of the app; never a version, a device or any user data.
//
//     ⚠ These pages must exist before release: run tools/check_links.sh.
//
// FR: Pages web ouvertes par l'écran À propos (FR-16), dans le navigateur de l'OS via
//     url_launcher et seulement au toucher : l'appli n'envoie rien et n'a pas la permission
//     INTERNET.
//
//     Le chemin ne nomme volontairement aucune appli. Une appli installée ne peut changer
//     ses liens ; ils doivent donc survivre à un changement de nom. Seule la langue est
//     transmise, pour que la page s'ouvre dans celle de l'appli ; jamais une version, un
//     appareil ou une donnée de l'utilisateur.
//
//     ⚠ Ces pages doivent exister avant la publication : lancer tools/check_links.sh.

import 'package:snowbird_in_usa_tracker/config/app_identity.dart';

enum AppPage { report, request, status, roadmap, contribute, privacy }

abstract final class AppLinks {
  static Uri page(AppPage page, String languageCode) => Uri.https(
        AppIdentity.maker,
        '/apps/days/${page.name}',
        {'lang': languageCode},
      );

  // EN: The public source-code repository.
  // FR: Le dépôt public du code source.
  static const String sourceUrl =
      'https://github.com/TACSAT/snowbird-in-usa-tracker';
}
