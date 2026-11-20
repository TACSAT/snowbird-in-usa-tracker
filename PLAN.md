# SnowBird-In-USA-Tracker — Project Plan

_Last updated: 2026-07-11 (feature-complete for UAT: trip logbook + full field set,
image/PDF/CSV export, day-count & time-since-last-visit alerts, on-screen SPT,
Settings (language/theme/font), About/Reference/feedback/donate, one-time backup
reminder. 86 tests pass, analyze clean, release APK builds with no INTERNET
permission. Pre-2026-07-11: formal FR/NFR; OS-backup durability; expanded fields)_

## Strategic context — why this app exists beyond itself

This app is a **stepping stone, not the destination**. It fills a real need (day
tracking that the official I-94 record demonstrably gets wrong for land crossings)
with a **secure-by-design** solution — on-device, no accounts, no cloud, open
source — and in doing so establishes the credentials of a broader effort:

- **The brand is "secure by design."** Every future app under this umbrella shares
  the same DNA: data stays on the user's device, the source is open and auditable,
  and privacy is the default rather than a setting. This free app is the proof of
  that promise, made in public.
- **Some later apps will be profitable; this one is deliberately not.** SnowBird
  is the trust-builder and the reference implementation. Its job is to be correct,
  honest, and genuinely useful to a community — and to make the brand's name mean
  something before anything is ever sold.
