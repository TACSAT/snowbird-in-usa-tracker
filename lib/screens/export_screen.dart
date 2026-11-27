// EN: Export the Presence Record (section 11). Three decisions come before any
//     file leaves the phone:
//     - what the record covers (EXP-1): all places, or one country. "United
//       States only" is the original US Presence Record, the one handed to a
//       border officer, who should not be shown unrelated travel;
//     - whether to add days worked (WRK-8): off every time this screen opens,
//       never remembered, because what someone does in a country can affect
//       their right to be there;
//     - a plain preview of what the file will contain (EXP-6): places, dates,
//       how many stays and visits, and which personal details (names, notes,
//       crossing details, work, home base) go with it.
//     Only then the formats: PDF, text, image, CSV, day-by-day ledger, print.
// FR: Exporter la fiche de présence (section 11). Trois décisions viennent avant
//     qu'un fichier ne quitte le téléphone :
//     - ce que couvre la fiche (EXP-1) : tous les lieux, ou un pays. « États-Unis
//       seulement » est la fiche de présence d'origine, celle remise à un agent
//       frontalier, à qui il ne faut pas montrer des voyages sans rapport ;
//     - ajouter ou non les jours travaillés (WRK-8) : désactivé à chaque
//       ouverture de cet écran, jamais mémorisé, car ce que l'on fait dans un pays
//       peut compter pour le droit d'y être ;
//     - un aperçu simple de ce que contiendra le fichier (EXP-6) : lieux, dates,
//       nombre de séjours et de visites, et quels détails personnels (noms,
//       notes, détails de passage, travail, domicile) l'accompagnent.
//     Ensuite seulement les formats : PDF, texte, image, CSV, registre jour par
//     jour, impression.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:snowbird_in_usa_tracker/l10n/app_localizations.dart';
import 'package:snowbird_in_usa_tracker/logic/presence_record.dart';
import 'package:snowbird_in_usa_tracker/models/place.dart';
import 'package:snowbird_in_usa_tracker/screens/place_names.dart';
import 'package:snowbird_in_usa_tracker/screens/section_heading.dart';
import 'package:snowbird_in_usa_tracker/services/record_exporter.dart';
import 'package:snowbird_in_usa_tracker/state/presence_settings.dart';
import 'package:snowbird_in_usa_tracker/state/trip_repository.dart';

enum ExportFormat { pdf, text, image, csv, ledger, print }

class ExportScreen extends StatefulWidget {
  const ExportScreen({super.key});

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  // EN: The chosen scope; null means all places. Set on first build from the
  //     data: a user whose stays are all in the United States starts on the
  //     US-only record, exactly as before places existed.
  // FR: La portée choisie ; null signifie tous les lieux. Fixée au premier
  //     affichage d'après les données : un utilisateur dont tous les séjours
  //     sont aux États-Unis commence sur la fiche des États-Unis seuls,
  //     exactement comme avant les lieux.
  Place? _scope;
  bool _scopeSet = false;
  bool _includeWork = false;
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final repo = context.watch<TripRepository>();
    final settings = context.watch<PresenceSettings>();
    final countries = <Place>{
      for (final t in repo.trips) t.place.country,
      for (final v in repo.visits) v.place.country,
    };
    final ordered = [
      for (final c in PlaceCatalog.countries)
        if (countries.contains(c)) c,
      ...([
        for (final c in countries)
          if (!PlaceCatalog.countries.contains(c)) c,
      ]..sort((a, b) => a.code.compareTo(b.code))),
    ];
    if (!_scopeSet) {
      _scopeSet = true;
      _scope = ordered.length == 1 && ordered.single == Place.unitedStates
          ? Place.unitedStates
          : null;
    }
    final work = settings.workEnabled && _includeWork;
    final record = PresenceRecord.build(
      trips: repo.trips,
      visits: repo.visits,
      scope: _scope,
      tracked: settings.tracked,
      home: settings.home,
      includeWork: work,
    );

