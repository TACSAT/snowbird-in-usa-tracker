// EN: The single source of truth for the trip list at runtime. This ChangeNotifier
//     owns the in-memory list and delegates all persistence to StorageService.
//
//     Widget trees listen to this notifier via Provider.of<TripRepository> or the
//     Consumer widget and rebuild automatically when the list changes. Widgets
//     NEVER call StorageService directly — all mutations go through here.
//
//     Why keep both an in-memory list AND persist on every mutation?
//     Because SharedPreferences writes are fast and the list is small (a user with
//     20 years of snowbird history has at most ~40 trips). The cost of persisting
//     synchronously on every change is negligible, and it eliminates an entire class
//     of bugs where the UI and storage get out of sync.
//
// FR: Source de vérité unique pour la liste des séjours à l'exécution. Ce
//     ChangeNotifier est propriétaire de la liste en mémoire et délègue toute
//     persistance au StorageService.
//
//     Les arbres de widgets écoutent ce notifieur via Provider.of<TripRepository>
//     ou le widget Consumer et se reconstruisent automatiquement lors des
//     changements. Les widgets N'appellent JAMAIS StorageService directement —
//     toutes les mutations passent par ici.
//
//     Pourquoi conserver une liste en mémoire ET persister à chaque mutation ?
//     Parce que les écritures SharedPreferences sont rapides et la liste est petite
//     (un utilisateur avec 20 ans d'histoire snowbird a au plus ~40 séjours). Le
//     coût de la persistance à chaque changement est négligeable et élimine toute
//     une classe de bugs où l'interface et le stockage se désynchronisent.

import 'package:flutter/foundation.dart';

import 'package:snowbird_in_usa_tracker/logic/input_limits.dart';
import 'package:snowbird_in_usa_tracker/models/day_visit.dart';
import 'package:snowbird_in_usa_tracker/models/place.dart';
import 'package:snowbird_in_usa_tracker/models/trip.dart';
import 'package:snowbird_in_usa_tracker/services/storage_service.dart';

// EN: Why a trip was refused. The UI turns these into localised, neutral messages.
// FR: Pourquoi un séjour a été refusé. L'interface en fait des messages neutres et
//     localisés.
// EN: Why a change was refused. moveBeforeArrival: "I have moved" dated before
//     the current stay began. splitDate: a split date outside the stay.
// FR: Pourquoi un changement a été refusé. moveBeforeArrival : « J'ai changé de
//     lieu » daté d'avant le début du séjour actuel. splitDate : une date de
//     division hors du séjour.
enum TripProblem {
  overlap,
  futureArrival,
  tooMany,
  moveBeforeArrival,
  splitDate,
}

class TripValidationException implements Exception {
  final TripProblem problem;
  const TripValidationException(this.problem);
}

class TripRepository extends ChangeNotifier {
  final StorageService _storage;

  // EN: Backing list — mutable internally, never exposed directly. External code
  //     receives an unmodifiable sorted view via the [trips] getter so there is
  //     exactly one code path that can change the list.
  // FR: Liste de support — mutable en interne, jamais exposée directement. Le code
  //     externe reçoit une vue non modifiable et triée via le getter [trips] afin
  //     qu'il y ait exactement un seul chemin de code pouvant modifier la liste.
  final List<Trip> _trips = [];

  // EN: Day visits (WRK-5), kept apart from stays and saved under their own key.
  // FR: Visites d'un jour (WRK-5), gardées à part des séjours et enregistrées
  //     sous leur propre clé.
  final List<DayVisit> _visits = [];

  // EN: Injectable clock, so "today" is deterministic in tests.
  // FR: Horloge injectable, pour un « aujourd'hui » déterministe dans les tests.
  final DateTime Function() _now;

  // EN: Tail of the mutation queue; see _mutate().
  // FR: Fin de la file des mutations ; voir _mutate().
  Future<void> _tail = Future<void>.value();

  TripRepository(this._storage, {DateTime Function()? now})
      : _now = now ?? DateTime.now {
    // EN: Load persisted trips synchronously during construction. SharedPreferences
    //     returns a synchronous value after its async initialisation (completed in
    //     main() before this constructor runs), so there is no I/O latency here.
    // FR: Charger les séjours persistés de manière synchrone lors de la
    //     construction. SharedPreferences retourne une valeur synchrone après son
    //     initialisation asynchrone (terminée dans main() avant que ce constructeur
    //     s'exécute), donc il n'y a pas de latence d'E/S ici.
    _trips.addAll(_storage.loadTrips());
    _visits.addAll(_storage.loadVisits());
  }

