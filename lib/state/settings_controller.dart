// EN: Holds the user's app preferences (FR-20) and persists them through
//     StorageService. Three independent settings, each defaulting to "follow the
//     phone / framework" so a fresh install never imposes a choice:
//       • locale      — null follows the OS language; 'en'/'fr' overrides it,
//       • themeMode    — system / light / dark,
//       • textScale    — an IN-APP multiplier applied on top of the OS text size,
//                        so a user can enlarge THIS app without changing every app.
//     The MaterialApp watches this controller and rebuilds when any of them change.
//
// FR: Détient les préférences de l'appli (FR-20) et les persiste via
//     StorageService. Trois réglages indépendants, chacun par défaut « suivre le
//     téléphone / le framework » pour qu'une nouvelle installation n'impose jamais
//     un choix :
//       • locale      — null suit la langue de l'OS ; « en »/« fr » l'outrepasse,
//       • themeMode    — système / clair / sombre,
//       • textScale    — un multiplicateur DANS l'appli appliqué par-dessus la
//                        taille de texte de l'OS, pour qu'un utilisateur agrandisse
//                        CETTE appli sans changer toutes les applis.
//     Le MaterialApp observe ce contrôleur et se reconstruit quand l'un d'eux change.

import 'package:flutter/material.dart';

import 'package:snowbird_in_usa_tracker/services/storage_service.dart';

// EN: The discrete text-scale steps offered in Settings, and the clamp bounds that
//     guard against a stored value outside this range (e.g. from a future version).
//     Discrete steps (not a free slider) keep the choice simple and legible for an
//     older audience, and every step stays within a layout-safe range.
// FR: Les paliers d'échelle de texte proposés dans les Réglages, et les bornes de
//     serrage contre une valeur stockée hors plage (p. ex. d'une version future).
//     Des paliers discrets (pas un curseur libre) gardent le choix simple et
//     lisible pour un public plus âgé, et chaque palier reste dans une plage sûre
//     pour la mise en page.
const double kMinTextScale = 0.85;
const double kMaxTextScale = 1.6;
const List<double> kTextScaleOptions = <double>[0.85, 1.0, 1.2, 1.4, 1.6];

class SettingsController extends ChangeNotifier {
  final StorageService _storage;

  Locale? _locale;
  ThemeMode _themeMode = ThemeMode.system;
  double _textScale = 1.0;
  bool _highContrast = false;

  SettingsController(this._storage) {
    _themeMode = _parseThemeMode(_storage.themeModeName);
    _textScale =
        _storage.textScale.clamp(kMinTextScale, kMaxTextScale).toDouble();
    _highContrast = _storage.highContrast;
    final code = _storage.localeCode;
    _locale = code == null ? null : Locale(code);
  }

  // EN: null = follow the OS language.
  // FR: null = suivre la langue de l'OS.
  Locale? get locale => _locale;
  ThemeMode get themeMode => _themeMode;
  double get textScale => _textScale;

  // EN: High contrast with bold text (FR-21), in addition to the phone's own settings:
  //     off means "follow the phone", never "less than the phone asks for".
  // FR: Contraste élevé et texte gras (FR-21), en plus des réglages du téléphone :
  //     désactivé signifie « suivre le téléphone », jamais « moins que demandé ».
  bool get highContrast => _highContrast;

  Future<void> setHighContrast(bool value) async {
    _highContrast = value;
    await _storage.setHighContrast(value);
    notifyListeners();
  }

  Future<void> setLocale(Locale? locale) async {
    _locale = locale;
    await _storage.setLocaleCode(locale?.languageCode);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _storage.setThemeModeName(mode.name);
    notifyListeners();
  }

  Future<void> setTextScale(double scale) async {
    _textScale = scale.clamp(kMinTextScale, kMaxTextScale).toDouble();
    await _storage.setTextScale(_textScale);
    notifyListeners();
  }

  // EN: Map a stored ThemeMode name back to the enum, defaulting to system for any
  //     unrecognised value.
  // FR: Reconvertir un nom de ThemeMode stocké en enum, avec système par défaut
  //     pour toute valeur non reconnue.
  static ThemeMode _parseThemeMode(String name) => ThemeMode.values.firstWhere(
        (m) => m.name == name,
        orElse: () => ThemeMode.system,
      );
}
