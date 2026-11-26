# Requirements: tracking days by place and by work

| | |
|---|---|
| **Status** | Version 3. **Approved by the owner 2026-11-25 (decisions in section 17).** Step 0 reported done by the owner 2026-11-26. Step 1 (model, migration, engine) built on branch `places-engine`, 2026-11-26. |
| **Date** | 2026-11-25 |
| **Changes** | The app counts days in *any place the user tracks*, not only the United States |
| **Maker** | teagarden.net |

**Must** = part of this change. **Should** = soon after. **Could** = later.


## 1. Who and why

**Owner's decision:** an app mainly for Canadians wintering in the United States enters a
crowded market. The first release will instead serve anyone who moves around North America for
long periods, and will take the time that needs. The US-only version will not be published.

| Group | Served by |
|---|---|
| **Full-time RV travellers**, of any citizenship or none of the four | Days by country and region |
| **Seasonal and travelling workers** (farm, fishing, forestry, wildfire, oil and gas, construction, events, health care, guiding) | The same, plus days worked |
| **Snowbirds and cross-border families** | The same, simpler |

| Example user | Needs |
|---|---|
| Ontario resident wintering in Florida | Days in Ontario, in Canada, in the US |
| Full-time RVer, Alberta licence, no fixed home | Days per province and territory, per country |
| US citizen summering in BC and Yukon | Days in Canada; perhaps days per US state |
| Mexican resident visiting the US and Canada | Days in each country |
| French citizen touring all four | Days in each country |
| Mexican farm worker in Ontario each season | Days in Ontario and in Mexico; days worked; Spanish |
| Travelling nurse on contracts in several states | Days present and days worked, per state |
| Wildfire or pipeline crew moving between provinces | Quick "moved to" entry, often without a signal |
| Person living in one place and working in another | Presence and work in the second place without dozens of entries |
| Existing user who only counts US days | **Nothing gets harder** |

## 2. Principles

- **PRN-1** Arithmetic, never verdicts. No built-in limits, no "danger" colours, no advice.
- **PRN-2** On-device only: no account, cloud, network or location. Places are typed or
  chosen, never detected.
- **PRN-3** **Citizenship and immigration status are not asked for or stored.** They do not
  change how many days someone was somewhere. The user chooses which places to track. This
  serves every combination, including "none of them", and keeps sensitive data off the device.
- **PRN-4** A place not recorded is *unknown*, never assumed (but see section 6).
- **PRN-5** Works fully with no signal, on an older or low-cost phone, one-handed.
- **PRN-6** Recording work is optional and off by default. Someone who does not use it never
  sees it.

## 3. Terms

| Term | Meaning |
|---|---|
| **Country** | Canada, United States, Mexico, France (Saint-Pierre-et-Miquelon), or Elsewhere |
| **Region** | Province, territory, state or district within a country |
| **Place** | A country, with or without a region |
| **Stay** | A continuous period in one place: from, to (or ongoing), actual or planned |
| **Day worked** | A date the user marks as worked, in a place. Never inferred |
| **Day visit** | Presence in another place on a date, without moving there |
| **Journey** | Optional name grouping several stays ("Winter 2027") |
| **Tracked place** | A place the user wants shown in the Days present table |

## 4. Places

- **PLC-1 (Must)** Every stay has a country.
- **PLC-2 (Must)** Region is optional, and offered for:

| Country | Regions | Priority |
|---|---|---|
| Canada | 10 provinces, 3 territories | Must |
| United States | 50 states, District of Columbia | Must, optional to use |
| Mexico | 32 federal entities | Must, optional to use |
| France | Saint-Pierre-et-Miquelon only | Not needed; the country entry names it |

- **PLC-3 (Must)** Puerto Rico and other US territories are **separate entries, not part of
  the United States count**. For the Substantial Presence Test, "United States" does not
  include US territories ([IRS][1]).
