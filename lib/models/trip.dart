// EN: Core data model for a single US trip. Immutable by design — mutations always
//     produce a new instance via copyWith(). All dates are stored as calendar-only
//     DateTime values (no time component) to avoid timezone-driven off-by-one errors;
//     we care about which day the user crossed the border, not what time.
//
// FR: Modèle de données principal pour un séjour aux États-Unis. Immuable par
//     conception — les mutations produisent toujours une nouvelle instance via
//     copyWith(). Toutes les dates sont des DateTime sans composante horaire afin
//     d'éviter les erreurs d'un jour causées par les fuseaux horaires ; ce qui
//     importe c'est le jour où l'utilisateur a franchi la frontière, pas l'heure.

import 'package:uuid/uuid.dart';

// EN: Distinguishes trips that have already happened from those the user intends
//     to take. UI and day-counter logic treat them differently — planned trips can
//     be included or excluded from counts depending on the view.
// FR: Distingue les séjours déjà effectués de ceux que l'utilisateur prévoit.
//     L'interface et la logique de comptage les traitent différemment — les séjours
//     planifiés peuvent être inclus ou exclus des totaux selon la vue.
enum TripStatus { actual, planned }

class Trip {
  final String id;
  final DateTime arrivalDate;
  final DateTime departureDate;
  final TripStatus status;
  final String? notes;

  // EN: Direct constructor — prefer Trip.create() for new trips (it generates a
  //     UUID and strips time components). Use this constructor only when
  //     round-tripping from storage (Trip.fromJson) or in tests with fixed IDs.
  // FR: Constructeur direct — préférer Trip.create() pour les nouveaux séjours
  //     (il génère un UUID et supprime la composante horaire). Utiliser ce
  //     constructeur uniquement lors du retour depuis le stockage (Trip.fromJson)
  //     ou dans les tests avec des ID fixes.
  const Trip({
    required this.id,
    required this.arrivalDate,
    required this.departureDate,
    required this.status,
    this.notes,
  });

  // EN: Factory constructor for creating brand-new trips at runtime. Generates a
  //     UUID v4 locally — no network call, no external service — so the app stays
  //     fully offline and IDs are guaranteed unique per device.
  // FR: Constructeur factory pour créer de nouveaux séjours à l'exécution. Génère
  //     un UUID v4 localement — sans appel réseau ni service externe — pour que
  //     l'appli reste entièrement hors-ligne et que les identifiants soient
  //     garantis uniques par appareil.
  factory Trip.create({
    required DateTime arrivalDate,
    required DateTime departureDate,
    required TripStatus status,
    String? notes,
  }) {
    if (!departureDate.isAtSameMomentAs(arrivalDate) &&
        departureDate.isBefore(arrivalDate)) {
      throw ArgumentError(
        'departureDate ($departureDate) must not precede arrivalDate ($arrivalDate).',
      );
    }
    return Trip(
      id: const Uuid().v4(),
      arrivalDate: _dateOnly(arrivalDate),
      departureDate: _dateOnly(departureDate),
      status: status,
      notes: notes?.trim().isEmpty == true ? null : notes?.trim(),
    );
  }

  // EN: Days in the US for this trip, arrival and departure both counted. This
  //     mirrors the convention used by CBP and the IRS Substantial Presence Test
  //     (both the day you enter and the day you leave count as a US day).
  //     The subtraction is anchored in UTC because the stored dates are LOCAL
  //     midnights: across a DST spring-forward they are 23 hours apart and a raw
  //     difference().inDays would silently drop a day (e.g. Mar 8 – Mar 10 in a
  //     DST zone would report 2 days instead of 3). UTC has no DST.
  // FR: Jours passés aux États-Unis pour ce séjour, arrivée et départ inclus. Cette
  //     convention correspond à celle utilisée par le CBP et l'IRS Substantial
  //     Presence Test (le jour d'entrée et le jour de sortie comptent tous les deux).
  //     La soustraction est ancrée en UTC car les dates stockées sont des minuits
  //     LOCAUX : à travers un passage à l'heure d'été elles sont séparées de
  //     23 heures et difference().inDays brut perdrait silencieusement un jour
  //     (p. ex. 8 – 10 mars dans un fuseau à heure d'été donnerait 2 jours au
  //     lieu de 3). L'UTC n'a pas d'heure d'été.
  int get daysInUS =>
      DateTime.utc(departureDate.year, departureDate.month, departureDate.day)
          .difference(
            DateTime.utc(
              arrivalDate.year,
              arrivalDate.month,
              arrivalDate.day,
            ),
          )
          .inDays +
      1;

