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

import 'dart:ui' show Locale;

import 'package:snowbird_in_usa_tracker/config/app_identity.dart';
import 'package:snowbird_in_usa_tracker/l10n/app_localizations.dart';
import 'package:snowbird_in_usa_tracker/logic/day_counter.dart';
import 'package:snowbird_in_usa_tracker/logic/presence_ledger.dart';
import 'package:snowbird_in_usa_tracker/models/crossing_info.dart';
import 'package:snowbird_in_usa_tracker/models/day_visit.dart';
import 'package:snowbird_in_usa_tracker/models/home_base.dart';
import 'package:snowbird_in_usa_tracker/models/place.dart';
import 'package:snowbird_in_usa_tracker/models/tracked_place.dart';
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

// EN: One place's totals on a record that is not the US-only one (EXP-2):
//     recorded days per window under the place's own convention, and,
//     separately, days assumed at home, planned days still ahead this calendar
//     year, and (only when the user adds them to this export) days worked.
// FR: Les totaux d'un lieu sur une fiche autre que celle des États-Unis seuls
//     (EXP-2) : jours enregistrés par fenêtre selon la convention propre du
//     lieu et, à part, les jours présumés au domicile, les jours planifiés
//     restant dans l'année civile, et (seulement si l'utilisateur les ajoute à
//     cet export) les jours travaillés.
class RecordPlaceTotals {
  final Place place;
  final CountingConvention convention;
  final int thisCalendarYear;
  final int rollingLast365;
  final int priorCalendarYear;
  final int assumedThisYear;
  final int assumedLast365;
  final int plannedThisYear;
  final int workedThisYear;
  final int workedLast365;

  const RecordPlaceTotals({
    required this.place,
    required this.convention,
    required this.thisCalendarYear,
    required this.rollingLast365,
    required this.priorCalendarYear,
    required this.assumedThisYear,
    required this.assumedLast365,
    required this.plannedThisYear,
    required this.workedThisYear,
    required this.workedLast365,
  });
}

// EN: One line of the record's list: a stay or a day visit, in date order.
// FR: Une ligne de la liste de la fiche : un séjour ou une visite d'un jour,
//     dans l'ordre des dates.
class RecordEntry {
  final Trip? stay;
  final DayVisit? visit;

  const RecordEntry.stay(Trip this.stay) : visit = null;
  const RecordEntry.visit(DayVisit this.visit) : stay = null;

  DateTime get date => stay?.arrivalDate ?? visit!.date;
  Place get place => stay?.place ?? visit!.place;
  TripStatus get status => stay?.status ?? visit!.status;
}

class PresenceRecord {
  // EN: The date the record is computed "as of" — current-year and rolling counts
  //     are measured up to and including this day.
  // FR: La date « à laquelle » la fiche est calculée — les comptes de l'année
  //     courante et glissants sont mesurés jusqu'à ce jour inclus.
  final DateTime asOf;

  // EN: What the record covers (EXP-1): one country, or null for all places.
  //     The United States reproduces the original US Presence Record, the one
  //     handed to border officers, who should not be shown unrelated travel:
  //     nothing outside the scope appears anywhere in it.
  // FR: Ce que couvre la fiche (EXP-1) : un pays, ou null pour tous les lieux.
  //     Les États-Unis reproduisent la fiche de présence d'origine, celle remise
  //     aux agents frontaliers, à qui il ne faut pas montrer des voyages sans
  //     rapport : rien hors de la portée n'y apparaît nulle part.
  final Place? scope;

  // EN: The stays in scope, chronological (oldest first) — the natural reading
  //     order for a record someone scans top to bottom.
  // FR: Les séjours dans la portée, chronologiques (plus ancien d'abord) —
  //     l'ordre de lecture naturel pour une fiche qu'on parcourt de haut en bas.
  final List<Trip> trips;

