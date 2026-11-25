// EN: Rendering + delivery layer for the flagship US Presence Record (FR-8). It is
//     a THIN skin over PresenceRecord (which holds the correctness-critical data
//     and the CSV): this file turns that data into a PDF, rasterises the PDF to a
//     PNG image, opens the system print dialog, and hands any of the three files to
//     the OS share sheet. Nothing here computes a day count — it only formats.
//
//     OFFLINE INVARIANT (NFR-1): the fonts are bundled assets (see RecordFonts), so
//     no font is downloaded and no network call happens. Never call PdfGoogleFonts.
//
// FR: Couche de rendu + livraison pour la fiche de présence vedette (FR-8). C'est
//     une FINE surface au-dessus de PresenceRecord (qui détient les données
//     critiques et le CSV) : ce fichier transforme ces données en PDF, pixellise le
//     PDF en image PNG, ouvre la boîte d'impression du système et remet l'un des
//     trois fichiers à la feuille de partage de l'OS. Rien ici ne calcule un compte
//     de jours — il ne fait que mettre en forme.
//
//     INVARIANT HORS-LIGNE (NFR-1) : les polices sont des ressources intégrées (voir
//     RecordFonts), donc aucune n'est téléchargée et aucun appel réseau n'a lieu. Ne
//     jamais appeler PdfGoogleFonts.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/widgets.dart' show Rect;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import 'package:snowbird_in_usa_tracker/l10n/app_localizations.dart';
import 'package:snowbird_in_usa_tracker/logic/presence_record.dart';
import 'package:snowbird_in_usa_tracker/models/trip.dart';
import 'package:snowbird_in_usa_tracker/services/record_fonts.dart';
import 'package:snowbird_in_usa_tracker/services/record_text.dart';

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
    final fonts = await RecordFonts.load();
    final dateFmt = DateFormat.yMMMd(localeName);
    final doc = pw.Document(
      theme: fonts.theme,
      title: strings.recordHeading,
      author: 'Veidimadur - veidimadur.ca',
    );

    doc.addPage(
      pw.MultiPage(
        // EN: US Letter — the paper of both the users (Canada) and the readers (US).
        // FR: Format Lettre US — le papier des utilisateurs (Canada) comme des
        //     lecteurs (É.-U.).
        pageFormat: PdfPageFormat.letter,
        // EN: The library stops at 20 pages by default, which would refuse a long
        //     history. Rows always fit a page (see _chunks), so layout terminates.
        // FR: La bibliothèque s'arrête à 20 pages par défaut, ce qui refuserait un
        //     long historique. Les rangées tiennent toujours sur une page (voir
        //     _chunks), donc la mise en page se termine.
        maxPages: 1000,
        margin: const pw.EdgeInsets.all(28),
        header: (context) => context.pageNumber == 1
            ? pw.SizedBox()
            : pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 8),
                child: pw.Text(
                  fonts.printable(strings.recordHeading),
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
                fonts.printable(strings.recordAuthor),
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
          _pdfHeader(record, fonts, strings, dateFmt),
          pw.SizedBox(height: 12),
          _pdfSummary(record, fonts, strings),
          pw.SizedBox(height: 16),
          _pdfTable(record, fonts, strings, dateFmt),
        ],
      ),
    );

    return doc.save();
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
    await Printing.layoutPdf(
      onLayout: (_) async => bytes,
      format: PdfPageFormat.letter,
    );
  }

  // EN: Share the PDF via the OS share sheet. No network — an OS handoff. [origin]
  //     is where the iPad anchors its popover; without it iPadOS refuses to share.
  // FR: Partager le PDF via la feuille de partage de l'OS. Aucun réseau — une remise
  //     à l'OS. [origin] est le point d'ancrage de la bulle sur iPad ; sans lui,
  //     iPadOS refuse le partage.
  static Future<void> sharePdf(
    PresenceRecord record, {
    required AppLocalizations strings,
    required String localeName,
    required Rect origin,
  }) async {
    final bytes =
        await buildPdf(record, strings: strings, localeName: localeName);
    final dir = await freshExportDir(await getTemporaryDirectory());
    final file = File('${dir.path}/$_fileBase.pdf');
    await file.writeAsBytes(bytes, flush: true);
    await shareFiles([file], 'application/pdf', origin);
  }

  // EN: Share the record as images, one PNG per PDF page (200 dpi), so a long
  //     history is never cut off. Rasterising the PDF keeps both identical.
  // FR: Partager la fiche en images, un PNG par page du PDF (200 ppp), pour qu'un
  //     long historique ne soit jamais tronqué. Pixelliser le PDF garde les deux
  //     identiques.
  static Future<void> shareImage(
    PresenceRecord record, {
    required AppLocalizations strings,
    required String localeName,
    required Rect origin,
  }) async {
    final bytes =
        await buildPdf(record, strings: strings, localeName: localeName);
    final files = await writeImages(
      Printing.raster(bytes, dpi: 200).asyncMap((page) => page.toPng()),
      await freshExportDir(await getTemporaryDirectory()),
    );
    await shareFiles(files, 'image/png', origin);
  }

  // EN: Share the plain-text record, the format meant to be listened to.
  // FR: Partager la fiche en texte brut, le format destiné à l'écoute.
  static Future<void> shareText(
    PresenceRecord record, {
    required AppLocalizations strings,
    required String localeName,
    required Rect origin,
  }) async {
    final file = await writeText(
      buildRecordText(record, strings: strings, localeName: localeName),
      await freshExportDir(await getTemporaryDirectory()),
    );
    await shareFiles([file], 'text/plain', origin);
  }

  // EN: Share the CSV via the OS share sheet. A UTF-8 BOM is prepended so desktop
  //     spreadsheet apps (notably Excel on Windows) read the accented French text
  //     correctly instead of mojibake.
  // FR: Partager le CSV via la feuille de partage de l'OS. Un BOM UTF-8 est ajouté
  //     en tête pour que les tableurs de bureau (notamment Excel sous Windows)
  //     lisent correctement le texte français accentué au lieu de mojibake.
  static Future<void> shareCsv(
    PresenceRecord record, {
    required Rect origin,
  }) async {
    final bom = [0xEF, 0xBB, 0xBF];
    final dir = await freshExportDir(await getTemporaryDirectory());
    final file = File('${dir.path}/$_fileBase.csv');
    await file.writeAsBytes(
      [...bom, ...utf8.encode(record.toCsv())],
      flush: true,
    );
    await shareFiles([file], 'text/csv', origin);
  }

  // ---------------------------------------------------------------------------
  // EN: Building blocks, public so they can be tested without platform channels.
  // FR: Briques publiques, pour être testées sans canaux de plateforme.
  // ---------------------------------------------------------------------------

  // EN: An empty export folder. The previous export is removed here rather than
  //     right after sharing, because the receiving app may still be reading it; this
  //     also keeps old copies of travel history from piling up in temporary storage.
  // FR: Un dossier d'export vide. L'export précédent est supprimé ici plutôt
  //     qu'aussitôt partagé, car l'appli réceptrice peut encore le lire ; cela évite
  //     aussi d'accumuler d'anciennes copies de l'historique en stockage temporaire.
  static Future<Directory> freshExportDir(Directory temp) async {
    final dir = Directory('${temp.path}/snowbird-export');
    if (await dir.exists()) await dir.delete(recursive: true);
    return dir.create(recursive: true);
  }

  // EN: Write each page as it arrives, so only one page is held in memory.
  // FR: Écrire chaque page dès son arrivée, pour n'en garder qu'une en mémoire.
  static Future<List<File>> writeImages(
    Stream<Uint8List> pages,
    Directory dir,
  ) async {
    final files = <File>[];
    await for (final png in pages) {
      final file = File('${dir.path}/$_fileBase-${files.length + 1}.png');
      files.add(await file.writeAsBytes(png, flush: true));
    }
    if (files.isEmpty) {
      throw StateError('The PDF produced no page to rasterise.');
    }
    return files;
  }

  // EN: UTF-8 with a byte-order mark: without it, some viewers (iOS previews, older
  //     Windows apps) guess another encoding and garble accents.
  // FR: UTF-8 avec marque d'ordre : sans elle, certains lecteurs (aperçus iOS, anciennes
  //     applis Windows) devinent un autre encodage et abîment les accents.
  static Future<File> writeText(String text, Directory dir) =>
      File('${dir.path}/$_fileBase.txt')
          .writeAsBytes([0xEF, 0xBB, 0xBF, ...utf8.encode(text)], flush: true);

  static Future<void> shareFiles(
    List<File> files,
    String mime,
    Rect origin,
  ) async {
    await SharePlus.instance.share(
      ShareParams(
        files: [for (final f in files) XFile(f.path, mimeType: mime)],
        sharePositionOrigin: origin,
      ),
    );
  }

  static pw.Widget _pdfHeader(
    PresenceRecord record,
    RecordFonts fonts,
    AppLocalizations strings,
    DateFormat dateFmt,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          fonts.printable(strings.recordHeading),
          style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          fonts.printable(strings.recordAsOf(dateFmt.format(record.asOf))),
          style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
        ),
        pw.SizedBox(height: 6),
        pw.Text(
          fonts.printable(strings.recordDisclaimer),
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
    RecordFonts fonts,
    AppLocalizations strings,
  ) {
    final t = record.totals;
    pw.Widget line(String label, String value) => pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 1),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                fonts.printable(label),
                style: const pw.TextStyle(fontSize: 10),
              ),
              pw.Text(
                fonts.printable(value),
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
            fonts.printable(strings.recordSummaryTitle),
            style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          line(strings.windowThisYear, '${t.thisCalendarYear}'),
          line(strings.windowLast365, '${t.rollingLast365}'),
          line(strings.windowLastYear, '${t.priorCalendarYear}'),
          pw.Divider(color: PdfColors.grey300),
          line(strings.recordSptLabel, record.formattedSpt),
          pw.Text(
            fonts.printable(strings.recordSptFormula),
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }

  static pw.Widget _pdfTable(
    PresenceRecord record,
    RecordFonts fonts,
    AppLocalizations strings,
    DateFormat dateFmt,
  ) {
    final headers = [
      strings.recordColDates,
      strings.recordColDays,
      strings.recordColStatus,
      strings.recordColDetails,
    ].map(fonts.printable).toList();

    final data = <List<String>>[];
    for (final trip in record.trips) {
      final departure = trip.departureDate;
      final dates = '${dateFmt.format(trip.arrivalDate)} – '
          '${departure == null ? strings.tripOngoing : dateFmt.format(departure)}';
      final status = trip.status == TripStatus.planned
          ? strings.tripStatusPlanned
          : trip.isInProgress(record.asOf)
              ? strings.tripStatusCurrent
              : strings.tripStatusActual;
      // EN: A PDF table row cannot span pages, so long details continue on rows
      //     whose other cells are blank. Nothing is dropped.
      // FR: Une rangée de tableau PDF ne peut s'étendre sur deux pages, donc de
      //     longs détails se poursuivent sur des rangées aux autres cellules vides.
      //     Rien n'est omis.
      final chunks = _chunks(fonts.printable(_details(trip, strings)));
      data.add([
        fonts.printable(dates),
        '${trip.daysPresent(record.asOf)}',
        fonts.printable(status),
        chunks.first,
      ]);
      for (final more in chunks.skip(1)) {
        data.add(['', '', '', more]);
      }
    }

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

  // EN: "Details" cell: trip name, then EVERY recorded crossing field for entry and
  //     exit, then notes — only the parts that exist. The record is evidence, so
  //     what the user took the trouble to record is printed.
  // FR: Cellule « détails » : nom du séjour, puis TOUS les champs de passage
  //     consignés à l'entrée et à la sortie, puis notes — seulement les parties
  //     présentes. La fiche est une preuve : ce que l'utilisateur a pris la peine de
  //     consigner est imprimé.
  static String _details(Trip trip, AppLocalizations strings) {
    final entry = crossingText(trip.arrivalInfo);
    final exit = crossingText(trip.departureInfo);
    return [
      if (trip.name != null) trip.name!,
      if (entry.isNotEmpty) strings.recordEntryLabel(entry),
      if (exit.isNotEmpty) strings.recordExitLabel(exit),
      if (trip.notes != null) trip.notes!,
    ].join('\n');
  }

  // EN: Split text into pieces that always fit on one page. The per-line estimate
  //     is pessimistic (the widest letters), so a piece may look short but can never
  //     overflow. Breaks at spaces; only an overlong single word is cut.
  // FR: Découper le texte en morceaux tenant toujours sur une page. L'estimation par
  //     ligne est pessimiste (lettres les plus larges) : un morceau peut sembler
  //     court mais ne déborde jamais. Coupe aux espaces ; seul un mot trop long est
  //     tranché.
  static List<String> _chunks(String text) {
    const charsPerLine = 25;
    const maxLines = 35;
    final lines = <String>[];
    for (final paragraph in text.split('\n')) {
      var line = '';
      for (var word in paragraph.split(' ')) {
        while (word.length > charsPerLine) {
          if (line.isNotEmpty) {
            lines.add('$line ');
            line = '';
          }
          lines.add(word.substring(0, charsPerLine));
          word = word.substring(charsPerLine);
        }
        if (line.isNotEmpty && line.length + 1 + word.length > charsPerLine) {
          lines.add('$line ');
          line = word;
        } else {
          line = line.isEmpty ? word : '$line $word';
        }
      }
      lines.add('$line\n');
    }
    return [
      for (var i = 0; i < lines.length; i += maxLines)
        lines
            .sublist(
              i,
              i + maxLines < lines.length ? i + maxLines : lines.length,
            )
            .join()
            .trimRight(),
    ];
  }
}
