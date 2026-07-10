// EN: Pure functions for counting days spent in the US across a list of trips.
//     "Pure" means: no I/O, no state, no Flutter framework dependency. Every
//     function takes inputs and returns a value — nothing else. This makes the
//     counting logic trivially unit-testable without a device, emulator, or mock.
//
//     The calculation rule: arrival day AND departure day both count as US days.
//     This matches the CBP convention and the IRS Substantial Presence Test
//     definition, and it is also the most intuitive for users (if you crossed the
//     border and slept in the US that night, that day counts).
//
// FR: Fonctions pures pour le calcul des jours passés aux États-Unis sur une liste
//     de séjours. « Pure » signifie : pas d'E/S, pas d'état, pas de dépendance au
//     framework Flutter. Chaque fonction prend des entrées et retourne une valeur —
//     rien d'autre. Cela rend la logique de comptage trivialement testable sans
//     appareil, émulateur ni mock.
//
//     Règle de calcul : le jour d'arrivée ET le jour de départ comptent tous les deux
//     comme des jours aux États-Unis. Cela correspond à la convention CBP et à la
//     définition du test de présence substantielle de l'IRS, et c'est aussi le plus
//     intuitif pour les utilisateurs (si vous avez franchi la frontière et dormi aux
//     États-Unis ce soir-là, ce jour compte).

import 'package:snowbird_in_usa_tracker/logic/input_limits.dart';
import 'package:snowbird_in_usa_tracker/models/trip.dart';

// EN: The result of the IRS Substantial Presence computation, kept as EXACT
//     integer arithmetic. The IRS formula weights three calendar years:
//     all days of the current year + 1/3 of the prior year + 1/6 of the year
//     before that. To avoid floating-point drift (1/3 is not representable in
//     binary), the weighted total is stored in SIXTHS of a day:
//       totalSixths = 6*current + 2*prior + 1*secondPrior
//     which is always an exact integer. The [total] getter divides only at
//     display time.
//
//     POSITIONING (PLAN.md): this is arithmetic, not advice. The result renders
//     no verdict — no comparison to 183, no pass/fail. It is the published
//     formula, computed exactly, presented neutrally.
//
// FR: Résultat du calcul de présence substantielle de l'IRS, conservé en
//     arithmétique ENTIÈRE EXACTE. La formule de l'IRS pondère trois années
//     civiles : tous les jours de l'année courante + 1/3 de l'année précédente
//     + 1/6 de l'année d'avant. Pour éviter la dérive des nombres flottants
//     (1/3 n'est pas représentable en binaire), le total pondéré est stocké en
//     SIXIÈMES de jour :
//       totalSixths = 6*courant + 2*précédent + 1*avant-précédent
//     ce qui est toujours un entier exact. Le getter [total] ne divise qu'au
//     moment de l'affichage.
//
//     POSITIONNEMENT (PLAN.md) : c'est de l'arithmétique, pas un avis. Le
//     résultat ne rend aucun verdict — aucune comparaison à 183, aucun
//     réussite/échec. C'est la formule publiée, calculée exactement, présentée
//     de façon neutre.
class SubstantialPresenceResult {
  // EN: The calendar year the figure is computed for (the year of [asOf]).
  // FR: L'année civile pour laquelle la valeur est calculée (l'année de [asOf]).
  final int asOfYear;

  // EN: Unweighted day counts per calendar year. Current-year days are counted
  //     only up to and including the asOf date; prior years are counted in full.
  // FR: Nombres de jours non pondérés par année civile. Les jours de l'année
  //     courante sont comptés seulement jusqu'à la date asOf incluse ; les
  //     années précédentes sont comptées en entier.
  final int currentYearDays;
  final int priorYearDays;
  final int secondPriorYearDays;

  const SubstantialPresenceResult({
    required this.asOfYear,
    required this.currentYearDays,
    required this.priorYearDays,
    required this.secondPriorYearDays,
  });

  // EN: The weighted total expressed in exact sixths of a day.
  // FR: Le total pondéré exprimé en sixièmes de jour exacts.
  int get totalSixths =>
      6 * currentYearDays + 2 * priorYearDays + secondPriorYearDays;

