// EN: A place the user chose to show in the Days present table (TBL-4), with the
//     counting convention they chose for it (CNT-1) and whether it is shown even
//     with no days (TBL-5, "pinned").
// FR: Un lieu que l'utilisateur a choisi d'afficher dans le tableau des jours de
//     présence (TBL-4), avec la convention de comptage choisie pour lui (CNT-1)
//     et le fait qu'il soit affiché même sans aucun jour (TBL-5, « épinglé »).

import 'package:snowbird_in_usa_tracker/logic/presence_ledger.dart';
import 'package:snowbird_in_usa_tracker/models/place.dart';

class TrackedPlace {
  final Place place;
  final CountingConvention convention;
  final bool pinned;

  const TrackedPlace(
    this.place, {
    this.convention = CountingConvention.anyPart,
    this.pinned = false,
  });

  TrackedPlace copyWith({CountingConvention? convention, bool? pinned}) =>
      TrackedPlace(
        place,
        convention: convention ?? this.convention,
        pinned: pinned ?? this.pinned,
      );

  Map<String, dynamic> toJson() => {
        'place': place.code,
        'convention': convention.name,
        'pinned': pinned,
      };

  // EN: A bad entry throws; the caller then falls back to the automatic list,
  //     which loses only a preference, never a record.
  // FR: Une entrée invalide lève une exception ; l'appelant revient alors à la
  //     liste automatique, ce qui ne perd qu'une préférence, jamais un relevé.
  factory TrackedPlace.fromJson(Map<String, dynamic> json) {
    final place = json['place'];
    final convention = json['convention'];
    final pinned = json['pinned'];
    if (place is! String || convention is! String || pinned is! bool) {
      throw const FormatException('Tracked place needs place, convention.');
    }
    return TrackedPlace(
      Place.parse(place),
      convention: CountingConvention.values.byName(convention),
      pinned: pinned,
    );
  }
}
