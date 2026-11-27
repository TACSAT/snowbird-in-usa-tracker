// EN: Turns a stored place code into words. Every name comes from the l10n files
//     (placeName), so English and French official names live with the other
//     translations and get the same review (PLC-7). Labels never put a place
//     inside a sentence that would need "en", "au" or "à" in French (LNG-1):
//     they are names, or "Region, Country".
// FR: Transforme un code de lieu enregistré en mots. Chaque nom vient des fichiers
//     de localisation (placeName), afin que les noms officiels anglais et
//     français vivent avec les autres traductions et passent la même révision
//     (PLC-7). Les libellés ne placent jamais un lieu dans une phrase qui
//     exigerait « en », « au » ou « à » en français (LNG-1) : ce sont des noms,
//     ou « Région, Pays ».

import 'package:snowbird_in_usa_tracker/l10n/app_localizations.dart';
import 'package:snowbird_in_usa_tracker/models/place.dart';
import 'package:snowbird_in_usa_tracker/models/trip.dart';

// EN: The name of one place on its own: "Ontario", "Mexico", "Elsewhere". An
//     unknown code from a newer version shows as its code (PLC-8).
// FR: Le nom d'un lieu seul : « Ontario », « Mexique », « Ailleurs ». Un code
//     inconnu venant d'une version plus récente s'affiche tel quel (PLC-8).
String placeShortName(AppLocalizations strings, Place place) =>
    strings.placeName(place.code.replaceAll('-', '_'));

// EN: The full name: a region with its country ("Ontario, Canada"), a country
//     alone, and Elsewhere with the typed name when there is one. Used in lists
//     and for screen readers, where a bare "Georgia" or "Mexico" could mislead.
// FR: Le nom complet : une région avec son pays (« Ontario, Canada »), un pays
//     seul, et Ailleurs avec le nom saisi s'il y en a un. Utilisé dans les listes
//     et pour les lecteurs d'écran, où un simple « Géorgie » ou « Mexico »
//     pourrait induire en erreur.
String placeFullName(
  AppLocalizations strings,
  Place place, {
  String? elsewhereName,
}) {
  if (place == Place.elsewhere && (elsewhereName?.isNotEmpty ?? false)) {
    return strings.placeElsewhereNamed(elsewhereName!);
  }
  if (place.isCountry) return placeShortName(strings, place);
  return strings.placeInCountry(
    placeShortName(strings, place),
    placeShortName(strings, place.country),
  );
}

// EN: The full name of a stay's place, Elsewhere name included.
// FR: Le nom complet du lieu d'un séjour, nom « Ailleurs » compris.
String stayPlaceName(AppLocalizations strings, Trip stay) =>
    placeFullName(strings, stay.place, elsewhereName: stay.placeName);
