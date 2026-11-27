// EN: The place chooser (PLC-2, PLC-9). Places are always chosen, never detected
//     (PRN-2: no location permission). Recently used places come first, so a
//     regular route is one tap; a search finds any country or region by name,
//     with or without accents; a country with regions opens its list, whose first
//     entry is the whole country with no region (STY-8: a region is optional).
// FR: Le sélecteur de lieu (PLC-2, PLC-9). Les lieux sont toujours choisis,
//     jamais détectés (PRN-2 : aucune permission de localisation). Les lieux
//     récents viennent en premier, pour qu'un trajet habituel ne demande qu'un
//     toucher ; une recherche trouve tout pays ou toute région par son nom, avec
//     ou sans accents ; un pays ayant des régions ouvre leur liste, dont la
//     première entrée est le pays entier sans région (STY-8 : la région est
//     facultative).

import 'package:flutter/material.dart';

import 'package:snowbird_in_usa_tracker/l10n/app_localizations.dart';
import 'package:snowbird_in_usa_tracker/models/place.dart';
import 'package:snowbird_in_usa_tracker/screens/place_names.dart';
import 'package:snowbird_in_usa_tracker/screens/section_heading.dart';

// EN: Opens the chooser and returns the chosen place, or null if dismissed.
//     [withinCountry] limits the choice to one country and its regions (used to
//     split a stay without changing its country).
// FR: Ouvre le sélecteur et retourne le lieu choisi, ou null s'il est fermé.
//     [withinCountry] limite le choix à un pays et à ses régions (pour diviser un
//     séjour sans changer de pays).
Future<Place?> pickPlace(
  BuildContext context, {
  List<Place> recent = const [],
  Place? withinCountry,
}) {
  final country = withinCountry?.country;
  return Navigator.of(context).push<Place>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => country == null
          ? PlacePickerScreen(recent: recent)
          : _RegionList(country: country),
    ),
  );
}

class PlacePickerScreen extends StatefulWidget {
  final List<Place> recent;

  const PlacePickerScreen({super.key, this.recent = const []});

  @override
  State<PlacePickerScreen> createState() => _PlacePickerScreenState();
}

class _PlacePickerScreenState extends State<PlacePickerScreen> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _openCountry(Place country) async {
    final navigator = Navigator.of(context);
    if (PlaceCatalog.regions[country] == null) {
      navigator.pop(country);
      return;
    }
    final chosen = await navigator.push<Place>(
      MaterialPageRoute(builder: (_) => _RegionList(country: country)),
    );
    if (chosen != null && mounted) navigator.pop(chosen);
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final query = foldForSearch(_search.text.trim());

    final List<Widget> items;
    if (query.isEmpty) {
      items = [
        if (widget.recent.isNotEmpty) ...[
          _heading(strings.placeRecent, theme),
          for (final place in widget.recent)
            _PlaceTile(
              place: place,
              title: placeFullName(strings, place),
              onTap: () => Navigator.of(context).pop(place),
            ),
        ],
        _heading(strings.placeCountries, theme),
        for (final country in PlaceCatalog.countries)
          _PlaceTile(
            place: country,
            title: placeShortName(strings, country),
            opensList: PlaceCatalog.regions[country] != null,
            onTap: () => _openCountry(country),
          ),
      ];
    } else {
      // EN: Search every country and region by its name in the current
      //     language. A matching country is offered as itself (no region).
      // FR: Chercher chaque pays et chaque région par son nom dans la langue
      //     courante. Un pays trouvé est proposé tel quel (sans région).
      final all = [
        ...PlaceCatalog.countries,
        for (final list in PlaceCatalog.regions.values) ...list,
      ];
      final found = [
        for (final place in all)
          if (foldForSearch(placeShortName(strings, place)).contains(query))
            place,
      ];
      items = found.isEmpty
          ? [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(strings.placeNoMatch),
              ),
            ]
          : [
              for (final place in found)
                _PlaceTile(
                  place: place,
                  title: placeFullName(strings, place),
                  onTap: () => Navigator.of(context).pop(place),
                ),
            ];
    }

    return Scaffold(
      appBar: AppBar(title: Text(strings.placePickerTitle)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _search,
              decoration: InputDecoration(
                labelText: strings.placeSearchHint,
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Expanded(child: ListView(children: items)),
        ],
      ),
    );
  }

  Widget _heading(String text, ThemeData theme) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        child: SectionHeading(text, style: theme.textTheme.titleSmall),
      );
}

// EN: One country's regions, sorted by name in the current language, after an
//     entry for the whole country with no region.
// FR: Les régions d'un pays, triées par nom dans la langue courante, après une
//     entrée pour le pays entier sans région.
class _RegionList extends StatelessWidget {
  final Place country;

  const _RegionList({required this.country});

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final regions = [...?PlaceCatalog.regions[country]]..sort(
        (a, b) => foldForSearch(placeShortName(strings, a))
            .compareTo(foldForSearch(placeShortName(strings, b))),
      );
    return Scaffold(
      appBar: AppBar(title: Text(placeShortName(strings, country))),
      body: ListView(
        children: [
          _PlaceTile(
            place: country,
            title: strings.placeWholeCountry(placeShortName(strings, country)),
            onTap: () => Navigator.of(context).pop(country),
          ),
          if (regions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: SectionHeading(
                strings.placeChooseRegion,
                style: theme.textTheme.titleSmall,
              ),
            ),
          for (final region in regions)
            _PlaceTile(
              place: region,
              title: placeShortName(strings, region),
              onTap: () => Navigator.of(context).pop(region),
            ),
        ],
      ),
    );
  }
}

class _PlaceTile extends StatelessWidget {
  final Place place;
  final String title;
  final bool opensList;
  final VoidCallback onTap;

  const _PlaceTile({
    required this.place,
    required this.title,
    required this.onTap,
    this.opensList = false,
  });

  @override
  Widget build(BuildContext context) => ListTile(
        key: ValueKey('place-${place.code}'),
        title: Text(title),
        trailing: opensList ? const Icon(Icons.chevron_right) : null,
        onTap: onTap,
      );
}

// EN: Lower case without accents, so "quebec" finds "Québec" and "mexico" finds
//     "México". Covers the letters used in English, French and Spanish names.
// FR: En minuscules et sans accents, afin que « quebec » trouve « Québec » et
//     « mexico » trouve « México ». Couvre les lettres des noms anglais,
//     français et espagnols.
String foldForSearch(String text) {
  const from = 'àâäáãåçéèêëíìîïñóòôöõúùûüýÿ';
  const to = 'aaaaaaceeeeiiiinooooouuuuyy';
  final buffer = StringBuffer();
  for (final char in text.toLowerCase().split('')) {
    final i = from.indexOf(char);
    if (char == 'œ') {
      buffer.write('oe');
    } else {
      buffer.write(i == -1 ? char : to[i]);
    }
  }
  return buffer.toString();
}