  // EN: Day visits, newest first, unmodifiable (same contract as [trips]).
  // FR: Visites d'un jour, de la plus récente à la plus ancienne, non
  //     modifiables (même contrat que [trips]).
  List<DayVisit> get visits => List.unmodifiable(
        List<DayVisit>.from(_visits)..sort((a, b) => b.date.compareTo(a.date)),
      );

  // EN: Everything that counts as presence by "any part of the day": the stays,
  //     plus each day visit as a one-day stay (DayVisit.asStay). Every figure
  //     built on DayCounter (summary, record, explore, alerts) reads this, so a
  //     visit to Detroit counts as a US day exactly as a same-day trip would.
  //     Lists and editors read [trips] and [visits] instead.
  // FR: Tout ce qui compte comme présence selon « toute partie du jour » : les
  //     séjours, plus chaque visite d'un jour sous forme de séjour d'un jour
  //     (DayVisit.asStay). Chaque chiffre fondé sur DayCounter (résumé, relevé,
  //     exploration, alertes) lit ceci ; une visite à Détroit compte donc comme
  //     un jour aux États-Unis exactement comme un aller-retour dans la journée.
  //     Les listes et les éditeurs lisent plutôt [trips] et [visits].
  List<Trip> get countedStays => List.unmodifiable([
        ..._trips,
        for (final visit in _visits) visit.asStay(),
      ]);

  // EN: Places used most recently first (stays and visits), at most [limit]:
  //     offered first in the chooser (PLC-9), so a regular route is one tap.
  // FR: Les lieux utilisés le plus récemment en premier (séjours et visites), au
  //     plus [limit] : proposés en tête du sélecteur (PLC-9), pour qu'un trajet
  //     habituel ne demande qu'un toucher.
  List<Place> recentPlaces({int limit = 5}) {
    final dated = [
      for (final t in _trips) (t.arrivalDate, t.place),
      for (final v in _visits) (v.date, v.place),
    ]..sort((a, b) => b.$1.compareTo(a.$1));
    final seen = <Place>[];
    for (final (_, place) in dated) {
      if (!seen.contains(place)) seen.add(place);
      if (seen.length == limit) break;
    }
    return seen;
  }

  // EN: All trips, sorted newest-first (by arrival date). Returns an unmodifiable
  //     list so callers cannot bypass the mutation API and alter the list directly.
  // FR: Tous les séjours, triés du plus récent au plus ancien (par date d'arrivée).
  //     Retourne une liste non modifiable pour que les appelants ne puissent pas
  //     contourner l'API de mutation et modifier la liste directement.
  List<Trip> get trips {
    final sorted = List<Trip>.from(_trips)
      ..sort((a, b) => b.arrivalDate.compareTo(a.arrivalDate));
    return List.unmodifiable(sorted);
  }

  // EN: Convenience getter — the count of trips, without exposing the list.
  // FR: Getter de commodité — le nombre de séjours, sans exposer la liste.
  int get tripCount => _trips.length;

  // EN: Add a new trip, persist, and notify listeners. The caller is responsible
  //     for supplying a Trip with a valid UUID (use Trip.create() to get one).
  // FR: Ajouter un nouveau séjour, persister et notifier les écouteurs. L'appelant
  //     est responsable de fournir un Trip avec un UUID valide (utiliser
  //     Trip.create() pour en obtenir un).
  //     Throws TripValidationException or StorageWriteException.
  //     Lance TripValidationException ou StorageWriteException.
  Future<void> addTrip(Trip trip) => _mutate((current) {
        if (current.length >= InputLimits.maxTrips) {
          throw const TripValidationException(TripProblem.tooMany);
        }
        _validate(trip, current);
        return [...current, trip];
      });

