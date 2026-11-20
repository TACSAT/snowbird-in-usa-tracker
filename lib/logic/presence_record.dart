// EN: The "US Presence Record" — the app's flagship deliverable (PLAN.md FR-8),
//     assembled here as PURE data + a CSV serialiser so the correctness-critical
//     part (which trips, which totals, which SPT figure) is unit-testable with no
//     Flutter, no packages, and no device. The rendering layers (PDF, PNG image,
//     print, share) live in RecordExporter and are a thin skin over this object.
//
//     POSITIONING (PLAN.md): the record shows NEUTRAL numbers only — per-window day
//     totals and the IRS Substantial Presence figure as arithmetic, each with the
//     "personal record, not advice" line. No verdict, no comparison to 183, no
//     colour of alarm. It never mentions any tax form by name (per the 2026-07-10
//     requirement revision).
//
//     The CSV uses ISO-8601 dates (YYYY-MM-DD) and fixed English column headers on
//     purpose: it is a DATA file an accountant or spreadsheet imports, where an
//     unambiguous, locale-neutral schema matters more than translation. The
//     human-facing PDF/image, by contrast, is localised by RecordExporter.
//
// FR: La « fiche de présence aux États-Unis » — le livrable vedette de l'appli
//     (PLAN.md FR-8), assemblée ici comme données PURES + un sérialiseur CSV pour
//     que la partie critique (quels séjours, quels totaux, quelle valeur SPT) soit
//     testable sans Flutter, sans paquets et sans appareil. Les couches de rendu
//     (PDF, image PNG, impression, partage) vivent dans RecordExporter et ne sont
//     qu'une fine surface au-dessus de cet objet.
//
//     POSITIONNEMENT (PLAN.md) : la fiche n'affiche que des nombres NEUTRES — les
//     totaux de jours par fenêtre et la valeur de présence substantielle de l'IRS
//     comme arithmétique, chacun avec la mention « fiche personnelle, pas un
//     conseil ». Aucun verdict, aucune comparaison à 183, aucune couleur d'alarme.
//     Elle ne nomme jamais aucun formulaire fiscal (selon la révision d'exigence du
//     2026-07-10).
//
//     Le CSV utilise des dates ISO-8601 (AAAA-MM-JJ) et des en-têtes de colonnes
//     anglais fixes à dessein : c'est un fichier de DONNÉES qu'un comptable ou un
//     tableur importe, où un schéma non ambigu et neutre compte plus que la
//     traduction. La fiche PDF/image destinée à l'humain, elle, est localisée par
//     RecordExporter.

import 'package:snowbird_in_usa_tracker/logic/day_counter.dart';
import 'package:snowbird_in_usa_tracker/models/crossing_info.dart';
import 'package:snowbird_in_usa_tracker/models/trip.dart';

// EN: The neutral per-window totals and the SPT breakdown that head the record.
// FR: Les totaux neutres par fenêtre et la décomposition SPT qui coiffent la fiche.
class PresenceTotals {
  final int asOfYear;
  final int thisCalendarYear;
  final int rollingLast365;
  final int priorCalendarYear;
  final SubstantialPresenceResult spt;

  const PresenceTotals({
    required this.asOfYear,
    required this.thisCalendarYear,
    required this.rollingLast365,
    required this.priorCalendarYear,
    required this.spt,
  });
}

class PresenceRecord {
  // EN: The date the record is computed "as of" — current-year and rolling counts
  //     are measured up to and including this day.
  // FR: La date « à laquelle » la fiche est calculée — les comptes de l'année
  //     courante et glissants sont mesurés jusqu'à ce jour inclus.
  final DateTime asOf;

  // EN: All trips, chronological (oldest first) — the natural reading order for a
  //     record someone scans top to bottom.
  // FR: Tous les séjours, chronologiques (plus ancien d'abord) — l'ordre de lecture
  //     naturel pour une fiche qu'on parcourt de haut en bas.
  final List<Trip> trips;

  final PresenceTotals totals;

  const PresenceRecord._({
    required this.asOf,
    required this.trips,
    required this.totals,
  });

  // EN: Build the record from the current trips. [asOf] defaults to today. Totals
  //     count ACTUAL presence only, so a planned trip never inflates a "days so
  //     far" number; planned trips still appear in the trip table, clearly marked.
  // FR: Construire la fiche à partir des séjours actuels. [asOf] par défaut =
  //     aujourd'hui. Les totaux ne comptent que la présence RÉELLE, pour qu'un
  //     séjour planifié ne gonfle jamais un nombre « jours à ce jour » ; les séjours
  //     planifiés apparaissent quand même dans le tableau, clairement marqués.
  factory PresenceRecord.build({required List<Trip> trips, DateTime? asOf}) {
    final asOfDate = _dateOnly(asOf ?? DateTime.now());
    final sorted = List<Trip>.from(trips)
      ..sort((a, b) => a.arrivalDate.compareTo(b.arrivalDate));

    final totals = PresenceTotals(
      asOfYear: asOfDate.year,
      thisCalendarYear: DayCounter.countDaysInCalendarYear(
        trips: trips,
        year: asOfDate.year,
      ),
      rollingLast365: DayCounter.countDaysInLastDays(
        trips: trips,
        days: 365,
        today: asOfDate,
      ),
      priorCalendarYear: DayCounter.countDaysInCalendarYear(
        trips: trips,
        year: asOfDate.year - 1,
      ),
      spt: DayCounter.substantialPresence(trips: trips, asOf: asOfDate),
    );

    return PresenceRecord._(asOf: asOfDate, trips: sorted, totals: totals);
  }

