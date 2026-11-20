# CLAUDE.md — SnowBird-In-USA-Tracker

Privacy-first, **on-device** Flutter app: a record-keeper and planner for US-days
(snowbirds logging past trips, sketching planned ones, seeing day counts over any
window). Free, open source. **`PLAN.md` is the authoritative scope document** —
read it before adding features; this file covers day-to-day operating rules.

## Positioning invariants (the product IS these — never drift)

The dividing line (per PLAN.md, revised 2026-07-10) is **verdicts vs. arithmetic**:
the app never judges, but it computes any published formula the user could do by hand.

1. **Calculator and logbook, not an adviser.** No verdicts, no app-imposed limits,
   no judgment-laden alerts or "over the limit" colouring — there is no honest
   cumulative limit to enforce (the "180-day rule" is a myth; see PLAN.md). Counts
   are neutral numbers. **In scope as arithmetic:** the IRS Substantial Presence
   figure (published formula, shown neutrally with a disclaimer) and thresholds the
   *user* defines themselves (the app ships with none built in). User-created
   thresholds may carry **opt-in local notifications** (user picks the value, the
   window, and the delivery timing — on the day at a chosen local time, or
   hours/days ahead). Zero defaults, neutral wording, and every numeric input is
   hard-capped (`AlertLimits`) at entry and at deserialisation.
2. **No legal / tax / immigration advice.** Never render a verdict on whether a
   trip is "safe."
3. **No accounts, no cloud, no data collection, no background location.** All data
   stays on-device; no network calls in the data path. `uuid` exists precisely so
   IDs are generated locally. This is also the brand: SnowBird is the first of a
   planned family of **secure-by-design** apps (see PLAN.md → Strategic context),
   so this invariant outranks any feature that would bend it.
4. **Data durability rides the OS phone backup — the app ships no bespoke backup
   feature.** Store data where iCloud/Google device backup captures it (never flag
   "exclude from backup"; keep Android `allowBackup` on) so it survives a phone
   migration, but build no in-app backup/restore/export-for-backup or cloud option:
   the trip log is not sensitive data warranting bespoke protection, and no data is
   ever sent to the developer (see PLAN.md → FR-11 / NFR-1). The flagship US Presence
   Record export (#5) is a deliverable, not the backup mechanism.
5. **The "US Presence Record" (image / PDF / CSV export) is the flagship feature**,
   not a nice-to-have — it leads the store listing and every screenshot.

## Code style (hard rules)

- **Every code comment is bilingual — English first, then French — and verbose**,
  explaining intent and the "why", not restating the line:
  ```dart
  // EN: Count only days marked as "actual" so planned trips never inflate the total.
  // FR: Ne compter que les jours marqués « réels » afin que les voyages planifiés
  //     ne gonflent jamais le total.
  ```
  Applies to all Dart/code files. Existing files follow it — match them.
- **Author attribution in any documentation is exactly `Veiðimaður - veidimadur.ca`**
  (README, About screen, LICENSE, store listings).
- User-facing strings go through l10n: add to `lib/l10n/app_en.arb` **and**
  `app_fr.arb`, never hard-code them in widgets.

## Architecture

- `lib/main.dart` / `lib/app.dart` — entry + MaterialApp (localization wiring).
- `lib/models/trip.dart` — Trip model (actual vs planned).
- `lib/logic/day_counter.dart` — day-count math (the correctness-critical core;
  it has the test suite: `test/logic/day_counter_test.dart`).
- `lib/state/trip_repository.dart` — ChangeNotifier state layer (via `provider`).
- `lib/services/storage_service.dart` — on-device persistence
  (`shared_preferences` / `path_provider`).
- `lib/screens/` — UI screens.
- Localization: `l10n.yaml` + `lib/l10n/*.arb` → generated `AppLocalizations`
  (`flutter: generate: true`).

## Run / verify

```bash
flutter pub get
flutter analyze          # lints per analysis_options.yaml — keep it clean
flutter test             # day-counter tests are the safety net for count changes
flutter run              # simulator/device
```

**`build/` is a symlink to `~/development/builds/snowbird-in-usa-tracker` — do
not replace it with a real directory.** This repo lives in `~/Documents`, which
is synced by iCloud Drive; the file provider stamps `com.apple.FinderInfo` on
directories it manages (even `*.nosync` ones), and Xcode 26's codesign refuses
to sign a framework bundle carrying that xattr ("resource fork, Finder
information, or similar detritus not allowed" → `flutter build ios` dies with
Xcode status 255). Building through the symlink keeps artifacts outside the
synced tree. If the symlink is missing (fresh clone), recreate it:

```bash
mkdir -p ~/development/builds/snowbird-in-usa-tracker
ln -s ~/development/builds/snowbird-in-usa-tracker build
```

Any change to day-count logic needs a test in `test/logic/day_counter_test.dart`
first — inclusive-date edge cases (arrival day counts, departure day counts,
overlapping windows) are exactly where this app can silently lie to its users.
