// EN: Places and home (sections 6 and 9). The table is automatic by default:
//     every country with recorded days, which is all most people need. Turning
//     that off lets the user choose places (countries or regions, TBL-3), their
//     order (buttons, not dragging, so it works by screen reader and one-handed),
//     each place's counting convention (CNT-1) and whether it shows with no days
//     (TBL-5). The home base is off by default and worded so it is not read as
//     a statement of legal residence (HOM-3).
// FR: Lieux et domicile (sections 6 et 9). Le tableau est automatique par
//     défaut : chaque pays ayant des jours enregistrés, ce qui suffit à la
//     plupart des gens. Désactiver cela permet de choisir les lieux (pays ou
//     régions, TBL-3), leur ordre (des boutons, pas de glisser, pour que cela
//     fonctionne au lecteur d'écran et d'une main), la convention de comptage de
//     chaque lieu (CNT-1) et s'il s'affiche sans jours (TBL-5). Le lieu de
//     résidence est désactivé par défaut et formulé pour ne pas être lu comme
//     une déclaration de résidence légale (HOM-3).

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:snowbird_in_usa_tracker/l10n/app_localizations.dart';
import 'package:snowbird_in_usa_tracker/logic/input_limits.dart';
import 'package:snowbird_in_usa_tracker/logic/presence_ledger.dart';
import 'package:snowbird_in_usa_tracker/logic/presence_table.dart';
import 'package:snowbird_in_usa_tracker/models/home_base.dart';
import 'package:snowbird_in_usa_tracker/models/place.dart';
import 'package:snowbird_in_usa_tracker/models/tracked_place.dart';
import 'package:snowbird_in_usa_tracker/screens/pickers.dart';
import 'package:snowbird_in_usa_tracker/screens/place_names.dart';
import 'package:snowbird_in_usa_tracker/screens/place_picker_screen.dart';
import 'package:snowbird_in_usa_tracker/screens/section_heading.dart';
import 'package:snowbird_in_usa_tracker/services/storage_service.dart';
import 'package:snowbird_in_usa_tracker/state/presence_settings.dart';
import 'package:snowbird_in_usa_tracker/state/trip_repository.dart';

class PlacesSettingsScreen extends StatelessWidget {
  const PlacesSettingsScreen({super.key});

