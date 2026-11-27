// EN: The counting engine for days by place (REQUIREMENTS-places.md section 8).
//     It builds a day-by-day ledger for a range of dates: for each date, the
//     places the user was in under one counting convention, plus whether the date
//     was assumed at home or not recorded at all. Every figure (the Days present
//     table, custom ranges, the day-by-day CSV of EXP-5) is then a count over this
//     ledger, so all of them agree by construction, and anyone can check a total
//     by reading the ledger line by line.
//
//     This is where the app could silently mislead, so the rules are written out:
//     - CNT-1: two conventions, "any part of the day" (default) and "end of day".
//     - CNT-2: by "any part", a crossing day counts in BOTH places; places can
//       therefore add up to more than the calendar, and no caller may present a
//       sum of places as a number of days.
//     - CNT-3: within one place a date counts once, however many stays cover it.
//     - CNT-4: a country counts unique dates across its regions; it is not the sum
//       of its regions.
//     - CNT-5: by "end of day", each date belongs to at most one place; an ongoing
//       stay counts through yesterday, because today has not ended.
//     - CNT-6: actual days stop at today; planned, assumed and not-recorded days
//       are separate figures (build one ledger without planned stays and one with).
//     - CNT-7: dates are plain calendar dates; no time zone ever shifts one.
//     - CNT-8: no legal exclusion (transit, commuting, medical) is applied.
//
// FR: Le moteur de comptage des jours par lieu (REQUIREMENTS-places.md, section 8).
//     Il construit un registre jour par jour pour une plage de dates : pour chaque
//     date, les lieux où se trouvait l'utilisateur selon une convention de
//     comptage, et si la date est présumée au lieu de résidence ou pas du tout
//     enregistrée. Chaque chiffre (le tableau des jours de présence, les plages
//     personnalisées, le CSV jour par jour d'EXP-5) est ensuite un compte sur ce
//     registre ; ils concordent donc tous par construction, et chacun peut
//     vérifier un total en lisant le registre ligne par ligne.
//
//     C'est ici que l'application pourrait induire en erreur sans le dire ; les
//     règles sont donc écrites :
//     - CNT-1 : deux conventions, « toute partie du jour » (par défaut) et « fin
//       de journée ».
//     - CNT-2 : selon « toute partie », un jour de passage compte dans LES DEUX
//       lieux ; les lieux peuvent donc totaliser plus que le calendrier, et aucun
//       appelant ne doit présenter une somme de lieux comme un nombre de jours.
//     - CNT-3 : dans un même lieu, une date compte une fois, quel que soit le
//       nombre de séjours qui la couvrent.
//     - CNT-4 : un pays compte les dates uniques de toutes ses régions ; ce n'est
//       pas la somme de ses régions.
//     - CNT-5 : selon « fin de journée », chaque date appartient à au plus un
//       lieu ; un séjour en cours compte jusqu'à hier, car aujourd'hui n'est pas
//       terminé.
//     - CNT-6 : les jours réels s'arrêtent à aujourd'hui ; les jours planifiés,
//       présumés et non enregistrés sont des chiffres séparés (construire un
//       registre sans les séjours planifiés et un autre avec).
//     - CNT-7 : les dates sont de simples dates calendaires ; aucun fuseau horaire
//       n'en décale une.
//     - CNT-8 : aucune exclusion légale (transit, navette, soins) n'est appliquée.

import 'package:snowbird_in_usa_tracker/models/day_visit.dart';
import 'package:snowbird_in_usa_tracker/models/home_base.dart';
import 'package:snowbird_in_usa_tracker/models/place.dart';
import 'package:snowbird_in_usa_tracker/models/trip.dart';

// EN: The two ways a day can be counted for a place (CNT-1). The user chooses one
//     per tracked place; every figure states which one it used (EXP-2).
// FR: Les deux façons de compter un jour pour un lieu (CNT-1). L'utilisateur en
//     choisit une par lieu suivi ; chaque chiffre indique celle utilisée (EXP-2).
enum CountingConvention {
  // EN: The date counts if the user was there at any moment of it. The US
  //     Substantial Presence Test and Canada's deemed-resident count both work
  //     this way, so it is the default.
  // FR: La date compte si l'utilisateur y était à un moment quelconque. Le
  //     critère de présence substantielle américain et le décompte canadien de la
  //     résidence réputée fonctionnent ainsi ; c'est donc la valeur par défaut.
  anyPart,

