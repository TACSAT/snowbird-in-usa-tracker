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

class TripRepository extends ChangeNotifier {
  final StorageService _storage;

  // EN: Backing list — mutable internally, never exposed directly. External code
  //     receives an unmodifiable sorted view via the [trips] getter so there is
  //     exactly one code path that can change the list.
  // FR: Liste de support — mutable en interne, jamais exposée directement. Le code
  //     externe reçoit une vue non modifiable et triée via le getter [trips] afin
  //     qu'il y ait exactement un seul chemin de code pouvant modifier la liste.
  final List<Trip> _trips = [];

  TripRepository(this._storage) {
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
  Future<void> addTrip(Trip trip) async {
    _trips.add(trip);
    await _persist();
  }

  // EN: Update an existing trip matched by ID. If no trip with that ID exists,
  //     this is a silent no-op — the caller passed a stale reference.
  // FR: Mettre à jour un séjour existant identifié par ID. Si aucun séjour avec
  //     cet ID n'existe, l'opération est silencieuse — l'appelant a passé une
  //     référence périmée.
  Future<void> updateTrip(Trip updated) async {
    final index = _trips.indexWhere((t) => t.id == updated.id);
    if (index == -1) return;
    _trips[index] = updated;
    await _persist();
  }

  // EN: Remove a trip by ID, persist, and notify. Silent no-op if the ID is not
  //     found (delete was already applied, e.g. from a retry).
  // FR: Supprimer un séjour par ID, persister et notifier. Opération silencieuse
  //     si l'ID n'est pas trouvé (la suppression a déjà été appliquée, p. ex.
  //     après une nouvelle tentative).
  Future<void> deleteTrip(String id) async {
    final before = _trips.length;
    _trips.removeWhere((t) => t.id == id);
    if (_trips.length != before) await _persist();
  }

  // EN: Replace the entire trip list with an imported backup. This is a
  //     destructive operation — always show a confirmation dialog before calling
  //     this from the UI so the user cannot accidentally overwrite their data.
  // FR: Remplacer toute la liste des séjours par une sauvegarde importée. C'est
  //     une opération destructrice — toujours afficher une boîte de dialogue de
  //     confirmation avant d'appeler ceci depuis l'interface pour que l'utilisateur
  //     ne puisse pas écraser ses données par accident.
  Future<void> replaceAll(List<Trip> imported) async {
    _trips
      ..clear()
      ..addAll(imported);
    await _persist();
  }

  // EN: Persist the current list and notify listeners in one step. Centralising
  //     this here ensures we never forget to call notifyListeners() after a
  //     storage write, or call it before the write completes.
  // FR: Persister la liste courante et notifier les écouteurs en une seule étape.
  //     Centraliser ceci ici garantit qu'on n'oubliera jamais d'appeler
  //     notifyListeners() après une écriture dans le stockage, ni de l'appeler
  //     avant que l'écriture soit terminée.
  Future<void> _persist() async {
    await _storage.saveTrips(_trips);
    notifyListeners();
  }
}