  // EN: Any refused write is reported, never shown as saved.
  // FR: Toute écriture refusée est signalée, jamais montrée comme enregistrée.
  static Future<void> _guard(
    BuildContext context,
    Future<void> Function() action,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final strings = AppLocalizations.of(context);
    try {
      await action();
    } on StorageWriteException {
      messenger.showSnackBar(SnackBar(content: Text(strings.errorSaveFailed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final settings = context.watch<PresenceSettings>();
    final repo = context.watch<TripRepository>();
    final tracked = settings.tracked;
    final dateFmt = DateFormat.yMMMMd(strings.localeName);

    // EN: What the automatic table shows now, to start a chosen list from.
    // FR: Ce que le tableau automatique montre maintenant, pour amorcer une
    //     liste choisie.
    List<Place> automaticPlaces() => [
          for (final entry in PresenceTable.build(
            stays: repo.trips,
            visits: repo.visits,
            home: settings.home,
            today: DateTime.now(),
          ).entries)
            entry.row.place,
        ];

    return Scaffold(
      appBar: AppBar(title: Text(strings.placesSettingsTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          SectionHeading(
            strings.placesTrackedHeading,
            style: theme.textTheme.titleSmall,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(strings.placesAutomatic),
            subtitle: Text(strings.placesAutomaticHelper),
            value: tracked == null,
            onChanged: (automatic) => _guard(
              context,
              () => settings.setAutomatic(
                automatic,
                initial: automatic ? const [] : automaticPlaces(),
              ),
            ),
          ),
          if (tracked != null) ...[
            for (var i = 0; i < tracked.length; i++)
              _TrackedTile(
                item: tracked[i],
                first: i == 0,
                last: i == tracked.length - 1,
                guard: (action) => _guard(context, action),
              ),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.add),
                label: Text(strings.placesAdd),
                onPressed: () async {
                  final picked =
                      await pickPlace(context, recent: repo.recentPlaces());
                  if (picked != null && context.mounted) {
                    await _guard(context, () => settings.addTracked(picked));
                  }
                },
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(strings.conventionExplain, style: theme.textTheme.bodySmall),
          const Divider(height: 32),
          SectionHeading(
            strings.homeHeading,
            style: theme.textTheme.titleSmall,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(strings.homeSwitch),
            value: settings.homeEnabled,
            onChanged: (on) {
              if (on && settings.homePeriods.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(strings.homeNeedPlace)),
                );
                return;
              }
              _guard(context, () => settings.setHomeEnabled(on));
            },
          ),
          Text(strings.homeExplain, style: theme.textTheme.bodySmall),
          const SizedBox(height: 8),
          for (final period in settings.homePeriods)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                strings.homePeriod(
                  placeFullName(strings, period.place),
                  dateFmt.format(period.from),
                ),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: strings.homeRemove,
                onPressed: () =>
                    _guard(context, () => settings.removeHomePeriod(period)),
              ),
            ),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.home_outlined),
              label: Text(strings.homeAddPeriod),
              onPressed: () => _addHome(context, settings, repo),
            ),
          ),
        ],
      ),
    );
  }

  // EN: A home period is a place and a start date. The date defaults to the
  //     first recorded stay (or today), since the home usually predates it.
  // FR: Une période de domicile est un lieu et une date de début. La date vaut
  //     par défaut le premier séjour enregistré (ou aujourd'hui), car le
  //     domicile le précède généralement.
  Future<void> _addHome(
    BuildContext context,
    PresenceSettings settings,
    TripRepository repo,
  ) async {
    final strings = AppLocalizations.of(context);
    final place = await pickPlace(context, recent: repo.recentPlaces());
    if (place == null || !context.mounted) return;
    final now = DateTime.now();
    final stays = repo.trips;
    final initial = stays.isEmpty ? now : stays.last.arrivalDate;
    final from = await pickDate(
      context,
      initial: initial,
      first: DateTime(InputLimits.minTripYear),
      last: DateTime(now.year, now.month, now.day),
      help: strings.homeFromLabel,
    );
    if (from == null || !context.mounted) return;
    await _guard(
      context,
      () => settings.addHomePeriod(HomePeriod(place: place, from: from)),
    );
  }
}

class _TrackedTile extends StatelessWidget {
  final TrackedPlace item;
  final bool first;
  final bool last;
  final Future<void> Function(Future<void> Function() action) guard;

  const _TrackedTile({
    required this.item,
    required this.first,
    required this.last,
    required this.guard,
  });

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final settings = context.read<PresenceSettings>();
    final name = placeFullName(strings, item.place);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 4, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_upward),
                  tooltip: '${strings.placesMoveUp}: $name',
                  onPressed: first
                      ? null
                      : () => guard(() => settings.moveTracked(item.place, -1)),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_downward),
                  tooltip: '${strings.placesMoveDown}: $name',
                  onPressed: last
                      ? null
                      : () => guard(() => settings.moveTracked(item.place, 1)),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: '${strings.placesRemove}: $name',
                  onPressed: () =>
                      guard(() => settings.removeTracked(item.place)),
                ),
              ],
            ),
            Text(strings.placesConventionLabel),
            const SizedBox(height: 4),
            SegmentedButton<CountingConvention>(
              segments: [
                ButtonSegment(
                  value: CountingConvention.anyPart,
                  label: Text(strings.conventionAnyPart),
                ),
                ButtonSegment(
                  value: CountingConvention.endOfDay,
                  label: Text(strings.conventionEndOfDay),
                ),
              ],
              selected: {item.convention},
              onSelectionChanged: (s) => guard(
                () =>
                    settings.updateTracked(item.copyWith(convention: s.first)),
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(strings.placesPinned),
              value: item.pinned,
              onChanged: (v) =>
                  guard(() => settings.updateTracked(item.copyWith(pinned: v))),
            ),
          ],
        ),
      ),
    );
  }
}
