// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'SnowBird';

  @override
  String get appDisclaimerTitle => 'A personal tracking tool — not advice';

  @override
  String get appDisclaimerBody =>
      'SnowBird counts your US trip days and lets you print or share that record. It does not give immigration, tax, or legal advice, and it does not tell you whether any stay is \'safe\'. Verify your own situation with a qualified professional.';

  @override
  String get appDisclaimerAcknowledge => 'I understand';

  @override
  String get backupReminderTitle => 'Keeping your data safe';

  @override
  String get backupReminderBody =>
      'SnowBird keeps everything on this device only — nothing is ever sent to us. Your trips are included in your phone\'s normal backup (iCloud or Google), so they move to a new phone automatically. Please make sure your phone backup is turned on.';

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
  String get aboutTitle => 'About SnowBird';

  @override
  String get aboutAuthor => 'Built by Veiðimaður — veidimadur.ca';

  @override
  String get feedbackButton => 'Send feedback';

  @override
  String get donateButton => 'Support the developer';

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
  String get alertsEmpty =>
      'No alerts.\nSnowBird sets no limits of its own — if you want a reminder at a number you choose, tap + to create one.';

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
  String get alertPermissionDenied =>
      'Notifications are turned off for SnowBird in your device settings, so this alert cannot be delivered.';

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
  String get summaryHeading => 'Days in the US';

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
  String get recordAuthor => 'Kept with SnowBird — Veiðimaður · veidimadur.ca';

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
  String get aboutPrivacyBody =>
      'SnowBird has no account, no cloud, and no tracking. Everything you enter stays on this device and is never sent to the developer. Your data is included in your phone\'s normal backup (iCloud or Google), so it moves to a new phone with you.';

  @override
  String get aboutSourceButton => 'View the source code';

  @override
  String get linkError => 'Could not open the link.';

  @override
  String get referenceTitle => 'Common day-count rules';

  @override
  String get referenceIntro =>
      'These are numbers people commonly track. SnowBird sets none of them for you — you enter your own in Alerts. This page is background information, not advice: verify your own situation with a qualified professional.';

  @override
  String get referenceSptTitle => 'US Substantial Presence Test';

  @override
  String get referenceSptBody =>
      'A US tax residency test based on a weighted count over three years: all your days this year, plus one third of last year, plus one sixth of the year before. SnowBird shows this figure as a neutral number.';

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
  String get referenceMythBody =>
      'There is no one cumulative \'days\' limit this app could enforce for you. Immigration lawyers often call the \'180-day rule\' a myth; the real constraints are the per-entry admission, the officer\'s discretion, and separate tax tests. That is why SnowBird counts and never judges.';

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
    return 'As of $date, it has been $threshold days since your last US visit — the target you set.';
  }

  @override
  String get tripStillInUs => 'I am still in the US';

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
  String get storageNewerBody =>
      'Your data was saved by a newer version of SnowBird. Please update the app. Until then, changes to that data cannot be saved, so nothing is overwritten.';

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
}