- **The day-count engine is a reusable platform asset.** The tested any-window
  math generalizes directly to Schengen 90/180, provincial health-coverage clocks
  (e.g. OHIP's 153 days), UK visitor rules, and other residency counters. Future
  apps can be skins over the same correctness-critical core.

Design decisions in this plan should therefore be judged on two axes: does it
serve the snowbird user, and does it uphold the secure-by-design standard the
brand will be held to later.

## What this is

A **privacy-first, on-device record-keeper and trip planner** for visitors to the
United States. It lets a user log the trips they have already taken and sketch out
trips they plan to take, and see their day counts over any window — so they can plan
an extended winter without losing track of how much time they have spent across all
their trips.

The creator already does this by hand in Excel and built this to make the same task
easier, faster, and shareable. It is shared free.

## Positioning — what it is NOT

This is deliberately **a calculator and a logbook, not an adviser**. The key
distinction — sharpened in the 2026-07-10 revision — is **verdicts vs. arithmetic**:
the app never judges, but it does compute any published formula the user could do
by hand. Refusing the arithmetic was over-caution that made the app less useful
than a spreadsheet; refusing verdicts remains the whole point and must not drift:

- ❌ **No verdicts, ever.** It never tells the user a trip is "safe," "allowed," or
  that they are "over the limit." There is no hard cumulative immigration day-limit
  it could honestly enforce (immigration lawyers call the "180-day rule" a myth —
  the real constraints are the per-entry 6-month admission, CBP officer discretion,
  and the separate IRS tax test).
- ❌ **No app-imposed limits or judgment-laden alerts.** The app ships with no
  built-in thresholds and never colours a number "dangerous" on its own authority.
- ❌ **No legal, tax, or immigration advice.**
- ❌ **No accounts, no cloud, no data collection, no background location.** Everything
  the user enters stays on their device.
- ✅ **Published arithmetic IS in scope.** The IRS Substantial Presence Test is a
  public, deterministic formula (this year's days + ⅓ of last year's + ⅙ of the year
  before). Computing it and displaying the resulting figure — as a neutral number,
  with the standard disclaimer — is calculation, not counsel. It is also the one
  computation the target user genuinely cannot do in a notebook.
- ✅ **User-defined thresholds ARE in scope.** The user may enter their own
  reference numbers (e.g. "show me against 182" or "against 153 for my provincial
  health coverage") and the app displays the count and the distance to *their*
  number. Their number, their responsibility; the app remains the abacus.
- ✅ **User-defined notifications ARE in scope.** The user may attach an opt-in
  local notification to a threshold *they* created (e.g. "notify me when I reach
  75 days in the last 36 months"), including *when* it fires: at a chosen local
  time (e.g. 09:00) on the day the target is reached, or a user-chosen number of
  hours/days in advance of that date. The app ships with **zero** built-in
  notifications and zero default values — every number is the user's. Wording is
  neutral ("You have reached 75 days — the target you set"), never a judgment.
  All numeric inputs are hard-capped and validated on entry *and* on
  import/deserialisation, so crafted values cannot overflow date math or schedule
  pathological work. Notifications are scheduled locally on-device — no push
  service, no network.
- ✅ It **counts days and shows the dates**, accurately, and lets the user print
  or share that record. The user is the judge; the app is the abacus.

A short, plain-language "this is a personal tracking tool, not advice — verify your
own situation" note belongs on first launch, in an About screen, and on any screen
that displays the Substantial Presence figure.

## Core features (MVP)

The flagship feature is **#4, the printable record** — it is the product, not a
nice-to-have. The official I-94 travel history routinely misses land-border
crossings (snowbirds and travel insurers both document this), so a clean,
self-maintained "US Presence Record" the user can hand to a border officer, an
accountant at tax time, or an insurer is the app's strongest reason to
exist. It should be the first store screenshot and the lead of every description.

1. **Log past trips** — enter arrival and departure dates for each US trip.
2. **Plan future trips** — enter intended arrival/departure dates, clearly marked as
   _planned_ vs _actual_. The planning question — "what happens to my counts if I
   take this trip in March?" — must be answerable in seconds; this windowed what-if
   math is exactly what paper calendars and the I-94 site cannot do.
3. **Day counts** — show total days present within user-chosen windows (e.g. this
   calendar year, rolling last 365 days, a custom range). Counts are presented as
   neutral numbers, not pass/fail judgments.
4. **Print / export the "US Presence Record"** _(flagship)_ — produce a clean,
   printable, evidence-grade list of all trips (past and planned, clearly
   distinguished) with per-window totals, that the user can:
   - hand to or share with others (e.g. an accountant, a lawyer, a family member, or
     a border officer who asks "how many days were you here last year?"), and
   - use for their own planning.
   Export should be a self-contained file the user controls (image, PDF, or CSV),
   shareable via the OS share sheet and printable via the system print dialog.
5. **Data durability via the OS phone backup — no bespoke backup feature.** The app
   stores its data where the platform's normal device backup captures it, so a new
   phone or a migrated phone carries the history across automatically. The developer
   ships **no** separate in-app backup, restore, or cloud-storage option: the trip
   log is not sensitive data that warrants bespoke protection, and riding the user's
   own iCloud/Google phone backup is sufficient. (The flagship US Presence Record
   export in #4 doubles as a manual, user-controlled archive, but it is a deliverable,
   not the backup mechanism.) See FR-11 for the concrete storage/backup rules.
6. **Substantial Presence figure** — compute and display the IRS Substantial
   Presence Test number (current-year days + ⅓ prior year + ⅙ year before) as a
   neutral figure with the standard disclaimer, and include it on the printed
   record. Arithmetic only — no pass/fail rendering (see Positioning).
7. **User-defined thresholds with opt-in notifications** — let the user enter
   their own reference numbers (threshold days + window, e.g. 75 days in the last
   36 months) and see each window's count alongside the distance to that number.
   Optionally, each threshold can schedule a **local notification**: the user
   chooses the delivery time of day (e.g. 09:00 local) and whether it fires on the
   day the target is reached or hours/days in advance. The projected reach date is
   computed from actual + planned trips. No thresholds and no notifications ship
   built-in; the user supplies every value, and every input is validated against
   hard maximums (see Positioning).

## Functional Requirements

_These formalise the informal "Core features" list above; where the two conflict,
these govern. Requirements marked ✅ are already implemented and tested as of
2026-07-10; the rest are planned. Every requirement inherits the Positioning
invariants (published arithmetic, never verdicts) and the bilingual code-style rules._

### Trip logging

- **FR-1 — Log numerous past (actual) trips.** The user can add an arbitrary number
  of past trips. **Only the entry (arrival) date and exit (departure) date are
  mandatory.** Each trip also accepts optional fields — all bounded by the entry limits
  (FR-5):
  - **per crossing** (recorded for the entry and for the exit): time of day (hour),
    time zone, location (where the crossing happened), means of travel, and carrier;
  - **trip-level**: a **trip name** the user gives it to remember the trip's purpose,
    and free-text **notes**.
  These fields define the canonical *trip record* that FR-2 and FR-3 reuse. Every field
  is validated on entry against hard maximums (`input_limits.dart`) — caps on the number
  of trips, on text length, and on the plausible date/time range — so no crafted or
  fat-fingered value can overflow the date math or the store. ✅ _(base model + engine
  built; the optional fields above extend the model)_
- **FR-2 — Manage the current trip.** For an in-progress trip the user can add, change,
  and delete the trip's info — the same trip-record fields as FR-1, though the exit date
  may still be open — under the same entry limits and validation. The current trip is
  clearly distinguished in the UI from completed and planned trips.
- **FR-3 — Plan numerous future trips.** The user can add an arbitrary number of planned
  future trips with the same trip-record fields (FR-1) and entry limits, always marked
  _planned_ (never counted as actual presence). Planned trips drive the what-if day-count
  and the projected threshold-reach date.
- **FR-4 — Edit and delete any trip.** Any trip — past, current, or planned — can be
  edited or deleted. The trip list is sorted by date and visually separates actual from
  planned.
- **FR-5 — Entry limits & data integrity.** All numeric, text, and date inputs are
  bounded and validated both on entry **and** on deserialisation/import. The app rejects
  impossible input (departure before arrival, an "actual" trip dated in the future,
  overlapping actual trips) rather than silently storing something that would corrupt a
  count. Entry limits exist specifically to reduce overflow and pathological-work risk.

### Counts, arithmetic & the record

- **FR-6 — Day counts over selectable windows.** Neutral day totals over user-chosen
  windows (calendar year, rolling 365 days, custom range), shown as numbers, never
  pass/fail. ✅
- **FR-7 — Substantial Presence figure.** Compute and display the IRS SPT figure
  (current-year days + ⅓ prior year + ⅙ year before) as a neutral number with the
  standard disclaimer. ✅
- **FR-8 — The US Presence Record (flagship).** Produce a clean record of all trips
  (actual + planned, clearly distinguished) with per-window totals and the SPT figure,
  exportable as an **image**, a **PDF**, and a **CSV** file, shareable via the OS share
  sheet and printable via the system print dialog. This export doubles as the user's
  manual archive (they can email the file to themselves) but is a deliverable, not the
  backup mechanism (see FR-11).

### Alerts & notifications

- **FR-9 — Current-trip trigger alerts.** During a trip the user can set opt-in local
  notifications on trigger events they define (e.g. "notify me when this trip reaches N
  days," "when my rolling-window count reaches M"). Alerts matter most mid-trip. The user
  picks the value, the window, and the delivery timing — on the day at a chosen local
  time, or a chosen number of hours/days ahead. Zero built-in defaults; neutral wording.
  ✅ _(engine + scheduler built)_
- **FR-10 — Standalone notifications, independent of any trip.** The user can set
  notifications not tied to a current trip — for example "tell me when it has been more
  than five years since my last US visit." These fire on user-defined elapsed-time or
  calendar conditions computed from the trip history, scheduled locally on-device, with
  no push service and no network.

### Data, durability & lifecycle

- **FR-11 — Durability via the OS phone backup; no bespoke backup feature.** App data is
  stored where the platform's normal device backup captures it — on iOS in a location
  included in iCloud/Finder backup (never flagged "exclude from backup"), on Android under
  Auto Backup with `allowBackup` enabled — so it travels with the user's regular phone
  backup and device migration. The developer ships **no** separate in-app backup, restore,
  export-for-backup, or cloud-storage option, and sends **no** data anywhere: the trip log
  is not sensitive data warranting bespoke protection. At setup the app shows **one**
  reminder — not repeated afterwards — telling the user that their data is kept safe only by
  their normal phone backup and that they should make sure that backup is enabled.
- **FR-12 — On-device schema versioning & migration.** Stored data carries a schema
  version; app updates migrate older data forward without loss or corruption. Because there
  is no cloud copy, a bad migration is unrecoverable — migrations are covered by tests.
  _(Maintenance-critical.)_
- **FR-13 — Fail-safe persistence.** Saves are atomic/crash-safe so an interrupted write
  never empties or corrupts the store; on unreadable data the app degrades gracefully
  (surfaces the problem, preserves what it can) rather than wiping history.

### Onboarding, guidance & support

- **FR-14 — First-launch & About "not advice" notice.** A plain-language "personal
  tracking tool, not advice — verify your own situation" note on first launch, in an About
  screen, and on any screen that shows the SPT figure.
- **FR-15 — Plain-language reference for common thresholds.** Because the app ships zero
  default thresholds (a Positioning invariant), a neutral educational page lists the numbers
  people commonly track (the IRS SPT/183 test, provincial health-coverage clocks, etc.),
  framed as "these are rules people track — ask your professional," so the user is not
  typing a number into a blank box from memory. It informs; it never prescribes or judges.
- **FR-16 — Feedback, bug reports & donations as external links.** In-app buttons open
  external browser links (a no-backend hosted form / public GitHub Issues / `mailto:` for
  feedback; PayPal.me / Ko-fi for donations). No backend, no in-app purchase, nothing gated
  behind donating.
- **FR-17 — Bilingual EN/FR throughout.** Every user-facing string is localised in English
  and French via the l10n pipeline; no hard-coded strings in widgets. ✅
- **FR-18 — Diagnostics without telemetry.** An About/diagnostics area shows the app version
  and build number so user-reported issues are actionable, while collecting and transmitting
  nothing. _(Supports maintenance without breaking the no-data-collection invariant.)_
- **FR-19 — Notification-permission lifecycle.** The app requests notification permission
  only when the user first creates an alert, explains why, and handles denial or later
  revocation gracefully (alerts degrade to in-app only; no nagging).

### Preferences & accessibility

- **FR-20 — In-app preferences.** The app offers user-settable options, each independent
  of the phone's system settings: **language** (English / French), **theme** (light /
  dark / follow system), and an **in-app font-size / text-scale control separate from the
  OS font size** — so a user can enlarge this app's text without changing every other app
  on their phone. These matter because the likely users are older adults who want to see
  everything clearly. Preferences persist on-device.
- **FR-21 — Accessibility for older adults (always-on).** Beyond FR-20's options, the app
  is accessible by default for a near-/post-retirement audience: large legible type and
  generous tap targets; an optional high-contrast / bold-text mode; meaning never conveyed
  by colour alone (which also upholds the no-"danger"-colouring invariant); full
  VoiceOver / TalkBack labelling; reduced or optional motion; uncluttered, plain-language
  layouts; and a confirmation step before destructive actions such as deleting a trip. It
  honours the OS dynamic-type and accessibility settings **in addition to** FR-20's in-app
  controls, so a user helped by either path is covered.

## Non-Functional Requirements

_NFR-1 is the requirement you specified; the rest are derived from the plan's standing
invariants and the target demographic. Extend or override as needed._

- **NFR-1 — Local-only data, nothing sent to the developer.** App data is backed up
  **only** by the user through their normal phone backup solution (iCloud / Google), and
  **no data is ever sent back to the app developer** — no telemetry, no analytics, no crash
  uploads, no accounts, no cloud sync. This is a brand invariant, not a preference. (The
  phone backup in FR-11 is the user's own, not a developer-operated service.)
- **NFR-2 — Offline-first.** Full functionality with no network connection, ever. The only
  thing that opens the network is the user tapping an external feedback/donate link.
- **NFR-3 — No background location, no device tracking.** The app never reads location or
  runs background tasks to detect border crossings — trips are user-entered.
- **NFR-4 — Correctness of the count engine.** The day-count and SPT math is the
  correctness-critical core; every change is test-first, covering inclusive-date edge cases
  (arrival/departure day counting, overlapping windows). The app must never silently
  miscount.
- **NFR-5 — Accessibility for a near-/post-retirement audience.** The always-on quality
  behind FR-20/FR-21: large legible type, high contrast, generous tap targets, minimal
  jargon, screen-reader compatibility, and no meaning carried by colour alone; respects the
  OS dynamic-type and accessibility settings as well as the app's own language/theme/font
  controls. The primary user is older and non-technical, so ease of seeing and operating the
  app is a first-class requirement, not a polish item.
- **NFR-6 — Performance on modest hardware.** Date-window computations and record generation
  stay responsive on older/low-end phones; the FR-5 input caps bound worst-case work.
- **NFR-7 — Reliability & data integrity.** No data loss across app updates, crashes, or
  interrupted writes (see FR-12 / FR-13).
- **NFR-8 — Localization quality.** Idiomatic EN and FR (not machine-literal); dates and
  numbers formatted per the active locale.
- **NFR-9 — Maintainability.** `flutter analyze` stays clean; bilingual verbose comments per
  the code-style rules; the day-count engine stays decoupled and reusable (it is the platform
  asset for future secure-by-design apps); schema migrations are documented and tested.
- **NFR-10 — Platform compatibility & store compliance.** Ships to current iOS and Android;
  satisfies both stores' privacy-label and content rules; a privacy-policy page states,
  honestly, "collects nothing, stores everything on your device."
- **NFR-11 — Input security.** All numeric inputs are hard-capped and validated at entry and
  at deserialisation so crafted values cannot overflow the date math or schedule pathological
  notification work.

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

## Distribution and the competitive landscape

Be honest about the field: **in this category, distribution is the whole game.**
The 7-year category leader has only ~163 App Store ratings, so nobody wins on
shelf presence — apps here spread through trusted community channels or not at all.

**Who is already here (checked 2026-07-10):**
- **Snowbirds US Day Tracker** — the incumbent: free, ~4.8★, ~12k users, since
  ~2019. Does the Substantial Presence math and milestone alerts, but **requires a
  cloud account**. That is the lane it cannot follow us into.
- **SnoBird (Galon Insurance)** — tracks the same three windows plus SPT; an
  insurance-brokerage funnel.
- **Snowbird: Travel Days Tracker** — has a US$79.99/yr paid tier with a single
  rating: strong evidence that *paid* does not work in this category (and support
  for keeping this app free).
- **SnowbirdAdvisor's free web calculator** — no persistence, no record-keeping.

**Our open lane is privacy.** Every serious competitor wants an account or is a
sales funnel. "Your data never leaves your device, and you can read the source to
verify it" is a position none of them occupy — and it is also the brand thesis
(see Strategic context). The listing writes itself: "Tracks your US trip dates
entirely on your device. No account, no cloud, no tracking. Print your US
Presence Record for the border, your accountant, or your insurer."

**Plan of record, not "later":**
- Ship **free** on the **Apple App Store** and **Google Play**.
- Lead every listing, screenshot, and post with the printed **US Presence Record**
  (the flagship — see Core features) and the I-94-gap story: the official record
  misses land crossings, so keep your own.
- Channels, in order of trust for this demographic: Canadian Snowbird Association
  (forums/newsletter), Snowbird Advisor newsletter, snowbird Facebook groups
  (including French-language Floribec communities — the bilingual EN/FR build is a
  real differentiator there), RV-park and winter-resident communities. Regulatory
  news cycles (rule-change panics) are recurring free-attention moments.
- **Cheap validation before store fees:** mock two screenshots — (A) logbook +
  printed record only, (B) the same plus the neutral SPT figure and a user-defined
  threshold line — and post them in one snowbird community asking which they'd
  use. Costs nothing, answers the live positioning question before the US$124 in
  store fees is spent.

## Out of scope (for now)

- Automatic border / location detection.
- Any cloud sync or multi-device account (a brand invariant, not just a scope cut).
- Immigration-rule or tax **verdicts** of any kind. (Note: the Substantial Presence
  *arithmetic* moved into MVP in the 2026-07-10 revision — computing the published
  formula is in scope; judging the result is not.)
- Multi-country / Schengen tracking. (A generic multi-jurisdiction day engine is the
  explicit _future_ direction for the secure-by-design app family — see Strategic
  context — but it is not this MVP and it would require legal-grade correctness
  before being marketed.)

## Rough build order

1. ✅ Data model for trips (actual + planned) and on-device storage.
2. ✅ Day-count calculations over selectable windows (engine + test suite).
3. ✅ Add / edit / delete a trip (with the full FR-1 field set: dates mandatory,
   optional name/notes and per-crossing time/zone/location/means/carrier); list
   view sorted by date with a neutral day-count summary; first-launch disclaimer
   (FR-14) and one-time backup reminder (FR-11); Android `allowBackup` made
   explicit. (Trip form + list + onboarding built and widget-tested 2026-07-10.)
4. ✅ Substantial Presence figure + user-defined thresholds. Built 2026-07-11: the
   SPT figure shows on the main summary card (FR-7) with its required not-advice
   note, tappable through to the reference page; user-defined day-count alerts
   (FR-9) and standalone "time since last visit" alerts (FR-10) both schedule local
   notifications. Engine + repository + model changes are unit-tested.
5. ✅ Print / export the **US Presence Record** to image, PDF, and CSV via the OS
   share/print dialogs — the flagship. Built 2026-07-10: pure-Dart `PresenceRecord`
   (per-window totals + neutral SPT figure + CSV) is unit-tested; `RecordExporter`
   renders the PDF with the standard Latin-1 font (no bundled font, no network —
   verified no dependency injects the INTERNET permission), rasterises to PNG, and
   drives print/share. On-device visual rendering (glyphs, layout, print sheet) is
   a physical-test item. Store-screenshot polish still to do.
6. ✅ Data durability: Android `allowBackup="true"` made explicit (FR-11); trip and
   alert models are additive/migration-safe (FR-12), covered by tests. No in-app
   backup UI is built, by design. (iOS "exclude from backup" not set — the store is
   in the app documents/preferences area, which iCloud backs up; confirm on device.)
7. ✅ About + "not advice" note (FR-14); Settings — language / theme / font size
   (FR-20/21); Feedback / Donate / Source external links (FR-16, url_launcher) and
   app version/build via `package_info_plus` (FR-18); a neutral common-rules
   reference page (FR-15). Reached from the trip-list overflow menu. Built 2026-07-11.
8. Community validation post (see Distribution), then store assets, privacy policy
   page, and submission to both stores. **Remaining before submission:** replace the
   placeholder feedback/donate/source URLs in `lib/config/app_links.dart`; add app
   icons + store screenshots; on-device UAT (visual rendering, print/share sheets,
   real notification delivery, iOS build/signing).
