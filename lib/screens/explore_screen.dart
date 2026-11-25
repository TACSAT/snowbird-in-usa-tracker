// EN: Explore days and plans: neutral counts for any period (FR-6) and a what-if for
//     a possible trip (FR-3). The possible trip lives only on this screen until the
//     user saves it. Projections say what they assume and carry the not-advice note
//     (FR-14); no figure is ever compared with a limit.
// FR: Explorer les jours et projets : comptes neutres pour toute période (FR-6) et
//     hypothèse pour un séjour possible (FR-3). Le séjour possible n'existe que sur
//     cet écran tant que l'utilisateur ne l'enregistre pas. Les projections disent ce
//     qu'elles supposent et portent la mention « pas un conseil » (FR-14) ; aucun
//     nombre n'est jamais comparé à une limite.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:snowbird_in_usa_tracker/l10n/app_localizations.dart';
import 'package:snowbird_in_usa_tracker/logic/input_limits.dart';
import 'package:snowbird_in_usa_tracker/logic/projection.dart';
import 'package:snowbird_in_usa_tracker/models/trip.dart';
import 'package:snowbird_in_usa_tracker/screens/pickers.dart';
import 'package:snowbird_in_usa_tracker/screens/value_row.dart';
import 'package:snowbird_in_usa_tracker/services/storage_service.dart';
import 'package:snowbird_in_usa_tracker/state/trip_repository.dart';

enum _Range { thisYear, last365, lastYear, custom }

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  _Range _range = _Range.thisYear;
  DateTime? _from;
  DateTime? _to;
  DateTime? _arrival;
  DateTime? _departure;

  // EN: Guards against a double tap saving the same trip twice.
  // FR: Évite qu'un double toucher enregistre deux fois le même séjour.
  bool _saving = false;

  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  (DateTime, DateTime)? get _bounds {
    final today = _today;
    switch (_range) {
      case _Range.thisYear:
        return (DateTime(today.year), DateTime(today.year, 12, 31));
      case _Range.last365:
        return (DateTime(today.year, today.month, today.day - 364), today);
      case _Range.lastYear:
        return (DateTime(today.year - 1), DateTime(today.year - 1, 12, 31));
      case _Range.custom:
        final from = _from;
        final to = _to;
        return from == null || to == null ? null : (from, to);
    }
  }

  Future<DateTime?> _pick(DateTime? current, DateTime first) => pickDate(
        context,
        initial: current ?? (first.isAfter(_today) ? first : _today),
        first: first,
        last: DateTime(_today.year + InputLimits.maxYearsAhead, 12, 31),
      );

  Future<void> _pickFrom() async {
    final d = await _pick(_from, DateTime(InputLimits.minTripYear));
    if (d == null || !mounted) return;
    setState(() {
      _from = d;
      if (_to?.isBefore(d) ?? false) _to = null;
    });
  }

  Future<void> _pickTo() async {
    final d = await _pick(_to, _from ?? DateTime(InputLimits.minTripYear));
    if (d != null && mounted) setState(() => _to = d);
  }

  Future<void> _pickArrival() async {
    final d = await _pick(_arrival, _today);
    if (d == null || !mounted) return;
    setState(() {
      _arrival = d;
      if (_departure?.isBefore(d) ?? false) _departure = null;
    });
  }

  Future<void> _pickDeparture() async {
    final d = await _pick(_departure, _arrival ?? _today);
    if (d != null && mounted) setState(() => _departure = d);
  }

  Future<void> _savePlanned(DateTime arrival, DateTime departure) async {
    if (_saving) return;
    _saving = true;
    final strings = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await context.read<TripRepository>().addTrip(
            Trip.create(
              arrivalDate: arrival,
              departureDate: departure,
              status: TripStatus.planned,
            ),
          );
      messenger.showSnackBar(SnackBar(content: Text(strings.whatIfSaved)));
      // EN: Clear it: the trip is now counted as planned, and leaving it here would
      //     show a difference of zero.
      // FR: L'effacer : le séjour compte désormais comme planifié, et le laisser ici
      //     montrerait une différence de zéro.
      if (mounted) _clearWhatIf();
    } on TripValidationException {
      // EN: Only the trip limit can refuse a planned trip.
      // FR: Seule la limite de séjours peut refuser un séjour planifié.
      messenger.showSnackBar(
        SnackBar(
          content: Text(strings.errorTooManyTrips(InputLimits.maxTrips)),
        ),
      );
    } on StorageWriteException {
      messenger.showSnackBar(SnackBar(content: Text(strings.errorSaveFailed)));
    } finally {
      _saving = false;
    }
  }

  void _clearWhatIf() => setState(() {
        _arrival = null;
        _departure = null;
      });

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final trips = context.watch<TripRepository>().trips;
    final dates = DateFormat.yMMMMd(strings.localeName);
    String shown(DateTime? d) =>
        d == null ? strings.optionalNotSet : dates.format(d);

    final bounds = _bounds;
    final count = bounds == null
        ? null
        : RangeCount.compute(
            trips: trips,
            start: bounds.$1,
            end: bounds.$2,
            today: _today,
          );
    final arrival = _arrival;
    final departure = _departure;
    final hasOpen = trips.any((t) => t.departureDate == null);
    final stale = stalePlannedTrips(trips, _today).length;

    return Scaffold(
      appBar: AppBar(title: Text(strings.exploreTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(strings.exploreRangeHeading, style: text.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (range, label) in [
                (_Range.thisYear, strings.windowThisYear),
                (_Range.last365, strings.windowLast365),
                (_Range.lastYear, strings.windowLastYear),
                (_Range.custom, strings.windowCustom),
              ])
                ChoiceChip(
                  label: Text(label),
                  selected: _range == range,
                  onSelected: (_) => setState(() => _range = range),
                ),
            ],
          ),
          if (_range == _Range.custom) ...[
            ValueRow(
              label: strings.rangeFrom,
              value: shown(_from),
              onTap: _pickFrom,
            ),
            ValueRow(
              label: strings.rangeTo,
              value: shown(_to),
              onTap: _pickTo,
            ),
          ],
          if (bounds != null && count != null) ...[
            const SizedBox(height: 12),
            Text(
              '${dates.format(bounds.$1)} – ${dates.format(bounds.$2)}',
              style: text.bodyMedium,
            ),
            const SizedBox(height: 4),
            Text(
              strings.rangeActual(strings.daysCount(count.actual)),
              style: text.titleMedium,
            ),
            Text(
              strings.rangeWithPlanned(strings.daysCount(count.withPlanned)),
              style: text.titleMedium,
            ),
          ],
          const Divider(height: 32),
          Text(strings.whatIfHeading, style: text.titleMedium),
          const SizedBox(height: 4),
          Text(strings.whatIfIntro, style: text.bodyMedium),
          ValueRow(
            label: strings.whatIfArrival,
            value: shown(arrival),
            onTap: _pickArrival,
          ),
          ValueRow(
            label: strings.whatIfDeparture,
            value: shown(departure),
            onTap: _pickDeparture,
          ),
          if (arrival != null && departure != null) ...[
            _WhatIfCard(
              result: WhatIf.compute(
                trips: trips,
                arrival: arrival,
                departure: departure,
              ),
              strings: strings,
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () => _savePlanned(arrival, departure),
              child: Text(strings.whatIfSave, textAlign: TextAlign.center),
            ),
          ],
          if (arrival != null || departure != null)
            TextButton(
              onPressed: _clearWhatIf,
              child: Text(strings.whatIfClear),
            ),
          const SizedBox(height: 16),
          // EN: Assumptions appear only when they affect the figures above.
          // FR: Les hypothèses n'apparaissent que si elles touchent les nombres
          //     ci-dessus.
          if (hasOpen) _Note(strings.assumeOpenTrip),
          if (stale > 0) _Note(strings.assumeStalePlanned(stale)),
          _Note(strings.recordDisclaimer),
        ],
      ),
    );
  }
}

