// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appDisclaimerTitle => 'A personal tracking tool — not advice';

  @override
  String appDisclaimerBody(String appName) {
    return '$appName counts your US trip days and lets you print or share that record. It does not give immigration, tax, or legal advice, and it does not tell you whether any stay is \'safe\'. Verify your own situation with a qualified professional.';
  }

  @override
  String get appDisclaimerAcknowledge => 'I understand';

  @override
  String get backupReminderTitle => 'Keeping your data safe';

  @override
  String backupReminderBody(String appName) {
    return '$appName keeps everything on this device only — nothing is ever sent to us. Your trips are included in your phone\'s normal backup (iCloud or Google), so they move to a new phone automatically. Please make sure your phone backup is turned on.';
  }

  @override
  String get backupReminderAcknowledge => 'Got it';

  @override
  String get tripStatusActual => 'Actual';

  @override
  String get tripStatusPlanned => 'Planned';

  @override
  String daysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String get tripListEmpty =>
      'No trips recorded yet.\nTap + to add your first trip.';

  @override
  String get addTrip => 'Add trip';

  @override
  String get editTrip => 'Edit trip';

  @override
  String get deleteTrip => 'Delete trip';

  @override
  String get deleteTripConfirm => 'Delete this trip? This cannot be undone.';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get save => 'Save';

  @override
  String get fieldArrivalDate => 'Arrival date';

  @override
  String get fieldDepartureDate => 'Departure date';

  @override
  String get fieldNotes => 'Notes (optional)';

  @override
  String get errorDepartureBefore => 'Departure must be on or after arrival.';

  @override
  String aboutTitle(String appName) {
    return 'About $appName';
  }

  @override
  String aboutAuthor(String maker) {
    return 'Created and maintained by $maker';
  }

  @override
  String get windowLast365 => 'Last 365 days';

  @override
  String get windowThisYear => 'This calendar year';

  @override
  String get windowLastYear => 'Last calendar year';

  @override
  String get windowCustom => 'Custom range';

  @override
  String get alertsTitle => 'My alerts';

  @override
  String get alertsTooltip => 'My alerts';

  @override
  String alertsEmpty(String appName) {
    return 'No alerts.\n$appName sets no limits of its own — if you want a reminder at a number you choose, tap + to create one.';
  }

  @override
  String get addAlert => 'Add alert';

  @override
  String get editAlert => 'Edit alert';

  @override
  String get deleteAlert => 'Delete alert';

  @override
  String get deleteAlertConfirm =>
      'Delete this alert? Your trips are not affected.';

  @override
  String get alertLabelField => 'Name (optional)';

  @override
  String get alertThresholdField => 'Notify me at this many days';

  @override
  String get alertWindowField => 'Counted within the last (days)';

  @override
  String get alertWindowHelper => 'For example, 36 months is about 1095 days.';

  @override
  String get alertTimeField => 'Delivery time';

  @override
  String get alertLeadField => 'Advance notice';

  @override
  String get alertLeadDaysField => 'Days before';

  @override
  String get alertLeadHoursField => 'Hours before';

  @override
  String get alertEnabledToggle => 'Active';

  @override
  String alertSummary(int threshold, int window) {
    return '$threshold days within the last $window days';
  }

  @override
  String alertProjectedReach(String date) {
    return 'Projected to reach your target on $date';
  }

  @override
  String get alertNotReached =>
      'Not reached with your current and planned trips';

  @override
  String alertRangeError(int min, int max) {
    return 'Enter a whole number between $min and $max.';
  }

  @override
  String alertPermissionDenied(String appName) {
    return 'Notifications are turned off for $appName in your device settings, so this alert cannot be delivered.';
  }

  @override
  String get alertNotificationTitle => 'Your day-count target';

  @override
  String alertNotificationBodyToday(int threshold, int window) {
    return 'Today you reach $threshold days within your $window-day window — the target you set.';
  }

  @override
  String alertNotificationBodyAdvance(String date, int threshold, int window) {
    return 'On $date, you will reach $threshold days within your $window-day window — the target you set.';
  }

  @override
  String get alertChannelName => 'Your day-count targets';

  @override
  String get alertChannelDescription =>
      'Reminders you created for day-count targets you set yourself.';

  @override
  String get summaryHeading => 'Days present';

  @override
  String get tripTypeLabel => 'Trip type';

  @override
  String get fieldTripName => 'Trip name (optional)';

  @override
  String get fieldTripNameHelper =>
      'A name to help you remember what this trip was for.';

  @override
  String get entryDetailsTitle => 'Entry crossing (optional)';

  @override
  String get exitDetailsTitle => 'Exit crossing (optional)';

  @override
  String get fieldCrossingTime => 'Time (optional)';

  @override
  String get fieldTimeZone => 'Time zone (optional)';

  @override
  String get fieldLocation => 'Location (optional)';

  @override
  String get fieldMeansOfTravel => 'Means of travel (optional)';

  @override
  String get fieldCarrier => 'Carrier (optional)';

  @override
  String get optionalNotSet => 'Not set';

  @override
  String get errorArrivalRequired => 'Select an arrival date.';

  @override
  String get errorDepartureRequired => 'Select a departure date.';

  @override
  String tripSubtitle(String arrival, String departure, String days) {
    return '$arrival – $departure · $days';
  }

  @override
  String get exportRecord => 'Export record';

  @override
  String get exportAsPdf => 'PDF document';

  @override
  String get exportAsImage => 'Image (PNG)';

  @override
  String get exportAsCsv => 'Spreadsheet (CSV)';

  @override
  String get exportPrint => 'Print';

  @override
  String exportError(String reason) {
    return 'Could not create the export: $reason';
  }

  @override
  String get exportEmpty =>
      'Add a trip first — there is nothing to export yet.';

  @override
  String get recordHeading => 'US Presence Record';

  @override
  String recordAsOf(String date) {
    return 'As of $date';
  }

  @override
  String get recordDisclaimer =>
      'This is a personal record, not advice. It gives no immigration, tax, or legal opinion. Verify your situation with a qualified professional.';

  @override
  String get recordSummaryTitle => 'Days present in the US (actual)';

  @override
  String get recordSptLabel => 'Substantial Presence figure';

  @override
  String get recordSptFormula =>
      'current year + ⅓ prior year + ⅙ second-prior year';

  @override
  String get recordColDates => 'Dates';

  @override
  String get recordColDays => 'Days';

  @override
  String get recordColStatus => 'Type';

  @override
  String get recordColDetails => 'Trip / details';

  @override
  String recordAuthor(String appName, String maker) {
    return 'Kept with $appName · $maker';
  }

  @override
  String get menuSettings => 'Settings';

  @override
  String get menuAbout => 'About';

  @override
  String get menuReference => 'Common day-count rules';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsTextSize => 'Text size in this app';

  @override
  String get optionFollowPhone => 'Follow phone';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageFrench => 'Français';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get textSizeSample => 'Sample text at this size';

  @override
  String aboutVersion(String version, String build) {
    return 'Version $version (build $build)';
  }

  @override
  String get aboutPrivacyTitle => 'Your privacy';

  @override
  String aboutPrivacyBody(String appName) {
    return '$appName has no account, no cloud, and no tracking. Everything you enter stays on this device and is never sent to the developer. Your data is included in your phone\'s normal backup (iCloud or Google), so it moves to a new phone with you.';
  }

  @override
  String get aboutSourceButton => 'View the source code';

  @override
  String get linkError => 'Could not open the link.';

  @override
  String get referenceTitle => 'Common day-count rules';

  @override
  String referenceIntro(String appName) {
    return 'These are numbers people commonly track. $appName sets none of them for you — you enter your own in Alerts. This page is background information, not advice: verify your own situation with a qualified professional.';
  }

  @override
  String get referenceSptTitle => 'US Substantial Presence Test';

  @override
  String referenceSptBody(String appName) {
    return 'A US tax residency test based on a weighted count over three years: all your days this year, plus one third of last year, plus one sixth of the year before. $appName shows this figure as a neutral number.';
  }

  @override
  String get referenceHealthTitle => 'Provincial health coverage';

  @override
  String get referenceHealthBody =>
      'Many provincial health plans expect you to be physically present in your province for a minimum number of days each year. The exact number varies by province and changes over time — check your own plan\'s current rule.';

  @override
  String get referenceEntryTitle => 'Length of a US visit';

  @override
  String get referenceEntryBody =>
      'A visitor is generally admitted for a limited period per entry, at the border officer\'s discretion. The admitted-until date is on your I-94 record — and land crossings are not always recorded, which is exactly why keeping your own dates matters.';

  @override
  String get referenceMythTitle => 'There is no single cumulative limit';

  @override
  String referenceMythBody(String appName) {
    return 'There is no one cumulative \'days\' limit this app could enforce for you. Immigration lawyers often call the \'180-day rule\' a myth; the real constraints are the per-entry admission, the officer\'s discretion, and separate tax tests. That is why $appName counts and never judges.';
  }

  @override
  String get sptDisclaimer => 'A neutral figure, not advice — tap for context.';

  @override
  String get alertKindLabel => 'What to watch';

  @override
  String get alertKindDayCount => 'Days in a window';

  @override
  String get alertKindSinceVisit => 'Time since last visit';

  @override
  String get alertThresholdSinceField =>
      'Notify me after this many days since my last visit';

  @override
  String get alertSinceHelper => 'For example, 1825 days is about 5 years.';

  @override
  String alertSummarySince(int threshold) {
    return '$threshold days since the last visit';
  }

  @override
  String get alertNoVisits =>
      'Add an actual trip first — there is no visit to measure from yet';

  @override
  String alertNotificationBodySince(String date, int threshold) {
    return 'As of $date, it has been $threshold days since your last visit — the target you set.';
  }

  @override
  String get tripStillInUs => 'I am still here';

  @override
  String get tripStillInUsHelper =>
      'Leave on until you know your departure date. Days count through today.';

  @override
  String get tripOngoing => 'ongoing';

  @override
  String tripDaysSoFar(String days) {
    return '$days so far';
  }

  @override
  String get tripStatusCurrent => 'Current';

  @override
  String get errorTripOverlap =>
      'These dates overlap another actual trip. Leaving and returning on the same day is fine.';

  @override
  String get errorFutureArrival =>
      'An actual trip cannot start in the future. Choose Planned instead.';

  @override
  String get errorSaveFailed =>
      'Your change could not be saved on this device.';

  @override
  String get storageProblemTitle => 'Some saved data could not be read';

  @override
  String get storageProblemBody =>
      'Part of your saved data could not be read, so it is not shown or counted. Nothing has been erased: the original is kept on this device, even after you make changes.';

  @override
  String storageNewerBody(String appName) {
    return 'Your data was saved by a newer version of $appName. Please update the app. Until then, changes to that data cannot be saved, so nothing is overwritten.';
  }

  @override
  String get alertInUsNow =>
      'Will be measured once you record a departure from your current trip';

  @override
  String recordEntryLabel(String details) {
    return 'Entry: $details';
  }

  @override
  String recordExitLabel(String details) {
    return 'Exit: $details';
  }

  @override
  String get clearTime => 'Clear time';

  @override
  String get errorTimeRequired => 'Choose a delivery time.';

  @override
  String get alertReached => 'Reached as of today';

  @override
  String get exploreTitle => 'Explore days and plans';

  @override
  String get exploreRangeHeading => 'Days in a period';

  @override
  String get rangeFrom => 'From';

  @override
  String get rangeTo => 'To';

  @override
  String rangeActual(String days) {
    return 'Actual days so far: $days';
  }

  @override
  String rangeWithPlanned(String days) {
    return 'Including planned trips: $days';
  }

  @override
  String get whatIfHeading => 'What if I take this trip?';

  @override
  String get whatIfIntro =>
      'Choose possible dates to see your counts. Nothing is saved unless you choose to.';

  @override
  String get whatIfArrival => 'Possible arrival';

  @override
  String get whatIfDeparture => 'Possible departure';

  @override
  String whatIfWithout(String value) {
    return 'Without this trip: $value';
  }

  @override
  String whatIfWith(String value) {
    return 'With this trip: $value';
  }

  @override
  String whatIfYear(String year, String date) {
    return 'Calendar year $year, through $date';
  }

  @override
  String whatIfLast365(String date) {
    return '365 days ending $date';
  }

  @override
  String whatIfSpt(String date) {
    return 'Substantial Presence figure, projected to $date';
  }

  @override
  String get whatIfSave => 'Save as a planned trip';

  @override
  String get whatIfSaved => 'Planned trip saved.';

  @override
  String get whatIfClear => 'Clear';

  @override
  String get assumeOpenTrip =>
      'Counts that include planned trips assume your current trip continues until you record a departure.';

  @override
  String assumeStalePlanned(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Includes $count planned trips whose dates have passed. Mark them as actual or delete them.',
      one:
          'Includes 1 planned trip whose dates have passed. Mark it as actual or delete it.',
    );
    return '$_temp0';
  }

  @override
  String errorTooManyTrips(int count) {
    return 'The limit of $count trips is reached. Delete a trip to add another.';
  }

  @override
  String alertToggleLabel(String name) {
    return 'Alert active: $name';
  }

  @override
  String get exportAsText => 'Plain text (for screen readers)';

  @override
  String recordLine(String label, String value) {
    return '$label: $value';
  }

  @override
  String recordTripNumber(int number, int total) {
    return 'Trip $number of $total';
  }

  @override
  String get recordTripName => 'Trip name';

  @override
  String get recordNotes => 'Notes';

  @override
  String get settingsHighContrast => 'High contrast and bold text';

  @override
  String get settingsHighContrastHelper =>
      'When off, follows your phone\'s contrast and bold text settings where available.';

  @override
  String get aboutHelpTitle => 'Help and planning';

  @override
  String get aboutReport => 'Report a problem';

  @override
  String get aboutRequest => 'Request a feature';

  @override
  String get aboutStatus => 'Track reports and requests';

  @override
  String get aboutRoadmap => 'What is planned';

  @override
  String get aboutContribute => 'Make a voluntary contribution';

  @override
  String aboutContributeNote(String maker) {
    return 'Contributions are optional and unlock nothing: every feature is free. These buttons open $maker, or GitHub for the source code, in your browser.';
  }

  @override
  String get aboutPrivacyPolicy => 'Privacy policy';

  @override
  String placeName(String code) {
    String _temp0 = intl.Intl.selectLogic(
      code,
      {
        'CA': 'Canada',
        'US': 'United States',
        'MX': 'Mexico',
        'PM': 'Saint Pierre and Miquelon',
        'PR': 'Puerto Rico',
        'VI': 'U.S. Virgin Islands',
        'GU': 'Guam',
        'AS': 'American Samoa',
        'MP': 'Northern Mariana Islands',
        'ZZ': 'Elsewhere',
        'CA_AB': 'Alberta',
        'CA_BC': 'British Columbia',
        'CA_MB': 'Manitoba',
        'CA_NB': 'New Brunswick',
        'CA_NL': 'Newfoundland and Labrador',
        'CA_NS': 'Nova Scotia',
        'CA_NT': 'Northwest Territories',
        'CA_NU': 'Nunavut',
        'CA_ON': 'Ontario',
        'CA_PE': 'Prince Edward Island',
        'CA_QC': 'Quebec',
        'CA_SK': 'Saskatchewan',
        'CA_YT': 'Yukon',
        'US_AL': 'Alabama',
        'US_AK': 'Alaska',
        'US_AZ': 'Arizona',
        'US_AR': 'Arkansas',
        'US_CA': 'California',
        'US_CO': 'Colorado',
        'US_CT': 'Connecticut',
        'US_DE': 'Delaware',
        'US_DC': 'District of Columbia',
        'US_FL': 'Florida',
        'US_GA': 'Georgia',
        'US_HI': 'Hawaii',
        'US_ID': 'Idaho',
        'US_IL': 'Illinois',
        'US_IN': 'Indiana',
        'US_IA': 'Iowa',
        'US_KS': 'Kansas',
        'US_KY': 'Kentucky',
        'US_LA': 'Louisiana',
        'US_ME': 'Maine',
        'US_MD': 'Maryland',
        'US_MA': 'Massachusetts',
        'US_MI': 'Michigan',
        'US_MN': 'Minnesota',
        'US_MS': 'Mississippi',
        'US_MO': 'Missouri',
        'US_MT': 'Montana',
        'US_NE': 'Nebraska',
        'US_NV': 'Nevada',
        'US_NH': 'New Hampshire',
        'US_NJ': 'New Jersey',
        'US_NM': 'New Mexico',
        'US_NY': 'New York',
        'US_NC': 'North Carolina',
        'US_ND': 'North Dakota',
        'US_OH': 'Ohio',
        'US_OK': 'Oklahoma',
        'US_OR': 'Oregon',
        'US_PA': 'Pennsylvania',
        'US_RI': 'Rhode Island',
        'US_SC': 'South Carolina',
        'US_SD': 'South Dakota',
        'US_TN': 'Tennessee',
        'US_TX': 'Texas',
        'US_UT': 'Utah',
        'US_VT': 'Vermont',
        'US_VA': 'Virginia',
        'US_WA': 'Washington',
        'US_WV': 'West Virginia',
        'US_WI': 'Wisconsin',
        'US_WY': 'Wyoming',
        'MX_AGU': 'Aguascalientes',
        'MX_BCN': 'Baja California',
        'MX_BCS': 'Baja California Sur',
        'MX_CAM': 'Campeche',
        'MX_CHH': 'Chihuahua',
        'MX_CHP': 'Chiapas',
        'MX_CMX': 'Mexico City',
        'MX_COA': 'Coahuila',
        'MX_COL': 'Colima',
        'MX_DUR': 'Durango',
        'MX_GRO': 'Guerrero',
        'MX_GUA': 'Guanajuato',
        'MX_HID': 'Hidalgo',
        'MX_JAL': 'Jalisco',
        'MX_MEX': 'State of Mexico',
        'MX_MIC': 'Michoacán',
        'MX_MOR': 'Morelos',
        'MX_NAY': 'Nayarit',
        'MX_NLE': 'Nuevo León',
        'MX_OAX': 'Oaxaca',
        'MX_PUE': 'Puebla',
        'MX_QUE': 'Querétaro',
        'MX_ROO': 'Quintana Roo',
        'MX_SIN': 'Sinaloa',
        'MX_SLP': 'San Luis Potosí',
        'MX_SON': 'Sonora',
        'MX_TAB': 'Tabasco',
        'MX_TAM': 'Tamaulipas',
        'MX_TLA': 'Tlaxcala',
        'MX_VER': 'Veracruz',
        'MX_YUC': 'Yucatán',
        'MX_ZAC': 'Zacatecas',
        'other': '$code',
      },
    );
    return '$_temp0';
  }

  @override
  String placeInCountry(String region, String country) {
    return '$region, $country';
  }

  @override
  String placeElsewhereNamed(String name) {
    return 'Elsewhere ($name)';
  }

  @override
  String placeWholeCountry(String country) {
    return '$country, region not recorded';
  }

  @override
  String get fieldPlace => 'Place';

  @override
  String get errorPlaceRequired => 'Choose a place.';

  @override
  String get fieldElsewhereName => 'Country name (optional)';

  @override
  String get placePickerTitle => 'Choose a place';

  @override
  String get placeSearchHint => 'Search by name';

  @override
  String get placeRecent => 'Recent';

  @override
  String get placeCountries => 'Countries';

  @override
  String get placeNoMatch => 'No place matches that name.';

  @override
  String get placeChooseRegion => 'Province, territory or state';

  @override
  String tripPlaceSubtitle(String place, String rest) {
    return '$place · $rest';
  }

  @override
  String get addNextStop => 'Add next stop';

  @override
  String get movedOn => 'I have moved…';

  @override
  String moveConfirmTitle(String place) {
    return 'New place: $place';
  }

  @override
  String get moveDateLabel => 'Date of the move';

  @override
  String moveExplain(String from, String to) {
    return 'The current stay ($from) ends on this date, and a new stay ($to) starts the same day. That day counts in both places.';
  }

  @override
  String get errorMoveBeforeArrival =>
      'The move cannot be before the current stay began.';

  @override
  String get splitStay => 'Split into two places';

  @override
  String get splitTitle => 'Split this stay';

  @override
  String get splitDateLabel => 'Second place from';

  @override
  String get splitBeforeLabel => 'Place before that date';

  @override
  String get splitAfterLabel => 'Place from that date';

  @override
  String splitExplain(String country) {
    return 'Both parts stay in $country, so its total does not change. The date you choose ends the first part and starts the second, so it counts in both places.';
  }

  @override
  String get errorSplitDate => 'Choose a date within the stay.';

  @override
  String get visitsTitle => 'Day visits';

  @override
  String get visitsExplain =>
      'A day visit is part of a day in another place, without moving there: work, shopping or an appointment. It counts as a day present there, without a stay out and a stay back.';

  @override
  String get visitsEmpty => 'No day visits recorded.';

  @override
  String get addVisit => 'Add day visit';

  @override
  String get deleteVisit => 'Delete day visit';

  @override
  String get fieldVisitDate => 'Date of the visit';

  @override
  String errorTooManyVisits(int max) {
    return 'You have reached the limit of $max day visits.';
  }

  @override
  String get tableColumnYear => 'This year';

  @override
  String get tableColumnLast365 => 'Last 365';

  @override
  String tableRowSemantics(String place, String year, String last) {
    return '$place: $year this calendar year, $last in the last 365 days';
  }

  @override
  String get tableRegionNotRecorded => 'Region not recorded';

  @override
  String get tableAssumed => 'Assumed at home';

  @override
  String get tableNotRecorded => 'Not recorded';

  @override
  String get tableCrossingNote =>
      'Crossing days count in both places, so places can add up to more than the calendar.';

  @override
  String tableNow(String place, String days) {
    return 'Now: $place, $days';
  }

  @override
  String get tableAnyPartNote => 'Counted by any part of the day.';

  @override
  String get tableEndOfDayNote =>
      'Rows marked \"end of day\" count where you were at midnight.';

  @override
  String get tableEndOfDayTag => 'end of day';

  @override
  String get tableEmpty => 'No days recorded in these periods.';

  @override
  String get tableChoosePlaces => 'Choose places';

  @override
  String get tableShowRegions => 'Show regions';

  @override
  String get tableHideRegions => 'Hide regions';

  @override
  String get placesSettingsTitle => 'Places and home';

  @override
  String get placesTrackedHeading => 'Places in the table';

  @override
  String get placesAutomatic => 'Show places with recorded days';

  @override
  String get placesAutomaticHelper =>
      'Turn off to choose the places, their order and how days are counted.';

  @override
  String get placesAdd => 'Add place';

  @override
  String get placesRemove => 'Remove';

  @override
  String get placesMoveUp => 'Move up';

  @override
  String get placesMoveDown => 'Move down';

  @override
  String get placesPinned => 'Show even with no days';

  @override
  String get placesConventionLabel => 'How days are counted';

  @override
  String get conventionAnyPart => 'Any part of the day';

  @override
  String get conventionEndOfDay => 'End of the day';

  @override
  String get conventionExplain =>
      'Any part of the day: a date counts if you were there at any moment of it, so a crossing day counts in both places. End of the day: a date counts where you were at midnight. Rules differ from one place to another; the app does not choose for you.';

  @override
  String get homeHeading => 'Home base';

  @override
  String get homeSwitch => 'Count unrecorded days at home';

  @override
  String get homeExplain =>
      'When on, a past day with no stay counts as a day assumed at home, shown apart from recorded days. The days you leave and come back count there too. This is not a statement of legal residence.';

  @override
  String get homeAddPeriod => 'Add home place';

  @override
  String homePeriod(String place, String date) {
    return '$place, from $date';
  }

  @override
  String get homeRemove => 'Remove home place';

  @override
  String get homeFromLabel => 'Home from';

  @override
  String get homeNeedPlace => 'Add your home place first.';

  @override
  String get whatsNewTitle => 'New: days by place';

  @override
  String whatsNewBody(String appName) {
    return '$appName now counts days in Canada, the United States, Mexico and Saint-Pierre-et-Miquelon, by province, territory or state if you wish. Your trips are now stays in the United States, and every US count is unchanged. Choose places and an optional home base under Settings.';
  }

  @override
  String get workHeading => 'Days worked';

  @override
  String get workSwitch => 'Record days worked';

  @override
  String get workExplain =>
      'Optional. Days worked are kept apart from days present and are never guessed from them. No wages, hours or employer details are asked for.';

  @override
  String get workWeekdaysLabel => 'Usually worked on';

  @override
  String get workCorrectDays => 'Correct single days';

  @override
  String workStayCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days worked',
      one: '1 day worked',
      zero: 'No days worked so far',
    );
    return '$_temp0';
  }

  @override
  String get workCalendarHelp => 'Tap a day to mark it worked or not worked.';

  @override
  String workDayWorked(String date) {
    return '$date: worked';
  }

  @override
  String workDayNotWorked(String date) {
    return '$date: not worked';
  }

  @override
  String get workDone => 'Done';

  @override
  String get visitWorked => 'Worked there that day';

  @override
  String get tableWorked => 'Worked';

  @override
  String tableWorkedSemantics(String year, String last) {
    return 'worked: $year this calendar year, $last in the last 365 days';
  }

  @override
  String alertSummaryAt(String place, String summary) {
    return '$place: $summary';
  }

  @override
  String alertSummaryWorked(int threshold, int window) {
    return '$threshold days worked within the last $window days';
  }

  @override
  String get alertMeasureLabel => 'What to count';

  @override
  String get alertMeasurePresent => 'Days present';

  @override
  String get alertMeasureWorked => 'Days worked';

  @override
  String alertNotificationWithPlace(String place, String body) {
    return '$place: $body';
  }

  @override
  String alertNotificationWorkedPlace(String place, String body) {
    return '$place, days worked: $body';
  }

  @override
  String rangeWorked(String days) {
    return 'Days worked: $days';
  }

  @override
  String get whatIfPlaceLabel => 'Place of this trip';

  @override
  String get filterTooltip => 'Filter stays';

  @override
  String get filterYear => 'Year';

  @override
  String get filterAll => 'All';

  @override
  String filterShown(int shown, int total) {
    return '$shown of $total stays shown';
  }

  @override
  String get filterClear => 'Clear filter';

  @override
  String get filterNone => 'No stay matches this filter.';

  @override
  String get filterApply => 'Show';

  @override
  String get recordHeadingAll => 'Presence Record';

  @override
  String recordHeadingPlace(String place) {
    return 'Presence Record: $place';
  }

  @override
  String get recordSummaryTitleAll => 'Days present (actual)';

  @override
  String recordCountedBy(String convention) {
    return 'Counted by: $convention';
  }

  @override
  String recordAssumedLine(String year, String last) {
    return 'Assumed at home, not recorded: $year this calendar year, $last in the last 365 days';
  }

  @override
  String recordPlannedLine(String year, String days) {
    return 'Planned for the rest of $year: $days';
  }

  @override
  String recordWorkedLine(String year, String last) {
    return 'Days worked: $year this calendar year, $last in the last 365 days';
  }

  @override
  String get recordVisit => 'Day visit';

  @override
  String get exportScopeHeading => 'What the record covers';

  @override
  String get exportScopeAll => 'All places';

  @override
  String exportScopeOnly(String place) {
    return '$place only';
  }

  @override
  String get exportIncludeWork => 'Add days worked to this export';

  @override
  String get exportIncludeWorkHelper =>
      'Off each time you open this screen: what someone does in a country can matter to their right to be there.';

  @override
  String get exportPreviewHeading => 'This export contains';

  @override
  String exportPreviewPlaces(String places) {
    return 'Places: $places';
  }

  @override
  String exportPreviewDates(String from, String to) {
    return 'Dates: $from to $to';
  }

  @override
  String exportPreviewStays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count stays',
      one: '1 stay',
      zero: 'No stays',
    );
    return '$_temp0';
  }

  @override
  String exportPreviewVisits(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count day visits',
      one: '1 day visit',
      zero: 'No day visits',
    );
    return '$_temp0';
  }

  @override
  String exportPreviewNames(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'The names of $count stays',
      one: 'The name of 1 stay',
      zero: 'No stay names',
    );
    return '$_temp0';
  }

  @override
  String exportPreviewNotes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Notes from $count stays',
      one: 'Notes from 1 stay',
      zero: 'No notes',
    );
    return '$_temp0';
  }

  @override
  String exportPreviewCrossings(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Crossing details from $count stays',
      one: 'Crossing details from 1 stay',
      zero: 'No crossing details',
    );
    return '$_temp0';
  }

  @override
  String get exportPreviewWorkYes => 'Days worked: included';

  @override
  String get exportPreviewWorkNo => 'Days worked: not included';

  @override
  String get exportPreviewHome => 'Days assumed at home: included, shown apart';

  @override
  String get exportFormatsHeading => 'Share or print';

  @override
  String get exportAsLedger => 'Day-by-day ledger (CSV)';
}
