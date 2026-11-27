// EN: Day visits (WRK-5): part of a day in another place without moving there.
//     One entry replaces a stay out and a stay back, which spares a commuter
//     dozens of entries. Each visit counts as a day present in its place by "any
//     part of the day".
// FR: Visites d'un jour (WRK-5) : une partie de journée dans un autre lieu, sans
//     y déménager. Une entrée remplace un séjour aller et un séjour retour, ce qui
//     épargne des dizaines d'entrées à un navetteur. Chaque visite compte comme un
//     jour de présence dans son lieu selon « toute partie du jour ».

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:snowbird_in_usa_tracker/l10n/app_localizations.dart';
import 'package:snowbird_in_usa_tracker/logic/input_limits.dart';
import 'package:snowbird_in_usa_tracker/models/day_visit.dart';
import 'package:snowbird_in_usa_tracker/models/place.dart';
import 'package:snowbird_in_usa_tracker/models/trip.dart';
import 'package:snowbird_in_usa_tracker/screens/pickers.dart';
import 'package:snowbird_in_usa_tracker/screens/place_names.dart';
import 'package:snowbird_in_usa_tracker/screens/place_picker_screen.dart';
import 'package:snowbird_in_usa_tracker/screens/value_row.dart';
import 'package:snowbird_in_usa_tracker/services/storage_service.dart';
import 'package:snowbird_in_usa_tracker/state/trip_repository.dart';

class VisitsScreen extends StatelessWidget {
  const VisitsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final repo = context.watch<TripRepository>();
    final visits = repo.visits;
    final dateFmt = DateFormat.yMMMd(strings.localeName);
    return Scaffold(
      appBar: AppBar(title: Text(strings.visitsTitle)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 88),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(strings.visitsExplain),
          ),
          if (visits.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(strings.visitsEmpty),
            ),
          for (final visit in visits)
            MergeSemantics(
              child: ListTile(
                title: Text(placeFullName(strings, visit.place)),
                subtitle: Text(
                  visit.status == TripStatus.planned
                      ? '${dateFmt.format(visit.date)} · '
                          '${strings.tripStatusPlanned}'
                      : dateFmt.format(visit.date),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: strings.deleteVisit,
                  onPressed: () => _delete(context, visit),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: Text(strings.addVisit),
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const VisitEditScreen()),
        ),
      ),
    );
  }

  Future<void> _delete(BuildContext context, DayVisit visit) async {
    final strings = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await context.read<TripRepository>().deleteVisit(visit.id);
    } on StorageWriteException {
      messenger.showSnackBar(SnackBar(content: Text(strings.errorSaveFailed)));
    }
  }
}

class VisitEditScreen extends StatefulWidget {
  const VisitEditScreen({super.key});

  @override
  State<VisitEditScreen> createState() => _VisitEditScreenState();
}

class _VisitEditScreenState extends State<VisitEditScreen> {
  TripStatus _status = TripStatus.actual;
  late DateTime _date;
  Place? _place;
  String? _dateError;
  String? _placeError;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _date = DateTime(now.year, now.month, now.day);
  }

  Future<void> _save() async {
    final strings = AppLocalizations.of(context);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final place = _place;
    if (place == null) {
      setState(() => _placeError = strings.errorPlaceRequired);
      return;
    }
    try {
      await context.read<TripRepository>().addVisit(
            DayVisit.create(date: _date, place: place, status: _status),
          );
    } on TripValidationException catch (e) {
      if (e.problem == TripProblem.tooMany) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(strings.errorTooManyVisits(InputLimits.maxVisits)),
          ),
        );
      } else {
        setState(() => _dateError = strings.errorFutureArrival);
      }
      return;
    } on StorageWriteException {
      messenger.showSnackBar(SnackBar(content: Text(strings.errorSaveFailed)));
      return;
    }
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(strings.addVisit)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SegmentedButton<TripStatus>(
              segments: [
                ButtonSegment(
                  value: TripStatus.actual,
                  label: Text(strings.tripStatusActual),
                ),
                ButtonSegment(
                  value: TripStatus.planned,
                  label: Text(strings.tripStatusPlanned),
                ),
              ],
              selected: {_status},
              onSelectionChanged: (s) => setState(() {
                _status = s.first;
                _dateError = null;
              }),
            ),
            const SizedBox(height: 16),
            ValueRow(
              label: strings.fieldPlace,
              value: _place == null
                  ? strings.optionalNotSet
                  : placeFullName(strings, _place!),
              error: _placeError,
              onTap: () async {
                final picked = await pickPlace(
                  context,
                  recent: context.read<TripRepository>().recentPlaces(),
                );
                if (picked != null) {
                  setState(() {
                    _place = picked;
                    _placeError = null;
                  });
                }
              },
            ),
            ValueRow(
              label: strings.fieldVisitDate,
              value: DateFormat.yMMMMd(strings.localeName).format(_date),
              error: _dateError,
              onTap: () async {
                final picked = await pickDate(
                  context,
                  initial: _date,
                  first: DateTime(InputLimits.minTripYear),
                  last: DateTime(
                    DateTime.now().year + InputLimits.maxYearsAhead,
                    12,
                    31,
                  ),
                );
                if (picked != null) {
                  setState(() {
                    _date = picked;
                    _dateError = null;
                  });
                }
              },
            ),
            const SizedBox(height: 24),
            FilledButton(onPressed: _save, child: Text(strings.save)),
          ],
        ),
      ),
    );
  }
}
