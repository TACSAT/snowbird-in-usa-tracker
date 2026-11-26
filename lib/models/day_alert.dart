// EN: Data model for a user-defined day-count alert. POSITIONING (PLAN.md):
//     every value here is chosen by the user — the app ships with ZERO built-in
//     alerts, zero default thresholds, and the notification wording is neutral
//     ("you have reached the target you set"), never a judgment. An alert says
//     "notify me when I reach [thresholdDays] days within the rolling
//     [windowDays]-day window, delivered at [hour]:[minute] local time,
//     [leadDays] days and [leadHours] hours before the projected reach date"
//     (both leads zero = on the day itself).
//
//     SECURITY: every numeric field is validated against InputLimits in the
//     constructor, so an out-of-range value can never exist in a constructed
//     instance — whether it arrives from the UI, from stored JSON, or from an
//     imported backup file (untrusted input). fromJson() converts those
//     ArgumentErrors into FormatExceptions so StorageService can skip corrupt
//     records without crashing, exactly like Trip.fromJson.
//
// FR: Modèle de données d'une alerte de compte de jours définie par
//     l'utilisateur. POSITIONNEMENT (PLAN.md) : chaque valeur ici est choisie
//     par l'utilisateur — l'appli ne livre AUCUNE alerte intégrée, aucun seuil
//     par défaut, et le libellé de la notification est neutre (« vous avez
//     atteint la cible que vous avez fixée »), jamais un jugement. Une alerte
//     dit : « m'aviser quand j'atteins [thresholdDays] jours dans la fenêtre
//     glissante de [windowDays] jours, livré à [hour]:[minute] heure locale,
//     [leadDays] jours et [leadHours] heures avant la date d'atteinte projetée »
//     (les deux avances à zéro = le jour même).
//
//     SÉCURITÉ : chaque champ numérique est validé contre InputLimits dans le
//     constructeur, donc une valeur hors plage ne peut jamais exister dans une
//     instance construite — qu'elle vienne de l'interface, du JSON stocké ou
//     d'un fichier de sauvegarde importé (entrée non fiable). fromJson()
//     convertit ces ArgumentError en FormatException pour que StorageService
//     puisse ignorer les enregistrements corrompus sans planter, exactement
//     comme Trip.fromJson.

import 'package:uuid/uuid.dart';

import 'package:snowbird_in_usa_tracker/logic/input_limits.dart';
import 'package:snowbird_in_usa_tracker/logic/presence_ledger.dart';
import 'package:snowbird_in_usa_tracker/models/place.dart';

// EN: What KIND of target this alert measures (FR-9 vs FR-10):
//     • dayCountThreshold — "notify me at N days within the last M-day rolling
//       window" (the original alert; uses thresholdDays AND windowDays), and
//     • sinceLastVisit — "notify me when it has been N days since my last actual US
//       visit" (uses thresholdDays as the elapsed-days target; windowDays is
//       ignored). Splitting on kind lets both reuse the same delivery-time / lead /
//       scheduling machinery — only the projected REACH DATE is computed differently
//       (see AlertRepository).
// FR: Quel TYPE de cible cette alerte mesure (FR-9 vs FR-10) :
//     • dayCountThreshold — « m'aviser à N jours dans la fenêtre glissante de M
//       jours » (l'alerte d'origine ; utilise thresholdDays ET windowDays), et
//     • sinceLastVisit — « m'aviser quand il s'est écoulé N jours depuis mon dernier
//       séjour réel aux É.-U. » (utilise thresholdDays comme cible de jours écoulés ;
//       windowDays est ignoré). Séparer par type permet aux deux de réutiliser la
//       même machinerie heure/préavis/planification — seule la DATE D'ATTEINTE
//       projetée est calculée différemment (voir AlertRepository).
enum AlertKind { dayCountThreshold, sinceLastVisit }

// EN: What a day-count alert counts (WRK-10): days present, or days worked
//     (offered only when days worked are turned on).
// FR: Ce que compte une alerte de jours (WRK-10) : les jours de présence, ou
//     les jours travaillés (proposés seulement si ceux-ci sont activés).
enum AlertMeasure { present, worked }

// EN: Maximum length of the optional user label — a modest cap so a crafted
//     backup file cannot smuggle megabytes of text into storage or the
//     notification body.
// FR: Longueur maximale de l'étiquette optionnelle — un plafond modeste pour
//     qu'un fichier de sauvegarde forgé ne puisse pas glisser des mégaoctets de
//     texte dans le stockage ou le corps de la notification.
const int kMaxAlertLabelLength = 80;

class DayAlert {
  final String id;