  // EN: The weighted total as a decimal — for display only; comparisons or
  //     tests should prefer [totalSixths] to stay exact.
  // FR: Le total pondéré en décimal — pour l'affichage seulement ; les
  //     comparaisons ou tests devraient préférer [totalSixths] pour rester exacts.
  double get total => totalSixths / 6;
}

// EN: Namespace class for pure day-counting functions. Not instantiable — all
//     methods are static. Grouping them in a class keeps the API surface clean and
//     makes import aliasing easy if needed.
// FR: Classe espace-de-noms pour les fonctions pures de comptage de jours. Non
//     instanciable — toutes les méthodes sont statiques. Les regrouper dans une
//     classe maintient une surface d'API propre et facilite les alias d'import si
//     nécessaire.
abstract final class DayCounter {
  // EN: Count total days within [windowStart, windowEnd] inclusive, for all trips
  //     whose status is in [includeStatuses]. Only the calendar overlap between
  //     a trip and the window contributes — a trip that starts before the window
  //     or ends after it is clamped to the window boundaries.
  //
  //     No double-counting: each calendar day in the window is counted at most once
  //     per trip. Overlapping trips (unusual but possible in planned data) could
  //     double-count — this function does not de-duplicate. If de-duplication is
  //     ever needed, add a separate function; do not complicate this one.
  //
  // FR: Compter les jours totaux dans [windowStart, windowEnd] inclus, pour tous
  //     les séjours dont le statut figure dans [includeStatuses]. Seul le
  //     chevauchement calendaire entre un séjour et la fenêtre contribue — un séjour
  //     qui commence avant la fenêtre ou se termine après est borné aux limites de
  //     la fenêtre.
  //
  //     Pas de double comptage : chaque jour calendaire de la fenêtre est compté au
  //     plus une fois par séjour. Des séjours qui se chevauchent (inhabituel mais
  //     possible dans des données planifiées) pourraient être comptés en double —
  //     cette fonction ne déduplique pas. Si la déduplication est un jour nécessaire,
  //     ajouter une fonction séparée ; ne pas compliquer celle-ci.
  static int countDaysInWindow({
    required List<Trip> trips,
    required DateTime windowStart,
    required DateTime windowEnd,
    Set<TripStatus> includeStatuses = const {TripStatus.actual},
  }) {
    assert(
      !windowEnd.isBefore(windowStart),
      'windowEnd must not precede windowStart.',
    );

    var total = 0;
    for (final trip in trips) {
      if (!includeStatuses.contains(trip.status)) continue;

      // EN: Clamp the trip to the window. If there is no overlap at all,
      //     clampedStart will be after clampedEnd and the difference will be
      //     negative — skip it.
      // FR: Borner le séjour à la fenêtre. S'il n'y a aucun chevauchement,
      //     clampedStart sera après clampedEnd et la différence sera négative —
      //     on saute ce séjour.
      final clampedStart = trip.arrivalDate.isAfter(windowStart)
          ? trip.arrivalDate
          : windowStart;
      final clampedEnd = trip.departureDate.isBefore(windowEnd)
          ? trip.departureDate
          : windowEnd;

      if (!clampedEnd.isBefore(clampedStart)) {
        total += _daysBetween(clampedStart, clampedEnd) + 1;
      }
    }
    return total;
  }

