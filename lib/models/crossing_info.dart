// EN: Optional metadata about ONE border crossing — either the entry into the US
//     or the exit from it. A Trip carries two of these (one for arrival, one for
//     departure). EVERY field here is optional: per FR-1 only the entry and exit
//     dates are mandatory, so a user who only remembers "I drove down in November"
//     can leave all of this blank. The fields answer, for that single crossing:
//     at what time, in which time zone, where, by what means, and with which
//     carrier the user crossed.
//
//     Immutable by design, like Trip and DayAlert — there is no copyWith because
//     the whole object is small and the UI simply rebuilds a fresh one from the
//     form. An all-null instance is considered [isEmpty] and is stored as nothing
//     (Trip.toJson omits it) so empty details never bloat the file.
//
//     SECURITY (FR-5 / NFR-11): the time is range-checked (0–1439 minutes) and the
//     free-text fields are length-capped. Text over the cap is truncated rather
//     than rejected — a long value is a usability slip, not an attack worth failing
//     a whole import over — mirroring the DayAlert label policy. An out-of-range
//     time in imported JSON, by contrast, IS rejected (FormatException), because a
//     nonsense minute count is corruption, not a typo.
//
// FR: Métadonnées optionnelles sur UN passage frontalier — soit l'entrée aux
//     États-Unis, soit la sortie. Un Trip en porte deux (une pour l'arrivée, une
//     pour le départ). CHAQUE champ ici est optionnel : selon FR-1, seules les
//     dates d'entrée et de sortie sont obligatoires, donc un utilisateur qui se
//     rappelle seulement « je suis descendu en novembre » peut tout laisser vide.
//     Les champs répondent, pour ce seul passage : à quelle heure, dans quel
//     fuseau, où, par quel moyen et avec quel transporteur l'utilisateur a
//     traversé.
//
//     Immuable par conception, comme Trip et DayAlert — pas de copyWith car l'objet
//     est petit et l'interface reconstruit simplement un nouvel objet à partir du
//     formulaire. Une instance entièrement nulle est considérée [isEmpty] et n'est
//     rien stockée (Trip.toJson l'omet) pour que des détails vides ne gonflent
//     jamais le fichier.
//
//     SÉCURITÉ (FR-5 / NFR-11) : l'heure est bornée (0–1439 minutes) et les champs
//     texte libres sont plafonnés en longueur. Un texte au-delà du plafond est
//     tronqué plutôt que rejeté — une valeur trop longue est une maladresse
//     d'ergonomie, pas une attaque justifiant l'échec d'un import entier — comme la
//     politique de l'étiquette DayAlert. En revanche, une heure hors plage dans un
//     JSON importé EST rejetée (FormatException), car un nombre de minutes
//     aberrant est une corruption, pas une faute de frappe.

import 'package:snowbird_in_usa_tracker/logic/input_limits.dart';

class CrossingInfo {
  // EN: Time of the crossing as minutes since local midnight (0–1439), or null if
  //     the user did not record a time. Stored as an integer to keep validation
  //     trivial; serialised as "HH:mm" so the backup file stays human-readable.
  // FR: Heure du passage en minutes depuis minuit local (0–1439), ou null si
  //     l'utilisateur n'a pas noté d'heure. Stockée en entier pour une validation
  //     triviale ; sérialisée en « HH:mm » pour que la sauvegarde reste lisible.
  final int? timeMinutes;

  // EN: Free-text time-zone label the user associates with the crossing (e.g.
  //     "EST" or "America/Toronto"). Kept as text, not an IANA lookup, because the
  //     app never converts times across zones — this is a memory aid the user reads
  //     back, nothing the engine computes with.
  // FR: Étiquette de fuseau horaire en texte libre associée au passage (p. ex.
  //     « HNE » ou « America/Toronto »). Conservée en texte, sans recherche IANA,
  //     car l'appli ne convertit jamais les heures entre fuseaux — c'est un
  //     aide-mémoire que l'utilisateur relit, rien que le moteur calcule.
  final String? timeZone;

  // EN: Where the crossing happened (e.g. "Champlain–Lacolle", "Toronto Pearson").
  // FR: Où le passage a eu lieu (p. ex. « Champlain–Lacolle », « Toronto Pearson »).
  final String? location;

