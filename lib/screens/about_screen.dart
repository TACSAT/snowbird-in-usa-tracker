// EN: About screen (FR-14 / FR-16 / FR-18): the app's identity and privacy promise,
//     the version + build number (so a user report is actionable without any
//     telemetry), and external Feedback / Donate / Source buttons that open in the
//     OS browser. No data leaves the app — url_launcher hands the URL to the
//     browser, which makes the request, so the app itself needs no INTERNET
//     permission (NFR-1).
//
// FR: Écran À propos (FR-14 / FR-16 / FR-18) : l'identité de l'appli et sa promesse
//     de confidentialité, le numéro de version + build (pour qu'un signalement soit
//     exploitable sans aucune télémétrie), et des boutons externes Commentaires /
//     Don / Source qui s'ouvrent dans le navigateur de l'OS. Aucune donnée ne quitte
//     l'appli — url_launcher remet l'URL au navigateur, qui fait la requête, donc
//     l'appli elle-même n'a pas besoin de la permission INTERNET (NFR-1).

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:snowbird_in_usa_tracker/config/app_links.dart';
import 'package:snowbird_in_usa_tracker/l10n/app_localizations.dart';
import 'package:snowbird_in_usa_tracker/screens/section_heading.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(strings.aboutTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Column(
              children: [
                const Icon(Icons.ac_unit_rounded, size: 56),
                const SizedBox(height: 8),
                Text(strings.appTitle, style: theme.textTheme.headlineSmall),
                // EN: Version + build via package_info_plus — read locally from the
                //     installed bundle, no network.
                // FR: Version + build via package_info_plus — lu localement depuis le
                //     bundle installé, sans réseau.
                FutureBuilder<PackageInfo>(
                  future: PackageInfo.fromPlatform(),
                  builder: (context, snapshot) {
                    final info = snapshot.data;
                    if (info == null) return const SizedBox(height: 20);
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        strings.aboutVersion(info.version, info.buildNumber),
                        style: theme.textTheme.bodySmall,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          SectionHeading(
            strings.aboutPrivacyTitle,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(strings.aboutPrivacyBody, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 16),

          // EN: The same not-advice line the app shows on first launch.
          // FR: La même mention « pas un conseil » qu'au premier lancement.
          Text(
            strings.appDisclaimerBody,
            style: theme.textTheme.bodySmall?.copyWith(
              fontStyle: FontStyle.italic,
            ),
          ),
          const Divider(height: 32),

          OutlinedButton.icon(
            icon: const Icon(Icons.feedback_outlined),
            label: Text(strings.feedbackButton),
            onPressed: () => _launch(context, AppLinks.feedbackUrl),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.favorite_outline),
            label: Text(strings.donateButton),
            onPressed: () => _launch(context, AppLinks.donateUrl),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.code_rounded),
            label: Text(strings.aboutSourceButton),
            onPressed: () => _launch(context, AppLinks.sourceUrl),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              strings.aboutAuthor,
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  // EN: Open [url] in the OS browser. Capture the messenger before the await (the
  //     widget may unmount) and show a neutral error if the launch fails.
  // FR: Ouvrir [url] dans le navigateur de l'OS. Capturer le messenger avant l'await
  //     (le widget peut être démonté) et afficher une erreur neutre en cas d'échec.
  Future<void> _launch(BuildContext context, String url) async {
    final messenger = ScaffoldMessenger.of(context);
    final strings = AppLocalizations.of(context);
    var ok = false;
    try {
      ok = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      ok = false;
    }
    if (!ok) {
      messenger.showSnackBar(SnackBar(content: Text(strings.linkError)));
    }
  }
}