  // EN: Count days in a rolling window that ends today (or [today] if supplied,
  //     for testability). The window covers the last [days] calendar days,
  //     including today. Example: countDaysInLastDays(days: 365) answers
  //     "how many days was I in the US in the last 365 days?"
  // FR: Compter les jours dans une fenêtre glissante se terminant aujourd'hui (ou
  //     [today] si fourni, pour la testabilité). La fenêtre couvre les [days]
  //     derniers jours calendaires, aujourd'hui inclus. Exemple :
  //     countDaysInLastDays(days: 365) répond à « combien de jours ai-je passés
  //     aux États-Unis au cours des 365 derniers jours ? »
  static int countDaysInLastDays({
    required List<Trip> trips,
    required int days,
    DateTime? today,
    Set<TripStatus> includeStatuses = const {TripStatus.actual},
  }) {
    assert(days >= 1, 'days must be at least 1.');
    final end = _dateOnly(today ?? DateTime.now());
    // EN: Calendar arithmetic via the DateTime constructor (which normalises
    //     out-of-range day values), NOT via subtract(Duration(...)) — a Duration
    //     is absolute time, so subtracting "days" across a DST change would land
    //     at 23:00 or 01:00 and shift the window boundary by a calendar day.
    // FR: Arithmétique calendaire via le constructeur DateTime (qui normalise
    //     les valeurs de jour hors plage), PAS via subtract(Duration(...)) — une
    //     Duration est un temps absolu, donc soustraire des « jours » à travers
    //     un changement d'heure aboutirait à 23 h ou 1 h et décalerait la
    //     frontière de la fenêtre d'un jour calendaire.
    final start = DateTime(end.year, end.month, end.day - (days - 1));
    return countDaysInWindow(
      trips: trips,
      windowStart: start,
      windowEnd: end,
      includeStatuses: includeStatuses,
    );
  }

  // EN: Count days within an entire calendar year (1 Jan – 31 Dec of [year]).
  //     Useful for the "this year" summary shown on the main dashboard.
  // FR: Compter les jours dans une année civile complète (1er jan. – 31 déc. de
  //     [year]). Utile pour le résumé « cette année » affiché sur le tableau de
  //     bord principal.
  static int countDaysInCalendarYear({
    required List<Trip> trips,
    required int year,
    Set<TripStatus> includeStatuses = const {TripStatus.actual},
  }) {
    return countDaysInWindow(
      trips: trips,
      windowStart: DateTime(year, 1, 1),
      windowEnd: DateTime(year, 12, 31),
      includeStatuses: includeStatuses,
    );
  }

  // EN: Compute the IRS Substantial Presence figure as of [asOf]:
  //     all US days in asOf's calendar year up to and including asOf, plus the
  //     FULL day totals of the two preceding calendar years, weighted 1 : 1/3 :
  //     1/6. Returns the exact breakdown — see SubstantialPresenceResult for the
  //     arithmetic and the positioning constraints (no verdict, ever).
  //
  //     By default only actual trips count, matching how the IRS test looks at
  //     days actually spent — callers may include planned trips to project a
  //     hypothetical future figure, but must label it clearly as a projection.
  //
  // FR: Calculer la valeur de présence substantielle de l'IRS au [asOf] : tous
  //     les jours aux É.-U. de l'année civile de asOf jusqu'à asOf inclus, plus
  //     les totaux COMPLETS des deux années civiles précédentes, pondérés
  //     1 : 1/3 : 1/6. Retourne la décomposition exacte — voir
  //     SubstantialPresenceResult pour l'arithmétique et les contraintes de
  //     positionnement (aucun verdict, jamais).
  //
  //     Par défaut seuls les séjours réels comptent, conformément à la façon
  //     dont le test de l'IRS considère les jours réellement passés — l'appelant
  //     peut inclure les séjours planifiés pour projeter une valeur future
  //     hypothétique, mais doit l'étiqueter clairement comme une projection.
  static SubstantialPresenceResult substantialPresence({
    required List<Trip> trips,
    required DateTime asOf,
    Set<TripStatus> includeStatuses = const {TripStatus.actual},
  }) {
    final asOfDate = _dateOnly(asOf);
    final year = asOfDate.year;

    // EN: Current year is clamped at asOf — days after asOf have not happened
    //     yet from the calculation's point of view, even if a trip row spans them.
    // FR: L'année courante est bornée à asOf — les jours après asOf n'ont pas
    //     encore eu lieu du point de vue du calcul, même si un séjour les couvre.
    final current = countDaysInWindow(
      trips: trips,
      windowStart: DateTime(year, 1, 1),
      windowEnd: asOfDate,
      includeStatuses: includeStatuses,
    );
    final prior = countDaysInCalendarYear(
      trips: trips,
      year: year - 1,
      includeStatuses: includeStatuses,
    );
    final secondPrior = countDaysInCalendarYear(
      trips: trips,
      year: year - 2,
      includeStatuses: includeStatuses,
    );

    return SubstantialPresenceResult(
      asOfYear: year,
      currentYearDays: current,
      priorYearDays: prior,
      secondPriorYearDays: secondPrior,
    );
  }

