// EN: Places a stay can be in (REQUIREMENTS-places.md section 4). A place is a
//     country, with or without a region (province, territory, state, federal
//     entity). It is stored as a standard ISO 3166 code, never as a name (PLC-6):
//     "US", "CA-ON", "MX-SON", "PM". Names change with the language and with
//     official renamings; a code does not, so no translation or renaming can ever
//     alter a stored record.
// FR: Lieux où peut se dérouler un séjour (REQUIREMENTS-places.md, section 4). Un
//     lieu est un pays, avec ou sans région (province, territoire, État, entité
//     fédérative). Il est enregistré sous forme de code ISO 3166 normalisé, jamais
//     sous forme de nom (PLC-6) : « US », « CA-ON », « MX-SON », « PM ». Les noms
//     changent selon la langue et les changements officiels ; un code, non. Ainsi
//     aucune traduction ni aucun changement de nom ne peut modifier un relevé.

// EN: The shape every code must have: two capital letters for the country,
//     optionally a hyphen and one to three letters or digits for the region. Only
//     the SHAPE is checked, not membership in the catalogue below: a code from a
//     newer version of the app (a region added later) must still be read, shown as
//     its code and counted, never dropped (PLC-8).
// FR: La forme que tout code doit avoir : deux majuscules pour le pays, puis
//     éventuellement un trait d'union et un à trois lettres ou chiffres pour la
//     région. Seule la FORME est vérifiée, pas l'appartenance au catalogue
//     ci-dessous : un code venant d'une version plus récente de l'application (une
//     région ajoutée plus tard) doit quand même être lu, affiché tel quel et
//     compté, jamais perdu (PLC-8).
final RegExp _placeCodeShape = RegExp(r'^[A-Z]{2}(-[A-Z0-9]{1,3})?$');

class Place {
  // EN: The full code: "CA" for a country, "CA-ON" for a region of it.
  // FR: Le code complet : « CA » pour un pays, « CA-ON » pour l'une de ses régions.
  final String code;

  const Place._(this.code);

  // EN: The countries the app knows by name. United States territories have their
  //     OWN codes (PR, VI, GU, AS, MP) and so are never part of the United States
  //     count (PLC-3): the Substantial Presence Test excludes them. Saint-Pierre-
  //     et-Miquelon is recorded as itself (PM), never as metropolitan France
  //     (PLC-4). "ZZ" is the ISO code reserved for user-assigned use; here it means
  //     "Elsewhere": any other country, so that time away is known, not blank.
  // FR: Les pays que l'application connaît par leur nom. Les territoires des
  //     États-Unis ont leurs PROPRES codes (PR, VI, GU, AS, MP) et ne font donc
  //     jamais partie du total des États-Unis (PLC-3) : le critère de présence
  //     substantielle les exclut. Saint-Pierre-et-Miquelon est enregistré pour
  //     lui-même (PM), jamais comme la France métropolitaine (PLC-4). « ZZ » est le
  //     code ISO réservé à l'usage de l'utilisateur ; ici il signifie « Ailleurs » :
  //     tout autre pays, afin que le temps passé hors des lieux suivis soit connu
  //     plutôt que vide.
  static const canada = Place._('CA');
  static const unitedStates = Place._('US');
  static const mexico = Place._('MX');
  static const saintPierreAndMiquelon = Place._('PM');
  static const elsewhere = Place._('ZZ');

  // EN: Reads a stored or typed code. Throws FormatException when the shape is
  //     wrong, so that corrupt storage is quarantined by StorageService instead of
  //     being silently counted somewhere else. Lower-case input is NOT accepted:
  //     codes are only ever written by the app itself, so anything else is
  //     damage, not a variant.
  // FR: Lit un code enregistré ou saisi. Lève FormatException quand la forme est
  //     incorrecte, afin qu'un stockage corrompu soit mis en quarantaine par
  //     StorageService plutôt que compté en silence ailleurs. Les minuscules ne
  //     sont PAS acceptées : seuls les codes écrits par l'application elle-même
  //     existent, donc tout autre chose est un dommage, pas une variante.
  factory Place.parse(String raw) {
    if (!_placeCodeShape.hasMatch(raw)) {
      throw FormatException('Not a place code: "$raw".');
    }
    return Place._(raw);
  }

  // EN: The country part of the code: "CA" for both "CA" and "CA-ON".
  // FR: La partie pays du code : « CA » pour « CA » comme pour « CA-ON ».
  String get countryCode => code.substring(0, 2);

  // EN: True for a whole country, false for a region within one.
  // FR: Vrai pour un pays entier, faux pour une région d'un pays.
  bool get isCountry => code.length == 2;

  // EN: The country this place belongs to (itself when it is a country).
  // FR: Le pays auquel ce lieu appartient (lui-même s'il s'agit d'un pays).
  Place get country => isCountry ? this : Place._(countryCode);

  // EN: Whether a stay recorded in [other] counts towards this place. A country
  //     contains itself and all of its regions; a region contains only itself. A
  //     stay recorded in the country with no region therefore counts for the
  //     country but for none of its regions (STY-8): it is never spread across
  //     regions.
  // FR: Indique si un séjour enregistré dans [other] compte pour ce lieu. Un pays
  //     contient lui-même et toutes ses régions ; une région ne contient qu'elle-
  //     même. Un séjour enregistré dans le pays sans région compte donc pour le
  //     pays mais pour aucune de ses régions (STY-8) : il n'est jamais réparti
  //     entre les régions.
  bool contains(Place other) =>
      other.code == code || (isCountry && other.countryCode == code);