  // EN: The day visits in scope, chronological.
  // FR: Les visites d'un jour dans la portée, chronologiques.
  final List<DayVisit> visits;

  // EN: The United States totals and SPT (used by the US-only record, and for
  //     the SPT on an all-places record).
  // FR: Les totaux et le critère de présence substantielle des États-Unis
  //     (utilisés par la fiche des États-Unis seuls, et pour ce critère sur une
  //     fiche de tous les lieux).
  final PresenceTotals totals;

  // EN: Per-place totals for any other record (empty for the US-only one).
  // FR: Totaux par lieu pour toute autre fiche (vide pour celle des États-Unis
  //     seuls).
  final List<RecordPlaceTotals> places;

  // EN: Whether days worked are in this export (WRK-8): false unless the user
  //     ticked it for this export, so a default record holds no work detail.
  // FR: Si les jours travaillés figurent dans cet export (WRK-8) : faux sauf si
  //     l'utilisateur l'a coché pour cet export ; une fiche par défaut ne
  //     contient donc aucun détail de travail.
  final bool includeWork;

  final HomeBase _home;

  const PresenceRecord._({
    required this.asOf,
    required this.scope,
    required this.trips,
    required this.visits,
    required this.totals,
    required this.places,
    required this.includeWork,
    required HomeBase home,
  }) : _home = home;

  bool get isUnitedStates => scope == Place.unitedStates;

  // EN: The SPT is printed on the US-only record, and on an all-places record
  //     that includes the United States.
  // FR: Le critère est imprimé sur la fiche des États-Unis seuls, et sur une
  //     fiche de tous les lieux qui inclut les États-Unis.
  bool get showsSpt =>
      isUnitedStates || places.any((p) => p.place == Place.unitedStates);

  // EN: Stays and visits together, in date order (stays first on a tie).
  // FR: Séjours et visites ensemble, dans l'ordre des dates (séjours d'abord à
  //     égalité).
  List<RecordEntry> get entries => [
        for (final t in trips) RecordEntry.stay(t),
        for (final v in visits) RecordEntry.visit(v),
      ]..sort((a, b) {
          final byDate = a.date.compareTo(b.date);
          if (byDate != 0) return byDate;
          return (a.stay == null ? 1 : 0).compareTo(b.stay == null ? 1 : 0);
        });

  // EN: Build the record. [asOf] defaults to today. Totals count ACTUAL
  //     presence only, so a planned trip never inflates a "days so far"
  //     number; planned trips still appear in the list, clearly marked. The
  //     default scope is the United States, which is exactly the original
  //     record; [tracked] and [home] shape an all-places record like the Days
  //     present table.
  // FR: Construire la fiche. [asOf] par défaut = aujourd'hui. Les totaux ne
  //     comptent que la présence RÉELLE, pour qu'un séjour planifié ne gonfle
  //     jamais un nombre « jours à ce jour » ; les séjours planifiés
  //     apparaissent quand même dans la liste, clairement marqués. La portée par
  //     défaut est les États-Unis, exactement la fiche d'origine ; [tracked] et
  //     [home] façonnent une fiche de tous les lieux comme le tableau des jours
  //     de présence.
  factory PresenceRecord.build({
    required List<Trip> trips,
    List<DayVisit> visits = const [],
    DateTime? asOf,
    Place? scope = Place.unitedStates,
    List<TrackedPlace>? tracked,
    HomeBase? home,
    bool includeWork = false,
  }) {
    final asOfDate = _dateOnly(asOf ?? DateTime.now());
    final homeBase = home ?? HomeBase.none;
    bool inScope(Place p) => scope == null || scope.contains(p);
    final sorted = [
      for (final t in trips)
        if (inScope(t.place)) t,
    ]..sort((a, b) => a.arrivalDate.compareTo(b.arrivalDate));
    final shownVisits = [
      for (final v in visits)
        if (inScope(v.place)) v,
    ]..sort((a, b) => a.date.compareTo(b.date));

    // EN: US totals exactly as before places: DayCounter, any part, with each
    //     visit as a one-day stay.
    // FR: Totaux des États-Unis exactement comme avant les lieux : DayCounter,
    //     toute partie, chaque visite comptant comme un séjour d'un jour.
    final counted = [...trips, for (final v in visits) v.asStay()];
    final totals = PresenceTotals(
      asOfYear: asOfDate.year,
      thisCalendarYear: DayCounter.countDaysInCalendarYear(
        trips: counted,
        year: asOfDate.year,
        asOf: asOfDate,
      ),
      rollingLast365: DayCounter.countDaysInLastDays(
        trips: counted,
        days: 365,
        today: asOfDate,
      ),
      priorCalendarYear: DayCounter.countDaysInCalendarYear(
        trips: counted,
        year: asOfDate.year - 1,
        asOf: asOfDate,
      ),
      spt: DayCounter.substantialPresence(trips: counted, asOf: asOfDate),
    );

    final places = scope == Place.unitedStates
        ? const <RecordPlaceTotals>[]
        : _placeTotals(
            trips: trips,
            visits: visits,
            home: homeBase,
            asOf: asOfDate,
            scope: scope,
            tracked: tracked,
          );

    return PresenceRecord._(
      asOf: asOfDate,
      scope: scope,
      trips: sorted,
      visits: shownVisits,
      totals: totals,
      places: places,
      includeWork: includeWork,
      home:
          scope == null || homeBase.periods.any((p) => scope.contains(p.place))
              ? homeBase
              : HomeBase.none,
    );
  }