  // EN: Optional user-written name for the alert (e.g. "OHIP margin"). Trimmed;
  //     null when blank. Capped at kMaxAlertLabelLength.
  // FR: Nom optionnel écrit par l'utilisateur (p. ex. « marge RAMQ »). Épuré ;
  //     null si vide. Plafonné à kMaxAlertLabelLength.
  final String? label;

  // EN: The user's own target: notify at this many days…
  // FR: La cible de l'utilisateur : aviser à ce nombre de jours…
  final int thresholdDays;

  // EN: …counted within this rolling window (in days, ending on the evaluated
  //     date). E.g. "the last 36 months" is entered as ~1 095 days.
  // FR: …comptés dans cette fenêtre glissante (en jours, se terminant à la date
  //     évaluée). P. ex. « les 36 derniers mois » se saisit comme ~1 095 jours.
  final int windowDays;

  // EN: Local wall-clock delivery time. There is no default — the UI suggests
  //     09:00 but the user always confirms the choice explicitly.
  // FR: Heure locale de livraison. Aucune valeur par défaut — l'interface
  //     suggère 09:00 mais l'utilisateur confirme toujours explicitement.
  final int hour;
  final int minute;

  // EN: Advance notice before the projected reach date: whole days plus a finer
  //     hour adjustment. Both zero = notify on the reach day itself.
  // FR: Préavis avant la date d'atteinte projetée : jours entiers plus un
  //     ajustement fin en heures. Les deux à zéro = aviser le jour même.
  final int leadDays;
  final int leadHours;

  // EN: A disabled alert is kept (the user's numbers are preserved) but never
  //     scheduled.
  // FR: Une alerte désactivée est conservée (les nombres de l'utilisateur sont
  //     préservés) mais jamais planifiée.
  final bool enabled;

  // EN: Which kind of target this is (FR-9 rolling day-count vs FR-10 elapsed time
  //     since the last actual visit). For sinceLastVisit, [thresholdDays] is the
  //     elapsed-days target and [windowDays] is ignored.
  // FR: Quel type de cible (compte glissant FR-9 vs temps écoulé FR-10 depuis le
  //     dernier séjour réel). Pour sinceLastVisit, [thresholdDays] est la cible de
  //     jours écoulés et [windowDays] est ignoré.
  final AlertKind kind;

  // EN: The place the alert watches, and how its days are counted (FEA-1).
  //     Alerts saved before places existed read as the United States, any part
  //     of the day: exactly what they measured then.
  // FR: Le lieu que surveille l'alerte, et la façon d'en compter les jours
  //     (FEA-1). Les alertes enregistrées avant les lieux se lisent comme les
  //     États-Unis, toute partie du jour : exactement ce qu'elles mesuraient.
  final Place place;
  final CountingConvention convention;
  final AlertMeasure measure;

  // EN: Direct constructor — validates EVERY numeric field against InputLimits
  //     and throws ArgumentError on violation. Prefer DayAlert.create() for new
  //     alerts (generates the UUID); use this one when round-tripping from
  //     storage or in tests with fixed IDs.
  // FR: Constructeur direct — valide CHAQUE champ numérique contre InputLimits
  //     et lance ArgumentError en cas de violation. Préférer DayAlert.create()
  //     pour les nouvelles alertes (génère l'UUID) ; utiliser celui-ci lors du
  //     retour depuis le stockage ou dans les tests avec des ID fixes.
  DayAlert({
    required this.id,
    required this.thresholdDays,
    required this.windowDays,
    required this.hour,
    required this.minute,
    this.leadDays = 0,
    this.leadHours = 0,
    this.enabled = true,
    this.kind = AlertKind.dayCountThreshold,
    this.place = Place.unitedStates,
    this.convention = CountingConvention.anyPart,
    this.measure = AlertMeasure.present,
    String? label,
  }) : label = _normalizeLabel(label) {
    _requireInRange(
      'thresholdDays',
      thresholdDays,
      InputLimits.minThresholdDays,
      InputLimits.maxThresholdDays,
    );
    _requireInRange(
      'windowDays',
      windowDays,
      InputLimits.minWindowDays,
      InputLimits.maxWindowDays,
    );
    _requireInRange('hour', hour, InputLimits.minHour, InputLimits.maxHour);
    _requireInRange(
      'minute',
      minute,
      InputLimits.minMinute,
      InputLimits.maxMinute,
    );
    _requireInRange(
      'leadDays',
      leadDays,
      InputLimits.minLeadDays,
      InputLimits.maxLeadDays,
    );
    _requireInRange(
      'leadHours',
      leadHours,
      InputLimits.minLeadHours,
      InputLimits.maxLeadHours,
    );
    if (id.isEmpty) {
      throw ArgumentError.value(id, 'id', 'must not be empty');
    }
  }

