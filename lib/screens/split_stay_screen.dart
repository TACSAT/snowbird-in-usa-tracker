// EN: Refine a stay into two places later, without retyping it (STY-9): a user
//     who recorded "Canada, 1 June to 30 September" can say "from 12 July, Yukon".
//     The places offered are limited to the stay's country, so the country's
//     total cannot change; the repository enforces this too.
// FR: Préciser plus tard un séjour en deux lieux, sans le retaper (STY-9) : un
//     utilisateur qui a noté « Canada, du 1er juin au 30 septembre » peut dire
//     « à partir du 12 juillet, Yukon ». Les lieux proposés sont limités au pays
//     du séjour, afin que le total du pays ne puisse pas changer ; le dépôt
//     l'impose aussi.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:snowbird_in_usa_tracker/l10n/app_localizations.dart';
import 'package:snowbird_in_usa_tracker/logic/input_limits.dart';
import 'package:snowbird_in_usa_tracker/models/place.dart';
import 'package:snowbird_in_usa_tracker/models/trip.dart';
import 'package:snowbird_in_usa_tracker/screens/pickers.dart';
import 'package:snowbird_in_usa_tracker/screens/place_names.dart';
import 'package:snowbird_in_usa_tracker/screens/place_picker_screen.dart';
import 'package:snowbird_in_usa_tracker/screens/value_row.dart';
import 'package:snowbird_in_usa_tracker/services/storage_service.dart';
import 'package:snowbird_in_usa_tracker/state/trip_repository.dart';

class SplitStayScreen extends StatefulWidget {
  final Trip stay;

  const SplitStayScreen({super.key, required this.stay});

  @override
  State<SplitStayScreen> createState() => _SplitStayScreenState();
}

class _SplitStayScreenState extends State<SplitStayScreen> {
  DateTime? _at;
  late Place _before = widget.stay.place;
  Place? _after;
  String? _dateError;
  String? _afterError;

  // EN: The last date of the stay that has happened or is planned: its
  //     departure, or today for an ongoing stay.
  // FR: La dernière date du séjour, vécue ou planifiée : son départ, ou
  //     aujourd'hui pour un séjour en cours.
  DateTime get _end {
    final now = DateTime.now();
    return widget.stay.departureDate ?? DateTime(now.year, now.month, now.day);
  }

  Future<void> _pick({required bool before}) async {
    final picked = await pickPlace(context, withinCountry: widget.stay.place);
    if (picked == null) return;
    setState(() {
      if (before) {
        _before = picked;
      } else {
        _after = picked;
        _afterError = null;
      }
    });
  }

  Future<void> _save() async {
    final strings = AppLocalizations.of(context);
    final repo = context.read<TripRepository>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final at = _at;
    final after = _after;
    setState(() {
      _dateError = at == null ? strings.errorSplitDate : null;
      _afterError = after == null ? strings.errorPlaceRequired : null;
    });
    if (at == null || after == null) return;
    try {
      await repo.splitStay(widget.stay, at, before: _before, after: after);
    } on TripValidationException catch (e) {
      if (e.problem == TripProblem.tooMany) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(strings.errorTooManyTrips(InputLimits.maxTrips)),
          ),
        );
      } else {
        setState(() => _dateError = strings.errorSplitDate);
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
    final stay = widget.stay;
    final dateFmt = DateFormat.yMMMMd(strings.localeName);
    return Scaffold(
      appBar: AppBar(title: Text(strings.splitTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              strings.splitExplain(placeShortName(strings, stay.place.country)),
            ),
            const SizedBox(height: 16),
            ValueRow(
              label: strings.splitBeforeLabel,
              value: placeFullName(strings, _before),
              onTap: () => _pick(before: true),
            ),
            ValueRow(
              label: strings.splitDateLabel,
              value:
                  _at == null ? strings.optionalNotSet : dateFmt.format(_at!),
              error: _dateError,
              onTap: () async {
                final picked = await pickDate(
                  context,
                  initial: _at ?? stay.arrivalDate,
                  first: stay.arrivalDate,
                  last: _end,
                );
                if (picked != null) {
                  setState(() {
                    _at = picked;
                    _dateError = null;
                  });
                }
              },
            ),
            ValueRow(
              label: strings.splitAfterLabel,
              value: _after == null
                  ? strings.optionalNotSet
                  : placeFullName(strings, _after!),
              error: _afterError,
              onTap: () => _pick(before: false),
            ),
            const SizedBox(height: 24),
            FilledButton(onPressed: _save, child: Text(strings.save)),
          ],
        ),
      ),
    );
  }
}
