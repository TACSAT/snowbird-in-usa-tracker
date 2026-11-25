// EN: The bundled Roboto faces used to draw the US Presence Record. They ship inside
//     the app (assets/fonts, Apache 2.0), so nothing is ever downloaded (NFR-1) and
//     French œ/Œ/Ÿ and other scripts print as typed. Roboto lacks ⅓, ⅙ and →, which
//     are replaced by plain equivalents; anything else it cannot draw (emoji, for
//     example) becomes a visible "?" instead of vanishing.
// FR: Les polices Roboto intégrées servant à dessiner la fiche de présence. Elles
//     sont livrées dans l'appli (assets/fonts, Apache 2.0) : rien n'est téléchargé
//     (NFR-1) et œ/Œ/Ÿ ainsi que d'autres écritures s'impriment tels que saisis.
//     Roboto n'a pas ⅓, ⅙ ni →, remplacés par des équivalents simples ; tout autre
//     caractère impossible à dessiner (un emoji, par exemple) devient un « ? »
//     visible plutôt que de disparaître.

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart' show TtfParser;
import 'package:pdf/widgets.dart' as pw;

class RecordFonts {
  final pw.ThemeData theme;
  final Set<int> _supported;

  const RecordFonts._(this.theme, this._supported);

  // EN: Loaded once per run; parsing three faces on every export would be waste.
  // FR: Chargé une fois par exécution ; analyser trois polices à chaque export
  //     serait du gaspillage.
  static RecordFonts? _cached;

  static Future<RecordFonts> load() async {
    final cached = _cached;
    if (cached != null) return cached;
    final regular = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
    final bold = await rootBundle.load('assets/fonts/Roboto-Bold.ttf');
    final italic = await rootBundle.load('assets/fonts/Roboto-Italic.ttf');
    return _cached = RecordFonts._(
      pw.ThemeData.withFont(
        base: pw.Font.ttf(regular),
        bold: pw.Font.ttf(bold),
        italic: pw.Font.ttf(italic),
      ),
      TtfParser(regular).charToGlyphIndexMap.keys.toSet(),
    );
  }

  // EN: Convert text to what these faces can draw. Newlines are kept: they are
  //     layout, not glyphs.
  // FR: Convertir le texte vers ce que ces polices peuvent dessiner. Les sauts de
  //     ligne sont gardés : c'est de la mise en page, pas des glyphes.
  String printable(String input) {
    final mapped = input
        .replaceAll('⅓', '1/3')
        .replaceAll('⅙', '1/6')
        .replaceAll('→', '>')
        .replaceAll(RegExp(r'[\u2000-\u200a\u202f\t]'), ' ');
    final buffer = StringBuffer();
    for (final rune in mapped.runes) {
      buffer.writeCharCode(
        rune == 0x0A || _supported.contains(rune) ? rune : 0x3F /* '?' */,
      );
    }
    return buffer.toString();
  }
}