class _Note extends StatelessWidget {
  final String text;
  const _Note(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(fontStyle: FontStyle.italic),
        ),
      );
}

// EN: Figures stacked as full sentences rather than a table, which would not survive
//     large text and reads poorly aloud.
// FR: Nombres empilés en phrases complètes plutôt qu'en tableau, qui ne survivrait pas
//     au grand texte et se lit mal à voix haute.
class _WhatIfCard extends StatelessWidget {
  final WhatIf result;
  final AppLocalizations strings;
  const _WhatIfCard({required this.result, required this.strings});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final dates = DateFormat.yMMMMd(strings.localeName);
    final asOf = dates.format(result.asOf);

    List<Widget> block(String title, String without, String including) => [
          const SizedBox(height: 12),
          Text(title, style: text.titleSmall),
          Text(strings.whatIfWithout(without), style: text.bodyLarge),
          Text(strings.whatIfWith(including), style: text.bodyLarge),
        ];
    List<Widget> days(String title, Comparison c) => block(
          title,
          strings.daysCount(c.without),
          strings.daysCount(c.including),
        );

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final y in result.years)
              ...days(
                strings.whatIfYear('${y.year}', dates.format(y.through)),
                y.days,
              ),
            ...days(strings.whatIfLast365(asOf), result.last365),
            ...block(
              strings.whatIfSpt(asOf),
              result.sptWithout.formatted,
              result.sptIncluding.formatted,
            ),
          ],
        ),
      ),
    );
  }
}
