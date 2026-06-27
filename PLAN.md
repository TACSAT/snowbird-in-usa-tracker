# SnowBird-In-USA-Tracker — Project Plan

_Last updated: 2026-06-27_

## What this is

A **privacy-first, on-device record-keeper and trip planner** for visitors to the
United States. It lets a user log the trips they have already taken and sketch out
trips they plan to take, and see their day counts over any window — so they can plan
an extended winter without losing track of how much time they have spent across all
their trips.

The creator already does this by hand in Excel and built this to make the same task
easier, faster, and shareable. It is shared free.

## Positioning — what it is NOT

This is deliberately **a calculator and a logbook, not an adviser**. This framing is
the whole point and must not drift:

- ❌ **No alerts, alarms, or warnings.** It never tells the user they are "over a
  limit." There is no hard cumulative immigration day-limit it could honestly enforce
  (immigration lawyers call the "180-day rule" a myth — the real constraints are the
  per-entry 6-month admission, CBP officer discretion, and the separate IRS tax test).
- ❌ **No legal, tax, or immigration advice.** It does not render a verdict on whether
  a trip is "safe."
- ❌ **No accounts, no cloud, no data collection, no background location.** Everything
  the user enters stays on their device.
- ✅ It just **counts days and shows the dates**, accurately, and lets the user print
  or share that record. The user is the judge; the app is the abacus.

A short, plain-language "this is a personal tracking tool, not advice — verify your
own situation" note belongs on first launch and in an About screen.

## Core features (MVP)

1. **Log past trips** — enter arrival and departure dates for each US trip.
2. **Plan future trips** — enter intended arrival/departure dates, clearly marked as
   _planned_ vs _actual_.
3. **Day counts** — show total days present within user-chosen windows (e.g. this
   calendar year, rolling last 365 days, a custom range). Counts are presented as
   neutral numbers, not pass/fail judgments.
4. **Print / export the trip list** — produce a clean, printable list of all trips
   (past and planned) the user can:
   - hand to or share with others (e.g. an accountant, a lawyer, a family member, or
     a border officer who asks "how many days were you here last year?"), and
   - use for their own planning.
   Export should be a self-contained file the user controls (e.g. PDF and/or CSV),
   shareable via the OS share sheet and printable via the system print dialog.
5. **Local backup the user controls** — because data never leaves the device, the user
   must be able to export/import their data so a new phone or a lost phone does not
   wipe their history. Treat this as part of MVP, not a nice-to-have.

## Build approach — how to make one app for iPhone **and** Android

**Recommendation: stay with Flutter (already chosen in `pubspec.yaml`). It is the
right tool.** One Dart codebase compiles to both a native iOS app and a native
Android app, which is exactly what a solo developer wanting both platforms cheaply
needs. The current dependencies already fit an on-device app: `shared_preferences`
and `path_provider` for local storage, `intl` for date handling, and the localization
setup for sharing the app beyond English later.

Why not the alternatives:
- **Native (Swift for iOS + Kotlin for Android)** = two separate codebases to build
  and maintain. Double the work for one solo developer, no upside for an app this
  simple.
- **React Native** is a reasonable cross-platform alternative, but there is no reason
  to switch — the project is already scaffolded in Flutter and Flutter's tooling for a
  simple, offline, form-and-list app is excellent.

**What shipping to both stores actually requires (real costs, even for a free app):**
- A **Mac** to build and submit the iOS app — already covered (developer is on macOS).
- **Apple Developer Program** membership: **US$99/year** (required to publish to the
  App Store).
- **Google Play Developer** account: **US$25 one-time** (required to publish to Play).
- App icons, screenshots, a privacy-policy URL (easy here — the honest answer is
  "this app collects nothing and stores everything on your device").

## Feedback, bug reports, and donations

All three should be **simple external links the app opens in the browser** — no backend
for the developer to run, and (for donations) this keeps the app out of in-app-purchase
rules and avoids the store 30% cut.

**Feature requests & bug reports** — pick one primary channel, linked from an in-app
"Feedback" / "Report a problem" button:
- _Recommended:_ a no-backend hosted form (e.g. **Tally** or **Google Forms**) — most
  accessible for the older, non-technical target users.
- _Optional, for transparency:_ a public **GitHub repository with Issues** for users
  comfortable with it, and as the project's source-of-truth.
- _Simplest fallback:_ a `mailto:` button that opens a pre-filled email to a dedicated
  feedback address.

**Donations** — a "Support the developer" button that opens an external browser link:
- _Recommended:_ **PayPal.me** (most familiar to the snowbird demographic) and/or
  **Ko-fi** / **Buy Me a Coffee** (simple, low fees, one-time or recurring).
- **Open the donation link in the external browser, not via in-app purchase.** Apple
  restricts IAP-based donations and takes a cut; an external web link for a developer
  tip is the clean, compliant path. Do not gate any app feature behind donating —
  donations are gratitude, not a paywall.

## Coding standards & repository

- **Open source, public on GitHub.** The source is published publicly — which also
  reinforces the privacy story (anyone can verify the app collects nothing) and lets
  the public GitHub Issues double as the bug/feature-request channel.
- **A `LICENSE` file is required before publishing** so reuse terms are explicit.
- **All code comments are bilingual — English _and_ French — and verbose.** Every
  comment is written in both languages (fitting for a Canadian, officially-bilingual
  audience) and explains the _intent and the "why"_, not just a restatement of what the
  line does. Favour fuller explanations over terse ones. Suggested convention: English
  first, then the French equivalent, e.g.
  ```dart
  // EN: Count only days marked as "actual" so planned trips never inflate the total.
  // FR: Ne compter que les jours marqués « réels » afin que les voyages planifiés
  //     ne gonflent jamais le total.
  ```
- This bilingual-verbose-comment rule applies to all Dart/code files in this project.
- **Author attribution in documentation is always `Veiðimaður - veidimadur.ca`.** Use
  this exact form (name + site) wherever documentation credits the author — README, the
  in-app About screen, store listings, the `LICENSE` copyright line, etc.

## Distribution

- Ship **free** on the **Apple App Store** and **Google Play**.
- Honest, privacy-forward store listing: "Tracks your US trip dates entirely on your
  device. No account, no cloud, no tracking. Print or share your trip record for
  planning." Privacy is the genuine differentiator and the marketing.
- Natural places to share it later: Canadian Snowbird Association, snowbird Facebook
  groups, winter-resident communities (note: distribution is the hardest part and is
  not solved yet — that is fine for a tool the creator built primarily for themselves).

## Out of scope (for now)

- Automatic border / location detection.
- Any cloud sync or multi-device account.
- Tax Substantial Presence Test math or immigration-rule verdicts.
- Multi-country / Schengen tracking. (A generic multi-jurisdiction day engine is a
  plausible _future_ direction if interest appears, but it is not the MVP and it would
  require legal-grade correctness before being marketed.)

## Rough build order

1. Data model for trips (actual + planned) and on-device storage.
2. Add / edit / delete a trip; list view sorted by date.
3. Day-count calculations over selectable windows.
4. Print / export to PDF + CSV via the OS share/print dialogs.
5. Local backup export/import.
6. About + "not advice" note; Feedback and Donate buttons (external links).
7. Store assets, privacy policy page, and submission to both stores.
