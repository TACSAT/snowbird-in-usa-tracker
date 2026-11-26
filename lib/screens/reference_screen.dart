// EN: Reference screen (FR-15, FEA-5): a neutral, plain-language page of
//     background for each place the app counts, framed explicitly as
//     information — never advice, never a value the app sets for you. It exists
//     so a user facing the empty Alerts screen is not staring at a blank box
//     wondering what number to type; it informs without prescribing, and every
//     item ends by pointing back to the user's own judgement or a professional.
//     This upholds the positioning invariant (arithmetic and information, never
//     a verdict).
//
//     Owner's decision 10 (2026-11-25): no figures at first. Only facts checked
//     in REQUIREMENTS-places.md section 19 appear, each with its source and the
//     date it was checked; nothing listed there as "not confirmed" is used.
//     The page also says, as CNT-8 requires, that the app applies no legal
//     exclusion (transit, commuting, medical).
//
// FR: Écran de référence (FR-15, FEA-5) : une page neutre en langage simple de
//     repères pour chaque lieu que compte l'application, présentée explicitement
//     comme une information — jamais un conseil, jamais une valeur que l'appli
//     fixe pour vous. Elle existe pour qu'un utilisateur devant l'écran d'alertes
//     vide ne fixe pas une case blanche en se demandant quel nombre saisir ; elle
//     informe sans prescrire, et chaque élément renvoie au jugement de
//     l'utilisateur ou à un professionnel. Cela respecte l'invariant de
//     positionnement (arithmétique et information, jamais un verdict).
//
//     Décision 10 du propriétaire (2026-11-25) : aucun chiffre pour commencer.
//     Seuls figurent les faits vérifiés à la section 19 de
//     REQUIREMENTS-places.md, chacun avec sa source et sa date de vérification ;
//     rien de ce qui y est noté « non confirmé » n'est utilisé. La page dit
//     aussi, comme l'exige CNT-8, que l'application n'applique aucune exclusion
//     légale (transit, navette, soins).

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:snowbird_in_usa_tracker/config/app_identity.dart';
import 'package:snowbird_in_usa_tracker/l10n/app_localizations.dart';
import 'package:snowbird_in_usa_tracker/models/place.dart';
import 'package:snowbird_in_usa_tracker/screens/place_names.dart';
import 'package:snowbird_in_usa_tracker/screens/section_heading.dart';

// EN: The date the sourced facts on this page were last checked. Update it,
//     and REQUIREMENTS-places.md section 19, whenever a source is re-checked.
// FR: La date de la dernière vérification des faits sourcés de cette page. La
//     mettre à jour, ainsi que la section 19 de REQUIREMENTS-places.md, à chaque
//     nouvelle vérification d'une source.
final DateTime kReferenceCheckedOn = DateTime(2026, 11, 25);

class ReferenceScreen extends StatelessWidget {
  const ReferenceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final checked =
        DateFormat.yMMMMd(strings.localeName).format(kReferenceCheckedOn);
    String source(String name) => strings.referenceSource(name, checked);
    const app = AppIdentity.name;

    return Scaffold(
      appBar: AppBar(title: Text(strings.referenceTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // EN: The framing up front — this is information, not advice, and the
          //     app sets no limit for you.
          // FR: Le cadrage d'abord — ceci est une information, pas un conseil, et
          //     l'appli ne fixe aucune limite pour vous.
          Card(
            color: theme.colorScheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                strings.referenceIntro(app),
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ),
          _country(theme, strings.referenceGeneralTitle),
          _item(
            theme,
            strings.referenceHowTitle,
            [strings.referenceHowBody(app)],
          ),
          _item(
            theme,
            strings.referenceMythTitle,
            [strings.referenceMythBody(app)],
          ),
          _country(theme, placeShortName(strings, Place.unitedStates)),
          _item(
            theme,
            strings.referenceSptTitle,
            [
              strings.referenceSptBody(app),
              strings.referenceSptExclusions(app),
            ],
            source: source(strings.referenceSourceIrs),
          ),
          _item(
            theme,
            strings.referenceEntryTitle,
            [strings.referenceEntryBody],
          ),
          _item(
            theme,
            strings.referenceTerritoriesTitle,
            [strings.referenceTerritoriesBody],
            source: source(strings.referenceSourceIrs),
          ),
          _country(theme, placeShortName(strings, Place.canada)),
          _item(
            theme,
            strings.referenceCanadaTaxTitle,
            [strings.referenceCanadaTaxBody],
            source: source(strings.referenceSourceCra),
          ),
          _item(
            theme,
            strings.referenceHealthTitle,
            [strings.referenceHealthBody],
          ),
          _country(theme, placeShortName(strings, Place.mexico)),
          _item(
            theme,
            strings.referenceMexicoTitle,
            [strings.referenceMexicoBody(app)],
          ),
          _country(
            theme,
            placeShortName(strings, Place.saintPierreAndMiquelon),
          ),
          _item(
            theme,
            strings.referenceSpmTitle,
            [strings.referenceSpmBody(app)],
            source: source(strings.referenceSourceTravel),
          ),
        ],
      ),
    );
  }

  // EN: A country heading between groups of items, read as a heading.
  // FR: Un titre de pays entre les groupes d'éléments, lu comme un titre.
  Widget _country(ThemeData theme, String name) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 20, 4, 4),
        child: SectionHeading(name, style: theme.textTheme.titleLarge),
      );

  // EN: One item: a heading, its paragraphs, and its dated source if any.
  // FR: Un élément : un titre, ses paragraphes et sa source datée, s'il y en a.
  Widget _item(
    ThemeData theme,
    String title,
    List<String> paragraphs, {
    String? source,
  }) =>
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeading(title, style: theme.textTheme.titleMedium),
              for (final p in paragraphs) ...[
                const SizedBox(height: 6),
                Text(p, style: theme.textTheme.bodyMedium),
              ],
              if (source != null) ...[
                const SizedBox(height: 8),
                Text(
                  source,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
}