  // EN: Find the FIRST calendar date on or after [from] where the rolling
  //     [windowDays]-day count (window ending on that date, inclusive) reaches
  //     [thresholdDays]. Returns null if the threshold is never reached.
  //
  //     This is the engine behind user-defined notification targets ("tell me
  //     when I hit 75 days in the last 36 months"): the caller schedules a local
  //     notification for the returned date. Planned trips are INCLUDED by
  //     default because projecting forward is the whole point of the feature.
  //
  //     Correctness note: a rolling-window count is NOT monotonic — days age out
  //     of the window as it slides — so this scans day by day. The scan is
  //     bounded twice:
  //       • by the latest departure date across the considered trips (once no
  //         more days can enter the window, the count can only shrink), and
  //       • by InputLimits.maxReachSearchDays as an absolute ceiling, because
  //         trip dates themselves are user/import-controlled input and must not
  //         be able to force a multi-million-iteration loop.
  //
  //     Inputs outside InputLimits throw ArgumentError — callers (UI, storage)
  //     validate first; the engine still refuses rather than trusting them.
  //
  // FR: Trouver la PREMIÈRE date calendaire à partir de [from] (incluse) où le
  //     compte glissant de [windowDays] jours (fenêtre se terminant à cette
  //     date, incluse) atteint [thresholdDays]. Retourne null si le seuil n'est
  //     jamais atteint.
  //
  //     C'est le moteur des cibles de notification définies par l'utilisateur
  //     (« avisez-moi quand j'atteins 75 jours sur les 36 derniers mois ») :
  //     l'appelant planifie une notification locale pour la date retournée. Les
  //     séjours planifiés sont INCLUS par défaut car la projection vers l'avant
  //     est précisément l'objet de la fonctionnalité.
  //
  //     Note de justesse : un compte à fenêtre glissante n'est PAS monotone —
  //     des jours sortent de la fenêtre quand elle glisse — donc on parcourt
  //     jour par jour. Le parcours est borné deux fois :
  //       • par la dernière date de départ parmi les séjours considérés (quand
  //         plus aucun jour ne peut entrer dans la fenêtre, le compte ne peut
  //         que diminuer), et
  //       • par InputLimits.maxReachSearchDays comme plafond absolu, car les
  //         dates de séjour sont elles-mêmes des entrées contrôlées par
  //         l'utilisateur ou l'import et ne doivent pas pouvoir forcer une
  //         boucle de millions d'itérations.
  //
  //     Les entrées hors des InputLimits lancent ArgumentError — l'interface et
  //     le stockage valident d'abord ; le moteur refuse quand même plutôt que de
  //     leur faire confiance.
  static DateTime? firstDateReachingThreshold({
    required List<Trip> trips,
    required int thresholdDays,
    required int windowDays,
    required DateTime from,
    Set<TripStatus> includeStatuses = const {
      TripStatus.actual,
      TripStatus.planned,
    },
  }) {
    if (thresholdDays < InputLimits.minThresholdDays ||
        thresholdDays > InputLimits.maxThresholdDays) {
      throw ArgumentError.value(
        thresholdDays,
        'thresholdDays',
        'must be within ${InputLimits.minThresholdDays}–'
            '${InputLimits.maxThresholdDays}',
      );
    }
    if (windowDays < InputLimits.minWindowDays ||
        windowDays > InputLimits.maxWindowDays) {
      throw ArgumentError.value(
        windowDays,
        'windowDays',
        'must be within ${InputLimits.minWindowDays}–'
            '${InputLimits.maxWindowDays}',
      );
    }

    // EN: A window of N days can never contain more than N days — a threshold
    //     above the window size is unreachable by construction.
    // FR: Une fenêtre de N jours ne peut jamais contenir plus de N jours — un
    //     seuil supérieur à la taille de la fenêtre est inatteignable par
    //     construction.
    if (thresholdDays > windowDays) return null;

    // EN: Once the scan date passes the latest departure, no new day can enter
    //     the window and the count is non-increasing — scanning further is
    //     pointless. If there are no considered trips at all, there is nothing
    //     to reach.
    // FR: Une fois la date de parcours passée le dernier départ, aucun nouveau
    //     jour ne peut entrer dans la fenêtre et le compte est non croissant —
    //     poursuivre est inutile. S'il n'y a aucun séjour considéré, il n'y a
    //     rien à atteindre.
    DateTime? lastDeparture;
    for (final trip in trips) {
      if (!includeStatuses.contains(trip.status)) continue;
      if (lastDeparture == null || trip.departureDate.isAfter(lastDeparture)) {
        lastDeparture = trip.departureDate;
      }
    }
    if (lastDeparture == null) return null;

    final start = _dateOnly(from);
    final scanEnd = lastDeparture.isAfter(start) ? lastDeparture : start;

    // EN: Number of calendar days to scan, capped by the absolute safety
    //     ceiling (see InputLimits.maxReachSearchDays). All date stepping below
    //     uses the DateTime constructor's day-normalisation instead of
    //     add/subtract(Duration) — Durations are absolute time and would drift
    //     by an hour across DST changes, corrupting the calendar date.
    // FR: Nombre de jours calendaires à parcourir, plafonné par le plafond de
    //     sécurité absolu (voir InputLimits.maxReachSearchDays). Tous les pas de
    //     date ci-dessous utilisent la normalisation de jour du constructeur
    //     DateTime au lieu de add/subtract(Duration) — les Durations sont du
    //     temps absolu et dériveraient d'une heure à travers les changements
    //     d'heure, corrompant la date calendaire.
    var scanLength = _daysBetween(start, scanEnd);
    if (scanLength > InputLimits.maxReachSearchDays) {
      scanLength = InputLimits.maxReachSearchDays;
    }

    for (var i = 0; i <= scanLength; i++) {
      final d = DateTime(start.year, start.month, start.day + i);
      final count = countDaysInWindow(
        trips: trips,
        windowStart: DateTime(d.year, d.month, d.day - (windowDays - 1)),
        windowEnd: d,
        includeStatuses: includeStatuses,
      );
      if (count >= thresholdDays) return d;
    }
    return null;
  }

