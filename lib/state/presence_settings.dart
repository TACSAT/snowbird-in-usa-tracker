// EN: The user's choices for the Days present table and the home base:
//     which places are tracked, in what order and by which convention (TBL-4,
//     CNT-1); which countries are expanded (TBL-2: remembered); and the home
//     base periods with an on/off switch (section 6, off by default). Turning
//     the home base off keeps its periods, so turning it back on loses nothing.
// FR: Les choix de l'utilisateur pour le tableau des jours de présence et le
//     lieu de résidence : quels lieux sont suivis, dans quel ordre et selon
//     quelle convention (TBL-4, CNT-1) ; quels pays sont dépliés (TBL-2 :
//     mémorisé) ; et les périodes du lieu de résidence avec un interrupteur
//     (section 6, désactivé par défaut). Désactiver le lieu de résidence garde
//     ses périodes ; le réactiver ne perd donc rien.

import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:snowbird_in_usa_tracker/models/home_base.dart';
import 'package:snowbird_in_usa_tracker/models/place.dart';
import 'package:snowbird_in_usa_tracker/models/tracked_place.dart';
import 'package:snowbird_in_usa_tracker/services/storage_service.dart';

class PresenceSettings extends ChangeNotifier {
  // EN: A ceiling on tracked places, like every other list in the app: more
  //     than the four countries' regions together would never be readable.
  // FR: Un plafond de lieux suivis, comme pour toute autre liste de
  //     l'application : plus que l'ensemble des régions des quatre pays ne
  //     serait jamais lisible.
  static const int maxTracked = 120;

  final StorageService _storage;
  List<TrackedPlace>? _tracked;
  Set<String> _expanded = {};
  bool _homeEnabled = false;
  List<HomePeriod> _homePeriods = [];

  PresenceSettings(this._storage) {
    _tracked = _readTracked();
    _expanded = {..._storage.expandedPlaces};
    _readHome();
  }

  // EN: Null means automatic (places with recorded days, TBL-4).
  // FR: Null signifie automatique (lieux ayant des jours enregistrés, TBL-4).
  List<TrackedPlace>? get tracked =>
      _tracked == null ? null : List.unmodifiable(_tracked!);

  bool isExpanded(Place place) => _expanded.contains(place.code);

  bool get homeEnabled => _homeEnabled;

  List<HomePeriod> get homePeriods => List.unmodifiable(
        [..._homePeriods]..sort((a, b) => a.from.compareTo(b.from)),
      );

  // EN: What the engine receives: the periods when on, nothing when off.
  // FR: Ce que reçoit le moteur : les périodes si activé, rien sinon.
  HomeBase get home => _homeEnabled ? HomeBase(_homePeriods) : HomeBase.none;

  // EN: Switch between automatic and a chosen list. A new chosen list starts
  //     from [initial] (what the table shows now), so nothing jumps.
  // FR: Basculer entre automatique et une liste choisie. Une nouvelle liste
  //     choisie part de [initial] (ce que le tableau montre maintenant), afin
  //     que rien ne bouge.
  Future<void> setAutomatic(bool automatic, {List<Place> initial = const []}) =>
      _saveTracked(
        automatic ? null : [for (final p in initial) TrackedPlace(p)],
      );

  Future<void> addTracked(Place place) async {
    final list = [...?_tracked];
    if (list.any((t) => t.place == place) || list.length >= maxTracked) {
      return;
    }
    await _saveTracked([...list, TrackedPlace(place)]);
  }

  Future<void> removeTracked(Place place) =>
      _saveTracked([...?_tracked]..removeWhere((t) => t.place == place));

  Future<void> updateTracked(TrackedPlace updated) => _saveTracked([
        for (final t in [...?_tracked]) t.place == updated.place ? updated : t,
      ]);

  // EN: Move an entry one step up (-1) or down (+1). Buttons, not dragging,
  //     so that it works with a screen reader and one hand (PRN-5, ACC-1).
  // FR: Déplacer une entrée d'un cran vers le haut (-1) ou le bas (+1). Des
  //     boutons, pas de glisser, afin que cela fonctionne avec un lecteur
  //     d'écran et d'une seule main (PRN-5, ACC-1).
  Future<void> moveTracked(Place place, int step) async {
    final list = [...?_tracked];
    final i = list.indexWhere((t) => t.place == place);
    final j = i + step;
    if (i == -1 || j < 0 || j >= list.length) return;
    final item = list.removeAt(i);
    list.insert(j, item);
    await _saveTracked(list);
  }

  Future<void> setExpanded(Place place, bool expanded) async {
    expanded ? _expanded.add(place.code) : _expanded.remove(place.code);
    notifyListeners();
    await _storage.setExpandedPlaces(_expanded.toList()..sort());
  }

  // EN: The home base can be turned on only once it has a place (HOM-1).
  // FR: Le lieu de résidence ne peut être activé qu'une fois doté d'un lieu
  //     (HOM-1).
  Future<void> setHomeEnabled(bool enabled) async {
    if (enabled && _homePeriods.isEmpty) return;
    await _saveHome(enabled, _homePeriods);
  }

  // EN: Adding the first period turns the home base on: that is why it is
  //     being added. A period on the same date as another replaces it.
  // FR: Ajouter la première période active le lieu de résidence : c'est pour
  //     cela qu'on l'ajoute. Une période à la même date qu'une autre la
  //     remplace.
  Future<void> addHomePeriod(HomePeriod period) => _saveHome(
        _homePeriods.isEmpty ? true : _homeEnabled,
        [
          for (final p in _homePeriods)
            if (p.from != period.from) p,
          period,
        ],
      );

  Future<void> removeHomePeriod(HomePeriod period) {
    final rest = [
      for (final p in _homePeriods)
        if (!identical(p, period) && p.from != period.from) p,
    ];
    return _saveHome(rest.isEmpty ? false : _homeEnabled, rest);
  }

  // EN: Memory changes only after the device accepted the write, as for stays.
  // FR: La mémoire ne change qu'après l'écriture acceptée, comme pour les
  //     séjours.
  Future<void> _saveTracked(List<TrackedPlace>? list) async {
    await _storage.setTrackedPlacesJson(
      list == null ? null : jsonEncode([for (final t in list) t.toJson()]),
    );
    _tracked = list;
    notifyListeners();
  }

  Future<void> _saveHome(bool enabled, List<HomePeriod> periods) async {
    await _storage.setHomeBaseJson(
      jsonEncode({
        'enabled': enabled,
        'periods': [for (final p in periods) p.toJson()],
      }),
    );
    _homeEnabled = enabled;
    _homePeriods = [...periods];
    notifyListeners();
  }

  List<TrackedPlace>? _readTracked() {
    final raw = _storage.trackedPlacesJson;
    if (raw == null) return null;
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return [
        for (final item in list.take(maxTracked))
          TrackedPlace.fromJson(item as Map<String, dynamic>),
      ];
    } catch (_) {
      return null;
    }
  }

  void _readHome() {
    final raw = _storage.homeBaseJson;
    if (raw == null) return;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final periods = [
        for (final item in map['periods'] as List<dynamic>)
          HomePeriod.fromJson(item as Map<String, dynamic>),
      ];
      _homePeriods = periods;
      _homeEnabled = map['enabled'] == true && periods.isNotEmpty;
    } catch (_) {
      _homePeriods = [];
      _homeEnabled = false;
    }
  }
}