  // EN: Return a new Trip with selected fields replaced. All unchanged fields are
  //     copied from the original — callers never mutate the instance directly.
  // FR: Retourner un nouveau Trip avec les champs sélectionnés remplacés. Tous les
  //     champs inchangés sont copiés de l'original — les appelants ne mutent jamais
  //     l'instance directement.
  Trip copyWith({
    String? id,
    DateTime? arrivalDate,
    DateTime? departureDate,
    TripStatus? status,
    Object? notes = _sentinel,
  }) {
    return Trip(
      id: id ?? this.id,
      arrivalDate: arrivalDate != null ? _dateOnly(arrivalDate) : this.arrivalDate,
      departureDate:
          departureDate != null ? _dateOnly(departureDate) : this.departureDate,
      status: status ?? this.status,
      notes: notes == _sentinel ? this.notes : notes as String?,
    );
  }

  // EN: Serialize to a plain JSON map for SharedPreferences storage and backup
  //     export. Dates are YYYY-MM-DD strings — human-readable, timezone-neutral,
  //     and easy to verify in a text editor or spreadsheet.
  // FR: Sérialiser en dictionnaire JSON brut pour le stockage SharedPreferences et
  //     l'exportation de sauvegarde. Les dates sont des chaînes AAAA-MM-JJ —
  //     lisibles par l'humain, neutres par rapport au fuseau horaire et faciles à
  //     vérifier dans un éditeur de texte ou un tableur.
  Map<String, dynamic> toJson() => {
        'id': id,
        'arrivalDate': _isoDate(arrivalDate),
        'departureDate': _isoDate(departureDate),
        'status': status.name,
        if (notes != null) 'notes': notes,
      };

  // EN: Deserialize from a JSON map, validating every required field. Throws a
  //     FormatException on any malformed data so StorageService can catch it and
  //     skip or reject the record without crashing the app.
  // FR: Désérialiser depuis un dictionnaire JSON en validant chaque champ
  //     obligatoire. Lance une FormatException sur toute donnée malformée afin que
  //     StorageService puisse l'intercepter et ignorer ou rejeter l'enregistrement
  //     sans faire planter l'appli.
  factory Trip.fromJson(Map<String, dynamic> json) {
    final arrival = DateTime.tryParse(json['arrivalDate'] as String? ?? '');
    final departure = DateTime.tryParse(json['departureDate'] as String? ?? '');

    if (arrival == null) {
      throw const FormatException('Trip JSON is missing a valid "arrivalDate".');
    }
    if (departure == null) {
      throw const FormatException('Trip JSON is missing a valid "departureDate".');
    }
    if (departure.isBefore(arrival)) {
      throw FormatException(
        'Trip "departureDate" (${_isoDate(departure)}) precedes '
        '"arrivalDate" (${_isoDate(arrival)}).',
      );
    }

    final statusRaw = json['status'] as String? ?? '';
    final TripStatus status;
    try {
      status = TripStatus.values.byName(statusRaw);
    } catch (_) {
      throw FormatException('Unknown trip status: "$statusRaw".');
    }

    final id = json['id'] as String?;
    if (id == null || id.isEmpty) {
      throw const FormatException('Trip JSON is missing a non-empty "id".');
    }

    return Trip(
      id: id,
      arrivalDate: _dateOnly(arrival),
      departureDate: _dateOnly(departure),
      status: status,
      notes: json['notes'] as String?,
    );
  }

  // EN: Trips are equal if they share the same ID — the other fields can differ
  //     between an old and a newly-updated copy.
  // FR: Deux séjours sont égaux s'ils partagent le même identifiant — les autres
  //     champs peuvent différer entre une ancienne et une nouvelle copie mise à jour.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Trip && runtimeType == other.runtimeType && id == other.id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Trip(id: $id, arrival: ${_isoDate(arrivalDate)}, '
      'departure: ${_isoDate(departureDate)}, status: ${status.name})';

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  // EN: Strip the time component so all dates in the model are midnight-anchored.
  // FR: Supprimer la composante horaire pour que toutes les dates soient ancrées
  //     à minuit.
  static DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  // EN: Format a DateTime as a YYYY-MM-DD string for JSON serialisation.
  // FR: Formater un DateTime en chaîne AAAA-MM-JJ pour la sérialisation JSON.
  static String _isoDate(DateTime dt) =>
      '${dt.year.toString().padLeft(4, '0')}-'
      '${dt.month.toString().padLeft(2, '0')}-'
      '${dt.day.toString().padLeft(2, '0')}';
}

// EN: Sentinel used by copyWith() to distinguish "caller passed null for notes"
//     from "caller did not mention notes". Without this, there's no way to
//     clear a note by passing `notes: null` — it would be ambiguous with "leave
//     notes unchanged".
// FR: Sentinelle utilisée par copyWith() pour distinguer « l'appelant a passé
//     null pour notes » de « l'appelant n'a pas mentionné notes ». Sans cela, il
//     serait impossible d'effacer une note en passant `notes: null` — ce serait
//     ambigu avec « laisser notes inchangé ».
const Object _sentinel = Object();