- **PLC-4 (Must)** Saint-Pierre-et-Miquelon is recorded as itself, shown under France. It is
  French but [not in the Schengen area][2] and has its own entry rules, so its days must never
  be added silently to metropolitan France. Metropolitan France falls under
  Elsewhere for now.
- **PLC-5 (Must)** "Elsewhere" covers any other country, with an optional name, so that time
  away is *known* rather than blank.
- **PLC-6 (Must)** Places are stored as standard codes (ISO 3166-1 and 3166-2, for example
  `CA`, `CA-ON`, `US-FL`, `MX-SON`, `PM`), never as names, so language or naming changes cannot
  alter records.
- **PLC-7 (Must)** Official names in English and French. Short names where space is tight, with
  the full name for screen readers.
- **PLC-8 (Must)** The place list ships in the app. An unknown code (from a newer version) is
  shown as its code and still counted, never dropped.
- **PLC-9 (Should)** Recently used places come first in the chooser; search by name.

## 5. Recording stays

- **STY-1 (Must)** A stay needs country and arrival date; departure may be open. All existing
  optional details remain (name, notes, time, zone, location, means, carrier).
- **STY-2 (Must)** **Add next stop:** from any stay, start the next one with its arrival date
  set to this one's departure. A border crossing is entered once, not twice.
- **STY-3 (Must)** **Moving on while ongoing:** "I have moved to..." closes the current stay and
  opens the next on the same date, in one step.
- **STY-4 (Must)** Several places in one day are allowed (breakfast in Ontario, lunch in New
  York, night in Quebec). Same-day order follows recorded times, otherwise entry order, and
  the user can reorder.
- **STY-5 (Must)** Two *actual* stays may share only a boundary day, in any two places. The
  same rule as today, now across all places.
- **STY-6 (Must)** Planned stays may overlap anything, so alternatives can be compared.
- **STY-7 (Must)** Moving between regions inside one country is not a border crossing: no
  crossing details are asked for, though they can be added.
- **STY-8 (Must)** A stay recorded with no region counts for the country and appears as
  "region not recorded", never spread across regions.
- **STY-9 (Must)** Refine later: split an existing stay into regions without retyping it. The
  country total must not change.
- **STY-10 (Should)** Gaps between actual stays are listed, with an offer to fill them. No
  nagging.
- **STY-11 (Should)** Group stays into a journey; show the list by date or by journey.
- **STY-12 (Could)** Repeat a past journey as a plan.

## 6. Home base (optional, off by default)

Without it, a resident would have to log every day at home.

- **HOM-1 (Must)** The user may set one home place with a start date; it may change over
  time (a move to another province).
- **HOM-2 (Must)** Days with no recorded stay then count for the home place as
  **assumed** days: always labelled, shown separately from recorded days, and never mixed
  into an export without saying so.
- **HOM-3 (Must)** Off by default. Not a statement of legal residence, and worded so.
- **HOM-4 (Must)** Without it, unrecorded days show as "not recorded".
- **HOM-5 (Must)** By "any part of the day", the day a stay starts after an unrecorded day
  and the day it ends before one also count as assumed days at home: the user was home for
  part of them. Not when that date is already recorded in the home place. (Owner, 2026-11-26.)

## 7. Work (optional)

- **WRK-1 (Must)** Turned on in Settings. Until then no work field, column or export appears.
- **WRK-2 (Must)** **Days worked and days present are different figures.** Being somewhere "for
  work" does not make every day a worked day; the app never infers one from the other.
- **WRK-3 (Must)** Mark days worked quickly: a weekday pattern for a stay, then correct single
  days on a calendar. Changing the stay's dates never invents worked days outside it.
- **WRK-4 (Must)** A day worked has a place, by default the stay's. It may differ (living in
  Ottawa, working in Gatineau).
- **WRK-5 (Must)** Working in another place that day is a **day visit** there: it counts as
  presence by "any part of the day", not by "end of day". This also covers shopping or
  appointments, and spares commuters dozens of stays.
