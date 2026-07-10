# SnowBird-In-USA-Tracker — Project Plan

_Last updated: 2026-07-10 (revised after an adversarial council review of the plan)_

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
accountant at Form 8840 season, or an insurer is the app's strongest reason to
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
   Export should be a self-contained file the user controls (e.g. PDF and/or CSV),
   shareable via the OS share sheet and printable via the system print dialog.
5. **Local backup the user controls** — because data never leaves the device, the user
   must be able to export/import their data so a new phone or a lost phone does not
   wipe their history. Treat this as part of MVP, not a nice-to-have.
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
3. Add / edit / delete a trip; list view sorted by date.
4. Substantial Presence figure + user-defined thresholds (extend the day-count
   engine; tests first in `test/logic/day_counter_test.dart`, same as any count
   change).
5. Print / export the **US Presence Record** to PDF + CSV via the OS share/print
   dialogs — the flagship; budget polish time here, it is the store screenshot.
6. Local backup export/import.
7. About + "not advice" note; Feedback and Donate buttons (external links).
8. Community validation post (see Distribution), then store assets, privacy policy
   page, and submission to both stores.