  // EN: How the user travelled (e.g. "Car", "Air", "Bus"). Free text on purpose —
  //     a dropdown would force the app to guess the user's categories and would
  //     need translating; open text lets the user write what they mean.
  // FR: Comment l'utilisateur a voyagé (p. ex. « Voiture », « Avion », « Autobus »).
  //     Texte libre volontairement — une liste déroulante forcerait l'appli à
  //     deviner les catégories de l'utilisateur et devrait être traduite ; le texte
  //     ouvert laisse l'utilisateur écrire ce qu'il veut dire.
  final String? meansOfTravel;

  // EN: The carrier or conveyance detail (e.g. "Air Canada AC123", plate number).
  // FR: Le transporteur ou le détail du moyen (p. ex. « Air Canada AC123 »,
  //     numéro de plaque).
  final String? carrier;

  const CrossingInfo({
    this.timeMinutes,
    this.timeZone,
    this.location,
    this.meansOfTravel,
    this.carrier,
  });

  // EN: True when no field is set. An empty CrossingInfo is never serialised, so
  //     the common "date only" trip stays as small in storage as it was before
  //     these fields existed.
  // FR: Vrai quand aucun champ n'est renseigné. Un CrossingInfo vide n'est jamais
  //     sérialisé, donc le séjour courant « date seulement » reste aussi petit en
  //     stockage qu'avant l'existence de ces champs.
  bool get isEmpty =>
      timeMinutes == null &&
      timeZone == null &&
      location == null &&
      meansOfTravel == null &&
      carrier == null;

  bool get isNotEmpty => !isEmpty;

  // EN: Build a normalised instance from raw UI input: trim every string, turn
  //     blanks into null, truncate to the field cap, and validate the time. This
  //     is the ONLY constructor the UI should use so the caps are always applied.
  //     Returns null when the result would be empty, so callers can store "no
  //     details" as a genuine null rather than an empty object.
  // FR: Construire une instance normalisée à partir de la saisie brute de
  //     l'interface : épurer chaque chaîne, transformer les vides en null, tronquer
  //     au plafond du champ et valider l'heure. C'est le SEUL constructeur que
  //     l'interface devrait utiliser pour que les plafonds soient toujours
  //     appliqués. Retourne null quand le résultat serait vide, afin que les
  //     appelants stockent « aucun détail » comme un vrai null plutôt qu'un objet
  //     vide.
  static CrossingInfo? fromInput({
    int? timeMinutes,
    String? timeZone,
    String? location,
    String? meansOfTravel,
    String? carrier,
  }) {
    final info = CrossingInfo(
      timeMinutes: _clampTime(timeMinutes),
      timeZone: _cap(timeZone, InputLimits.maxTimeZoneLength),
      location: _cap(location, InputLimits.maxLocationLength),
      meansOfTravel: _cap(meansOfTravel, InputLimits.maxMeansOfTravelLength),
      carrier: _cap(carrier, InputLimits.maxCarrierLength),
    );
    return info.isEmpty ? null : info;
  }

  // EN: Serialise to a plain JSON map, omitting every null so the stored object
  //     carries only what the user actually entered. Time becomes "HH:mm".
  // FR: Sérialiser en dictionnaire JSON brut, en omettant chaque null pour que
  //     l'objet stocké ne porte que ce que l'utilisateur a réellement saisi.
  //     L'heure devient « HH:mm ».
  Map<String, dynamic> toJson() => {
        if (timeMinutes != null) 'time': _formatTime(timeMinutes!),
        if (timeZone != null) 'timeZone': timeZone,
        if (location != null) 'location': location,
        if (meansOfTravel != null) 'meansOfTravel': meansOfTravel,
        if (carrier != null) 'carrier': carrier,
      };