  static List<RecordPlaceTotals> _placeTotals({
    required List<Trip> trips,
    required List<DayVisit> visits,
    required HomeBase home,
    required DateTime asOf,
    required Place? scope,
    required List<TrackedPlace>? tracked,
  }) {
    final yearStart = DateTime(asOf.year);
    final priorStart = DateTime(asOf.year - 1);
    final priorEnd = DateTime(asOf.year - 1, 12, 31);
    final last365Start = DateTime(asOf.year, asOf.month, asOf.day - 364);
    final actual = <CountingConvention, PresenceLedger>{};
    final planned = <CountingConvention, PresenceLedger>{};
    PresenceLedger ledgerActual(CountingConvention c) =>
        actual[c] ??= PresenceLedger.build(
          stays: trips,
          visits: visits,
          home: home,
          from: priorStart.isBefore(last365Start) ? priorStart : last365Start,
          to: asOf,
          today: asOf,
          convention: c,
        );
    PresenceLedger ledgerPlanned(CountingConvention c) =>
        planned[c] ??= PresenceLedger.build(
          stays: trips,
          visits: visits,
          from: yearStart,
          to: DateTime(asOf.year, 12, 31),
          today: asOf,
          convention: c,
          includeStatuses: const {TripStatus.actual, TripStatus.planned},
        );

    final any = ledgerActual(CountingConvention.anyPart);
    final seen = {
      ...any.recordedPlaces,
      ...ledgerPlanned(CountingConvention.anyPart).recordedPlaces,
      if (!home.isOff)
        for (final p in home.periods) p.place,
    };
    final List<TrackedPlace> list;
    if (scope != null) {
      // EN: One country: the country, then its regions with any day.
      // FR: Un pays : le pays, puis ses régions ayant au moins un jour.
      final convention = tracked
              ?.where((t) => t.place == scope)
              .map((t) => t.convention)
              .firstOrNull ??
          CountingConvention.anyPart;
      list = [
        TrackedPlace(scope, convention: convention),
        for (final p in ({
          for (final p in seen)
            if (!p.isCountry && scope.contains(p)) p,
        }.toList()
          ..sort((a, b) => a.code.compareTo(b.code))))
          TrackedPlace(p, convention: convention),
      ];
    } else {
      list = tracked ??
          [
            for (final country in {
              ...PlaceCatalog.countries,
              ...([for (final p in seen) p.country]
                ..sort((a, b) => a.code.compareTo(b.code))),
            })
              if (seen.any(country.contains)) TrackedPlace(country),
          ];
    }

    return [
      for (final item in list)
        () {
          final l = ledgerActual(item.convention);
          final p = item.place;
          final thisYear = l.daysIn(p, start: yearStart);
          return RecordPlaceTotals(
            place: p,
            convention: item.convention,
            thisCalendarYear: thisYear,
            rollingLast365: l.daysIn(p, start: last365Start),
            priorCalendarYear: l.daysIn(p, start: priorStart, end: priorEnd),
            assumedThisYear: l.assumedIn(p, start: yearStart),
            assumedLast365: l.assumedIn(p, start: last365Start),
            plannedThisYear:
                ledgerPlanned(item.convention).daysIn(p) - thisYear,
            workedThisYear: l.workedIn(p, start: yearStart),
            workedLast365: l.workedIn(p, start: last365Start),
          );
        }(),
    ];
  }

