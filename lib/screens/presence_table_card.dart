// EN: The Days present table on the main screen (section 9). Built as a list,
//     not a grid (TBL-10): at large text each row stacks its figures under the
//     name, and a screen reader hears one item per place ("Canada: 120 days this
//     calendar year, 180 days in the last 365 days"). Places are named in words,
//     never shown by flag or colour alone (ACC-1). The numbers themselves come
//     from PresenceTable; nothing is computed here.
// FR: Le tableau des jours de présence sur l'écran principal (section 9).
//     Construit comme une liste, pas une grille (TBL-10) : en grand texte,
//     chaque ligne empile ses chiffres sous le nom, et un lecteur d'écran entend
//     un élément par lieu (« Canada : 120 jours cette année civile, 180 jours au
//     cours des 365 derniers jours »). Les lieux sont nommés en mots, jamais
//     montrés par un drapeau ou une couleur seuls (ACC-1). Les nombres viennent
//     de PresenceTable ; rien n'est calculé ici.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:snowbird_in_usa_tracker/l10n/app_localizations.dart';
import 'package:snowbird_in_usa_tracker/logic/presence_ledger.dart';
import 'package:snowbird_in_usa_tracker/logic/presence_table.dart';
import 'package:snowbird_in_usa_tracker/models/place.dart';
import 'package:snowbird_in_usa_tracker/screens/explore_screen.dart';
import 'package:snowbird_in_usa_tracker/screens/place_names.dart';
import 'package:snowbird_in_usa_tracker/screens/places_settings_screen.dart';
import 'package:snowbird_in_usa_tracker/screens/reference_screen.dart';
import 'package:snowbird_in_usa_tracker/screens/section_heading.dart';
import 'package:snowbird_in_usa_tracker/state/presence_settings.dart';
import 'package:snowbird_in_usa_tracker/state/trip_repository.dart';

class PresenceTableCard extends StatelessWidget {
  const PresenceTableCard({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final repo = context.watch<TripRepository>();
    final settings = context.watch<PresenceSettings>();
    final table = PresenceTable.build(
      stays: repo.trips,
      visits: repo.visits,
      home: settings.home,
      tracked: settings.tracked,
      today: DateTime.now(),
    );
    final large = MediaQuery.textScalerOf(context).scale(14) / 14 > 1.3;
    final now = table.now;
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    final rows = <Widget>[];
    for (final entry in table.entries) {
      final expanded = entry.expandable && settings.isExpanded(entry.row.place);
      rows.add(
        _FigureRow(
          name: placeFullName(strings, entry.row.place),
          figures: entry.row.recorded,
          worked: settings.workEnabled ? entry.row.worked : null,
          endOfDay: entry.row.convention == CountingConvention.endOfDay,
          large: large,
          expanded: entry.expandable ? expanded : null,
          onTap: entry.expandable
              ? () => settings.setExpanded(entry.row.place, !expanded)
              : null,
        ),
      );
      if (expanded) {
        for (final region in entry.regions) {
          rows.add(
            _FigureRow(
              name: placeShortName(strings, region.place),
              semanticName: placeFullName(strings, region.place),
              figures: region.recorded,
              worked: settings.workEnabled ? region.worked : null,
              large: large,
              depth: 1,
            ),
          );
        }
        if (!entry.regionNotRecorded.isZero) {
          rows.add(
            _FigureRow(
              name: strings.tableRegionNotRecorded,
              semanticName: strings.placeWholeCountry(
                placeShortName(strings, entry.row.place),
              ),
              figures: entry.regionNotRecorded,
              large: large,
              depth: 1,
            ),
          );
        }
      }
      if (!entry.row.assumed.isZero) {
        rows.add(
          _FigureRow(
            name: strings.tableAssumed,
            semanticName: '${placeFullName(strings, entry.row.place)}, '
                '${strings.tableAssumed}',
            figures: entry.row.assumed,
            large: large,
            depth: 1,
          ),
        );
      }
      final spt = table.spt;
      if (spt != null && entry.row.place == Place.unitedStates) {
        rows.add(_SptRow(formatted: spt.formatted));
      }
    }
    if (!table.notRecorded.isZero) {
      rows.add(
        _FigureRow(
          name: strings.tableNotRecorded,
          figures: table.notRecorded,
          large: large,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeading(
            strings.summaryHeading,
            style: theme.textTheme.titleSmall,
          ),
          if (now != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                strings.tableNow(
                  stayPlaceName(strings, now.stay),
                  strings.daysCount(now.days),
                ),
                style: theme.textTheme.bodyLarge,
              ),
            ),
          const SizedBox(height: 8),
          if (table.entries.isEmpty)
            Text(strings.tableEmpty)
          else ...[
            if (!large)
              ExcludeSemantics(
                child: Row(
                  children: [
                    const Expanded(child: SizedBox()),
                    _NumberCell(strings.tableColumnYear, style: muted),
                    _NumberCell(strings.tableColumnLast365, style: muted),
                  ],
                ),
              ),
            ...rows,
            const SizedBox(height: 8),
            if (table.hasCrossingDays)
              Text(strings.tableCrossingNote, style: muted),
            if (table.conventions.contains(CountingConvention.anyPart))
              Text(strings.tableAnyPartNote, style: muted),
            if (table.conventions.contains(CountingConvention.endOfDay))
              Text(strings.tableEndOfDayNote, style: muted),
          ],
          Wrap(
            spacing: 8,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const ExploreScreen(),
                  ),
                ),
                child: Text(strings.exploreTitle),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const PlacesSettingsScreen(),
                  ),
                ),
                child: Text(strings.tableChoosePlaces),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NumberCell extends StatelessWidget {
  final String text;
  final TextStyle? style;

  const _NumberCell(this.text, {this.style});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 84,
        child: Text(text, textAlign: TextAlign.end, style: style),
      );
}

// EN: One line of the table. [expanded] is null for a row that cannot expand.
//     The whole line is ONE screen-reader item whose label carries both figures
//     (TBL-10); an expandable line is also a button that says whether it is
//     open.
// FR: Une ligne du tableau. [expanded] est null pour une ligne qui ne se déplie
//     pas. Toute la ligne est UN élément pour le lecteur d'écran, dont le libellé
//     porte les deux chiffres (TBL-10) ; une ligne dépliable est aussi un bouton
//     qui dit si elle est ouverte.
class _FigureRow extends StatelessWidget {
  final String name;
  final String? semanticName;
  final WindowFigures figures;
  final bool large;
  final int depth;
  final bool endOfDay;
  final bool? expanded;
  final VoidCallback? onTap;

