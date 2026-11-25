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

import 'package:snowbird_in_usa_tracker/models/trip.dart';
import 'package:snowbird_in_usa_tracker/services/storage_service.dart';

// EN: Why a trip was refused. The UI turns these into localised, neutral messages.
// FR: Pourquoi un séjour a été refusé. L'interface en fait des messages neutres et
//     localisés.
enum TripProblem { overlap, futureArrival }

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

  // EN: Replace the entire list. Destructive — the caller must confirm first.
  // FR: Remplacer toute la liste. Destructeur — l'appelant doit confirmer d'abord.
  Future<void> replaceAll(List<Trip> imported) =>
      _mutate((_) => List.of(imported));

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