  // EN: Serialise to CSV text (RFC-4180-style quoting, CRLF line endings). Layout:
  //     a two-line title/disclaimer, the "as of" date, a blank line, the list
  //     with a header row, a blank line, then the neutral summary rows. The
  //     columns of the original record come first and unchanged; country and
  //     region (codes and English names) are added AT THE END, so an existing
  //     spreadsheet import keeps working (EXP-4), then days worked only when
  //     chosen for this export (WRK-8).
  // FR: Sérialiser en texte CSV (guillemets façon RFC-4180, fins de ligne CRLF).
  //     Disposition : un titre/avertissement sur deux lignes, la date « au », une
  //     ligne vide, la liste avec une ligne d'en-tête, une ligne vide, puis les
  //     lignes de résumé neutres. Les colonnes de la fiche d'origine viennent
  //     d'abord, inchangées ; pays et région (codes et noms anglais) sont ajoutés
  //     À LA FIN, afin qu'une importation de tableur existante continue de
  //     fonctionner (EXP-4), puis les jours travaillés seulement s'ils sont
  //     choisis pour cet export (WRK-8).
  String toCsv() {
    final rows = <List<String>>[
      [
        isUnitedStates
            ? '${AppIdentity.name} — US Presence Record'
            : scope == null
                ? '${AppIdentity.name} — Presence Record'
                : '${AppIdentity.name} — Presence Record: '
                    '${_english(scope!)}',
      ],
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
        'Country code',
        'Country',
        'Region code',
        'Region',
        if (includeWork) 'Days worked',
      ],
    ];
    for (final entry in entries) {
      final t = entry.stay;
      final v = entry.visit;
      if (t != null) {
        final info = t.arrivalInfo;
        final exit = t.departureInfo;
        rows.add([
          t.status == TripStatus.planned
              ? 'Planned'
              : t.isInProgress(asOf)
                  ? 'Actual (in progress)'
                  : 'Actual',
          _safeText(t.name ?? ''),
          _iso(t.arrivalDate),
          t.departureDate == null ? '' : _iso(t.departureDate!),
          '${t.daysPresent(asOf)}',
          _time(info),
          _safeText(info?.timeZone ?? ''),
          _safeText(info?.location ?? ''),
          _safeText(info?.meansOfTravel ?? ''),
          _safeText(info?.carrier ?? ''),
          _time(exit),
          _safeText(exit?.timeZone ?? ''),
          _safeText(exit?.location ?? ''),
          _safeText(exit?.meansOfTravel ?? ''),
          _safeText(exit?.carrier ?? ''),
          _safeText(t.notes ?? ''),
          ..._placeColumns(t.place, t.placeName),
          if (includeWork) '${workedInStay(t)}',
        ]);
      } else if (v != null) {
        rows.add([
          v.status == TripStatus.planned ? 'Day visit (planned)' : 'Day visit',
          '',
          _iso(v.date),
          _iso(v.date),
          '1',
          for (var i = 0; i < 11; i++) '',
          ..._placeColumns(v.place, null),
          if (includeWork) v.worked ? '1' : '0',
        ]);
      }
    }
    rows.add(<String>[]);
    rows.add(['Summary', '(actual days present)']);
    if (isUnitedStates) {
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
    } else {
      for (final p in places) {
        final name = _english(p.place);
        rows.add([
          '$name — this calendar year (${asOf.year})',
          '${p.thisCalendarYear}',
        ]);
        rows.add(['$name — rolling last 365 days', '${p.rollingLast365}']);
        rows.add([
          '$name — prior calendar year (${asOf.year - 1})',
          '${p.priorCalendarYear}',
        ]);
        rows.add(['$name — counted by', _conventionText(p.convention)]);
        if (p.assumedThisYear > 0 || p.assumedLast365 > 0) {
          rows.add([
            '$name — assumed at home, not recorded, this calendar year',
            '${p.assumedThisYear}',
          ]);
          rows.add([
            '$name — assumed at home, not recorded, rolling last 365 days',
            '${p.assumedLast365}',
          ]);
        }
        if (p.plannedThisYear > 0) {
          rows.add([
            '$name — planned, rest of this calendar year',
            '${p.plannedThisYear}',
          ]);
        }
        if (includeWork) {
          rows.add([
            '$name — days worked, this calendar year',
            '${p.workedThisYear}',
          ]);
          rows.add([
            '$name — days worked, rolling last 365 days',
            '${p.workedLast365}',
          ]);
        }
      }
    }
    if (showsSpt) {
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
    }
    // EN: Every record states how its days were counted (EXP-2).
    // FR: Chaque fiche dit comment ses jours ont été comptés (EXP-2).
    if (isUnitedStates) {
      rows.add(['Counted by', _conventionText(CountingConvention.anyPart)]);
    }

