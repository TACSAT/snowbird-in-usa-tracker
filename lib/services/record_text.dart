// EN: The US Presence Record as plain text, for people who listen to their documents: a
//     PDF from this app carries no reading structure and an image carries no words. One
//     fact per line, labelled, in reading order, in the user's language. It only formats;
//     every number comes from PresenceRecord.
// FR: La fiche de présence en texte brut, pour qui écoute ses documents : un PDF de cette
//     appli n'a pas de structure de lecture et une image n'a pas de mots. Un fait par
//     ligne, étiqueté, dans l'ordre de lecture et dans la langue de l'utilisateur. Simple
//     mise en forme ; chaque nombre vient de PresenceRecord.

import 'package:intl/intl.dart';

import 'package:snowbird_in_usa_tracker/logic/presence_ledger.dart';
import 'package:snowbird_in_usa_tracker/screens/place_names.dart';
import 'package:snowbird_in_usa_tracker/screens/trip_edit_screen.dart'
    show purposeName;
import 'package:snowbird_in_usa_tracker/config/app_identity.dart';
import 'package:snowbird_in_usa_tracker/l10n/app_localizations.dart';
import 'package:snowbird_in_usa_tracker/logic/presence_record.dart';
import 'package:snowbird_in_usa_tracker/models/crossing_info.dart';
import 'package:snowbird_in_usa_tracker/models/trip.dart';

// EN: Every recorded field of a crossing on one line; empty when nothing was recorded.
//     Shared with the PDF so the two never disagree.
// FR: Tous les champs consignés d'un passage sur une ligne ; vide si rien ne l'est.
//     Partagé avec le PDF pour que les deux ne divergent jamais.
String crossingText(CrossingInfo? info) {
  if (info == null) return '';
  final time = [
    if (info.timeMinutes != null) info.formattedTime,
    if (info.timeZone != null) info.timeZone!,
  ].join(' ');
  return [
    if (time.isNotEmpty) time,
    if (info.location != null) info.location!,
    if (info.meansOfTravel != null) info.meansOfTravel!,
    if (info.carrier != null) info.carrier!,
  ].join(', ');
}

// EN: The record's title: the original one for the US-only record, otherwise
//     "Presence Record", with the country when limited to one (EXP-1).
// FR: Le titre de la fiche : celui d'origine pour les États-Unis seuls, sinon
//     « Fiche de présence », avec le pays si elle est limitée à un seul (EXP-1).
String recordHeadingFor(PresenceRecord record, AppLocalizations strings) {
  final scope = record.scope;
  if (record.isUnitedStates) return strings.recordHeading;
  return scope == null
      ? strings.recordHeadingAll
      : strings.recordHeadingPlace(placeFullName(strings, scope));
}

// EN: A counting convention in words, as the settings name it.
// FR: Une convention de comptage en mots, comme la nomment les paramètres.
String conventionName(AppLocalizations strings, CountingConvention c) =>
    switch (c) {
      CountingConvention.anyPart => strings.conventionAnyPart,
      CountingConvention.endOfDay => strings.conventionEndOfDay,
    };