  // EN: Days worked, shown as a SECOND line and never summed with presence
  //     (TBL-12); null when work is off or the row is not a place.
  // FR: Jours travaillés, montrés en SECONDE ligne et jamais additionnés à la
  //     présence (TBL-12) ; null si le travail est désactivé ou si la ligne
  //     n'est pas un lieu.
  final WindowFigures? worked;

  const _FigureRow({
    required this.name,
    required this.figures,
    required this.large,
    this.semanticName,
    this.depth = 0,
    this.endOfDay = false,
    this.expanded,
    this.onTap,
    this.worked,
  });

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final style =
        depth == 0 ? theme.textTheme.titleMedium : theme.textTheme.bodyMedium;
    final presence = strings.tableRowSemantics(
      endOfDay
          ? '${semanticName ?? name} (${strings.tableEndOfDayTag})'
          : semanticName ?? name,
      strings.daysCount(figures.thisYear),
      strings.daysCount(figures.last365),
    );
    final work = worked;
    final label = work == null
        ? presence
        : '$presence; ${strings.tableWorkedSemantics(
            strings.daysCount(work.thisYear),
            strings.daysCount(work.last365),
          )}';
    final small = theme.textTheme.bodySmall;
    final nameWidget = Row(
      children: [
        if (expanded != null)
          Icon(expanded! ? Icons.expand_less : Icons.expand_more, size: 20),
        Flexible(
          child: Text(
            endOfDay ? '$name (${strings.tableEndOfDayTag})' : name,
            style: style,
          ),
        ),
      ],
    );
    final Widget content = large
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              nameWidget,
              Wrap(
                spacing: 16,
                children: [
                  Text('${strings.tableColumnYear}  ${figures.thisYear}'),
                  Text('${strings.tableColumnLast365}  ${figures.last365}'),
                ],
              ),
              if (work != null)
                Wrap(
                  spacing: 16,
                  children: [
                    Text(strings.tableWorked, style: small),
                    Text(
                      '${strings.tableColumnYear}  ${work.thisYear}',
                      style: small,
                    ),
                    Text(
                      '${strings.tableColumnLast365}  ${work.last365}',
                      style: small,
                    ),
                  ],
                ),
            ],
          )
        : Column(
            children: [
              Row(
                children: [
                  Expanded(child: nameWidget),
                  _NumberCell('${figures.thisYear}', style: style),
                  _NumberCell('${figures.last365}', style: style),
                ],
              ),
              if (work != null)
                Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsetsDirectional.only(start: 20),
                        child: Text(strings.tableWorked, style: small),
                      ),
                    ),
                    _NumberCell('${work.thisYear}', style: small),
                    _NumberCell('${work.last365}', style: small),
                  ],
                ),
            ],
          );
    return Semantics(
      container: true,
      button: onTap != null,
      expanded: expanded,
      label: label,
      hint: expanded == null
          ? null
          : expanded!
              ? strings.tableHideRegions
              : strings.tableShowRegions,
      child: ExcludeSemantics(
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: EdgeInsetsDirectional.only(
              start: depth * 24.0,
              top: 6,
              bottom: 6,
            ),
            child: content,
          ),
        ),
      ),
    );
  }
}

// EN: The Substantial Presence figure, under the United States only (TBL-7),
//     with its not-advice note and a link to the reference page, as before.
// FR: Le chiffre de présence substantielle, sous les États-Unis seulement
//     (TBL-7), avec sa note « pas un conseil » et un lien vers la page de
//     référence, comme avant.
class _SptRow extends StatelessWidget {
  final String formatted;

  const _SptRow({required this.formatted});

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return MergeSemantics(
      child: Semantics(
        button: true,
        child: InkWell(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const ReferenceScreen()),
          ),
          child: Padding(
            padding: const EdgeInsetsDirectional.only(
              start: 24,
              top: 6,
              bottom: 6,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        strings.recordSptLabel,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    Text(formatted, style: theme.textTheme.titleMedium),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.info_outline,
                      size: 18,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
                Text(
                  strings.sptDisclaimer,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