  // EN: The date counts where the user was at the midnight that ends it.
  // FR: La date compte là où se trouvait l'utilisateur au minuit qui la termine.
  endOfDay,
}

// EN: One line of the ledger: what is known about one date.
// FR: Une ligne du registre : ce que l'on sait d'une date.
class LedgerDay {
  final DateTime date;

  // EN: The places the user was in, as recorded (from stays and day visits), in
  //     order of arrival. By "end of day" there is at most one. Empty when
  //     nothing was recorded for the date.
  // FR: Les lieux où se trouvait l'utilisateur, tels qu'enregistrés (séjours et
  //     visites d'un jour), dans l'ordre d'arrivée. Selon « fin de journée », il y
  //     en a au plus un. Vide quand rien n'a été enregistré pour la date.
  final List<Place> places;

  // EN: True when a STAY covers the date. A day visit alone does not: the user
  //     was somewhere else for the rest of that day.
  // FR: Vrai quand un SÉJOUR couvre la date. Une visite d'un jour seule ne suffit
  //     pas : l'utilisateur était ailleurs le reste de la journée.
  final bool coveredByStay;

  // EN: The home place when the date is ASSUMED there (home base on, past date):
  //     either no stay covers it, or, by "any part of the day", it is the day the
  //     user left home or came back (see PresenceLedger.build). Never the same
  //     place as one in [places], so recorded and assumed days of one place can be
  //     shown side by side without counting a date twice (HOM-2).
  // FR: Le lieu de résidence quand la date y est PRÉSUMÉE (lieu de résidence
  //     activé, date passée) : soit aucun séjour ne la couvre, soit, selon « toute
  //     partie du jour », c'est le jour où l'utilisateur a quitté son domicile ou
  //     y est revenu (voir PresenceLedger.build). Jamais le même lieu que l'un de
  //     ceux de [places], afin que les jours enregistrés et présumés d'un même
  //     lieu puissent être montrés côte à côte sans compter une date deux fois
  //     (HOM-2).
  final Place? assumed;

  // EN: True for a past date with neither a stay nor a home base to assume.
  // FR: Vrai pour une date passée sans séjour ni lieu de résidence à présumer.
  final bool notRecorded;

  const LedgerDay({
    required this.date,
    required this.places,
    required this.coveredByStay,
    required this.assumed,
    required this.notRecorded,
  });
}

class PresenceLedger {
  // EN: The longest range one ledger may cover: a little over 40 years. It bounds
  //     memory and time whatever a caller passes; the widest window the app uses
  //     (ten years, InputLimits.maxWindowDays) fits easily.
  // FR: La plage la plus longue qu'un registre peut couvrir : un peu plus de 40
  //     ans. Elle borne la mémoire et le temps quoi que passe un appelant ; la
  //     fenêtre la plus large de l'application (dix ans,
  //     InputLimits.maxWindowDays) y tient largement.
  static const int maxRangeDays = 15000;

  final CountingConvention convention;
  final DateTime from;
  final DateTime to;
  final int _first;
  final List<LedgerDay> days;

  PresenceLedger._(this.convention, this.from, this.to, this._first, this.days);

