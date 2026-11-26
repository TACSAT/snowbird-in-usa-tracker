// EN: Optional home base (REQUIREMENTS-places.md section 6), off by default. When
//     set, a past date with no recorded stay counts for the home place as an
//     ASSUMED day: always labelled, always a separate figure, never mixed into
//     recorded days (HOM-2). Without it, a resident would have to log every day at
//     home. It is not a statement of legal residence (HOM-3).
// FR: Lieu de résidence facultatif (REQUIREMENTS-places.md, section 6), désactivé
//     par défaut. Lorsqu'il est défini, une date passée sans séjour enregistré
//     compte pour ce lieu comme jour PRÉSUMÉ : toujours étiqueté, toujours un
//     chiffre séparé, jamais mêlé aux jours enregistrés (HOM-2). Sans lui, un
//     résident devrait noter chaque jour passé chez lui. Ce n'est pas une
//     déclaration de résidence légale (HOM-3).

import 'package:snowbird_in_usa_tracker/models/place.dart';

// EN: One home place from a start date on. A move to another province is a new
//     period (HOM-1); the earlier one simply ends where the next one starts.
// FR: Un lieu de résidence à partir d'une date de début. Un déménagement dans une
//     autre province est une nouvelle période (HOM-1) ; la précédente se termine
//     simplement là où commence la suivante.
class HomePeriod {
  final Place place;
  final DateTime from;

  HomePeriod({required this.place, required DateTime from})
      : from = DateTime(from.year, from.month, from.day);

  Map<String, dynamic> toJson() => {
        'place': place.code,
        'from': '${from.year.toString().padLeft(4, '0')}-'
            '${from.month.toString().padLeft(2, '0')}-'
            '${from.day.toString().padLeft(2, '0')}',
      };

  factory HomePeriod.fromJson(Map<String, dynamic> json) {
    final place = json['place'];
    final from = json['from'];
    final parsed = from is String ? DateTime.tryParse(from) : null;
    if (place is! String || parsed == null) {
      throw const FormatException('Home period needs "place" and "from".');
    }
    return HomePeriod(place: Place.parse(place), from: parsed);
  }
}

// EN: The whole home history. Empty means the feature is off: then no day is
//     ever assumed and unrecorded days show as "not recorded" (HOM-4).
// FR: L'historique complet du lieu de résidence. Vide signifie que la fonction
//     est désactivée : alors aucun jour n'est jamais présumé et les jours non
//     enregistrés apparaissent comme « non enregistrés » (HOM-4).
class HomeBase {
  final List<HomePeriod> periods;

  HomeBase(Iterable<HomePeriod> periods)
      : periods = List.unmodifiable(
          [...periods]..sort((a, b) => a.from.compareTo(b.from)),
        );

  static final HomeBase none = HomeBase(const []);

  bool get isOff => periods.isEmpty;

  // EN: The home place on [date]: the latest period that started on or before
  //     it, or null before the first one (those dates stay "not recorded").
  // FR: Le lieu de résidence à [date] : la dernière période commencée ce jour-là
  //     ou avant, ou null avant la première (ces dates restent « non
  //     enregistrées »).
  Place? placeOn(DateTime date) {
    Place? found;
    for (final period in periods) {
      if (period.from.isAfter(date)) break;
      found = period.place;
    }
    return found;
  }
}