- **WRK-6 (Must)** A date may be worked in several places; it counts once in each.
- **WRK-7 (Should)** A stay may carry a purpose (personal, work, transit, other) and a label such
  as a job or contract. Labels are free text and optional.
- **WRK-8 (Must)** **Work details stay out of exports unless the user adds them each time.** What
  someone does in a country can affect their right to be there, and a record handed to an
  officer, employer or landlord should contain only what the user chose.
- **WRK-9 (Must)** No wages, hours, employer verification, work-permit details or advice.
- **WRK-10 (Must)** Totals, alerts, custom ranges and what-if offer days worked per place.
- **WRK-11 (Should)** Optional lock with the phone's own face, fingerprint or code, since phones
  in shared housing are handled by others. Uses the phone's service; nothing leaves it.

## 8. How days are counted

This is where the app could silently mislead, so it is tested first.

- **CNT-1 (Must)** Two conventions, computed side by side and always labelled:

| Convention | A day counts when the user was there |
|---|---|
| **Any part of the day** (default) | at any moment of it |
| **End of day** | at midnight ending it |

  The US test counts any part of a day ([IRS][1]), and Canada's deemed-resident count includes
  [each day or part of a day][3]. Other rules may differ, so the user chooses the convention
  for each tracked place.

- **CNT-2 (Must)** With "any part", **a crossing day counts in both places**. So places add up
  to more than the calendar. The app says this next to the table, and never shows a sum of
  places as if it were days.
- **CNT-3 (Must)** Within one place, a date counts once, however many stays cover it.
- **CNT-4 (Must)** A country counts unique dates across its regions: it is **not** the sum of
  its regions.
- **CNT-5 (Must)** With "end of day", each date belongs to at most one place. An ongoing stay
  counts through yesterday; today is not yet ended.
- **CNT-6 (Must)** Actual days stop at today. Planned, assumed and not-recorded days are always
  separate figures.
- **CNT-7 (Must)** Dates are local to the place. A journey across time zones changes no date
  the user entered.
- **CNT-8 (Must)** A stay passing through without staying counts like any other; the user may
  delete it. Legal exclusions (transit, commuting, medical) are **not** applied: they depend on
  circumstances the app does not know. The reference page says so.

**Worked example** (all "any part"): Ontario 1 to 10 January, New York 10 to 15, Quebec 15 to 20.

| Place | Days | Note |
|---|---|---|
| Ontario | 10 | |
| Quebec | 6 | |
| **Canada** | **16** | two separate periods, no shared date |
| **United States** (New York) | **6** | 10 and 15 January also count in Canada |
| Sum of countries | 22 | but only **20** calendar days: two crossing days count twice |

Ontario 1 to 5 June, then Quebec 5 to 8: Ontario 5, Quebec 4, **Canada 8, not 9**.
By "end of day": Ontario 4 (1 to 4), Quebec 3 (5 to 7); 8 June belongs to the next place.

## 9. Days present table

Replaces the current two figures and the SPT row.

- **TBL-1 (Must)** One row per tracked country: name, this calendar year, last 365 days.
- **TBL-2 (Must)** A country with regions expands to its regions. Collapsed by default, and
  the choice is remembered.
- **TBL-3 (Must)** A region may be tracked without its country, and the reverse.
- **TBL-4 (Must)** The user picks tracked places and their order. **A new user with one place
  sees a layout as simple as today's.** Suggested at first: places with recorded days.
- **TBL-5 (Must)** Places with no days in either window are hidden unless pinned.
- **TBL-6 (Must)** Rows for "region not recorded", "assumed (home)" and "not recorded" appear
  only when not zero.
- **TBL-7 (Must)** The Substantial Presence figure appears under the United States only, and
  only if the user tracks it. It keeps its not-advice note.
- **TBL-8 (Must)** A line explains crossing days when any were counted twice.
- **TBL-9 (Must)** The current place and length of stay are shown: "Now: Yukon, 12 days".
- **TBL-10 (Must)** Built as a list, not a grid: at large text each row stacks, and a screen
  reader gets one item per place ("Canada: 120 days this year, 180 in the last 365").
