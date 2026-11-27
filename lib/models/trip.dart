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

import 'package:snowbird_in_usa_tracker/logic/input_limits.dart';
import 'package:snowbird_in_usa_tracker/models/crossing_info.dart';
import 'package:snowbird_in_usa_tracker/models/place.dart';
import 'package:snowbird_in_usa_tracker/models/work_plan.dart';

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

  // EN: Null means an OPEN stay: the user is in the US and has not left yet (FR-2).
  //     Only an actual trip may be open. A null is better than asking the user to
  //     invent a date, which would then be counted as if it had happened.
  // FR: Null signifie un séjour OUVERT : l'utilisateur est aux É.-U. et n'est pas
  //     encore reparti (FR-2). Seul un séjour réel peut être ouvert. Mieux vaut un
  //     null que de demander une date inventée, ensuite comptée comme vécue.
  final DateTime? departureDate;
  final TripStatus status;

  // EN: Optional user-given name for the trip, recording its purpose so the user
  //     can recognise it in the list (e.g. "Winter in Hallandale", "Golf week").
  //     Only the two dates are mandatory (FR-1); this and every field below may be
  //     null.
  // FR: Nom optionnel donné par l'utilisateur au séjour, consignant son but pour
  //     qu'il le reconnaisse dans la liste (p. ex. « Hiver à Hallandale »,
  //     « Semaine de golf »). Seules les deux dates sont obligatoires (FR-1) ; ce
  //     champ et tous ceux ci-dessous peuvent être null.
  final String? name;

  // EN: Free-text notes about the trip as a whole (trip-level, distinct from the
  //     per-crossing carrier/location). Length-capped on entry and import (FR-5).
  // FR: Notes en texte libre sur l'ensemble du séjour (niveau séjour, distinctes du
  //     transporteur/lieu par passage). Plafonnées en longueur à la saisie et à
  //     l'import (FR-5).
  final String? notes;

  // EN: Optional details of the ENTRY crossing (time, zone, location, means,
  //     carrier). Null when the user recorded nothing beyond the arrival date.
  // FR: Détails optionnels du passage d'ENTRÉE (heure, fuseau, lieu, moyen,
  //     transporteur). Null quand l'utilisateur n'a rien noté au-delà de la date
  //     d'arrivée.
  final CrossingInfo? arrivalInfo;

  // EN: Optional details of the EXIT crossing — same shape as [arrivalInfo].
  // FR: Détails optionnels du passage de SORTIE — même forme que [arrivalInfo].
  final CrossingInfo? departureInfo;

  // EN: Where this stay was (REQUIREMENTS-places.md section 4): a country, with or
  //     without a region. Every stay has one (PLC-1). Data written before places
  //     existed has none and is read as the United States with no region (MIG-1),
  //     which is exactly what every trip meant then; so the default here is the
  //     United States too.
  // FR: Où ce séjour a eu lieu (REQUIREMENTS-places.md, section 4) : un pays, avec
  //     ou sans région. Chaque séjour en a un (PLC-1). Les données écrites avant
  //     l'existence des lieux n'en ont pas et sont lues comme les États-Unis sans
  //     région (MIG-1), ce que chaque séjour signifiait alors ; la valeur par
  //     défaut est donc aussi les États-Unis.
  final Place place;

  // EN: Optional free-text name for a stay "Elsewhere" (PLC-5), such as
  //     "Iceland". Kept only when [place] is Elsewhere: the four countries are
  //     named by the app from their code, never by typed text.
  // FR: Nom libre facultatif pour un séjour « Ailleurs » (PLC-5), par exemple
  //     « Islande ». Conservé seulement quand [place] vaut Ailleurs : les quatre
  //     pays sont nommés par l'application à partir de leur code, jamais par du
  //     texte saisi.
  final String? placeName;

  // EN: Days worked during this stay (section 7), or null when none are
  //     recorded. Read only inside the stay's own dates (see WorkPlan).
  // FR: Jours travaillés pendant ce séjour (section 7), ou null quand aucun
  //     n'est noté. Lu seulement à l'intérieur des dates du séjour (voir
  //     WorkPlan).
  final WorkPlan? work;

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
    this.name,
    this.notes,
    this.arrivalInfo,
    this.departureInfo,
    this.place = Place.unitedStates,
    this.placeName,
    this.work,
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
    required DateTime? departureDate,
    required TripStatus status,
    String? name,
    String? notes,
    CrossingInfo? arrivalInfo,
    CrossingInfo? departureInfo,
    Place place = Place.unitedStates,
    String? placeName,
    WorkPlan? work,
  }) {
    if (departureDate == null && status == TripStatus.planned) {
      throw ArgumentError('A planned trip needs a departureDate.');
    }
    if (departureDate != null && departureDate.isBefore(arrivalDate)) {
      throw ArgumentError(
        'departureDate ($departureDate) must not precede arrivalDate ($arrivalDate).',
      );
    }
    return Trip(
      id: const Uuid().v4(),
      arrivalDate: _dateOnly(arrivalDate),
      departureDate: departureDate == null ? null : _dateOnly(departureDate),
      status: status,
      name: _capText(name, InputLimits.maxTripNameLength),
      notes: _capText(notes, InputLimits.maxNotesLength),
      // EN: Drop an all-empty CrossingInfo to null so "no details" is stored as
      //     nothing, keeping date-only trips as small as before these fields existed.
      // FR: Réduire un CrossingInfo entièrement vide à null pour que « aucun détail »
      //     soit stocké comme rien, gardant les séjours « date seulement » aussi
      //     petits qu'avant l'existence de ces champs.
      arrivalInfo: (arrivalInfo?.isEmpty ?? true) ? null : arrivalInfo,
      departureInfo: (departureInfo?.isEmpty ?? true) ? null : departureInfo,
      place: place,
      placeName: _placeNameFor(place, placeName),
      work: _workFor(work, arrivalDate, departureDate),
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
  //     Null for an open trip: its full length is not known yet.
  //     Null pour un séjour ouvert : sa durée complète n'est pas encore connue.
  int? get daysInUS {
    final departure = departureDate;
    return departure == null ? null : _inclusiveDays(arrivalDate, departure);
  }

  // EN: Days to show for this trip as of [asOf]. An actual trip is clipped to asOf
  //     because days that have not happened cannot be presence; a planned trip
  //     shows its whole intended span. This keeps each row consistent with the
  //     totals, which apply the same rule.
  // FR: Jours à afficher pour ce séjour au [asOf]. Un séjour réel est borné à asOf
  //     car des jours non vécus ne sont pas de la présence ; un séjour planifié
  //     montre toute sa durée prévue. Chaque ligne reste ainsi cohérente avec les
  //     totaux, qui appliquent la même règle.
  int daysPresent(DateTime asOf) {
    final end = effectiveEnd(asOf);
    return end.isBefore(arrivalDate) ? 0 : _inclusiveDays(arrivalDate, end);
  }

  // EN: Last day that counts as of [asOf] — the single definition of the clipping
  //     rule, shared with DayCounter. May precede the arrival: then nothing counts.
  // FR: Dernier jour compté au [asOf] — l'unique définition de la règle de bornage,
  //     partagée avec DayCounter. Peut précéder l'arrivée : alors rien ne compte.
  DateTime effectiveEnd(DateTime asOf) {
    final today = _dateOnly(asOf);
    final departure = departureDate ?? today;
    if (status == TripStatus.planned) return departure;
    return departure.isAfter(today) ? today : departure;
  }

  // EN: True while an actual stay has begun but not ended, whether it is open or
  //     has an expected departure in the future.
  // FR: Vrai tant qu'un séjour réel a commencé sans être terminé, qu'il soit ouvert
  //     ou qu'il ait un départ prévu dans le futur.
  bool isInProgress(DateTime asOf) {
    final today = _dateOnly(asOf);
    return status == TripStatus.actual &&
        !arrivalDate.isAfter(today) &&
        (departureDate?.isAfter(today) ?? true);
  }

  // EN: Two actual trips conflict when they share more than a boundary day. Leaving
  //     and re-entering on the same date is ordinary and must stay allowed, hence
  //     the strict comparisons. An open trip has no end, so it conflicts with
  //     anything departing after its arrival.
  // FR: Deux séjours réels sont en conflit s'ils partagent plus qu'un jour limite.
  //     Sortir et rentrer le même jour est courant et doit rester permis, d'où les
  //     comparaisons strictes. Un séjour ouvert n'a pas de fin : il est en conflit
  //     avec tout séjour dont le départ suit son arrivée.
  bool conflictsWith(Trip other) {
    if (status != TripStatus.actual || other.status != TripStatus.actual) {
      return false;
    }
    final end = departureDate;
    final otherEnd = other.departureDate;
    return (otherEnd == null || arrivalDate.isBefore(otherEnd)) &&
        (end == null || other.arrivalDate.isBefore(end));
  }

  // EN: Return a new Trip with selected fields replaced. All unchanged fields are
  //     copied from the original — callers never mutate the instance directly.
  // FR: Retourner un nouveau Trip avec les champs sélectionnés remplacés. Tous les
  //     champs inchangés sont copiés de l'original — les appelants ne mutent jamais
  //     l'instance directement.
  Trip copyWith({
    String? id,
    DateTime? arrivalDate,
    Object? departureDate = _sentinel,
    TripStatus? status,
    Object? name = _sentinel,
    Object? notes = _sentinel,
    Object? arrivalInfo = _sentinel,
    Object? departureInfo = _sentinel,
    Place? place,
    Object? placeName = _sentinel,
    Object? work = _sentinel,
  }) {
    final nextPlace = place ?? this.place;
    return Trip(
      id: id ?? this.id,
      arrivalDate:
          arrivalDate != null ? _dateOnly(arrivalDate) : this.arrivalDate,
      departureDate: departureDate == _sentinel
          ? this.departureDate
          : departureDate == null
              ? null
              : _dateOnly(departureDate as DateTime),
      status: status ?? this.status,
      name: name == _sentinel ? this.name : name as String?,
      notes: notes == _sentinel ? this.notes : notes as String?,
      arrivalInfo: arrivalInfo == _sentinel
          ? this.arrivalInfo
          : arrivalInfo as CrossingInfo?,
      departureInfo: departureInfo == _sentinel
          ? this.departureInfo
          : departureInfo as CrossingInfo?,
      place: nextPlace,
      // EN: Re-apply the Elsewhere-only rule, so moving a stay from Elsewhere to
      //     a named country drops a name that would no longer mean anything.
      // FR: Réappliquer la règle « Ailleurs seulement », afin que déplacer un
      //     séjour d'Ailleurs vers un pays nommé retire un nom qui n'aurait plus
      //     de sens.
      placeName: _placeNameFor(
        nextPlace,
        placeName == _sentinel ? this.placeName : placeName as String?,
      ),
      // EN: Re-clip to the (possibly new) dates: WRK-3, no worked day outside.
      // FR: Rebornée aux dates (peut-être nouvelles) : WRK-3, aucun jour
      //     travaillé hors du séjour.
      work: _workFor(
        work == _sentinel ? this.work : work as WorkPlan?,
        arrivalDate ?? this.arrivalDate,
        departureDate == _sentinel
            ? this.departureDate
            : departureDate as DateTime?,
      ),
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
        // EN: The key is always written, null included: a MISSING key is damage,
        //     and must never be mistaken for a stay that is still open.
        // FR: La clé est toujours écrite, null compris : une clé ABSENTE est un
        //     dommage et ne doit jamais passer pour un séjour encore ouvert.
        'departureDate':
            departureDate == null ? null : _isoDate(departureDate!),
        'status': status.name,
        // EN: Always written from schema version 3 on, so that a stay's place
        //     never depends on a default that a later version might change.
        // FR: Toujours écrit à partir de la version 3 du schéma, afin que le lieu
        //     d'un séjour ne dépende jamais d'une valeur par défaut qu'une version
        //     ultérieure pourrait changer.
        'place': place.code,
        if (placeName != null) 'placeName': placeName,
        if (work != null) 'work': work!.toJson(),
        if (name != null) 'name': name,
        if (notes != null) 'notes': notes,
        // EN: Only write crossing details that carry something. isNotEmpty is
        //     guaranteed by Trip.create/fromJson (they null out empties), but the
        //     guard keeps toJson honest even for hand-built instances.
        // FR: N'écrire que les détails de passage qui portent quelque chose.
        //     isNotEmpty est garanti par Trip.create/fromJson (ils annulent les
        //     vides), mais la garde garde toJson honnête même pour des instances
        //     construites à la main.
        if (arrivalInfo != null && arrivalInfo!.isNotEmpty)
          'arrivalInfo': arrivalInfo!.toJson(),
        if (departureInfo != null && departureInfo!.isNotEmpty)
          'departureInfo': departureInfo!.toJson(),
      };

  // EN: Deserialize from a JSON map, validating every required field. Throws a
  //     FormatException on any malformed data so StorageService can catch it and
  //     skip or reject the record without crashing the app.
  // FR: Désérialiser depuis un dictionnaire JSON en validant chaque champ
  //     obligatoire. Lance une FormatException sur toute donnée malformée afin que
  //     StorageService puisse l'intercepter et ignorer ou rejeter l'enregistrement
  //     sans faire planter l'appli.
  factory Trip.fromJson(Map<String, dynamic> json) {
    // EN: Every value is type-checked before use. A cast would throw TypeError,
    //     which is not the FormatException this method promises.
    // FR: Chaque valeur est vérifiée avant usage. Une conversion lancerait une
    //     TypeError, et non la FormatException que cette méthode promet.
    String? readText(String key) {
      final raw = json[key];
      if (raw == null || raw is String) return raw as String?;
      throw FormatException('Trip JSON "$key" must be a string.');
    }

    final arrival = DateTime.tryParse(readText('arrivalDate') ?? '');
    final departureRaw = readText('departureDate');
    final departure = DateTime.tryParse(departureRaw ?? '');
    final isOpen = json.containsKey('departureDate') && departureRaw == null;

    if (arrival == null) {
      throw const FormatException(
        'Trip JSON is missing a valid "arrivalDate".',
      );
    }
    if (departure == null && !isOpen) {
      throw const FormatException(
        'Trip JSON is missing a valid "departureDate".',
      );
    }
    if (departure != null && departure.isBefore(arrival)) {
      throw FormatException(
        'Trip "departureDate" (${_isoDate(departure)}) precedes '
        '"arrivalDate" (${_isoDate(arrival)}).',
      );
    }

    final statusRaw = readText('status') ?? '';
    final TripStatus status;
    try {
      status = TripStatus.values.byName(statusRaw);
    } catch (_) {
      throw FormatException('Unknown trip status: "$statusRaw".');
    }

    if (isOpen && status == TripStatus.planned) {
      throw const FormatException('A planned trip needs a "departureDate".');
    }

    final id = readText('id');
    if (id == null || id.isEmpty) {
      throw const FormatException('Trip JSON is missing a non-empty "id".');
    }

    // EN: The optional fields below are a FORWARD-COMPATIBLE (additive) schema
    //     change (FR-12): a record written by an older app version simply lacks
    //     these keys, and parseCrossing/_capText treat "absent" as "not recorded".
    //     No storage-key bump or destructive migration is needed — old data loads
    //     unchanged, and an older app reading newer data ignores keys it does not
    //     know. A malformed crossing time still throws (untrusted input), so
    //     StorageService can skip just that record.
    // FR: Les champs optionnels ci-dessous sont un changement de schéma
    //     RÉTROCOMPATIBLE (additif) (FR-12) : un enregistrement écrit par une
    //     version antérieure n'a tout simplement pas ces clés, et
    //     parseCrossing/_capText traitent « absent » comme « non renseigné ».
    //     Aucun changement de clé de stockage ni migration destructrice n'est
    //     requis — les anciennes données se chargent inchangées, et une ancienne
    //     appli lisant des données plus récentes ignore les clés inconnues. Une
    //     heure de passage malformée lance quand même (entrée non fiable), pour
    //     que StorageService puisse ignorer ce seul enregistrement.
    // EN: Migration (MIG-1): a record with no "place" key was written before
    //     places existed, when every trip was a trip to the United States. A
    //     present but malformed code is damage and throws, so the record is
    //     quarantined rather than counted in the wrong country.
    // FR: Migration (MIG-1) : un enregistrement sans clé « place » a été écrit
    //     avant l'existence des lieux, quand chaque séjour était un séjour aux
    //     États-Unis. Un code présent mais malformé est un dommage et lève une
    //     exception, afin que l'enregistrement soit mis en quarantaine plutôt que
    //     compté dans le mauvais pays.
    final placeRaw = readText('place');
    final place = placeRaw == null ? Place.unitedStates : Place.parse(placeRaw);

    // EN: Days worked: an additive key, absent in older data (no worked day).
    // FR: Jours travaillés : une clé additive, absente des anciennes données
    //     (aucun jour travaillé).
    WorkPlan? parseWork() {
      final raw = json['work'];
      if (raw == null) return null;
      if (raw is! Map<String, dynamic>) {
        throw const FormatException('Trip JSON "work" must be an object.');
      }
      return WorkPlan.fromJson(raw);
    }

    CrossingInfo? parseCrossing(String key) {
      final raw = json[key];
      if (raw == null) return null;
      if (raw is! Map<String, dynamic>) {
        throw FormatException('Trip JSON "$key" must be an object.');
      }
      final info = CrossingInfo.fromJson(raw);
      return info.isEmpty ? null : info;
    }

    return Trip(
      id: id,
      arrivalDate: _dateOnly(arrival),
      departureDate: departure == null ? null : _dateOnly(departure),
      status: status,
      name: _capText(readText('name'), InputLimits.maxTripNameLength),
      notes: _capText(readText('notes'), InputLimits.maxNotesLength),
      arrivalInfo: parseCrossing('arrivalInfo'),
      departureInfo: parseCrossing('departureInfo'),
      place: place,
      placeName: _placeNameFor(place, readText('placeName')),
      work: _workFor(
        parseWork(),
        _dateOnly(arrival),
        departure == null ? null : _dateOnly(departure),
      ),
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
  String toString() => 'Trip(id: $id, arrival: ${_isoDate(arrivalDate)}, '
      'departure: ${departureDate == null ? 'open' : _isoDate(departureDate!)}, '
      'status: ${status.name}, place: ${place.code})';

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  // EN: Trim, blank→null, truncate to [max]. Never throws — an over-length string
  //     is a usability slip, not corruption — matching CrossingInfo and the alert
  //     label policy (FR-5).
  // FR: Épurer, vide→null, tronquer à [max]. Ne lance jamais — une chaîne trop
  //     longue est une maladresse d'ergonomie, pas une corruption — comme la
  //     politique de CrossingInfo et de l'étiquette d'alerte (FR-5).
  static String? _capText(String? raw, int max) {
    final trimmed = raw?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed.length <= max ? trimmed : trimmed.substring(0, max);
  }

  // EN: Strip the time component so all dates in the model are midnight-anchored.
  // FR: Supprimer la composante horaire pour que toutes les dates soient ancrées
  //     à minuit.
  // EN: The Elsewhere name is trimmed and capped like every other free text, and
  //     kept only for a stay Elsewhere (see [placeName]).
  // FR: Le nom « Ailleurs » est épuré et plafonné comme tout autre texte libre,
  //     et conservé seulement pour un séjour Ailleurs (voir [placeName]).
  static String? _placeNameFor(Place place, String? raw) =>
      place == Place.elsewhere
          ? _capText(raw, InputLimits.maxPlaceNameLength)
          : null;

  // EN: An empty plan is stored as nothing; a real one is clipped to the stay.
  // FR: Un plan vide est enregistré comme rien ; un vrai est borné au séjour.
  static WorkPlan? _workFor(WorkPlan? work, DateTime from, DateTime? to) {
    final clipped = work?.clippedTo(from, to == null ? null : _dateOnly(to));
    return clipped == null || clipped.isEmpty ? null : clipped;
  }

  static DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  // EN: Inclusive calendar days, anchored in UTC so DST cannot drop a day.
  // FR: Jours calendaires inclusifs, ancrés en UTC pour que l'heure d'été ne
  //     fasse perdre aucun jour.
  static int _inclusiveDays(DateTime a, DateTime b) =>
      DateTime.utc(b.year, b.month, b.day)
          .difference(DateTime.utc(a.year, a.month, a.day))
          .inDays +
      1;

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