  // EN: Serialise to CSV text (RFC-4180-style quoting, CRLF line endings). Layout:
  //     a two-line title/disclaimer, the "as of" date, a blank line, the trip
  //     table with a header row, a blank line, then the neutral summary rows.
  // FR: Sérialiser en texte CSV (guillemets façon RFC-4180, fins de ligne CRLF).
  //     Disposition : un titre/avertissement sur deux lignes, la date « au », une
  //     ligne vide, le tableau des séjours avec une ligne d'en-tête, une ligne vide,
  //     puis les lignes de résumé neutres.
  String toCsv() {
    final rows = <List<String>>[
      ['SnowBird — US Presence Record'],
      [
        'This is a personal record, not advice. '
            'Verify your situation with a qualified professional.',
      ],
      ['As of', _iso(asOf)],
      <String>[],
      [
        'Status',
        'Trip name',
        'Arrival',
        'Departure',
        'Days',
        'Entry time',
        'Entry time zone',
        'Entry location',
        'Entry means',
        'Entry carrier',
        'Exit time',
        'Exit time zone',
        'Exit location',
        'Exit means',
        'Exit carrier',
        'Notes',
      ],
    ];

    for (final t in trips) {
      final entry = t.arrivalInfo;
      final exit = t.departureInfo;
      rows.add([
        t.status == TripStatus.planned ? 'Planned' : 'Actual',
        t.name ?? '',
        _iso(t.arrivalDate),
        _iso(t.departureDate),
        '${t.daysInUS}',
        _time(entry),
        entry?.timeZone ?? '',
        entry?.location ?? '',
        entry?.meansOfTravel ?? '',
        entry?.carrier ?? '',
        _time(exit),
        exit?.timeZone ?? '',
        exit?.location ?? '',
        exit?.meansOfTravel ?? '',
        exit?.carrier ?? '',
        t.notes ?? '',
      ]);
    }

    rows.add(<String>[]);
    rows.add(['Summary', '(actual days present)']);
    rows.add([
      'Days in the US — this calendar year (${totals.asOfYear})',
      '${totals.thisCalendarYear}',
    ]);
    rows.add([
      'Days in the US — rolling last 365 days',
      '${totals.rollingLast365}',
    ]);
    rows.add([
      'Days in the US — prior calendar year (${totals.asOfYear - 1})',
      '${totals.priorCalendarYear}',
    ]);
    rows.add([
      'Substantial Presence figure '
          '(current + 1/3 prior year + 1/6 second-prior year)',
      formattedSpt,
    ]);
    rows.add([
      '  Current year (${totals.spt.asOfYear}) days',
      '${totals.spt.currentYearDays}',
    ]);
    rows.add([
      '  Prior year (${totals.spt.asOfYear - 1}) days',
      '${totals.spt.priorYearDays}',
    ]);
    rows.add([
      '  Second-prior year (${totals.spt.asOfYear - 2}) days',
      '${totals.spt.secondPriorYearDays}',
    ]);

    return rows.map((r) => r.map(_escapeCsv).join(',')).join('\r\n');
  }

  // EN: The SPT figure as a neutral decimal string — a whole number when exact,
  //     otherwise two decimals. NEVER compared to any threshold.
  // FR: La valeur SPT en chaîne décimale neutre — un entier si exact, sinon deux
  //     décimales. JAMAIS comparée à un quelconque seuil.
  String get formattedSpt {
    final sixths = totals.spt.totalSixths;
    if (sixths % 6 == 0) return '${sixths ~/ 6}';
    return (sixths / 6).toStringAsFixed(2);
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  static String _time(CrossingInfo? info) =>
      info?.timeMinutes == null ? '' : info!.formattedTime;

  static DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  static String _iso(DateTime dt) => '${dt.year.toString().padLeft(4, '0')}-'
      '${dt.month.toString().padLeft(2, '0')}-'
      '${dt.day.toString().padLeft(2, '0')}';

  // EN: Quote a CSV field only when it contains a comma, quote, or newline;
  //     embedded quotes are doubled. Keeps simple fields unquoted and readable.
  // FR: Mettre un champ CSV entre guillemets seulement s'il contient une virgule,
  //     un guillemet ou un saut de ligne ; les guillemets internes sont doublés.
  //     Garde les champs simples sans guillemets et lisibles.
  static String _escapeCsv(String field) {
    final needsQuoting = field.contains(',') ||
        field.contains('"') ||
        field.contains('\n') ||
        field.contains('\r');
    if (!needsQuoting) return field;
    return '"${field.replaceAll('"', '""')}"';
  }
}
