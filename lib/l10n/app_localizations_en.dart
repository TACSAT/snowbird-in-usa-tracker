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
  String get aboutBody =>
      'SnowBird is a free, open-source, privacy-first trip tracker. Your data never leaves your device.';

  @override
  String get aboutAuthor => 'Built by Veiðimaður — veidimadur.ca';

  @override
  String get feedbackButton => 'Send feedback';

  @override
  String get donateButton => 'Support the developer';

  @override
  String get exportBackup => 'Export backup';

  @override
  String get importBackup => 'Import backup';

  @override
  String get importBackupConfirm =>
      'Importing will replace all current trip data. Continue?';

  @override
  String get importSuccess => 'Backup imported successfully.';

  @override
  String importError(String reason) {
    return 'Could not import backup: $reason';
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
  String get alertLeadNone => 'On the day itself';

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
}