    return rows.map((r) => r.map(_escapeCsv).join(',')).join('\r\n');
  }

  // EN: The day-by-day ledger (EXP-5): one row per date, from 1 January two
  //     years back (the SPT's first year) to the record's date, so anyone can
  //     check every total by date. Both conventions side by side. Places
  //     outside the record's scope are never named: a US-only ledger shows only
  //     United States places, and a date spent elsewhere is simply blank.
  // FR: Le registre jour par jour (EXP-5) : une ligne par date, du 1er janvier
  //     d'il y a deux ans (la première année du critère de présence
  //     substantielle) jusqu'à la date de la fiche, afin que chacun puisse
  //     vérifier chaque total par date. Les deux conventions côte à côte. Les
  //     lieux hors de la portée de la fiche ne sont jamais nommés : un registre
  //     des États-Unis seuls ne montre que des lieux américains, et une date
  //     passée ailleurs est simplement vide.
  String toLedgerCsv() {
    final from = DateTime(asOf.year - 2);
    PresenceLedger build(CountingConvention c) => PresenceLedger.build(
          stays: trips,
          visits: visits,
          home: _home,
          from: from,
          to: asOf,
          today: asOf,
          convention: c,
        );
    final any = build(CountingConvention.anyPart);
    final end = build(CountingConvention.endOfDay);
    bool inScope(Place p) => scope == null || scope!.contains(p);
    String codes(List<Place> ps) => [
          for (final p in ps)
            if (inScope(p)) p.code,
        ].join('; ');
    String names(List<Place> ps) => [
          for (final p in ps)
            if (inScope(p)) _english(p),
        ].join('; ');

    final rows = <List<String>>[
      [
        '${AppIdentity.name} — Day-by-day ledger'
            '${scope == null ? '' : ': ${_english(scope!)}'}',
      ],
      [
        'This is a personal record, not advice. '
            'Verify your situation with a qualified professional.',
      ],
      ['As of', _iso(asOf)],
      <String>[],
      [
        'Date',
        'Any part of the day: place codes',
        'Any part of the day: places',
        'End of day: place code',
        'End of day: place',
        'Assumed at home',
        'Not recorded',
        if (includeWork) 'Worked in',
      ],
    ];
    for (var i = 0; i < any.days.length; i++) {
      final a = any.days[i];
      final e = end.days[i];
      final assumed = a.assumed;
      rows.add([
        _iso(a.date),
        codes(a.places),
        names(a.places),
        codes(e.places),
        names(e.places),
        assumed != null && inScope(assumed) ? _english(assumed) : '',
        a.notRecorded && scope == null ? 'yes' : '',
        if (includeWork) names(a.worked),
      ]);
    }
    return rows.map((r) => r.map(_escapeCsv).join(',')).join('\r\n');
  }

  // EN: Days worked in one stay up to the record's date (actual stays stop at
  //     it, like presence).
  // FR: Jours travaillés dans un séjour jusqu'à la date de la fiche (les
  //     séjours réels s'y arrêtent, comme la présence).
  int workedInStay(Trip stay) {
    final plan = stay.work;
    if (plan == null) return 0;
    final end = stay.effectiveEnd(asOf);
    var n = 0;
    for (var d = stay.arrivalDate;
        !d.isAfter(end);
        d = DateTime(d.year, d.month, d.day + 1)) {
      if (plan.isWorked(d)) n++;
    }
    return n;
  }

  static final AppLocalizations _en = lookupAppLocalizations(
    const Locale('en'),
  );

  // EN: English names for the data file, like its English column headers.
  // FR: Noms anglais pour le fichier de données, comme ses en-têtes anglais.
  static String _english(Place place) {
    final name = _en.placeName(place.code.replaceAll('-', '_'));
    if (place.isCountry) return name;
    return '$name, ${_en.placeName(place.countryCode)}';
  }

  static List<String> _placeColumns(Place place, String? elsewhereName) => [
        place.countryCode,
        place.country == Place.elsewhere && (elsewhereName?.isNotEmpty ?? false)
            ? _safeText('Elsewhere: $elsewhereName')
            : _en.placeName(place.countryCode),
        place.isCountry ? '' : place.code,
        place.isCountry ? '' : _en.placeName(place.code.replaceAll('-', '_')),
      ];

  static String _conventionText(CountingConvention c) => switch (c) {
        CountingConvention.anyPart =>
          'any part of the day (a date counts when present at any moment of it)',
        CountingConvention.endOfDay =>
          'end of day (a date counts where you were at midnight)',
      };

  // EN: The SPT figure as a neutral decimal string — a whole number when exact,
  //     otherwise two decimals. NEVER compared to any threshold.
  // FR: La valeur SPT en chaîne décimale neutre — un entier si exact, sinon deux
  //     décimales. JAMAIS comparée à un quelconque seuil.
  String get formattedSpt => totals.spt.formatted;

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
  // EN: Text the user typed must never run as a spreadsheet formula when the file is
  //     opened by someone else. A leading apostrophe is the standard way to mark a
  //     cell as plain text; full-width forms are covered as some locales accept them.
  // FR: Le texte saisi ne doit jamais s'exécuter comme formule quand une autre
  //     personne ouvre le fichier. Une apostrophe en tête est la façon usuelle de
  //     marquer une cellule comme texte ; les formes pleine chasse sont couvertes
  //     car certaines locales les acceptent.
  static String _safeText(String text) =>
      RegExp(r'^[=+\-@\t\r＝＋－＠]').hasMatch(text) ? "'$text" : text;

  static String _escapeCsv(String field) {
    final needsQuoting = field.contains(',') ||
        field.contains('"') ||
        field.contains('\n') ||
        field.contains('\r');
    if (!needsQuoting) return field;
    return '"${field.replaceAll('"', '""')}"';
  }
}
