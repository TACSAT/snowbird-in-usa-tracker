// EN: Settings screen (FR-20): the user chooses the app language, the light/dark
//     appearance, and an in-app text size — each independent of the phone's system
//     settings, because the likely users are older adults who want to see this app
//     clearly without changing every app on their phone (NFR-5). Every control
//     writes straight through SettingsController, which persists it and rebuilds
//     the whole app; there is no separate "save" step to forget.
//
// FR: Écran des réglages (FR-20) : l'utilisateur choisit la langue de l'appli,
//     l'apparence claire/sombre et une taille de texte dans l'appli — chacun
//     indépendant des réglages du téléphone, car les utilisateurs probables sont
//     des personnes plus âgées qui veulent voir cette appli clairement sans changer
//     toutes leurs applis (NFR-5). Chaque contrôle écrit directement via
//     SettingsController, qui le persiste et reconstruit toute l'appli ; aucune
//     étape « enregistrer » séparée à oublier.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:snowbird_in_usa_tracker/l10n/app_localizations.dart';
import 'package:snowbird_in_usa_tracker/screens/section_heading.dart';
import 'package:snowbird_in_usa_tracker/state/settings_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final settings = context.watch<SettingsController>();

    return Scaffold(
      appBar: AppBar(title: Text(strings.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionLabel(context, strings.settingsLanguage),
          // EN: null = follow the phone's language; the two endonyms are shown in
          //     their own language, as is convention for a language picker.
          // FR: null = suivre la langue du téléphone ; les deux endonymes sont
          //     affichés dans leur propre langue, comme il est d'usage.
          _ChoiceTile<Locale?>(
            value: settings.locale,
            options: {
              null: strings.optionFollowPhone,
              const Locale('en'): strings.languageEnglish,
              const Locale('fr'): strings.languageFrench,
            },
            onChanged: (v) => context.read<SettingsController>().setLocale(v),
          ),
          const Divider(height: 32),

          _sectionLabel(context, strings.settingsAppearance),
          _ChoiceTile<ThemeMode>(
            value: settings.themeMode,
            options: {
              ThemeMode.system: strings.optionFollowPhone,
              ThemeMode.light: strings.themeLight,
              ThemeMode.dark: strings.themeDark,
            },
            onChanged: (v) =>
                context.read<SettingsController>().setThemeMode(v),
          ),
          const Divider(height: 32),

          _sectionLabel(context, strings.settingsTextSize),
          _TextSizeControl(
            scale: settings.textScale,
            onChanged: (v) =>
                context.read<SettingsController>().setTextScale(v),
          ),
          const SizedBox(height: 8),
          // EN: Live preview — this line grows/shrinks with the selection so the
          //     user sees the effect before leaving the screen.
          // FR: Aperçu en direct — cette ligne grandit/rapetisse avec la sélection
          //     pour que l'utilisateur voie l'effet avant de quitter l'écran.
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                strings.textSizeSample,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(BuildContext context, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: SectionHeading(
          text,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      );
}

// EN: A vertical radio-style list of mutually exclusive options — larger tap
//     targets and clearer than a dropdown for an older audience (NFR-5).
// FR: Une liste verticale façon boutons radio d'options exclusives — cibles de
//     toucher plus grandes et plus claires qu'un menu déroulant pour un public plus
//     âgé (NFR-5).
class _ChoiceTile<T> extends StatelessWidget {
  final T value;
  final Map<T, String> options;
  final ValueChanged<T> onChanged;

  const _ChoiceTile({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    // EN: RadioGroup is the current API (the per-tile groupValue/onChanged were
    //     deprecated after Flutter 3.32). The group owns the selection; each tile
    //     only declares its value. The `v is T` guard lets a nullable T (Locale?)
    //     accept null — the "follow phone" option — while a non-null T ignores it.
    // FR: RadioGroup est l'API actuelle (les groupValue/onChanged par tuile ont été
    //     dépréciés après Flutter 3.32). Le groupe possède la sélection ; chaque
    //     tuile ne déclare que sa valeur. La garde `v is T` permet à un T nullable
    //     (Locale?) d'accepter null — l'option « suivre le téléphone » — tandis
    //     qu'un T non nul l'ignore.
    return RadioGroup<T>(
      groupValue: value,
      onChanged: (v) {
        if (v is T) onChanged(v);
      },
      child: Column(
        children: options.entries
            .map(
              (e) => RadioListTile<T>(
                contentPadding: EdgeInsets.zero,
                title: Text(e.value),
                value: e.key,
              ),
            )
            .toList(),
      ),
    );
  }
}

// EN: A discrete text-size slider snapping to kTextScaleOptions, with big − / +
//     affordances at each end. Kept discrete (not free) so the choice is simple.
// FR: Un curseur de taille de texte discret s'accrochant à kTextScaleOptions, avec
//     de grandes commandes − / + à chaque extrémité. Gardé discret (non libre) pour
//     que le choix reste simple.
class _TextSizeControl extends StatelessWidget {
  final double scale;
  final ValueChanged<double> onChanged;

  const _TextSizeControl({required this.scale, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    // EN: Snap the current value to the nearest allowed step for the slider index.
    // FR: Accrocher la valeur courante au palier autorisé le plus proche pour
    //     l'index du curseur.
    var index = 0;
    var best = double.infinity;
    for (var i = 0; i < kTextScaleOptions.length; i++) {
      final d = (kTextScaleOptions[i] - scale).abs();
      if (d < best) {
        best = d;
        index = i;
      }
    }

    return Row(
      children: [
        const Icon(Icons.text_decrease, size: 20),
        Expanded(
          // EN: Named, and read as the size itself rather than a position on the track.
          // FR: Nommé, et lu comme la taille elle-même plutôt qu'une position.
          child: MergeSemantics(
            child: Semantics(
              label: AppLocalizations.of(context).settingsTextSize,
              child: Slider(
                value: index.toDouble(),
                semanticFormatterCallback: (v) =>
                    '${(kTextScaleOptions[v.round()] * 100).round()}%',
                min: 0,
                max: (kTextScaleOptions.length - 1).toDouble(),
                divisions: kTextScaleOptions.length - 1,
                onChanged: (v) => onChanged(kTextScaleOptions[v.round()]),
              ),
            ),
          ),
        ),
        const Icon(Icons.text_increase, size: 28),
      ],
    );
  }
}