String buildRecordText(
  PresenceRecord record, {
  required AppLocalizations strings,
  required String localeName,
}) {
  final dates = DateFormat.yMMMMd(localeName);
  final totals = record.totals;
  String line(String label, String value) => strings.recordLine(label, value);
  String days(String label, int n) => line(label, strings.daysCount(n));

  // EN: The US-only record keeps every line it always had, in the same order
  //     (tested against a frozen copy); it only adds how days were counted and
  //     each stay's place (EXP-2, EXP-3).
  // FR: La fiche des États-Unis seuls garde chacune de ses lignes, dans le même
  //     ordre (testé contre une copie figée) ; elle n'ajoute que la façon de
  //     compter les jours et le lieu de chaque séjour (EXP-2, EXP-3).
  final lines = <String>[
    recordHeadingFor(record, strings),
    strings.recordAsOf(dates.format(record.asOf)),
    '',
    strings.recordDisclaimer,
    '',
    if (record.isUnitedStates) ...[
      strings.recordSummaryTitle,
      days(strings.windowThisYear, totals.thisCalendarYear),
      days(strings.windowLast365, totals.rollingLast365),
      days(strings.windowLastYear, totals.priorCalendarYear),
    ] else ...[
      strings.recordSummaryTitleAll,
      for (final p in record.places) ...[
        '',
        placeFullName(strings, p.place),
        days(strings.windowThisYear, p.thisCalendarYear),
        days(strings.windowLast365, p.rollingLast365),
        days(strings.windowLastYear, p.priorCalendarYear),
        strings.recordCountedBy(conventionName(strings, p.convention)),
        if (p.assumedThisYear > 0 || p.assumedLast365 > 0)
          strings.recordAssumedLine(
            strings.daysCount(p.assumedThisYear),
            strings.daysCount(p.assumedLast365),
          ),
        if (p.plannedThisYear > 0)
          strings.recordPlannedLine(
            '${record.asOf.year}',
            strings.daysCount(p.plannedThisYear),
          ),
        if (record.includeWork)
          strings.recordWorkedLine(
            strings.daysCount(p.workedThisYear),
            strings.daysCount(p.workedLast365),
          ),
      ],
      if (record.showsSpt) '',
    ],
    if (record.showsSpt) ...[
      line(strings.recordSptLabel, record.formattedSpt),
      // EN: Fraction characters are not read reliably; plain digits are.
      // FR: Les caractères de fraction ne sont pas lus de façon fiable ; les chiffres si.
      strings.recordSptFormula.replaceAll('⅓', '1/3').replaceAll('⅙', '1/6'),
    ],
    if (record.isUnitedStates)
      strings.recordCountedBy(
        conventionName(strings, CountingConvention.anyPart),
      ),
  ];

  for (final (index, trip) in record.trips.indexed) {
    final departure = trip.departureDate;
    final entry = crossingText(trip.arrivalInfo);
    final exit = crossingText(trip.departureInfo);
    final status = trip.status == TripStatus.planned
        ? strings.tripStatusPlanned
        : trip.isInProgress(record.asOf)
            ? strings.tripStatusCurrent
            : strings.tripStatusActual;
    lines.addAll([
      '',
      strings.recordTripNumber(index + 1, record.trips.length),
      line(strings.recordColStatus, status),
      line(strings.fieldPlace, stayPlaceName(strings, trip)),
      if (trip.name != null) line(strings.recordTripName, trip.name!),
      line(strings.fieldArrivalDate, dates.format(trip.arrivalDate)),
      line(
        strings.fieldDepartureDate,
        departure == null ? strings.tripOngoing : dates.format(departure),
      ),
      line(strings.recordColDays, '${trip.daysPresent(record.asOf)}'),
      if (entry.isNotEmpty) strings.recordEntryLabel(entry),
      if (exit.isNotEmpty) strings.recordExitLabel(exit),
      if (trip.notes != null) line(strings.recordNotes, trip.notes!),
      if (record.includeWork) ...[
        strings.rangeWorked(strings.daysCount(record.workedInStay(trip))),
        if (trip.purpose != null)
          line(strings.workPurposeLabel, purposeName(strings, trip.purpose!)),
        if (trip.label != null) line(strings.workLabelField, trip.label!),
      ],
    ]);
  }
  if (record.visits.isNotEmpty) {
    lines.addAll(['', strings.visitsTitle]);
    for (final visit in record.visits) {
      lines.add(
        line(
          dates.format(visit.date),
          [
            placeFullName(strings, visit.place),
            if (visit.status == TripStatus.planned) strings.tripStatusPlanned,
            if (record.includeWork && visit.worked) strings.tableWorked,
          ].join(' · '),
        ),
      );
    }
  }
  lines.addAll(['', strings.recordAuthor(AppIdentity.name, AppIdentity.maker)]);

  // EN: CRLF throughout, including inside notes: older Windows readers need it.
  // FR: CRLF partout, y compris dans les notes : d'anciens lecteurs Windows l'exigent.
  return lines.join('\n').replaceAll(RegExp(r'\r\n|\r|\n'), '\r\n');
}
