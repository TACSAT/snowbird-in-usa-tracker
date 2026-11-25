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
  // EN: Count UNIQUE calendar days within [windowStart, windowEnd] inclusive, across
  //     all trips whose status is in [includeStatuses]. A day covered by several
  //     trips counts once: leaving and re-entering on one date is one day of
  //     presence. Actual trips are clipped to [asOf] (default: today), because days
  //     that have not happened are not presence; planned trips are not clipped.
  // FR: Compter les jours calendaires UNIQUES dans [windowStart, windowEnd] inclus,
  //     pour tous les séjours dont le statut figure dans [includeStatuses]. Un jour
  //     couvert par plusieurs séjours compte une fois : sortir et rentrer le même
  //     jour fait un seul jour de présence. Les séjours réels sont bornés à [asOf]
  //     (par défaut : aujourd'hui), car des jours non vécus ne sont pas de la
  //     présence ; les séjours planifiés ne sont pas bornés.
  static int countDaysInWindow({
    required List<Trip> trips,
    required DateTime windowStart,
    required DateTime windowEnd,
    DateTime? asOf,
    Set<TripStatus> includeStatuses = const {TripStatus.actual},
  }) {
    assert(
      !windowEnd.isBefore(windowStart),
      'windowEnd must not precede windowStart.',
    );
    final effectiveAsOf = asOf ?? DateTime.now();
    final spans = _mergedSpans(
      trips.where((t) => includeStatuses.contains(t.status)).map(
            (t) => (
              _dayNumber(t.arrivalDate),
              _dayNumber(t.effectiveEnd(effectiveAsOf)),
            ),
          ),
    );
    return _countInSpans(spans, _dayNumber(windowStart), _dayNumber(windowEnd));
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
      asOf: end,
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
    DateTime? asOf,
    Set<TripStatus> includeStatuses = const {TripStatus.actual},
  }) {
    return countDaysInWindow(
      trips: trips,
      windowStart: DateTime(year, 1, 1),
      windowEnd: DateTime(year, 12, 31),
      asOf: asOf,
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
      asOf: asOfDate,
      includeStatuses: includeStatuses,
    );
    final prior = countDaysInCalendarYear(
      trips: trips,
      year: year - 1,
      asOf: asOfDate,
      includeStatuses: includeStatuses,
    );
    final secondPrior = countDaysInCalendarYear(
      trips: trips,
      year: year - 2,
      asOf: asOfDate,
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

    // EN: Projection looks forward, so actual trips are NOT clipped to today here:
    //     an expected departure counts in full, and an open stay is assumed to
    //     continue (the mid-trip alert of FR-9 depends on it), up to the ceiling.
    // FR: La projection regarde vers l'avant, donc les séjours réels ne sont PAS
    //     bornés à aujourd'hui : un départ prévu compte en entier et un séjour
    //     ouvert est présumé se poursuivre (l'alerte en cours de séjour de FR-9 en
    //     dépend), jusqu'au plafond.
    final start = _dayNumber(from);
    final ceiling = start + InputLimits.maxReachSearchDays;
    final spans = _mergedSpans(
      trips.where((t) => includeStatuses.contains(t.status)).map((t) {
        final departure = t.departureDate;
        return (
          _dayNumber(t.arrivalDate),
          departure == null ? ceiling : _dayNumber(departure),
        );
      }),
    );
    if (spans.isEmpty) return null;

    // EN: Once the scan passes the last covered day, no new day can enter the
    //     window and the count is non-increasing — scanning further is pointless.
    //     Merging once, outside the loop, keeps each step cheap (NFR-6).
    // FR: Une fois le dernier jour couvert passé, aucun nouveau jour ne peut entrer
    //     dans la fenêtre et le compte est non croissant — poursuivre est inutile.
    //     Fusionner une seule fois, hors boucle, garde chaque pas léger (NFR-6).
    final lastDay = spans.last.$2;
    final scanEnd =
        lastDay < start ? start : (lastDay > ceiling ? ceiling : lastDay);
    for (var day = start; day <= scanEnd; day++) {
      final count = _countInSpans(spans, day - (windowDays - 1), day);
      if (count >= thresholdDays) {
        return DateTime(from.year, from.month, from.day + (day - start));
      }
    }
    return null;
  }

  // EN: The latest departure date among the considered trips, or null if there are
  //     none. This is the anchor for the "time since last visit" alert (FR-10): the
  //     reach date is this date plus the user's elapsed-days target. Defaults to
  //     ACTUAL trips only — "since my last visit" means a visit that happened, not a
  //     planned one.
  // FR: La dernière date de départ parmi les séjours considérés, ou null s'il n'y en
  //     a aucun. C'est l'ancre de l'alerte « temps depuis le dernier séjour »
  //     (FR-10) : la date d'atteinte est cette date plus la cible de jours écoulés de
  //     l'utilisateur. Par défaut, séjours RÉELS uniquement — « depuis mon dernier
  //     séjour » signifie un séjour ayant eu lieu, pas un séjour planifié.
  //
  //     Null while a considered trip is open: the user has not left, so there is
  //     no elapsed time to measure.
  //     Null tant qu'un séjour considéré est ouvert : l'utilisateur n'est pas
  //     reparti, il n'y a donc aucun temps écoulé à mesurer.
  static DateTime? lastDeparture({
    required List<Trip> trips,
    Set<TripStatus> includeStatuses = const {TripStatus.actual},
  }) {
    DateTime? last;
    for (final trip in trips) {
      if (!includeStatuses.contains(trip.status)) continue;
      final departure = trip.departureDate;
      if (departure == null) return null;
      if (last == null || departure.isAfter(last)) last = departure;
    }
    return last;
  }

  // EN: Strip the time component from a DateTime so all window calculations work
  //     in calendar dates only. Without this, DateTime.now() would include the
  //     current time, causing the window boundary to shift throughout the day.
  // FR: Supprimer la composante horaire d'un DateTime pour que tous les calculs
  //     de fenêtre fonctionnent uniquement en dates calendaires. Sans cela,
  //     DateTime.now() inclurait l'heure courante, ce qui ferait glisser la
  //     frontière de la fenêtre au fil de la journée.
  static DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  // EN: Serial number of a calendar day. Anchored in UTC because local midnights are
  //     23 or 25 hours apart across a DST change, and a raw difference would be off
  //     by a day; integers then make interval arithmetic exact.
  // FR: Numéro de série d'un jour calendaire. Ancré en UTC car les minuits locaux
  //     sont séparés de 23 ou 25 heures lors d'un changement d'heure, et une
  //     différence brute serait fausse d'un jour ; les entiers rendent ensuite
  //     l'arithmétique d'intervalles exacte.
  static int _dayNumber(DateTime d) =>
      DateTime.utc(d.year, d.month, d.day).millisecondsSinceEpoch ~/
      Duration.millisecondsPerDay;

  // EN: Sort inclusive (first, last) spans and fuse the ones that overlap, so the
  //     result is disjoint and every day exists at most once. Inverted spans (an
  //     actual trip entirely in the future, after clipping) are dropped.
  // FR: Trier les intervalles inclusifs (premier, dernier) et fusionner ceux qui se
  //     chevauchent : le résultat est disjoint et chaque jour existe au plus une
  //     fois. Les intervalles inversés (séjour réel entièrement futur, après
  //     bornage) sont écartés.
  static List<(int, int)> _mergedSpans(Iterable<(int, int)> raw) {
    final sorted = raw.where((s) => s.$2 >= s.$1).toList()
      ..sort((a, b) => a.$1.compareTo(b.$1));
    final merged = <(int, int)>[];
    for (final span in sorted) {
      if (merged.isNotEmpty && span.$1 <= merged.last.$2) {
        final (first, last) = merged.removeLast();
        merged.add((first, span.$2 > last ? span.$2 : last));
      } else {
        merged.add(span);
      }
    }
    return merged;
  }

  // EN: Days of disjoint [spans] that fall inside the inclusive window.
  // FR: Jours des intervalles disjoints [spans] situés dans la fenêtre inclusive.
  static int _countInSpans(List<(int, int)> spans, int start, int end) {
    var total = 0;
    for (final (first, last) in spans) {
      final from = first > start ? first : start;
      final to = last < end ? last : end;
      if (to >= from) total += to - from + 1;
    }
    return total;
  }
}