  // EN: Factory for brand-new alerts created in the UI. Generates a local
  //     UUID v4 (no network — same offline-first rationale as Trip.create).
  // FR: Factory pour les nouvelles alertes créées dans l'interface. Génère un
  //     UUID v4 local (aucun réseau — même logique hors-ligne que Trip.create).
  factory DayAlert.create({
    required int thresholdDays,
    required int windowDays,
    required int hour,
    required int minute,
    int leadDays = 0,
    int leadHours = 0,
    bool enabled = true,
    AlertKind kind = AlertKind.dayCountThreshold,
    Place place = Place.unitedStates,
    CountingConvention convention = CountingConvention.anyPart,
    AlertMeasure measure = AlertMeasure.present,
    String? label,
  }) {
    return DayAlert(
      id: const Uuid().v4(),
      thresholdDays: thresholdDays,
      windowDays: windowDays,
      hour: hour,
      minute: minute,
      leadDays: leadDays,
      leadHours: leadHours,
      enabled: enabled,
      kind: kind,
      label: label,
      place: place,
      convention: convention,
      measure: measure,
    );
  }

  // EN: The exact local wall-clock moment the notification should fire, given
  //     the projected [reachDate] (a calendar date). Calendar arithmetic goes
  //     through the DateTime constructor's normalisation — NOT Duration
  //     subtraction — so "2 days before, at 09:00" stays 09:00 wall-clock even
  //     across a DST change (a Duration is absolute time and would drift an
  //     hour; see the same rule in DayCounter).
  // FR: L'instant local exact où la notification doit partir, étant donné la
  //     [reachDate] projetée (une date calendaire). L'arithmétique calendaire
  //     passe par la normalisation du constructeur DateTime — PAS par une
  //     soustraction de Duration — pour que « 2 jours avant, à 9 h » reste 9 h
  //     à l'horloge même à travers un changement d'heure (une Duration est du
  //     temps absolu et dériverait d'une heure ; même règle dans DayCounter).
  DateTime fireMomentFor(DateTime reachDate) {
    return DateTime(
      reachDate.year,
      reachDate.month,
      reachDate.day - leadDays,
      hour - leadHours,
      minute,
    );
  }

  // EN: Copy with selected fields replaced — same immutability pattern as Trip.
  //     Validation re-runs in the constructor, so a copyWith can never produce
  //     an out-of-range instance either.
  // FR: Copie avec champs choisis remplacés — même patron d'immuabilité que
  //     Trip. La validation se réexécute dans le constructeur, donc un copyWith
  //     ne peut pas non plus produire une instance hors plage.
  DayAlert copyWith({
    int? thresholdDays,
    int? windowDays,
    int? hour,
    int? minute,
    int? leadDays,
    int? leadHours,
    bool? enabled,
    AlertKind? kind,
    Place? place,
    CountingConvention? convention,
    AlertMeasure? measure,
    Object? label = _sentinel,
  }) {
    return DayAlert(
      id: id,
      thresholdDays: thresholdDays ?? this.thresholdDays,
      windowDays: windowDays ?? this.windowDays,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      leadDays: leadDays ?? this.leadDays,
      leadHours: leadHours ?? this.leadHours,
      enabled: enabled ?? this.enabled,
      kind: kind ?? this.kind,
      place: place ?? this.place,
      convention: convention ?? this.convention,
      measure: measure ?? this.measure,
      label: label == _sentinel ? this.label : label as String?,
    );
  }

  // EN: Plain JSON map for SharedPreferences storage and backup export — same
  //     conventions as Trip.toJson.
  // FR: Dictionnaire JSON brut pour le stockage SharedPreferences et
  //     l'exportation de sauvegarde — mêmes conventions que Trip.toJson.
  Map<String, dynamic> toJson() => {
        'id': id,
        'thresholdDays': thresholdDays,
        'windowDays': windowDays,
        'hour': hour,
        'minute': minute,
        'leadDays': leadDays,
        'leadHours': leadHours,
        'enabled': enabled,
        'kind': kind.name,
        'place': place.code,
        'convention': convention.name,
        'measure': measure.name,
        if (label != null) 'label': label,
      };

