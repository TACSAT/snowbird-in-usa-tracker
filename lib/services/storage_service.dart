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
import 'package:snowbird_in_usa_tracker/models/day_visit.dart';
import 'package:snowbird_in_usa_tracker/models/trip.dart';

// EN: What went wrong, if anything, while loading. Surfaced to the user because
//     showing an empty history without explanation would look like data loss.
// FR: Ce qui a mal tourné, le cas échéant, au chargement. Montré à l'utilisateur
//     car un historique vide sans explication ressemblerait à une perte de données.
enum StorageLoadProblem { none, unreadable, newerVersion }

// EN: The device did not accept a write. Callers must tell the user and must not
//     present the change as saved.
// FR: L'appareil n'a pas accepté une écriture. L'appelant doit en aviser
//     l'utilisateur et ne pas présenter le changement comme enregistré.
class StorageWriteException implements Exception {
  const StorageWriteException();
}

class StorageService {
  // EN: Version of the stored format (FR-12). 1 = a bare JSON list. 2 = an envelope
  //     {"schemaVersion", "trips"|"alerts"} whose trips may have a null departure.
  //     Every v1 record is already a valid v2 record, so that step changes nothing
  //     in the records. Raise this whenever an older app would misread new data,
  //     and convert in _records(). Version and data share one value so they can
  //     never disagree after an interrupted write (FR-13).
  // FR: Version du format stocké (FR-12). 1 = une simple liste JSON. 2 = une
  //     enveloppe {"schemaVersion", "trips"|"alerts"} dont les séjours peuvent avoir
  //     un départ null. Tout enregistrement v1 est déjà un v2 valide : cette étape
  //     ne change rien aux enregistrements. Augmenter dès qu'une ancienne appli
  //     lirait mal les nouvelles données, et convertir dans _records(). Version et
  //     données partagent une seule valeur pour ne jamais diverger après une
  //     écriture interrompue (FR-13).
  //
  // EN: 3 = every stay carries a "place" code (REQUIREMENTS-places.md MIG-2). A v2
  //     stay has none and is read as the United States with no region (MIG-1, in
  //     Trip.fromJson), so v2 data loads unchanged. An older build cannot count v3
  //     data correctly (it would add a Canadian stay to United States days), and
  //     it refuses anything newer than it knows; release notes must say so.
  // FR: 3 = chaque séjour porte un code « place » (REQUIREMENTS-places.md MIG-2).
  //     Un séjour v2 n'en a pas et est lu comme les États-Unis sans région (MIG-1,
  //     dans Trip.fromJson) ; les données v2 se chargent donc inchangées. Une
  //     version plus ancienne ne peut pas compter correctement des données v3
  //     (elle ajouterait un séjour au Canada aux jours aux États-Unis), et elle
  //     refuse tout ce qui est plus récent qu'elle ; les notes de version doivent
  //     le dire.
  static const schemaVersion = 3;

  // EN: The key names keep their "v1" suffix although the content is versioned now:
  //     renaming would split the history across two keys.
  // FR: Les noms de clés gardent leur suffixe « v1 » bien que le contenu soit
  //     désormais versionné : renommer scinderait l'historique entre deux clés.
  static const _kTripsKey = 'snowbird.trips.v1';

  // EN: Key for the user-defined alert list — same versioning convention.
  // FR: Clé de la liste des alertes définies par l'utilisateur — même
  //     convention de versionnage.
  static const _kAlertsKey = 'snowbird.alerts.v1';
  // EN: Day visits (WRK-5) live under their own key, so an older build that
  //     knows nothing of them leaves them untouched instead of dropping them.
  // FR: Les visites d'un jour (WRK-5) ont leur propre clé, afin qu'une version
  //     plus ancienne qui les ignore les laisse intactes au lieu de les perdre.
  static const _kVisitsKey = 'snowbird.visits.v1';

  // EN: One-shot onboarding flags. The disclaimer (FR-14) and the single
  //     backup reminder (FR-11) must each be shown exactly once; these booleans
  //     record that they have been acknowledged so they never nag again.
  // FR: Indicateurs d'accueil à usage unique. L'avertissement (FR-14) et l'unique
  //     rappel de sauvegarde (FR-11) doivent chacun être montrés exactement une
  //     fois ; ces booléens consignent leur acquittement pour qu'ils ne
  //     reviennent jamais importuner.
  static const _kDisclaimerAckKey = 'snowbird.flags.disclaimerAck.v1';
  static const _kBackupReminderKey = 'snowbird.flags.backupReminderShown.v1';

