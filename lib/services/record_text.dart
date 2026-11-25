// EN: The US Presence Record as plain text, for people who listen to their documents: a
//     PDF from this app carries no reading structure and an image carries no words. One
//     fact per line, labelled, in reading order, in the user's language. It only formats;
//     every number comes from PresenceRecord.
// FR: La fiche de présence en texte brut, pour qui écoute ses documents : un PDF de cette
//     appli n'a pas de structure de lecture et une image n'a pas de mots. Un fait par
//     ligne, étiqueté, dans l'ordre de lecture et dans la langue de l'utilisateur. Simple
//     mise en forme ; chaque nombre vient de PresenceRecord.

import 'package:intl/intl.dart';

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

String buildRecordText(
  PresenceRecord record, {
  required AppLocalizations strings,
  required String localeName,
}) {
  final dates = DateFormat.yMMMMd(localeName);
  final totals = record.totals;
  String line(String label, String value) => strings.recordLine(label, value);
  String days(String label, int n) => line(label, strings.daysCount(n));

  final lines = <String>[
    strings.recordHeading,
    strings.recordAsOf(dates.format(record.asOf)),
    '',
    strings.recordDisclaimer,
    '',
    strings.recordSummaryTitle,
    days(strings.windowThisYear, totals.thisCalendarYear),
    days(strings.windowLast365, totals.rollingLast365),
    days(strings.windowLastYear, totals.priorCalendarYear),
    line(strings.recordSptLabel, record.formattedSpt),
    // EN: Fraction characters are not read reliably; plain digits are.
    // FR: Les caractères de fraction ne sont pas lus de façon fiable ; les chiffres si.
    strings.recordSptFormula.replaceAll('⅓', '1/3').replaceAll('⅙', '1/6'),
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
    ]);
  }
  lines.addAll(['', strings.recordAuthor]);

  // EN: CRLF throughout, including inside notes: older Windows readers need it.
  // FR: CRLF partout, y compris dans les notes : d'anciens lecteurs Windows l'exigent.
  return lines.join('\n').replaceAll(RegExp(r'\r\n|\r|\n'), '\r\n');
}