  // EN: Deserialise with full validation. Any missing, non-integer, or
  //     out-of-range value throws FormatException — stored data and backup
  //     files are UNTRUSTED input, and range enforcement here is what stops a
  //     crafted backup from planting values that would overflow date math or
  //     schedule pathological work (PLAN.md security note).
  // FR: Désérialiser avec validation complète. Toute valeur manquante, non
  //     entière ou hors plage lance FormatException — les données stockées et
  //     les fichiers de sauvegarde sont des entrées NON FIABLES, et c'est ce
  //     contrôle de plage qui empêche une sauvegarde forgée d'introduire des
  //     valeurs qui feraient déborder le calcul de dates ou déclencheraient un
  //     travail pathologique (note de sécurité du PLAN.md).
  factory DayAlert.fromJson(Map<String, dynamic> json) {
    int readInt(String key) {
      final v = json[key];
      // EN: Accept only genuine integers — never parse doubles or strings,
      //     which is where sneaky values (1e300, "9999999999") hide.
      // FR: N'accepter que de vrais entiers — jamais de doubles ni de chaînes,
      //     là où se cachent les valeurs sournoises (1e300, « 9999999999 »).
      if (v is! int) {
        throw FormatException('DayAlert JSON field "$key" must be an integer.');
      }
      return v;
    }

    final id = json['id'];
    if (id is! String || id.isEmpty) {
      throw const FormatException('DayAlert JSON is missing a non-empty "id".');
    }

    final enabledRaw = json['enabled'];
    if (enabledRaw is! bool) {
      throw const FormatException('DayAlert JSON "enabled" must be a boolean.');
    }

    final labelRaw = json['label'];
    if (labelRaw != null && labelRaw is! String) {
      throw const FormatException('DayAlert JSON "label" must be a string.');
    }

    // EN: Additive, migration-safe (FR-12): an alert written before this field
    //     existed has no "kind" key and loads as the original dayCountThreshold. An
    //     unrecognised value (e.g. from a newer version) also falls back rather than
    //     throwing, so one odd record never wipes the list.
    // FR: Additif, sûr pour la migration (FR-12) : une alerte écrite avant ce champ
    //     n'a pas de clé « kind » et se charge comme le dayCountThreshold d'origine.
    //     Une valeur non reconnue (p. ex. d'une version plus récente) retombe aussi
    //     par défaut plutôt que de lever, pour qu'un enregistrement étrange n'efface
    //     jamais la liste.
    final placeRaw = json['place'];
    if (placeRaw != null && placeRaw is! String) {
      throw const FormatException('DayAlert JSON "place" must be a string.');
    }
    final kindRaw = json['kind'];
    final kind = AlertKind.values.firstWhere(
      (k) => k.name == kindRaw,
      orElse: () => AlertKind.dayCountThreshold,
    );

    try {
      return DayAlert(
        id: id,
        thresholdDays: readInt('thresholdDays'),
        windowDays: readInt('windowDays'),
        hour: readInt('hour'),
        minute: readInt('minute'),
        leadDays: readInt('leadDays'),
        leadHours: readInt('leadHours'),
        enabled: enabledRaw,
        kind: kind,
        label: labelRaw as String?,
        place: placeRaw == null ? Place.unitedStates : Place.parse(placeRaw),
        convention: CountingConvention.values.firstWhere(
          (c) => c.name == json['convention'],
          orElse: () => CountingConvention.anyPart,
        ),
        measure: AlertMeasure.values.firstWhere(
          (m) => m.name == json['measure'],
          orElse: () => AlertMeasure.present,
        ),
      );
    } on ArgumentError catch (e) {
      // EN: Surface range violations as FormatException so StorageService's
      //     skip-malformed-record strategy applies uniformly.
      // FR: Remonter les violations de plage comme FormatException pour que la
      //     stratégie « ignorer l'enregistrement malformé » de StorageService
      //     s'applique uniformément.
      throw FormatException('DayAlert JSON out of range: ${e.message}');
    }
  }

  // EN: Same ID ⇒ same alert, mirroring Trip's identity semantics.
  // FR: Même ID ⇒ même alerte, reflétant la sémantique d'identité de Trip.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DayAlert && runtimeType == other.runtimeType && id == other.id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'DayAlert(id: $id, threshold: $thresholdDays d / window: $windowDays d, '
      'at $hour:${minute.toString().padLeft(2, '0')}, lead: ${leadDays}d '
      '${leadHours}h, enabled: $enabled)';

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  // EN: Trim, blank→null, and enforce the length cap. Truncation (not
  //     rejection) is deliberate: a too-long label from the UI is a usability
  //     issue, not an attack worth failing a whole import over.
  // FR: Épurer, vide→null, et appliquer le plafond de longueur. La troncature
  //     (plutôt que le rejet) est délibérée : une étiquette trop longue venant
  //     de l'interface est un problème d'ergonomie, pas une attaque justifiant
  //     l'échec d'un import entier.
  static String? _normalizeLabel(String? raw) {
    final trimmed = raw?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed.length <= kMaxAlertLabelLength
        ? trimmed
        : trimmed.substring(0, kMaxAlertLabelLength);
  }

  static void _requireInRange(String name, int value, int min, int max) {
    if (value < min || value > max) {
      throw ArgumentError.value(value, name, 'must be within $min–$max');
    }
  }
}

// EN: copyWith sentinel — same pattern and rationale as Trip's.
// FR: Sentinelle de copyWith — même patron et justification que celle de Trip.
const Object _sentinel = Object();
