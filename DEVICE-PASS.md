# Device pass, Step 7 (simulators)

| | |
|---|---|
| **Date** | 2026-11-27 |
| **Build** | branch `places-extras` (PR #9), all PRs #3 to #9 stacked |
| **Devices** | iPhone 17e simulator (iOS), `pixel_test` Android emulator |
| **How** | `tools/device_pass.sh <device>` and `tools/lock_pass.sh <iOS simulator>` |
| **Output** | `build/device_pass/` (screenshots, PDF, page images, text, CSV, day-by-day CSV) |

This is the part of Step 7 that simulators can do. It does **not** replace the real-phone
pass or the 4-week trial with travellers (section 16, step 7).

## What ran, and the result

| Check | iOS | Android |
|---|---|---|
| Old schema 2 trips in real storage load as US stays; nothing written by reading; one-time note shown (checklist 7, MIG-1, MIG-4) | Pass | Pass |
| Every new screen, EN and FR, rendered with real fonts (30 captures each) | Pass, reviewed | Pass, key screens reviewed |
| Largest app text, dark, high contrast: main, stay, Explore, export | Pass, reviewed | Pass, reviewed |
| PDF of all places and US-only, EN and FR, laid out and rasterised on the device (checklist 4) | Pass, reviewed | Pass |
| Text, CSV and day-by-day CSV built as the export screen builds them | Pass | Pass |
| Lock screen | Pass | Pass |
| Real Face ID check through `local_auth` (enrolled face, matching face) | Pass; a non-matching face does not pass | Not tried (emulator fingerprint needs a PIN set up by hand) |
| App starts with `FlutterFragmentActivity` and AppCompat themes | n/a | Pass |

## Found and fixed during the pass

- The record printed "Job or contract **(optional)**: ..." (the form's label). Now "Job or contract".
- The record printed "Days worked: 0 days" for stays with no work pattern, and for places with
  none worked. Now shown only where there is a pattern or a day worked; the CSV leaves the cell
  blank for a stay without a pattern.
- A worked day visit read "Travaillés" (plural) in French. Now "Travaillé sur place".

## Noted, not changed

- The main table shows "Worked 0" under places with no day worked, because TBL-12 asks for the
  line on every row when work is on. Could be hidden at zero if preferred.
- "Recent" places are ordered by arrival date, so a planned stay in the future comes first (the
  alert editor then defaults to Mexico in the test data).
- The floating + button covers part of a row's status chip while scrolling (standard Material).
- App bar titles shorten at the largest text ("SENALOVI..."), as before this work.
- French dates read "1 janvier" rather than "1er janvier" (date library); for the French review.

## Still to do on real phones (owner)

From `RELEASING.md`, device checklist: notifications (1 to 3), sharing to other apps and
printing (4), listening with VoiceOver and TalkBack (4, 5), iPad, the system date picker at the
largest system text (5), restoring a phone backup (8). For the new work also: Face ID, Touch ID
or fingerprint and the device code on real phones, the Android launch screen on Android 7 to 8,
and timing a move on a real phone (target under 15 seconds). Then the 4-week trial.
