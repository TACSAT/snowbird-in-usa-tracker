// EN: The single gateway between runtime state and on-device persistent storage.
//     ALL reads and writes go through this class — no widget, repository, or other
//     service touches SharedPreferences directly. This hard boundary means:
//       • The storage format can change without hunting down scattered accesses.
//       • Business logic is never mixed with serialisation detail.
//       • The service can be replaced with a stub in unit tests without a real device.
//     This class contains NO business logic — it only serialises, deserialises,
//     and delegates validation errors upward to the caller.
//
// FR: Unique passerelle entre l'état en mémoire et le stockage persistant sur
//     l'appareil. TOUTES les lectures et écritures passent par cette classe —
//     aucun widget, dépôt ou autre service n'accède directement à SharedPreferences.
//     Cette frontière stricte signifie :
//       • Le format de stockage peut changer sans trouver tous les accès dispersés.
//       • La logique métier n'est jamais mélangée aux détails de sérialisation.
//       • Le service peut être remplacé par un stub dans les tests unitaires.
//     Cette classe ne contient AUCUNE logique métier — elle sérialise,
//     désérialise et remonte les erreurs de validation à l'appelant.

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:snowbird_in_usa_tracker/models/day_alert.dart';
import 'package:snowbird_in_usa_tracker/models/trip.dart';

class StorageService {
  // EN: SharedPreferences key under which the JSON-encoded trip list is stored.
  //     The "v1" suffix makes a future format migration explicit — if the schema
  //     ever changes, bump to "v2" and write a one-shot migration on first load.
  // FR: Clé SharedPreferences sous laquelle la liste JSON des séjours est stockée.
  //     Le suffixe « v1 » rend explicite une future migration de format — si le
  //     schéma change, passer à « v2 » et écrire une migration unique au premier
  //     chargement.
  static const _kTripsKey = 'snowbird.trips.v1';

  // EN: Key for the user-defined alert list — same versioning convention.
  // FR: Clé de la liste des alertes définies par l'utilisateur — même
  //     convention de versionnage.
  static const _kAlertsKey = 'snowbird.alerts.v1';

  final SharedPreferences _prefs;

  // EN: Inject SharedPreferences so this service can be unit-tested without a
  //     real device — pass a mock or fake in tests, pass the real instance in the
  //     app via main().
  // FR: Injecter SharedPreferences pour que ce service puisse être testé sans
  //     appareil réel — passer un mock ou un faux dans les tests, l'instance
  //     réelle dans l'appli via main().
  StorageService(this._prefs);

  // EN: Load the persisted trip list. Returns an empty list on first launch or if
  //     the stored value is absent. If a single Trip record is malformed, it is
  //     skipped (with a debug-only log) and the rest of the list is preserved.
  //     This means a corrupt record never wipes the user's entire history.
  // FR: Charger la liste des séjours persistés. Retourne une liste vide au premier
  //     lancement ou si la valeur stockée est absente. Si un enregistrement Trip
  //     est malformé, il est ignoré (avec un journal de débogage uniquement) et le
  //     reste de la liste est préservé. Ainsi, un enregistrement corrompu n'efface
  //     jamais tout l'historique de l'utilisateur.
  List<Trip> loadTrips() {
    final raw = _prefs.getString(_kTripsKey);
    if (raw == null || raw.isEmpty) return [];

    final List<dynamic> decoded;
    try {
      decoded = jsonDecode(raw) as List<dynamic>;
    } catch (e) {
      // EN: The top-level JSON is unparseable — return empty rather than crash.
      //     This can happen if storage was manually corrupted (rare) or if a
      //     previous app version wrote an incompatible format.
      // FR: Le JSON de niveau supérieur est non analysable — retourner vide
      //     plutôt que de planter. Cela peut arriver si le stockage a été
      //     corrompu manuellement (rare) ou si une version précédente a écrit
      //     un format incompatible.
      assert(() {
        // ignore: avoid_print
        print('[StorageService] Failed to decode trips JSON: $e');
        return true;
      }());
      return [];
    }

    final trips = <Trip>[];
    for (var i = 0; i < decoded.length; i++) {
      try {
        trips.add(Trip.fromJson(decoded[i] as Map<String, dynamic>));
      } on FormatException catch (e) {
        assert(() {
          // ignore: avoid_print
          print('[StorageService] Skipping malformed trip at index $i: $e');
          return true;
        }());
      }
    }
    return trips;
  }