  // EN: Strip the time component from a DateTime so all window calculations work
  //     in calendar dates only. Without this, DateTime.now() would include the
  //     current time, causing the window boundary to shift throughout the day.
  // FR: Supprimer la composante horaire d'un DateTime pour que tous les calculs
  //     de fenêtre fonctionnent uniquement en dates calendaires. Sans cela,
  //     DateTime.now() inclurait l'heure courante, ce qui ferait glisser la
  //     frontière de la fenêtre au fil de la journée.
  static DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  // EN: Whole calendar days from [a] to [b] (a ≤ b expected). Anchored in UTC
  //     before subtracting, because local-midnight DateTimes are 23 or 25 hours
  //     apart across a DST change — raw difference().inDays truncates that to
  //     the wrong day count (e.g. Jan 1 → Mar 16 in a DST zone would yield 73
  //     instead of 74). UTC has no DST, so the subtraction is always exact.
  // FR: Jours calendaires entiers de [a] à [b] (a ≤ b attendu). Ancré en UTC
  //     avant la soustraction, car des DateTime à minuit local sont séparés de
  //     23 ou 25 heures à travers un changement d'heure — difference().inDays
  //     brut tronquerait vers le mauvais nombre de jours (p. ex. 1 jan. →
  //     16 mars dans un fuseau à heure d'été donnerait 73 au lieu de 74). L'UTC
  //     n'a pas d'heure d'été, donc la soustraction est toujours exacte.
  static int _daysBetween(DateTime a, DateTime b) {
    final ua = DateTime.utc(a.year, a.month, a.day);
    final ub = DateTime.utc(b.year, b.month, b.day);
    return ub.difference(ua).inDays;
  }
}
