// EN: A day visit (WRK-5): being in another place on one date without moving
//     there, such as working across a river, shopping or an appointment. It counts
//     as presence by "any part of the day" only: by "end of day" the person was
//     back where their stay is. One entry instead of a stay out and a stay back
//     spares a commuter dozens of entries.
// FR: Une visite d'un jour (WRK-5) : être dans un autre lieu à une date donnée sans
//     y déménager, par exemple travailler de l'autre côté d'une rivière, faire des
//     courses ou aller à un rendez-vous. Elle compte comme présence seulement selon
//     « toute partie du jour » : selon « fin de journée », la personne était
//     revenue là où se trouve son séjour. Une seule entrée au lieu d'un séjour aller
//     et d'un séjour retour épargne des dizaines d'entrées à un navetteur.

import 'package:uuid/uuid.dart';

import 'package:snowbird_in_usa_tracker/models/place.dart';
import 'package:snowbird_in_usa_tracker/models/trip.dart';

class DayVisit {
  final String id;

  // EN: The calendar date of the visit, with no time part (CNT-7: dates are local
  //     to the place and never shifted by time zones).
  // FR: La date calendaire de la visite, sans heure (CNT-7 : les dates sont
  //     locales au lieu et jamais décalées par les fuseaux horaires).
  final DateTime date;

  final Place place;

  // EN: Actual or planned, with the same meaning as for a stay: a planned visit
  //     never counts in an actual figure.
  // FR: Réelle ou planifiée, avec le même sens que pour un séjour : une visite
  //     planifiée ne compte jamais dans un chiffre réel.
  final TripStatus status;

  DayVisit({
    required this.id,
    required DateTime date,
    required this.place,
    this.status = TripStatus.actual,
  }) : date = DateTime(date.year, date.month, date.day);

  // EN: New visits get a locally generated identifier, like stays (no network).
  // FR: Les nouvelles visites reçoivent un identifiant généré localement, comme
  //     les séjours (aucun réseau).
  factory DayVisit.create({
    required DateTime date,
    required Place place,
    TripStatus status = TripStatus.actual,
  }) =>
      DayVisit(id: const Uuid().v4(), date: date, place: place, status: status);

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': '${date.year.toString().padLeft(4, '0')}-'
            '${date.month.toString().padLeft(2, '0')}-'
            '${date.day.toString().padLeft(2, '0')}',
        'place': place.code,
        'status': status.name,
      };

  // EN: Every field is required and checked: a visit with no date or place is
  //     damage, and FormatException lets storage quarantine it.
  // FR: Chaque champ est requis et vérifié : une visite sans date ni lieu est un
  //     dommage, et FormatException permet au stockage de la mettre en quarantaine.
  factory DayVisit.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final date = json['date'];
    final place = json['place'];
    final status = json['status'];
    if (id is! String || id.isEmpty) {
      throw const FormatException('Visit JSON is missing a non-empty "id".');
    }
    final parsed = date is String ? DateTime.tryParse(date) : null;
    if (parsed == null) {
      throw const FormatException('Visit JSON is missing a valid "date".');
    }
    if (place is! String) {
      throw const FormatException('Visit JSON is missing a "place".');
    }
    final TripStatus parsedStatus;
    try {
      parsedStatus = TripStatus.values.byName(status as String);
    } catch (_) {
      throw FormatException('Unknown visit status: "$status".');
    }
    return DayVisit(
      id: id,
      date: parsed,
      place: Place.parse(place),
      status: parsedStatus,
    );
  }
}