  // EN: Persist the full trip list, replacing whatever was stored before.
  //     The write is awaited to confirm it succeeded before the caller
  //     considers the data durable.
  // FR: Persister la liste complète des séjours, en remplaçant ce qui était
  //     stocké auparavant. L'écriture est attendue pour confirmer son succès
  //     avant que l'appelant considère les données durables.
  Future<void> saveTrips(List<Trip> trips) async {
    final encoded = jsonEncode(
      trips.map((t) => t.toJson()).toList(),
    );
    await _prefs.setString(_kTripsKey, encoded);
  }

  // EN: Load the persisted user-defined alerts. Same resilience strategy as
  //     loadTrips(): a malformed record — including one whose numeric values
  //     fall outside InputLimits (DayAlert.fromJson enforces the caps) — is
  //     skipped individually, never allowed to wipe or crash the rest.
  // FR: Charger les alertes persistées définies par l'utilisateur. Même
  //     stratégie de résilience que loadTrips() : un enregistrement malformé —
  //     y compris un dont les valeurs numériques sortent des InputLimits
  //     (DayAlert.fromJson applique les plafonds) — est ignoré individuellement,
  //     sans jamais effacer ni faire planter le reste.
  List<DayAlert> loadAlerts() {
    final raw = _prefs.getString(_kAlertsKey);
    if (raw == null || raw.isEmpty) return [];

    final List<dynamic> decoded;
    try {
      decoded = jsonDecode(raw) as List<dynamic>;
    } catch (e) {
      assert(() {
        // ignore: avoid_print
        print('[StorageService] Failed to decode alerts JSON: $e');
        return true;
      }());
      return [];
    }

    final alerts = <DayAlert>[];
    for (var i = 0; i < decoded.length; i++) {
      try {
        alerts.add(DayAlert.fromJson(decoded[i] as Map<String, dynamic>));
      } on FormatException catch (e) {
        assert(() {
          // ignore: avoid_print
          print('[StorageService] Skipping malformed alert at index $i: $e');
          return true;
        }());
      }
    }
    return alerts;
  }

  // EN: Persist the full alert list — mirrors saveTrips().
  // FR: Persister la liste complète des alertes — reflète saveTrips().
  Future<void> saveAlerts(List<DayAlert> alerts) async {
    final encoded = jsonEncode(
      alerts.map((a) => a.toJson()).toList(),
    );
    await _prefs.setString(_kAlertsKey, encoded);
  }

  // EN: Serialise the trip list to a pretty-printed JSON string for the user to
  //     save as a backup file. The format is identical to the internal storage
  //     format, making import verification straightforward and allowing the user
  //     (or their accountant) to read the file in a text editor.
  // FR: Sérialiser la liste des séjours en chaîne JSON joliment formatée pour
  //     que l'utilisateur la sauvegarde dans un fichier. Le format est identique
  //     au format de stockage interne, ce qui simplifie la vérification à
  //     l'importation et permet à l'utilisateur (ou son comptable) de lire le
  //     fichier dans un éditeur de texte.
  String exportToJson(List<Trip> trips) {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(trips.map((t) => t.toJson()).toList());
  }

  // EN: Parse and validate a JSON backup string, returning a clean list of Trips
  //     if — and only if — every single record is valid. Uses an all-or-nothing
  //     strategy: if any record is invalid, the entire import is rejected and the
  //     on-device data is untouched. This prevents partial corruption.
  //
  //     Throws [FormatException] on any validation failure so the caller can
  //     surface an error message to the user without the app crashing.
  //
  // FR: Analyser et valider une chaîne JSON de sauvegarde, en retournant une liste
  //     propre de Trips si et seulement si chaque enregistrement est valide.
  //     Stratégie tout-ou-rien : si un enregistrement est invalide, l'import entier
  //     est rejeté et les données sur l'appareil restent intactes. Cela prévient
  //     la corruption partielle.
  //
  //     Lance [FormatException] en cas d'échec de validation afin que l'appelant
  //     puisse afficher un message d'erreur sans faire planter l'appli.
  List<Trip> importFromJson(String jsonString) {
    final List<dynamic> decoded;
    try {
      decoded = jsonDecode(jsonString) as List<dynamic>;
    } catch (_) {
      throw const FormatException(
        'The selected file does not contain valid JSON.',
      );
    }

    final trips = <Trip>[];
    for (var i = 0; i < decoded.length; i++) {
      try {
        trips.add(Trip.fromJson(decoded[i] as Map<String, dynamic>));
      } on FormatException catch (e) {
        throw FormatException(
          'Record #${i + 1} in the backup file is invalid: ${e.message}',
        );
      }
    }
    return trips;
  }
}
