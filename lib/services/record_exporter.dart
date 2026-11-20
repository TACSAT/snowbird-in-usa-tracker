// EN: Rendering + delivery layer for the flagship US Presence Record (FR-8). It is
//     a THIN skin over PresenceRecord (which holds the correctness-critical data
//     and the CSV): this file turns that data into a PDF, rasterises the PDF to a
//     PNG image, opens the system print dialog, and hands any of the three files to
//     the OS share sheet. Nothing here computes a day count — it only formats.
//
//     OFFLINE INVARIANT (NFR-1): the PDF is built with the pdf package's BUILT-IN
//     Helvetica (one of the 14 standard PDF fonts) — no font is downloaded, so no
//     network call ever happens. We deliberately never call PdfGoogleFonts. The
//     price of a no-bundled-font design is that standard Helvetica only covers the
//     Latin-1 character set, so [_pdf] normalises the typographic punctuation and
//     fractions we use (– — ⅓ ⅙ " " …) down to Latin-1 equivalents and replaces any
//     remaining non-Latin-1 rune with '?' so a stray glyph can never crash the
//     build. French accents, the guillemets « », the middle dot ·, and the ð in
//     "Veiðimaður" are all inside Latin-1 and render correctly. (The CSV, being
//     UTF-8, has no such limit — full Unicode there.) If arbitrary-Unicode PDF
//     output is ever needed, bundle a TTF font asset and load it here.
//
// FR: Couche de rendu + livraison pour la fiche de présence vedette (FR-8). C'est
//     une FINE surface au-dessus de PresenceRecord (qui détient les données
//     critiques et le CSV) : ce fichier transforme ces données en PDF, pixellise le
//     PDF en image PNG, ouvre la boîte d'impression du système et remet l'un des
//     trois fichiers à la feuille de partage de l'OS. Rien ici ne calcule un compte
//     de jours — il ne fait que mettre en forme.
//
//     INVARIANT HORS-LIGNE (NFR-1) : le PDF est construit avec la police Helvetica
//     INTÉGRÉE au paquet pdf (l'une des 14 polices PDF standard) — aucune police
//     n'est téléchargée, donc aucun appel réseau. Nous n'appelons jamais
//     PdfGoogleFonts. Le prix d'une conception sans police intégrée : Helvetica
//     standard ne couvre que le jeu Latin-1, donc [_pdf] normalise la ponctuation
//     typographique et les fractions que nous employons (– — ⅓ ⅙ " » …) vers des
//     équivalents Latin-1 et remplace tout caractère hors Latin-1 restant par « ? »
//     pour qu'un glyphe égaré ne fasse jamais planter la construction. Les accents
//     français, les guillemets « », le point médian · et le ð de « Veiðimaður »
//     sont tous dans Latin-1 et s'affichent correctement. (Le CSV, en UTF-8, n'a
//     pas cette limite — Unicode complet.) Si un jour un PDF Unicode arbitraire est
//     nécessaire, intégrer une police TTF et la charger ici.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import 'package:snowbird_in_usa_tracker/l10n/app_localizations.dart';
import 'package:snowbird_in_usa_tracker/logic/presence_record.dart';
import 'package:snowbird_in_usa_tracker/models/trip.dart';

abstract final class RecordExporter {
  // EN: Base filename (no extension) used for every exported artifact.
  // FR: Nom de fichier de base (sans extension) pour chaque artefact exporté.
  static const _fileBase = 'us-presence-record';