  @override
  bool operator ==(Object other) => other is Place && other.code == code;

  @override
  int get hashCode => code.hashCode;

  @override
  String toString() => code;
}

// EN: The catalogue that ships in the app (PLC-8): which countries and regions are
//     offered by name. Names themselves live in the l10n files, keyed by code, so
//     this file holds no user-facing text.
// FR: Le catalogue livré avec l'application (PLC-8) : les pays et régions proposés
//     par leur nom. Les noms eux-mêmes se trouvent dans les fichiers de
//     localisation, indexés par code ; ce fichier ne contient donc aucun texte
//     destiné à l'utilisateur.
abstract final class PlaceCatalog {
  // EN: Countries offered in the chooser, in display order. The four countries of
  //     the app first; then the United States territories, which are separate
  //     entries (PLC-3); then Elsewhere.
  // FR: Pays proposés dans le sélecteur, dans l'ordre d'affichage. D'abord les
  //     quatre pays de l'application ; puis les territoires des États-Unis, qui
  //     sont des entrées distinctes (PLC-3) ; puis Ailleurs.
  static const List<Place> countries = [
    Place.canada,
    Place.unitedStates,
    Place.mexico,
    Place.saintPierreAndMiquelon,
    Place._('PR'),
    Place._('VI'),
    Place._('GU'),
    Place._('AS'),
    Place._('MP'),
    Place.elsewhere,
  ];

  // EN: The display group a country is listed under, when it differs from the
  //     country itself. Saint-Pierre-et-Miquelon is shown under France (PLC-4)
  //     and the US territories next to the United States, but this is ONLY for
  //     display: counting always uses the country's own code, so none of their
  //     days is ever added to France or to the United States.
  // FR: Le groupe d'affichage sous lequel un pays est présenté, lorsqu'il diffère
  //     du pays lui-même. Saint-Pierre-et-Miquelon apparaît sous la France (PLC-4)
  //     et les territoires américains près des États-Unis, mais c'est SEULEMENT
  //     pour l'affichage : le comptage utilise toujours le code propre du pays, de
  //     sorte qu'aucun de leurs jours n'est jamais ajouté à la France ni aux
  //     États-Unis.
  static const Map<String, String> displayGroup = {
    'PM': 'FR',
    'PR': 'US',
    'VI': 'US',
    'GU': 'US',
    'AS': 'US',
    'MP': 'US',
  };

  // EN: Regions offered per country (PLC-2), as ISO 3166-2 codes. Canada: 10
  //     provinces and 3 territories. United States: 50 states and the District of
  //     Columbia. Mexico: 32 federal entities (CMX is Mexico City since 2016).
  //     Countries absent from this map have no regions to choose from.
  // FR: Régions proposées par pays (PLC-2), en codes ISO 3166-2. Canada : 10
  //     provinces et 3 territoires. États-Unis : 50 États et le district de
  //     Columbia. Mexique : 32 entités fédératives (CMX désigne Mexico depuis
  //     2016). Les pays absents de cette table n'ont pas de régions à choisir.
  static final Map<Place, List<Place>> regions = {
    Place.canada: _regionsOf('CA', const [
      'AB', 'BC', 'MB', 'NB', 'NL', 'NS', 'NT', 'NU', 'ON', 'PE', 'QC', 'SK', //
      'YT',
    ]),
    Place.unitedStates: _regionsOf('US', const [
      'AL', 'AK', 'AZ', 'AR', 'CA', 'CO', 'CT', 'DE', 'DC', 'FL', 'GA', 'HI', //
      'ID', 'IL', 'IN', 'IA', 'KS', 'KY', 'LA', 'ME', 'MD', 'MA', 'MI', 'MN', //
      'MS', 'MO', 'MT', 'NE', 'NV', 'NH', 'NJ', 'NM', 'NY', 'NC', 'ND', 'OH', //
      'OK', 'OR', 'PA', 'RI', 'SC', 'SD', 'TN', 'TX', 'UT', 'VT', 'VA', 'WA', //
      'WV', 'WI', 'WY',
    ]),
    Place.mexico: _regionsOf('MX', const [
      'AGU', 'BCN', 'BCS', 'CAM', 'CHH', 'CHP', 'CMX', 'COA', 'COL', 'DUR', //
      'GRO', 'GUA', 'HID', 'JAL', 'MEX', 'MIC', 'MOR', 'NAY', 'NLE', 'OAX', //
      'PUE', 'QUE', 'ROO', 'SIN', 'SLP', 'SON', 'TAB', 'TAM', 'TLA', 'VER', //
      'YUC', 'ZAC',
    ]),
  };

  // EN: True when the code is one this version offers by name. False does not
  //     make a code invalid: it is then shown as its code (PLC-8).
  // FR: Vrai lorsque le code est l'un de ceux que cette version propose par leur
  //     nom. Faux ne rend pas un code invalide : il est alors affiché tel quel
  //     (PLC-8).
  static bool isKnown(Place place) => place.isCountry
      ? countries.contains(place)
      : (regions[place.country]?.contains(place) ?? false);

  static List<Place> _regionsOf(String country, List<String> suffixes) =>
      List.unmodifiable([for (final s in suffixes) Place._('$country-$s')]);
}