  // EN: User preference keys (FR-20). Locale is stored as a language code
  //     ('en'/'fr') or ABSENT to mean "follow the phone"; theme as a ThemeMode
  //     name; text scale as a multiplier applied on top of the OS setting.
  // FR: Clés de préférences utilisateur (FR-20). La locale est stockée comme code
  //     de langue (« en »/« fr ») ou ABSENTE pour « suivre le téléphone » ; le
  //     thème comme nom de ThemeMode ; l'échelle du texte comme multiplicateur
  //     appliqué par-dessus le réglage de l'OS.
  static const _kLocaleKey = 'snowbird.settings.locale.v1';
  static const _kThemeModeKey = 'snowbird.settings.themeMode.v1';
  static const _kTextScaleKey = 'snowbird.settings.textScale.v1';
  static const _kHighContrastKey = 'snowbird.settings.highContrast.v1';
  // EN: Days present table preferences and the home base (sections 6 and 9).
  //     Plain JSON under their own keys: an older build ignores them, and a
  //     damaged value only falls back to the default (automatic table, home
  //     off), which changes no recorded day.
  // FR: Préférences du tableau des jours de présence et lieu de résidence
  //     (sections 6 et 9). Du JSON simple sous leurs propres clés : une version
  //     plus ancienne les ignore, et une valeur abîmée revient seulement à la
  //     valeur par défaut (tableau automatique, domicile désactivé), ce qui ne
  //     change aucun jour enregistré.
  static const _kTrackedPlacesKey = 'snowbird.places.tracked.v1';
  static const _kExpandedPlacesKey = 'snowbird.places.expanded.v1';
  static const _kHomeBaseKey = 'snowbird.home.v1';
  static const _kPlacesNoteKey = 'snowbird.flags.placesNoteShown.v1';

  final SharedPreferences _prefs;

  // EN: Inject SharedPreferences so this service can be unit-tested without a
  //     real device — pass a mock or fake in tests, pass the real instance in the
  //     app via main().
  // FR: Injecter SharedPreferences pour que ce service puisse être testé sans
  //     appareil réel — passer un mock ou un faux dans les tests, l'instance
  //     réelle dans l'appli via main().
  StorageService(this._prefs);

  // EN: Worst problem met while loading. Raw text awaiting quarantine, per key. Keys
  //     written by a newer app version, which this version must not overwrite.
  // FR: Pire problème rencontré au chargement. Texte brut en attente de quarantaine,
  //     par clé. Clés écrites par une version plus récente, que celle-ci ne doit
  //     pas écraser.
  StorageLoadProblem _loadProblem = StorageLoadProblem.none;
  final Map<String, String> _toQuarantine = {};
  final Set<String> _readOnly = {};

  // EN: Keys loaded from an OLDER schema version, with their original text. The
  //     original is kept aside under "<key>.premigration" while the first save in
  //     the new version is written, and removed only once that save has succeeded
  //     (MIG-3): an interrupted first save can never leave the user with neither
  //     the old data nor the new.
  // FR: Clés chargées depuis une version PLUS ANCIENNE du schéma, avec leur texte
  //     d'origine. L'original est mis de côté sous « <clé>.premigration » pendant
  //     l'écriture du premier enregistrement dans la nouvelle version, et retiré
  //     seulement une fois cet enregistrement réussi (MIG-3) : un premier
  //     enregistrement interrompu ne peut jamais laisser l'utilisateur sans les
  //     anciennes données ni les nouvelles.
  final Map<String, String> _premigration = {};

  StorageLoadProblem get loadProblem => _loadProblem;

  // EN: Load the persisted trips. Bad records are skipped one by one so they never
  //     hide the good ones, and the original text is kept for quarantine.
  // FR: Charger les séjours persistés. Les enregistrements fautifs sont ignorés un à
  //     un pour ne jamais masquer les bons, et le texte original est gardé pour la
  //     quarantaine.
  List<Trip> loadTrips() {
    final trips = _load(_kTripsKey, 'trips', Trip.fromJson);
    // EN: Remember whether these trips came from before places existed, for
    //     the one-time "what is new" note (MIG-4).
    // FR: Retenir si ces séjours datent d'avant les lieux, pour la note unique
    //     « quoi de neuf » (MIG-4).
    _loadedOlderTrips =
        trips.isNotEmpty && _premigration.containsKey(_kTripsKey);
    return trips;
  }

  bool _loadedOlderTrips = false;

