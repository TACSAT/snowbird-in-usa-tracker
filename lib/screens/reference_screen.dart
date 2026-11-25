// EN: Reference screen (FR-15): a neutral, plain-language page listing the numbers
//     snowbirds commonly track, framed explicitly as background information — never
//     advice, never a value the app sets for you. It exists so a user facing the
//     empty Alerts screen is not staring at a blank box wondering what number to
//     type; it informs without prescribing, and every item ends by pointing back to
//     the user's own judgement or a professional. This upholds the positioning
//     invariant (arithmetic and information, never a verdict).
//
// FR: Écran de référence (FR-15) : une page neutre en langage simple listant les
//     nombres que les snowbirds suivent souvent, présentée explicitement comme une
//     information générale — jamais un conseil, jamais une valeur que l'appli fixe
//     pour vous. Elle existe pour qu'un utilisateur devant l'écran d'alertes vide ne
//     fixe pas une case blanche en se demandant quel nombre saisir ; elle informe
//     sans prescrire, et chaque élément renvoie au jugement de l'utilisateur ou à un
//     professionnel. Cela respecte l'invariant de positionnement (arithmétique et
//     information, jamais un verdict).

import 'package:flutter/material.dart';

import 'package:snowbird_in_usa_tracker/config/app_identity.dart';
import 'package:snowbird_in_usa_tracker/l10n/app_localizations.dart';
import 'package:snowbird_in_usa_tracker/screens/section_heading.dart';

class ReferenceScreen extends StatelessWidget {
  const ReferenceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(strings.referenceTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // EN: The framing up front — this is information, not advice, and the app
          //     sets none of these numbers for you.
          // FR: Le cadrage d'abord — ceci est une information, pas un conseil, et
          //     l'appli ne fixe aucun de ces nombres pour vous.
          Card(
            color: theme.colorScheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                strings.referenceIntro(AppIdentity.name),
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ),
          const SizedBox(height: 8),
          _item(
            theme,
            strings.referenceSptTitle,
            strings.referenceSptBody(AppIdentity.name),
          ),
          _item(
            theme,
            strings.referenceHealthTitle,
            strings.referenceHealthBody,
          ),
          _item(theme, strings.referenceEntryTitle, strings.referenceEntryBody),
          _item(
            theme,
            strings.referenceMythTitle,
            strings.referenceMythBody(AppIdentity.name),
          ),
        ],
      ),
    );
  }

  Widget _item(ThemeData theme, String title, String body) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeading(title, style: theme.textTheme.titleMedium),
              const SizedBox(height: 6),
              Text(body, style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
      );
}