  // EN: Deserialise from a JSON map. Missing keys are fine (they mean "not
  //     recorded"). Text fields are trimmed and truncated to their caps. The time
  //     string must be a valid "HH:mm" in range if present — a malformed or
  //     out-of-range time throws FormatException so StorageService's skip-malformed
  //     strategy applies, exactly like Trip/DayAlert.
  // FR: Désérialiser depuis un dictionnaire JSON. Les clés manquantes sont
  //     acceptées (elles signifient « non renseigné »). Les champs texte sont
  //     épurés et tronqués à leurs plafonds. La chaîne d'heure doit être un
  //     « HH:mm » valide et dans la plage si elle est présente — une heure
  //     malformée ou hors plage lance FormatException pour que la stratégie
  //     « ignorer le malformé » de StorageService s'applique, comme Trip/DayAlert.
  factory CrossingInfo.fromJson(Map<String, dynamic> json) {
    return CrossingInfo(
      timeMinutes: _parseTime(json['time']),
      timeZone:
          _cap(_text(json, 'timeZone'), InputLimits.maxTimeZoneLength),
      location:
          _cap(_text(json, 'location'), InputLimits.maxLocationLength),
      meansOfTravel: _cap(
        _text(json, 'meansOfTravel'),
        InputLimits.maxMeansOfTravelLength,
      ),
      carrier: _cap(_text(json, 'carrier'), InputLimits.maxCarrierLength),
    );
  }

  // EN: Format minutes-of-day as a zero-padded 24-hour "HH:mm".
  // FR: Formater les minutes de la journée en « HH:mm » 24 h à zéros initiaux.
  String get formattedTime =>
      timeMinutes == null ? '' : _formatTime(timeMinutes!);

  @override
  String toString() =>
      'CrossingInfo(time: ${timeMinutes == null ? '—' : _formatTime(timeMinutes!)}, '
      'tz: $timeZone, loc: $location, means: $meansOfTravel, carrier: $carrier)';

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  // EN: Read an optional string, rejecting other types with the FormatException the
  //     storage layer expects instead of an uncaught TypeError.
  // FR: Lire une chaîne optionnelle, en rejetant les autres types par la
  //     FormatException attendue du stockage plutôt qu'une TypeError non gérée.
  static String? _text(Map<String, dynamic> json, String key) {
    final raw = json[key];
    if (raw == null || raw is String) return raw as String?;
    throw FormatException('CrossingInfo "$key" must be a string.');
  }

  // EN: Trim, blank→null, truncate to [max]. Never throws — over-length is a
  //     usability matter, not a corruption.
  // FR: Épurer, vide→null, tronquer à [max]. Ne lance jamais — trop long est une
  //     question d'ergonomie, pas une corruption.
  static String? _cap(String? raw, int max) {
    final trimmed = raw?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed.length <= max ? trimmed : trimmed.substring(0, max);
  }

  // EN: Accept an in-range minute count or null; anything out of range from the UI
  //     is treated as "not set" (the UI validates first, so this is belt-and-braces).
  // FR: Accepter un nombre de minutes dans la plage ou null ; toute valeur hors
  //     plage venant de l'interface est traitée comme « non renseignée »
  //     (l'interface valide d'abord ; ceci est une ceinture-et-bretelles).
  static int? _clampTime(int? m) {
    if (m == null) return null;
    if (m < InputLimits.minMinuteOfDay || m > InputLimits.maxMinuteOfDay) {
      return null;
    }
    return m;
  }

  // EN: Parse a stored "HH:mm" into minutes-of-day, validating range. Returns null
  //     for an absent value; throws FormatException for a malformed or out-of-range
  //     one (untrusted stored/imported input).
  // FR: Analyser un « HH:mm » stocké en minutes de la journée, en validant la
  //     plage. Retourne null pour une valeur absente ; lance FormatException pour
  //     une valeur malformée ou hors plage (entrée stockée/importée non fiable).
  static int? _parseTime(Object? raw) {
    if (raw == null) return null;
    if (raw is! String) {
      throw const FormatException(
        'CrossingInfo "time" must be an "HH:mm" string.',
      );
    }
    final parts = raw.split(':');
    if (parts.length != 2) {
      throw FormatException('CrossingInfo "time" is not "HH:mm": "$raw".');
    }
    final h = int.tryParse(parts[0]);
    final min = int.tryParse(parts[1]);
    if (h == null || min == null) {
      throw FormatException(
        'CrossingInfo "time" has non-numeric parts: "$raw".',
      );
    }
    if (h < 0 || h > 23 || min < 0 || min > 59) {
      throw FormatException('CrossingInfo "time" out of range: "$raw".');
    }
    return h * 60 + min;
  }

  // EN: Minutes-of-day → "HH:mm".
  // FR: Minutes de la journée → « HH:mm ».
  static String _formatTime(int minutesOfDay) {
    final h = (minutesOfDay ~/ 60).toString().padLeft(2, '0');
    final m = (minutesOfDay % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }
}