- **TBL-12 (Must)** With work on, each row adds days worked, as a second line and never as a sum
  with days present.
- **TBL-11 (Should)** Other windows (last 180 days, 12 months to a date, custom) per row.

Sketch:

    Now: Yukon, 12 days
                              This year   Last 365
    > Canada                        152        190
        Ontario                      60         95
        Yukon                        12         12
        Region not recorded          80         83
    > United States                  98        120
        Substantial Presence figure       106.33
      Mexico                         40         40
      France (St-Pierre-et-Miquelon)  6          6
    Crossing days count in both places.

## 10. Other features

- **FEA-1 (Must)** Alerts: each names a place (country or region) and a counting convention.
  Existing alerts become United States, any part. "Time since last visit" also takes a place.
- **FEA-2 (Must)** What-if: the possible trip has a place, or several stops. Results show each
  affected tracked place, with and without.
- **FEA-3 (Must)** Custom ranges report any chosen places.
- **FEA-4 (Must)** Filter the list by place, year and actual or planned.
- **FEA-5 (Must)** Reference page: neutral background for each country and for regions, without
  figures that can go stale unless sourced and dated.
- **FEA-6 (Must)** Stays up to the existing 2,000 limit. Raise to 10,000, since a
  full-time traveller may log a stop every few days for decades; measure speed on an old phone.

## 11. Records and exports

- **EXP-1 (Must)** "US Presence Record" becomes "Presence Record", for all places or a chosen
  country. **One choice must reproduce a US-only record** like today's: it is handed to border
  officers, who should not be shown unrelated travel.
- **EXP-2 (Must)** Totals per place state the convention used, and recorded, assumed and
  planned days separately.
- **EXP-3 (Must)** PDF, plain text and image show country and region for every stay.
- **EXP-4 (Must)** CSV adds country and region columns **at the end**, codes and English names,
  so existing imports keep working.
- **EXP-5 (Must)** Day-by-day ledger (date, places, convention, worked if chosen) as CSV, so
  anyone can check the counts. Days an employer or adviser asks about are usually asked by date.
- **EXP-6 (Must)** Before sharing, show what the export contains: places, dates, notes, work.

## 12. Existing data

- **MIG-1 (Must)** Every existing trip becomes a stay in the United States, region not recorded.
  **Every existing US count and the SPT figure must be identical before and after**, proven by
  tests over old data.
- **MIG-2 (Must)** Schema version 3. The app already refuses to overwrite data from a newer
  version; older builds cannot read version 3. Release notes say so.
- **MIG-3 (Must)** The original is kept aside until the first successful save after migration.
- **MIG-4 (Must)** No questions at upgrade; a one-time note says what is new.
- **MIG-6 (Note)** With nothing published, migration serves the owner and testers only. It stays
  required: it proves the counts did not change.
- **MIG-5 (Must)** A future release must not need another schema change to add a country or
  region.

## 13. Language, accessibility, wording

- **LNG-1 (Must)** English and French for every place name and screen. French articles and
  prepositions ("en Ontario", "au Québec", "à Terre-Neuve") must read correctly: whole
  sentences per place, or wording that avoids the preposition.
- **LNG-2 (Must, if a fluent reviewer is available)** Spanish at first release: seasonal workers from Mexico are a main
  audience. Reviewed by a fluent person, like French.
- **LNG-4 (Must)** Plain words, short sentences; no tax or immigration terms where everyday ones
  exist.
- **LNG-3 (Must)** Remove "US" from general wording: "I am still in the US" becomes "I am still
  here"; "Days in the US" becomes "Days present".
- **ACC-1 (Must)** All current accessibility tests extend to the new screens: both languages,
  light, dark, high contrast, 3.1x text, screen-reader order. Places are never shown by flag or
  colour alone.

## 14. Effects elsewhere