  // EN: Update an existing trip matched by ID; a stale ID is a silent no-op. Dates
  //     are validated only when they change, so a note can still be fixed on an
  //     overlapping pair stored before overlaps were refused.
  // FR: Mettre à jour un séjour existant par ID ; un ID périmé est sans effet. Les
  //     dates ne sont validées que si elles changent, pour qu'une note reste
  //     modifiable sur une paire chevauchante enregistrée avant ce refus.
  Future<void> updateTrip(Trip updated) => _mutate((current) {
        final index = current.indexWhere((t) => t.id == updated.id);
        if (index == -1) return null;
        final old = current[index];
        if (old.arrivalDate != updated.arrivalDate ||
            old.departureDate != updated.departureDate ||
            old.status != updated.status) {
          _validate(updated, current);
        }
        return [...current]..[index] = updated;
      });

  // EN: Remove a trip by ID. Silent no-op if the ID is not found (delete was already
  //     applied, e.g. from a retry).
  // FR: Supprimer un séjour par ID. Sans effet si l'ID est introuvable (suppression
  //     déjà appliquée, p. ex. après une nouvelle tentative).
  Future<void> deleteTrip(String id) => _mutate((current) {
        final kept = current.where((t) => t.id != id).toList();
        return kept.length == current.length ? null : kept;
      });

  // EN: "I have moved to..." (STY-3): close the ongoing [current] stay on [date]
  //     and open the next one, in [place], on the same date, in ONE saved step,
  //     so a crash between the two can never leave the user nowhere or in two
  //     places. The shared date is the crossing day: by "any part of the day" it
  //     counts in both places, as a crossing must. Returns the new stay.
  // FR: « J'ai changé de lieu... » (STY-3) : fermer le séjour en cours
  //     [current] à [date] et ouvrir le suivant, dans [place], à la même date, en
  //     UNE seule étape enregistrée, afin qu'une panne entre les deux ne puisse
  //     jamais laisser l'utilisateur nulle part ou à deux endroits. La date
  //     partagée est le jour du passage : selon « toute partie du jour », elle
  //     compte dans les deux lieux, comme il se doit. Retourne le nouveau séjour.
  Future<Trip> moveOn(
    Trip current,
    DateTime date,
    Place place, {
    String? placeName,
  }) async {
    final day = DateTime(date.year, date.month, date.day);
    late final Trip next;
    await _mutate((list) {
      final index = list.indexWhere((t) => t.id == current.id);
      final stored = index == -1 ? null : list[index];
      if (stored == null ||
          stored.status != TripStatus.actual ||
          stored.departureDate != null) {
        throw ArgumentError.value(current, 'current', 'not an ongoing stay');
      }
      if (list.length >= InputLimits.maxTrips) {
        throw const TripValidationException(TripProblem.tooMany);
      }
      if (day.isBefore(stored.arrivalDate)) {
        throw const TripValidationException(TripProblem.moveBeforeArrival);
      }
      final closed = stored.copyWith(departureDate: day);
      next = Trip.create(
        arrivalDate: day,
        departureDate: null,
        status: TripStatus.actual,
        place: place,
        placeName: placeName,
      );
      final updated = [...list]..[index] = closed;
      final result = [...updated, next];
      _validate(next, result);
      return result;
    });
    return next;
  }

  // EN: Refine a stay into two places of the SAME country without retyping it
  //     (STY-9): [stay] becomes [before] up to [at], and a new stay in [after]
  //     starts on [at] and keeps the rest (its departure, exit details). Because
  //     both parts are in one country and share [at], no date of the country is
  //     added or lost: its total cannot change (section 18, tested).
  // FR: Préciser un séjour en deux lieux du MÊME pays sans le retaper (STY-9) :
  //     [stay] devient [before] jusqu'à [at], et un nouveau séjour dans [after]
  //     commence à [at] et garde le reste (son départ, les détails de sortie).
  //     Comme les deux parties sont dans un même pays et partagent [at], aucune
  //     date du pays n'est ajoutée ni perdue : son total ne peut pas changer
  //     (section 18, testé).
  Future<void> splitStay(
    Trip stay,
    DateTime at, {
    required Place before,
    required Place after,
  }) {
    final day = DateTime(at.year, at.month, at.day);
    final country = stay.place.country;
    if (before.country != country || after.country != country) {
      throw ArgumentError('Both parts must stay in ${country.code}.');
    }
    return _mutate((list) {
      final index = list.indexWhere((t) => t.id == stay.id);
      if (index == -1) return null;
      if (list.length >= InputLimits.maxTrips) {
        throw const TripValidationException(TripProblem.tooMany);
      }
      final stored = list[index];
      final end = stored.departureDate ?? _dateOnly(_now());
      if (day.isBefore(stored.arrivalDate) || day.isAfter(end)) {
        throw const TripValidationException(TripProblem.splitDate);
      }
      final first = stored.copyWith(
        departureDate: day,
        place: before,
        departureInfo: null,
      );
      final second = Trip.create(
        arrivalDate: day,
        departureDate: stored.departureDate,
        status: stored.status,
        name: stored.name,
        place: after,
        placeName: stored.placeName,
        departureInfo: stored.departureInfo,
        work: stored.work,
        purpose: stored.purpose,
        label: stored.label,
      );
      return [...list]
        ..[index] = first
        ..add(second);
    });
  }