  // EN: Builds the ledger for [from]..[to] inclusive.
  //     - [stays] of a status in [includeStatuses] are counted; the default is
  //       actual stays only, so planned days never inflate an actual figure.
  //     - [today] decides what has happened: actual stays stop there (CNT-6), and
  //       only dates up to the last ENDED date can be assumed or not recorded.
  //       That last date is today by "any part" (the user is somewhere today) and
  //       yesterday by "end of day" (today's midnight has not come, CNT-5).
  //     - [visits] count by "any part" only (WRK-5).
  //     - [home] assumes unrecorded past dates at home (section 6).
  // FR: Construit le registre pour [from]..[to] inclus.
  //     - Les [stays] dont le statut figure dans [includeStatuses] sont comptés ;
  //       par défaut seulement les séjours réels, afin que des jours planifiés ne
  //       gonflent jamais un chiffre réel.
  //     - [today] décide de ce qui a eu lieu : les séjours réels s'y arrêtent
  //       (CNT-6), et seules les dates jusqu'à la dernière date TERMINÉE peuvent
  //       être présumées ou non enregistrées. Cette dernière date est aujourd'hui
  //       selon « toute partie » (l'utilisateur est quelque part aujourd'hui) et
  //       hier selon « fin de journée » (le minuit d'aujourd'hui n'est pas venu,
  //       CNT-5).
  //     - Les [visits] ne comptent que selon « toute partie » (WRK-5).
  //     - [home] présume au lieu de résidence les dates passées non enregistrées
  //       (section 6).
  factory PresenceLedger.build({
    required List<Trip> stays,
    required DateTime from,
    required DateTime to,
    required DateTime today,
    CountingConvention convention = CountingConvention.anyPart,
    Set<TripStatus> includeStatuses = const {TripStatus.actual},
    List<DayVisit> visits = const [],
    HomeBase? home,
  }) {
    final first = _dayNumber(from);
    final last = _dayNumber(to);
    if (last < first) {
      throw ArgumentError.value(to, 'to', 'precedes from');
    }
    final length = last - first + 1;
    if (length > maxRangeDays) {
      throw ArgumentError.value(to, 'to', 'range longer than $maxRangeDays');
    }
    final todayNumber = _dayNumber(today);
    final anyPart = convention == CountingConvention.anyPart;
    final lastEnded = anyPart ? todayNumber : todayNumber - 1;

    // EN: Per date: the recorded places (any part), or the single claimant with
    //     the rank that won it (end of day), and whether a stay covers it.
    // FR: Par date : les lieux enregistrés (toute partie), ou le seul occupant et
    //     le rang qui l'a emporté (fin de journée), et si un séjour la couvre.
    final places = List<List<Place>?>.filled(length, null);
    final claimRank = List<int>.filled(length, -1);
    // EN: Coverage reaches one day beyond each end of the range, so that the
    //     first and last dates can tell whether the user came from, or went back
    //     to, an unrecorded day (home crossing days, below).
    // FR: La couverture déborde d'un jour de chaque côté de la plage, afin que la
    //     première et la dernière date puissent savoir si l'utilisateur venait
    //     d'un jour non enregistré, ou y retournait (jours de passage au domicile,
    //     plus bas).
    final coveredWide = List<bool>.filled(length + 2, false);
    bool isCovered(int day) {
      final i = day - first + 1;
      return i >= 0 && i < coveredWide.length && coveredWide[i];
    }

    // EN: Per stay: its first and last counted day numbers, and whether that
    //     last day is its real departure (not a cut at today).
    // FR: Par séjour : ses premier et dernier jours comptés, et si ce dernier
    //     jour est son vrai départ (et non une coupure à aujourd'hui).
    final edges = <(int, int, bool)>[];

    // EN: Stays are taken in order of arrival, ties in list order. This gives the
    //     order of places within a date (STY-4) and, by "end of day", decides any
    //     overlap (possible only once planned stays are included) in favour of
    //     the stay that began most recently: that is where the user would be.
    // FR: Les séjours sont pris par ordre d'arrivée, à égalité dans l'ordre de la
    //     liste. Cela donne l'ordre des lieux dans une date (STY-4) et, selon « fin
    //     de journée », tranche tout chevauchement (possible seulement si les
    //     séjours planifiés sont inclus) en faveur du séjour commencé le plus
    //     récemment : c'est là que serait l'utilisateur.
    final ordered = [
      for (var i = 0; i < stays.length; i++)
        if (includeStatuses.contains(stays[i].status)) (i, stays[i]),
    ]..sort((a, b) {
        final byArrival = a.$2.arrivalDate.compareTo(b.$2.arrivalDate);
        return byArrival != 0 ? byArrival : a.$1.compareTo(b.$1);
      });

    for (var rank = 0; rank < ordered.length; rank++) {
      final stay = ordered[rank].$2;
      final start = _dayNumber(stay.arrivalDate);
      final departure = stay.departureDate;
      final actual = stay.status == TripStatus.actual;
      int end;
      if (anyPart) {
        // EN: The same rule as DayCounter, so both engines always agree: arrival
        //     and departure days both count, and an actual stay stops at today.
        // FR: La même règle que DayCounter, afin que les deux moteurs concordent
        //     toujours : les jours d'arrivée et de départ comptent, et un séjour
        //     réel s'arrête à aujourd'hui.
        end = _dayNumber(stay.effectiveEnd(today));
      } else {
        // EN: At the end of the departure day the user is already in the next
        //     place, so the stay holds arrival..departure-1. A stay that starts and
        //     ends on one date holds no night at all.
        // FR: À la fin du jour du départ, l'utilisateur est déjà dans le lieu
        //     suivant ; le séjour détient donc arrivée..départ-1. Un séjour qui
        //     commence et finit le même jour ne détient aucune nuit.
        end = departure == null ? last : _dayNumber(departure) - 1;
        if (actual && end > todayNumber - 1) end = todayNumber - 1;
      }
      if (end >= start) {
        edges.add(
          (start, end, departure != null && end == _dayNumber(departure)),
        );
      }
      for (var d = start > first - 1 ? start : first - 1;
          d <= (end < last + 1 ? end : last + 1);
          d++) {
        coveredWide[d - first + 1] = true;
      }
      final from0 = start > first ? start : first;
      final to0 = end < last ? end : last;
      for (var d = from0; d <= to0; d++) {
        final i = d - first;
        if (anyPart) {
          final list = places[i] ??= <Place>[];
          if (!list.contains(stay.place)) list.add(stay.place);
        } else if (rank > claimRank[i]) {
          claimRank[i] = rank;
          places[i] = [stay.place];
        }
      }
    }

    if (anyPart) {
      for (final visit in visits) {
        if (!includeStatuses.contains(visit.status)) continue;
        final d = _dayNumber(visit.date);
        if (d < first || d > last) continue;
        if (visit.status == TripStatus.actual && d > todayNumber) continue;
        final list = places[d - first] ??= <Place>[];
        if (!list.contains(visit.place)) list.add(visit.place);
      }
    }

    DateTime dateOf(int day) =>
        DateTime(from.year, from.month, from.day + (day - first));

    // EN: Home crossing days (owner's decision, 2026-11-26). By "any part of the
    //     day", the day a stay begins after an unrecorded day is a day the user
    //     was also at home (they left that morning), and so is the day a stay
    //     ends before an unrecorded day (they came back). With a home base on,
    //     those dates count as assumed home days too, for the home place of the
    //     unrecorded day next to them. A date already recorded in the home place
    //     (or a place containing it, or inside it) is not assumed again, so that
    //     no date counts twice for one place. By "end of day" nothing is needed:
    //     the end of a departure day already belongs to the unrecorded day's
    //     side, and is assumed there like any other.
    // FR: Jours de passage au domicile (décision du propriétaire, 2026-11-26).
    //     Selon « toute partie du jour », le jour où un séjour commence après un
    //     jour non enregistré est aussi un jour passé au domicile (l'utilisateur
    //     est parti ce matin-là), de même que le jour où un séjour se termine
    //     avant un jour non enregistré (il est revenu). Avec un lieu de résidence
    //     activé, ces dates comptent aussi comme jours présumés au domicile, pour
    //     le lieu de résidence du jour non enregistré voisin. Une date déjà
    //     enregistrée dans le lieu de résidence (ou dans un lieu qui le contient,
    //     ou qu'il contient) n'est pas présumée de nouveau, afin qu'aucune date ne
    //     compte deux fois pour un même lieu. Selon « fin de journée », rien n'est
    //     nécessaire : la fin d'un jour de départ appartient déjà au côté du jour
    //     non enregistré, et y est présumée comme toute autre.
    final crossingHome = <int, Place>{};
    if (anyPart && home != null && !home.isOff) {
      void consider(int day, int neighbour) {
        if (day < first || day > last || day > lastEnded) return;
        if (isCovered(neighbour)) return;
        final place = home.placeOn(dateOf(neighbour));
        if (place == null) return;
        final recorded = places[day - first] ?? const <Place>[];
        if (recorded.any((p) => place.contains(p) || p.contains(place))) {
          return;
        }
        crossingHome.putIfAbsent(day, () => place);
      }

      for (final (start, end, departed) in edges) {
        consider(start, start - 1);
        if (departed) consider(end, end + 1);
      }
    }

    final result = <LedgerDay>[];
    for (var i = 0; i < length; i++) {
      final date = DateTime(from.year, from.month, from.day + i);
      final past = first + i <= lastEnded;
      final covered = isCovered(first + i);
      final assumed = !past
          ? null
          : covered
              ? crossingHome[first + i]
              : home?.placeOn(date);
      result.add(
        LedgerDay(
          date: date,
          places: List.unmodifiable(places[i] ?? const <Place>[]),
          coveredByStay: covered,
          assumed: assumed,
          notRecorded: past && !covered && assumed == null,
        ),
      );
    }
    return PresenceLedger._(
      convention,
      DateTime(from.year, from.month, from.day),
      DateTime(to.year, to.month, to.day),
      first,
      List.unmodifiable(result),
    );
  }

