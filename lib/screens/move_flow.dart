// EN: "I have moved to..." (STY-3), the quickest entry in the app: from an
//     ongoing stay, choose the new place (recent places first), check the date
//     (today by default) and save. Three taps for a regular route; the target is
//     a move recorded in under 15 seconds (section 16, step 2). The old stay is
//     closed and the new one opened in one saved step (TripRepository.moveOn).
// FR: « J'ai changé de lieu... » (STY-3), la saisie la plus rapide de
//     l'application : depuis un séjour en cours, choisir le nouveau lieu (les
//     lieux récents d'abord), vérifier la date (aujourd'hui par défaut) et
//     enregistrer. Trois touchers pour un trajet habituel ; l'objectif est un
//     changement noté en moins de 15 secondes (section 16, étape 2). L'ancien
//     séjour est fermé et le nouveau ouvert en une seule étape enregistrée
//     (TripRepository.moveOn).

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:snowbird_in_usa_tracker/l10n/app_localizations.dart';
import 'package:snowbird_in_usa_tracker/logic/input_limits.dart';
import 'package:snowbird_in_usa_tracker/models/trip.dart';
import 'package:snowbird_in_usa_tracker/screens/pickers.dart';
import 'package:snowbird_in_usa_tracker/screens/place_names.dart';
import 'package:snowbird_in_usa_tracker/screens/place_picker_screen.dart';
import 'package:snowbird_in_usa_tracker/screens/value_row.dart';
import 'package:snowbird_in_usa_tracker/services/storage_service.dart';
import 'package:snowbird_in_usa_tracker/state/trip_repository.dart';

// EN: Runs the whole move from [current]. Returns true once it is saved.
// FR: Mène tout le changement depuis [current]. Retourne vrai une fois
//     enregistré.
Future<bool> startMove(BuildContext context, Trip current) async {
  final repo = context.read<TripRepository>();
  final strings = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final place = await pickPlace(
    context,
    recent: [
      for (final p in repo.recentPlaces(limit: 6))
        if (p != current.place) p,
    ],
  );
  if (place == null || !context.mounted) return false;

  final now = DateTime.now();
  var date = DateTime(now.year, now.month, now.day);
  String? error;
  final saved = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setState) => AlertDialog(
        title: Text(strings.moveConfirmTitle(placeFullName(strings, place))),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                strings.moveExplain(
                  stayPlaceName(strings, current),
                  placeFullName(strings, place),
                ),
              ),
              const SizedBox(height: 8),
              ValueRow(
                label: strings.moveDateLabel,
                value: DateFormat.yMMMMd(strings.localeName).format(date),
                error: error,
                onTap: () async {
                  final picked = await pickDate(
                    dialogContext,
                    initial: date,
                    first: DateTime(InputLimits.minTripYear),
                    last: DateTime(now.year, now.month, now.day),
                  );
                  if (picked != null) {
                    setState(() {
                      date = picked;
                      error = null;
                    });
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(strings.cancel),
          ),
          FilledButton(
            onPressed: () async {
              final navigator = Navigator.of(dialogContext);
              try {
                await repo.moveOn(current, date, place);
                navigator.pop(true);
              } on TripValidationException catch (e) {
                setState(() {
                  error = switch (e.problem) {
                    TripProblem.moveBeforeArrival =>
                      strings.errorMoveBeforeArrival,
                    TripProblem.futureArrival => strings.errorFutureArrival,
                    TripProblem.tooMany =>
                      strings.errorTooManyTrips(InputLimits.maxTrips),
                    TripProblem.overlap ||
                    TripProblem.splitDate =>
                      strings.errorTripOverlap,
                  };
                });
              } on StorageWriteException {
                messenger.showSnackBar(
                  SnackBar(content: Text(strings.errorSaveFailed)),
                );
              }
            },
            child: Text(strings.save),
          ),
        ],
      ),
    ),
  );
  return saved ?? false;
}