  // EN: Add a day visit. An actual visit cannot be in the future, like an
  //     actual arrival. Visits never conflict with stays: being somewhere else
  //     for part of a day is their very point.
  // FR: Ajouter une visite d'un jour. Une visite réelle ne peut pas être dans le
  //     futur, comme une arrivée réelle. Les visites n'entrent jamais en conflit
  //     avec les séjours : être ailleurs une partie de la journée est leur raison
  //     d'être.
  Future<void> addVisit(DayVisit visit) => _mutateVisits((current) {
        if (current.length >= InputLimits.maxVisits) {
          throw const TripValidationException(TripProblem.tooMany);
        }
        if (visit.status == TripStatus.actual &&
            visit.date.isAfter(_dateOnly(_now()))) {
          throw const TripValidationException(TripProblem.futureArrival);
        }
        return [...current, visit];
      });

  Future<void> deleteVisit(String id) => _mutateVisits((current) {
        final kept = current.where((v) => v.id != id).toList();
        return kept.length == current.length ? null : kept;
      });

  // EN: The same queue as _mutate, so a visit and a stay change never race.
  // FR: La même file que _mutate, afin qu'un changement de visite et un de
  //     séjour ne se concurrencent jamais.
  Future<void> _mutateVisits(
    List<DayVisit>? Function(List<DayVisit> current) change,
  ) {
    final result = _tail.then((_) async {
      final next = change(List.unmodifiable(_visits));
      if (next == null) return;
      await _storage.saveVisits(next);
      _visits
        ..clear()
        ..addAll(next);
      notifyListeners();
    });
    _tail = result.catchError((Object _) {});
    return result;
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  // EN: Planned trips are free to overlap: comparing alternatives is their purpose.
  //     An actual trip must have begun and must not conflict with another one. A
  //     future DEPARTURE is allowed (an expected date); counts clip it to today.
  // FR: Les séjours planifiés peuvent se chevaucher : comparer des options est leur
  //     but. Un séjour réel doit avoir commencé et ne pas être en conflit avec un
  //     autre. Un DÉPART futur est permis (date prévue) ; les comptes le bornent à
  //     aujourd'hui.
  void _validate(Trip trip, List<Trip> current) {
    if (trip.status != TripStatus.actual) return;
    if (trip.arrivalDate.isAfter(_now())) {
      throw const TripValidationException(TripProblem.futureArrival);
    }
    if (current.any((t) => t.id != trip.id && t.conflictsWith(trip))) {
      throw const TripValidationException(TripProblem.overlap);
    }
  }

  // EN: The only path that changes the list. Mutations run one at a time, so two
  //     quick saves cannot both pass validation against the same old list; memory
  //     changes only AFTER the device accepted the write, so the screen never shows
  //     something that was not saved. [change] returns null for "nothing to do".
  // FR: Le seul chemin qui modifie la liste. Les mutations passent une à la fois :
  //     deux enregistrements rapides ne peuvent être validés contre la même ancienne
  //     liste ; la mémoire ne change qu'APRÈS l'écriture acceptée par l'appareil,
  //     donc l'écran ne montre jamais ce qui n'est pas enregistré. [change] retourne
  //     null pour « rien à faire ».
  Future<void> _mutate(List<Trip>? Function(List<Trip> current) change) {
    final result = _tail.then((_) async {
      final next = change(List.unmodifiable(_trips));
      if (next == null) return;
      await _storage.saveTrips(next);
      _trips
        ..clear()
        ..addAll(next);
      notifyListeners();
    });
    // EN: A failed mutation must not block the ones queued after it.
    // FR: Une mutation échouée ne doit pas bloquer celles qui la suivent.
    _tail = result.catchError((Object _) {});
    return result;
  }
}