  // EN: Recorded days in [place] (a country includes its regions), optionally
  //     within a sub-range [start]..[end] of the ledger. Each date counts once
  //     (CNT-3, CNT-4). Assumed days are NOT included: see [assumedIn].
  // FR: Jours enregistrés dans [place] (un pays inclut ses régions),
  //     éventuellement dans une sous-plage [start]..[end] du registre. Chaque date
  //     compte une fois (CNT-3, CNT-4). Les jours présumés ne sont PAS inclus :
  //     voir [assumedIn].
  int daysIn(Place place, {DateTime? start, DateTime? end}) =>
      _count(start, end, (day) => day.places.any(place.contains));

  // EN: Days assumed in [place] because it was home and nothing was recorded.
  // FR: Jours présumés dans [place] parce que c'était le lieu de résidence et que
  //     rien n'a été enregistré.
  int assumedIn(Place place, {DateTime? start, DateTime? end}) => _count(
        start,
        end,
        (day) => day.assumed != null && place.contains(day.assumed!),
      );

  // EN: Days recorded in [country] with no region (STY-8): the "region not
  //     recorded" row under that country.
  // FR: Jours enregistrés dans [country] sans région (STY-8) : la ligne « région
  //     non enregistrée » sous ce pays.
  int regionNotRecorded(Place country, {DateTime? start, DateTime? end}) =>
      _count(start, end, (day) => day.places.contains(country.country));