    return Scaffold(
      appBar: AppBar(title: Text(strings.exportRecord)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          SectionHeading(
            strings.exportScopeHeading,
            style: theme.textTheme.titleSmall,
          ),
          RadioGroup<String>(
            groupValue: _scope?.code ?? '',
            onChanged: (code) => setState(
              () => _scope =
                  code == null || code.isEmpty ? null : Place.parse(code),
            ),
            child: Column(
              children: [
                RadioListTile<String>(
                  contentPadding: EdgeInsets.zero,
                  value: '',
                  title: Text(strings.exportScopeAll),
                ),
                for (final c in ordered)
                  RadioListTile<String>(
                    contentPadding: EdgeInsets.zero,
                    value: c.code,
                    title: Text(
                      strings.exportScopeOnly(placeShortName(strings, c)),
                    ),
                  ),
              ],
            ),
          ),
          if (settings.workEnabled)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(strings.exportIncludeWork),
              subtitle: Text(strings.exportIncludeWorkHelper),
              value: _includeWork,
              onChanged: (v) => setState(() => _includeWork = v),
            ),
          const SizedBox(height: 8),
          _Preview(record: record, workEnabled: settings.workEnabled),
          const SizedBox(height: 16),
          SectionHeading(
            strings.exportFormatsHeading,
            style: theme.textTheme.titleSmall,
          ),
          for (final (format, icon, label) in [
            (
              ExportFormat.pdf,
              Icons.picture_as_pdf_outlined,
              strings.exportAsPdf
            ),
            (ExportFormat.text, Icons.notes, strings.exportAsText),
            (ExportFormat.image, Icons.image_outlined, strings.exportAsImage),
            (ExportFormat.csv, Icons.table_chart_outlined, strings.exportAsCsv),
            (
              ExportFormat.ledger,
              Icons.calendar_view_day,
              strings.exportAsLedger
            ),
            (ExportFormat.print, Icons.print_outlined, strings.exportPrint),
          ])
            Builder(
              builder: (tile) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(icon),
                title: Text(label),
                enabled: !_busy && record.entries.isNotEmpty,
                onTap: () => _export(tile, record, format),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _export(
    BuildContext tile,
    PresenceRecord record,
    ExportFormat format,
  ) async {
    final strings = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final localeName = strings.localeName;
    // EN: The share sheet points at the tapped row on tablets.
    // FR: La feuille de partage pointe vers la ligne touchée sur tablette.
    final box = tile.findRenderObject();
    final origin = box is RenderBox && box.hasSize
        ? box.localToGlobal(Offset.zero) & box.size
        : const Rect.fromLTWH(0, 0, 1, 1);
    setState(() => _busy = true);
    try {
      switch (format) {
        case ExportFormat.pdf:
          await RecordExporter.sharePdf(
            record,
            strings: strings,
            localeName: localeName,
            origin: origin,
          );
        case ExportFormat.text:
          await RecordExporter.shareText(
            record,
            strings: strings,
            localeName: localeName,
            origin: origin,
          );
        case ExportFormat.image:
          await RecordExporter.shareImage(
            record,
            strings: strings,
            localeName: localeName,
            origin: origin,
          );
        case ExportFormat.csv:
          await RecordExporter.shareCsv(record, origin: origin);
        case ExportFormat.ledger:
          await RecordExporter.shareLedgerCsv(record, origin: origin);
        case ExportFormat.print:
          await RecordExporter.printRecord(
            record,
            strings: strings,
            localeName: localeName,
          );
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(strings.exportError(e.toString()))),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

// EN: What the file will contain, in plain words (EXP-6). Counts come from the
//     very record object that will be exported, so the preview cannot differ
//     from the file.
// FR: Ce que contiendra le fichier, en mots simples (EXP-6). Les comptes
//     viennent de l'objet fiche même qui sera exporté ; l'aperçu ne peut donc
//     pas différer du fichier.
class _Preview extends StatelessWidget {
  final PresenceRecord record;
  final bool workEnabled;

  const _Preview({required this.record, required this.workEnabled});

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final dates = DateFormat.yMMMMd(strings.localeName);
    final entries = record.entries;
    final stays = record.trips;
    // EN: Countries in catalogue order, the same order as everywhere else.
    // FR: Les pays dans l'ordre du catalogue, le même ordre que partout.
    final found = <Place>{for (final e in entries) e.place.country};
    final places = [
      for (final c in PlaceCatalog.countries)
        if (found.contains(c)) c,
      for (final c in found)
        if (!PlaceCatalog.countries.contains(c)) c,
    ];
    DateTime? last;
    for (final e in entries) {
      final end =
          e.stay?.departureDate ?? (e.stay == null ? e.date : record.asOf);
      if (last == null || end.isAfter(last)) last = end;
    }
    final lines = <String>[
      if (places.isNotEmpty)
        strings.exportPreviewPlaces(
          [for (final p in places) placeShortName(strings, p)].join(', '),
        ),
      if (entries.isNotEmpty && last != null)
        strings.exportPreviewDates(
          dates.format(entries.first.date),
          dates.format(last),
        ),
      strings.exportPreviewStays(stays.length),
      strings.exportPreviewVisits(record.visits.length),
      strings.exportPreviewNames(stays.where((t) => t.name != null).length),
      strings.exportPreviewNotes(stays.where((t) => t.notes != null).length),
      strings.exportPreviewCrossings(
        stays
            .where((t) => t.arrivalInfo != null || t.departureInfo != null)
            .length,
      ),
      if (record.places
          .any((p) => p.assumedLast365 > 0 || p.assumedThisYear > 0))
        strings.exportPreviewHome,
      if (workEnabled)
        record.includeWork
            ? strings.exportPreviewWorkYes
            : strings.exportPreviewWorkNo,
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Semantics(
          container: true,
          liveRegion: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SectionHeading(
                strings.exportPreviewHeading,
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              for (final line in lines)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(line),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