| Area | Effect |
|---|---|
| `PLAN.md` | Multi-country tracking was out of scope "for legal-grade correctness". Answered by section 8 (conventions shown, exclusions not applied, no verdicts); owner agreed |
| **Link addresses** | `/apps/us-days/` was replaced by `/apps/days/` in the app and the website requirements, before anything shipped |
| Positioning | No longer "snowbirds only"; store text, screenshots and competitors need a fresh look |
| Name | SENALOVIRA does not mention the US, so it still fits. Folder, package and IDs stay |
| Privacy policy | "Trips" becomes "stays and places". A travel history across countries is more revealing; keep it on-device, and add a note about exports |
| Website roadmap | `REQUIREMENTS-app-hub.md` to be updated with the wider audience |

## 15. Market: what is already there

Checked 2026-11-25 from store pages and vendor sites only; none was used or tested, and
Android results were thin.

| Product | What it appears to offer |
|---|---|
| [Nomad Tracker][6] | Multi-country, on-device, free to start |
| [Immio][7] | No location tracking, CSV, on-device or private iCloud, paid after trial |
| [Country Days Tracker][8] | Offline; 183, 365 or custom windows |
| [TripTrack][9] | Offline, optional GPS, day-by-day export |
| [TrackingDays][10], [SpyglassBeacon][11], TaxBird | Automatic, using background location |
| [Snowbirds US Day Tracker][12], [49th Parallel][13] | US or Canada and US, with the US test |

**So privacy and several countries together are not unique.** The gap this app can aim for is
the combination, which no product above was seen to offer in full:

1. Provinces and territories **and** states, with correct crossing-day and region arithmetic
2. Days worked, kept apart from days present
3. Android and iPhone, with no location, account or internet permission, and public source
4. English, French and Spanish, built for screen readers and large text
5. Records that can be limited to one country
6. Free

- **MKT-1 (Must, before building)** Show 5 to 10 RV travellers and 5 to 10 seasonal workers the
  table and entry sketches, and ask what they use now and what it lacks. Cheap, and it can
  still change the design. Include Android users.
- **MKT-2 (Must)** Install and try the four closest products for an hour each; correct this list.
- **MKT-3 (Must)** Store text claims nothing about competitors or compliance.

## 16. First release, order and risks

| Step | Contents | Done when |
|---|---|---|
| 0 | MKT-1, MKT-2 | Design confirmed or changed |
| 1 | Data model, migration, counting engine, no screens | Section 18 count and migration tests pass |
| 2 | Entering stays, next stop, moving on, splitting, day visits | Timed: a move takes under 15 seconds |
| 3 | Days present table, home base | Accessibility suite green |
| 4 | Work, alerts, what-if, ranges per place | Same |
| 5 | Exports and ledger | US-only export matches today's content |
| 6 | Spanish, French review, reference page, website pages | Fluent reviewers |
| 7 | Full device pass, 4-week trial by real travellers | No open data-loss or count defect |
| 8 | Stores | `RELEASING.md` complete |

After the first release: journeys, custom places (a campsite or job site), repeating a journey,
app lock if not already done.

| Risk | Response |
|---|---|
| Too much for one release | Steps 1 to 3 alone are a usable app; the order allows stopping early |
| A wrong count | Step 1 has no screens, is tested on random histories, and compares with the old engine |
| Harder for a simple user | Single-place check in section 18 |
| Crowded market after all | Step 0 comes before building |
| A revealing travel and work history | On-device, work off by default, export preview, optional lock |
| Effort spent testing PR #1 twice | Smoke-test and merge it now; keep the full device pass for step 7 |

## 17. Decisions (accepted by the owner 2026-11-25)