  // EN: Past dates with nothing recorded and nothing assumed (HOM-4).
  // FR: Dates passées sans rien d'enregistré ni de présumé (HOM-4).
  int notRecorded({DateTime? start, DateTime? end}) =>
      _count(start, end, (day) => day.notRecorded);

  // EN: Dates counted in two or more countries (CNT-2): the table explains these
  //     whenever there is at least one (TBL-8).
  // FR: Dates comptées dans deux pays ou plus (CNT-2) : le tableau les explique
  //     dès qu'il y en a au moins une (TBL-8).
  int crossingDays({DateTime? start, DateTime? end}) => _count(
        start,
        end,
        (day) => day.places.map((p) => p.countryCode).toSet().length > 1,
      );

  // EN: Every place with at least one recorded day, as recorded (regions stay
  //     regions). Used to suggest tracked places to a new user (TBL-4).
  // FR: Chaque lieu ayant au moins un jour enregistré, tel qu'enregistré (les
  //     régions restent des régions). Sert à suggérer des lieux suivis à un
  //     nouvel utilisateur (TBL-4).
  Set<Place> get recordedPlaces => {
        for (final day in days) ...day.places,
      };

  int _count(DateTime? start, DateTime? end, bool Function(LedgerDay) test) {
    final lo = start == null ? 0 : _dayNumber(start) - _first;
    final hi = end == null ? days.length - 1 : _dayNumber(end) - _first;
    var total = 0;
    for (var i = lo < 0 ? 0 : lo; i <= hi && i < days.length; i++) {
      if (test(days[i])) total++;
    }
    return total;
  }

  // EN: Days since the epoch in UTC: a plain, time-zone-free date number, the
  //     same one DayCounter uses, so a daylight-saving change can never make a
  //     day 23 or 25 hours long here.
  // FR: Jours depuis l'époque en UTC : un simple numéro de date sans fuseau, le
  //     même que DayCounter, afin qu'un changement d'heure ne puisse jamais faire
  //     un jour de 23 ou 25 heures ici.
  static int _dayNumber(DateTime d) =>
      DateTime.utc(d.year, d.month, d.day).millisecondsSinceEpoch ~/
      Duration.millisecondsPerDay;
}