  // EN: True when this launch read trips written by a version before places.
  // FR: Vrai quand ce lancement a lu des séjours écrits par une version
  //     antérieure aux lieux.
  bool get loadedOlderTrips => _loadedOlderTrips;

  // EN: Persist the full trip list, replacing what was stored. Throws
  //     StorageWriteException if the device refuses, so a failure is never silent.
  // FR: Persister la liste complète des séjours, en remplaçant l'ancienne. Lance
  //     StorageWriteException si l'appareil refuse : un échec n'est jamais muet.
  Future<void> saveTrips(List<Trip> trips) =>
      _save(_kTripsKey, 'trips', trips.map((t) => t.toJson()).toList());

  // EN: Alerts follow exactly the same rules as trips.
  // FR: Les alertes suivent exactement les mêmes règles que les séjours.
  List<DayAlert> loadAlerts() =>
      _load(_kAlertsKey, 'alerts', DayAlert.fromJson);

  Future<void> saveAlerts(List<DayAlert> alerts) =>
      _save(_kAlertsKey, 'alerts', alerts.map((a) => a.toJson()).toList());

  List<DayVisit> loadVisits() =>
      _load(_kVisitsKey, 'visits', DayVisit.fromJson);

  Future<void> saveVisits(List<DayVisit> visits) =>
      _save(_kVisitsKey, 'visits', visits.map((v) => v.toJson()).toList());

  List<T> _load<T>(
    String key,
    String field,
    T Function(Map<String, dynamic>) parse,
  ) {
    // EN: get() rather than getString(): the latter throws on a non-string value,
    //     which would stop the app before its first screen.
    // FR: get() plutôt que getString() : ce dernier lance une exception sur une
    //     valeur non textuelle, ce qui arrêterait l'appli avant son premier écran.
    final stored = _prefs.get(key);
    if (stored == null || stored == '') return [];
    final raw = stored.toString();

    final List<dynamic> records;
    try {
      if (stored is! String) throw const FormatException('Not a string.');
      final found = _records(jsonDecode(raw), field, key, raw);
      if (found == null) {
        _readOnly.add(key);
        _loadProblem = StorageLoadProblem.newerVersion;
        return [];
      }
      records = found;
    } on FormatException {
      _markUnreadable(key, raw);
      return [];
    }

    final result = <T>[];
    for (final record in records) {
      // EN: Catch everything, not only FormatException: no single record, however
      //     damaged, may prevent the app from opening.
      // FR: Tout intercepter, pas seulement FormatException : aucun enregistrement,
      //     si abîmé soit-il, ne doit empêcher l'appli de s'ouvrir.
      try {
        result.add(parse(record as Map<String, dynamic>));
      } catch (e) {
        _markUnreadable(key, raw);
        assert(() {
          // ignore: avoid_print
          print('[StorageService] Skipping malformed record in $key: $e');
          return true;
        }());
      }
    }
    return result;
  }

  // EN: Unwrap any supported version to its record list; null means "newer than
  //     this app understands".
  // FR: Extraire la liste d'enregistrements de toute version prise en charge ; null
  //     signifie « plus récent que ce que cette appli comprend ».
  List<dynamic>? _records(
    Object? decoded,
    String field,
    String key,
    String raw,
  ) {
    if (decoded is List) {
      _premigration[key] = raw;
      return decoded;
    }
    if (decoded is! Map) throw const FormatException('Unknown storage shape.');
    final version = decoded['schemaVersion'];
    if (version is! int) throw const FormatException('Missing schemaVersion.');
    if (version > schemaVersion) return null;
    if (version < schemaVersion) _premigration[key] = raw;

    final records = decoded[field];
    if (records is! List) throw FormatException('Missing "$field" list.');
    return records;
  }

  void _markUnreadable(String key, String raw) {
    _toQuarantine[key] = raw;
    if (_loadProblem == StorageLoadProblem.none) {
      _loadProblem = StorageLoadProblem.unreadable;
    }
  }