| # | Question | Decision |
|---|---|---|
| 1 | Release the current US-only version first, or wait? | Wait. Merge PR #1 after a smoke test; do not publish |
| 2 | US states and Mexican states as well as Canadian regions? | Yes, optional, same work |
| 3 | Home base with assumed days? | Yes, first release, off by default: seasonal workers have a home |
| 4 | Default counting convention? | Any part of the day |
| 5 | Metropolitan France, and other countries? | Elsewhere for now |
| 6 | Address: `/apps/days/` instead of `/apps/us-days/`? | Yes |
| 7 | Spanish at first release? | Yes, **on condition** that a fluent reviewer is available; none is named yet |
| 8 | Raise the limit to 10,000 stays? | Yes, **on condition** that measurements on an old phone allow it |
| 9 | Do not ask citizenship (PRN-3)? | Agree |
| 10 | Offer dated, sourced figures on the reference page? | No figures at first |
| 11 | Work tracking as in section 7? | Yes |
| 12 | Talk to users before building (MKT-1)? | Yes; it is the cheapest protection |
| 13 | App lock in the first release? | Yes **if simple**; otherwise soon after |
| 14 | With a home base, do crossing days count as home too? (2026-11-26) | Yes, by "any part of the day" (HOM-5) |

## 18. Acceptance

- [ ] Old data: identical US counts and SPT, over randomly generated histories.
- [ ] Both worked examples in section 8 pass as tests, with both conventions.
- [ ] For any history: each place's days are no more than calendar days; a country is never
      less than its largest region nor more than the sum of its regions; "end of day" places
      plus unrecorded days equal the calendar.
- [ ] Splitting a stay never changes its country's total.
- [ ] A single-country user sees no extra steps beyond choosing the country once.
- [ ] US-only export contains no other place.
- [ ] Accessibility suite green on every new screen; French place names reviewed.
- [ ] With work off, no work field, figure or export column exists anywhere (tested).
- [ ] Days worked never exceed days present, by any part, for the same place and dates.
- [ ] A default export contains no work detail, label or purpose.
- [ ] Every entry and count works with no network permission, as now.
- [ ] 10,000 stays: table and exports stay responsive on an old phone.

## 19. Facts checked and to check

Checked 2026-11-25: US territories are outside the test and some commuting and exempt days are
excluded ([IRS][1]); Saint-Pierre-et-Miquelon is outside Schengen ([Government of Canada][2]);
Canada counts part-days for deemed residence ([CRA][3]).

**Not confirmed, do not publish:** the US transit rule (not found in the pages searched);
Saint-Pierre-et-Miquelon stay limits (sources disagree); Ontario's 153 days (only secondary
sources found, though `PLAN.md` mentions it); every other province's rule; Mexican rules; how
provinces count part-days; what each state or province counts as a day worked. US states differ
widely: [Wolters Kluwer][5] (2023) lists ten with workday thresholds for withholding, and says
somewhat over half of states with an income tax have none. It did not define a workday.

[1]: https://www.irs.gov/individuals/international-taxpayers/substantial-presence-test
[2]: https://travel.gc.ca/destinations/saint-pierre-et-miquelon
[3]: https://www.canada.ca/en/revenue-agency/services/tax/international-non-residents/individuals-leaving-entering-canada-non-residents/deemed-residents.html
[5]: https://www.wolterskluwer.com/en-gb/expert-insights/whole-ball-of-tax-nonresident-withholding-filing-rules
[6]: https://apps.apple.com/us/app/nomad-tracker/id6760122306
[7]: https://apps.apple.com/us/app/immio-country-days-tracker/id6747927306
[8]: https://apps.apple.com/us/app/country-days-tracker/id1635268679
[9]: https://apps.apple.com/us/app/triptrack-days-abroad-counter/id6754455635
[10]: https://www.trackingdays.com/
[11]: https://spyglassbeacon.com/
[12]: https://apps.apple.com/ca/app/snowbirds-us-day-tracker/id1455792679
[13]: http://www.prnewswire.com/news-releases/49th-parallel-wealth-management-launches-cross-border-day-tracker-app-to-help-snowbirds-and-dual-residents-avoid-unintended-us-tax-residency-302856629.html