  // EN: Build the PDF document bytes. Pure formatting — takes the already-computed
  //     record plus the active locale for date/label localisation.
  // FR: Construire les octets du document PDF. Mise en forme pure — prend la fiche
  //     déjà calculée plus la locale active pour la localisation des dates/libellés.
  static Future<Uint8List> buildPdf(
    PresenceRecord record, {
    required AppLocalizations strings,
    required String localeName,
  }) async {
    final dateFmt = DateFormat.yMMMd(localeName);
    final doc = pw.Document(
      title: strings.recordHeading,
      author: 'Veidimadur - veidimadur.ca',
    );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        header: (context) => context.pageNumber == 1
            ? pw.SizedBox()
            : pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 8),
                child: pw.Text(
                  _pdf(strings.recordHeading),
                  style: const pw.TextStyle(
                    fontSize: 9,
                    color: PdfColors.grey600,
                  ),
                ),
              ),
        footer: (context) => pw.Padding(
          padding: const pw.EdgeInsets.only(top: 8),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                _pdf(strings.recordAuthor),
                style:
                    const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
              ),
              pw.Text(
                '${context.pageNumber} / ${context.pagesCount}',
                style:
                    const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
              ),
            ],
          ),
        ),
        build: (context) => [
          _pdfHeader(record, strings, dateFmt),
          pw.SizedBox(height: 12),
          _pdfSummary(record, strings),
          pw.SizedBox(height: 16),
          _pdfTable(record, strings, dateFmt),
        ],
      ),
    );

    return doc.save();
  }

  // EN: Rasterise page 1 of the PDF to a PNG image (200 dpi — crisp on screen and
  //     when re-shared). Reuses buildPdf so the image and the PDF are identical.
  // FR: Pixelliser la page 1 du PDF en image PNG (200 ppp — net à l'écran et au
  //     repartage). Réutilise buildPdf pour que l'image et le PDF soient identiques.
  static Future<Uint8List> buildImage(
    PresenceRecord record, {
    required AppLocalizations strings,
    required String localeName,
  }) async {
    final pdfBytes =
        await buildPdf(record, strings: strings, localeName: localeName);
    await for (final page in Printing.raster(pdfBytes, pages: [0], dpi: 200)) {
      return page.toPng();
    }
    throw StateError('The PDF produced no page to rasterise.');
  }

  // EN: Open the system print dialog with the record.
  // FR: Ouvrir la boîte de dialogue d'impression du système avec la fiche.
  static Future<void> printRecord(
    PresenceRecord record, {
    required AppLocalizations strings,
    required String localeName,
  }) async {
    final bytes =
        await buildPdf(record, strings: strings, localeName: localeName);
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }

  // EN: Share the PDF via the OS share sheet (printing handles the temp file and
  //     filename). No network — the share sheet is an OS handoff.
  // FR: Partager le PDF via la feuille de partage de l'OS (printing gère le fichier
  //     temporaire et le nom). Aucun réseau — le partage est une remise à l'OS.
  static Future<void> sharePdf(
    PresenceRecord record, {
    required AppLocalizations strings,
    required String localeName,
  }) async {
    final bytes =
        await buildPdf(record, strings: strings, localeName: localeName);
    await Printing.sharePdf(bytes: bytes, filename: '$_fileBase.pdf');
  }

  // EN: Share the PNG image via the OS share sheet.
  // FR: Partager l'image PNG via la feuille de partage de l'OS.
  static Future<void> shareImage(
    PresenceRecord record, {
    required AppLocalizations strings,
    required String localeName,
  }) async {
    final bytes =
        await buildImage(record, strings: strings, localeName: localeName);
    await _shareBytes(bytes, '$_fileBase.png', 'image/png');
  }

  // EN: Share the CSV via the OS share sheet. A UTF-8 BOM is prepended so desktop
  //     spreadsheet apps (notably Excel on Windows) read the accented French text
  //     correctly instead of mojibake.
  // FR: Partager le CSV via la feuille de partage de l'OS. Un BOM UTF-8 est ajouté
  //     en tête pour que les tableurs de bureau (notamment Excel sous Windows)
  //     lisent correctement le texte français accentué au lieu de mojibake.
  static Future<void> shareCsv(PresenceRecord record) async {
    final bom = [0xEF, 0xBB, 0xBF];
    final bytes = Uint8List.fromList([...bom, ...utf8.encode(record.toCsv())]);
    await _shareBytes(bytes, '$_fileBase.csv', 'text/csv');
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  // EN: Write bytes to a temp file with a correct name/extension (so the receiving
  //     app recognises the type), then hand it to the share sheet.
  // FR: Écrire les octets dans un fichier temporaire au nom/extension correct (pour
  //     que l'appli réceptrice reconnaisse le type), puis le remettre au partage.
  static Future<void> _shareBytes(
    Uint8List bytes,
    String name,
    String mime,
  ) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$name');
    await file.writeAsBytes(bytes, flush: true);
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path, mimeType: mime)]),
    );
  }

  static pw.Widget _pdfHeader(
    PresenceRecord record,
    AppLocalizations strings,
    DateFormat dateFmt,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          _pdf(strings.recordHeading),
          style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          _pdf(strings.recordAsOf(dateFmt.format(record.asOf))),
          style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
        ),
        pw.SizedBox(height: 6),
        pw.Text(
          _pdf(strings.recordDisclaimer),
          style: pw.TextStyle(
            fontSize: 9,
            fontStyle: pw.FontStyle.italic,
            color: PdfColors.grey700,
          ),
        ),
        pw.Divider(color: PdfColors.grey400),
      ],
    );
  }

  static pw.Widget _pdfSummary(
    PresenceRecord record,
    AppLocalizations strings,
  ) {
    final t = record.totals;
    pw.Widget line(String label, String value) => pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 1),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(_pdf(label), style: const pw.TextStyle(fontSize: 10)),
              pw.Text(
                _pdf(value),
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
        );

    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            _pdf(strings.recordSummaryTitle),
            style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          line(strings.windowThisYear, '${t.thisCalendarYear}'),
          line(strings.windowLast365, '${t.rollingLast365}'),
          line(strings.windowLastYear, '${t.priorCalendarYear}'),
          pw.Divider(color: PdfColors.grey300),
          line(strings.recordSptLabel, record.formattedSpt),
          pw.Text(
            _pdf(strings.recordSptFormula),
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }

  static pw.Widget _pdfTable(
    PresenceRecord record,
    AppLocalizations strings,
    DateFormat dateFmt,
  ) {
    final headers = [
      strings.recordColDates,
      strings.recordColDays,
      strings.recordColStatus,
      strings.recordColDetails,
    ].map(_pdf).toList();

    final data = record.trips.map((trip) {
      final dates =
          '${dateFmt.format(trip.arrivalDate)} – ${dateFmt.format(trip.departureDate)}';
      final status = trip.status == TripStatus.planned
          ? strings.tripStatusPlanned
          : strings.tripStatusActual;
      return [
        _pdf(dates),
        '${trip.daysInUS}',
        _pdf(status),
        _pdf(_details(trip)),
      ];
    }).toList();

    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: data,
      headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
      cellStyle: const pw.TextStyle(fontSize: 9),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
      cellAlignments: {
        1: pw.Alignment.centerRight,
        2: pw.Alignment.center,
      },
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(1.4),
        3: const pw.FlexColumnWidth(4),
      },
    );
  }

  // EN: Compact "details" cell: trip name, then entry/exit locations, then notes —
  //     only the parts that exist, joined so an empty trip shows an empty cell.
  // FR: Cellule « détails » compacte : nom du séjour, puis lieux d'entrée/sortie,
  //     puis notes — seulement les parties présentes, jointes pour qu'un séjour vide
  //     affiche une cellule vide.
  static String _details(Trip trip) {
    final parts = <String>[];
    if (trip.name != null) parts.add(trip.name!);
    final entryLoc = trip.arrivalInfo?.location;
    final exitLoc = trip.departureInfo?.location;
    if (entryLoc != null || exitLoc != null) {
      parts.add('${entryLoc ?? '—'} → ${exitLoc ?? '—'}');
    }
    if (trip.notes != null) parts.add(trip.notes!);
    return parts.join('\n');
  }

  // EN: Normalise a string to what standard-font Helvetica can render (Latin-1):
  //     map the typographic punctuation and fractions this app uses to Latin-1
  //     equivalents, then replace any remaining rune above U+00FF with '?'. Without
  //     this, an unsupported glyph would throw during PDF layout (see file header).
  // FR: Normaliser une chaîne vers ce que l'Helvetica standard peut rendre
  //     (Latin-1) : convertir la ponctuation typographique et les fractions
  //     utilisées ici en équivalents Latin-1, puis remplacer tout caractère
  //     au-dessus de U+00FF restant par « ? ». Sans cela, un glyphe non pris en
  //     charge lèverait une exception au rendu du PDF (voir l'en-tête du fichier).
  static String _pdf(String input) {
    final mapped = input
        .replaceAll('—', '-')
        .replaceAll('–', '-')
        .replaceAll('⅓', '1/3')
        .replaceAll('⅙', '1/6')
        .replaceAll('’', "'")
        .replaceAll('‘', "'")
        .replaceAll('“', '"')
        .replaceAll('”', '"')
        .replaceAll('…', '...')
        .replaceAll('→', '>');
    final buffer = StringBuffer();
    for (final rune in mapped.runes) {
      buffer.writeCharCode(rune <= 0xFF ? rune : 0x3F /* '?' */);
    }
    return buffer.toString();
  }
}