  // EN: The original goes to quarantine BEFORE its key is overwritten, and a failed
  //     copy aborts the save: better an unsaved change than a destroyed history.
  // FR: L'original part en quarantaine AVANT que sa clé soit écrasée, et une copie
  //     échouée annule l'enregistrement : mieux vaut un changement non enregistré
  //     qu'un historique détruit.
  Future<void> _save(String key, String field, List<Object> records) async {
    if (_readOnly.contains(key)) throw const StorageWriteException();

    final bad = _toQuarantine[key];
    if (bad != null) {
      final quarantineKey = '$key.quarantine';
      final kept = _prefs.getStringList(quarantineKey) ?? const <String>[];
      if (!kept.contains(bad)) {
        await _write(
          () => _prefs.setStringList(quarantineKey, [...kept, bad]),
        );
      }
      _toQuarantine.remove(key);
    }

    final encoded =
        jsonEncode({'schemaVersion': schemaVersion, field: records});
    final original = _premigration[key];
    final premigrationKey = '$key.premigration';
    if (original != null) {
      await _write(() => _prefs.setString(premigrationKey, original));
    }
    await _write(() => _prefs.setString(key, encoded));
    if (original != null) {
      _premigration.remove(key);
      // EN: The new data is safely written; a failure to tidy up the copy only
      //     leaves a harmless extra key, so it must not fail the save.
      // FR: Les nouvelles données sont écrites en sécurité ; un échec du ménage de
      //     la copie ne laisse qu'une clé de trop, sans danger : il ne doit pas
      //     faire échouer l'enregistrement.
      try {
        await _prefs.remove(premigrationKey);
      } catch (_) {}
    }
  }

  // EN: Platform code reports failure by returning false or by throwing; both
  //     become one exception type.
  // FR: La plateforme signale un échec par un retour false ou une exception ; les
  //     deux deviennent un seul type d'exception.
  Future<void> _write(Future<bool> Function() action) async {
    bool ok;
    try {
      ok = await action();
    } catch (_) {
      ok = false;
    }
    if (!ok) throw const StorageWriteException();
  }

  // EN: Onboarding flags — read defaults to false (not yet shown) on first launch.
  // FR: Indicateurs d'accueil — la lecture retourne false (pas encore montré) au
  //     premier lancement.
  bool get disclaimerAcknowledged =>
      _prefs.getBool(_kDisclaimerAckKey) ?? false;

  Future<void> setDisclaimerAcknowledged() =>
      _prefs.setBool(_kDisclaimerAckKey, true);

  bool get backupReminderShown => _prefs.getBool(_kBackupReminderKey) ?? false;

  Future<void> setBackupReminderShown() =>
      _prefs.setBool(_kBackupReminderKey, true);

  // EN: User preferences (FR-20). All default to "not set" so a fresh install
  //     follows the phone (locale) and framework defaults (theme = system, scale
  //     = 1.0), never a value chosen behind the user's back.
  // FR: Préférences utilisateur (FR-20). Toutes par défaut « non définies » pour
  //     qu'une nouvelle installation suive le téléphone (locale) et les défauts du
  //     framework (thème = système, échelle = 1,0), jamais une valeur choisie dans
  //     le dos de l'utilisateur.
  String? get localeCode => _prefs.getString(_kLocaleKey);

  Future<void> setLocaleCode(String? code) async {
    if (code == null) {
      await _prefs.remove(_kLocaleKey);
    } else {
      await _prefs.setString(_kLocaleKey, code);
    }
  }

  String get themeModeName => _prefs.getString(_kThemeModeKey) ?? 'system';

  Future<void> setThemeModeName(String name) =>
      _prefs.setString(_kThemeModeKey, name);

  bool get highContrast => _prefs.getBool(_kHighContrastKey) ?? false;

  String? get trackedPlacesJson => _prefs.getString(_kTrackedPlacesKey);

  Future<void> setTrackedPlacesJson(String? json) => json == null
      ? _write(() => _prefs.remove(_kTrackedPlacesKey))
      : _write(() => _prefs.setString(_kTrackedPlacesKey, json));

  List<String> get expandedPlaces =>
      _prefs.getStringList(_kExpandedPlacesKey) ?? const [];

  Future<void> setExpandedPlaces(List<String> codes) =>
      _prefs.setStringList(_kExpandedPlacesKey, codes);

  String? get homeBaseJson => _prefs.getString(_kHomeBaseKey);

  Future<void> setHomeBaseJson(String json) =>
      _write(() => _prefs.setString(_kHomeBaseKey, json));

  bool get placesNoteShown => _prefs.getBool(_kPlacesNoteKey) ?? false;

  Future<void> setPlacesNoteShown() => _prefs.setBool(_kPlacesNoteKey, true);

  Future<void> setHighContrast(bool value) =>
      _prefs.setBool(_kHighContrastKey, value);

  double get textScale => _prefs.getDouble(_kTextScaleKey) ?? 1.0;

  Future<void> setTextScale(double value) =>
      _prefs.setDouble(_kTextScaleKey, value);
}
