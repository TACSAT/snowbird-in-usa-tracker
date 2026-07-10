import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr')
  ];

  /// The application name shown in the OS task switcher and title bar.
  ///
  /// In en, this message translates to:
  /// **'SnowBird'**
  String get appTitle;

  /// Title of the first-launch disclaimer dialog.
  ///
  /// In en, this message translates to:
  /// **'A personal tracking tool — not advice'**
  String get appDisclaimerTitle;

  /// Body of the first-launch disclaimer dialog.
  ///
  /// In en, this message translates to:
  /// **'SnowBird counts your US trip days and lets you print or share that record. It does not give immigration, tax, or legal advice, and it does not tell you whether any stay is \'safe\'. Verify your own situation with a qualified professional.'**
  String get appDisclaimerBody;

  /// Button label to dismiss the disclaimer dialog.
  ///
  /// In en, this message translates to:
  /// **'I understand'**
  String get appDisclaimerAcknowledge;

  /// Label for a completed (already taken) trip.
  ///
  /// In en, this message translates to:
  /// **'Actual'**
  String get tripStatusActual;

  /// Label for a future, intended trip.
  ///
  /// In en, this message translates to:
  /// **'Planned'**
  String get tripStatusPlanned;

  /// Plural-aware count of days.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day} other{{count} days}}'**
  String daysCount(int count);

  /// Placeholder shown when the trip list is empty.
  ///
  /// In en, this message translates to:
  /// **'No trips recorded yet.\nTap + to add your first trip.'**
  String get tripListEmpty;

  /// FAB tooltip and screen title for adding a trip.
  ///
  /// In en, this message translates to:
  /// **'Add trip'**
  String get addTrip;

  /// Screen title when editing an existing trip.
  ///
  /// In en, this message translates to:
  /// **'Edit trip'**
  String get editTrip;

  /// Confirm-delete dialog title.
  ///
  /// In en, this message translates to:
  /// **'Delete trip'**
  String get deleteTrip;

  /// Confirm-delete dialog body.
  ///
  /// In en, this message translates to:
  /// **'Delete this trip? This cannot be undone.'**
  String get deleteTripConfirm;

  /// Generic cancel button label.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Generic delete/confirm button label.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Generic save button label.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Label for the arrival date field.
  ///
  /// In en, this message translates to:
  /// **'Arrival date'**
  String get fieldArrivalDate;

  /// Label for the departure date field.
  ///
  /// In en, this message translates to:
  /// **'Departure date'**
  String get fieldDepartureDate;

  /// Label for the optional notes field.
  ///
  /// In en, this message translates to:
  /// **'Notes (optional)'**
  String get fieldNotes;

  /// Validation error when departure precedes arrival.
  ///
  /// In en, this message translates to:
  /// **'Departure must be on or after arrival.'**
  String get errorDepartureBefore;

  /// About screen title.
  ///
  /// In en, this message translates to:
  /// **'About SnowBird'**
  String get aboutTitle;

  /// About screen description.
  ///
  /// In en, this message translates to:
  /// **'SnowBird is a free, open-source, privacy-first trip tracker. Your data never leaves your device.'**
  String get aboutBody;

  /// Author credit line on the About screen.
  ///
  /// In en, this message translates to:
  /// **'Built by Veiðimaður — veidimadur.ca'**
  String get aboutAuthor;

  /// Button that opens the feedback link.
  ///
  /// In en, this message translates to:
  /// **'Send feedback'**
  String get feedbackButton;

  /// Button that opens the donation link.
  ///
  /// In en, this message translates to:
  /// **'Support the developer'**
  String get donateButton;

  /// Menu item / button to export a backup file.
  ///
  /// In en, this message translates to:
  /// **'Export backup'**
  String get exportBackup;

  /// Menu item / button to import a backup file.
  ///
  /// In en, this message translates to:
  /// **'Import backup'**
  String get importBackup;

  /// Confirmation dialog body before overwriting data with a backup.
  ///
  /// In en, this message translates to:
  /// **'Importing will replace all current trip data. Continue?'**
  String get importBackupConfirm;

  /// Snack bar message after a successful import.
  ///
  /// In en, this message translates to:
  /// **'Backup imported successfully.'**
  String get importSuccess;

  /// Snack bar message when import fails.
  ///
  /// In en, this message translates to:
  /// **'Could not import backup: {reason}'**
  String importError(String reason);

  /// Day-count window label for rolling 365 days.
  ///
  /// In en, this message translates to:
  /// **'Last 365 days'**
  String get windowLast365;

  /// Day-count window label for the current year.
  ///
  /// In en, this message translates to:
  /// **'This calendar year'**
  String get windowThisYear;

  /// Day-count window label for the previous year.
  ///
  /// In en, this message translates to:
  /// **'Last calendar year'**
  String get windowLastYear;

  /// Day-count window label for a user-defined range.
  ///
  /// In en, this message translates to:
  /// **'Custom range'**
  String get windowCustom;

  /// Alerts screen title — 'my' stresses that every alert is user-created.
  ///
  /// In en, this message translates to:
  /// **'My alerts'**
  String get alertsTitle;

  /// Tooltip for the alerts icon in the app bar.
  ///
  /// In en, this message translates to:
  /// **'My alerts'**
  String get alertsTooltip;

  /// Empty state for the alerts screen; restates the zero-defaults positioning.
  ///
  /// In en, this message translates to:
  /// **'No alerts.\nSnowBird sets no limits of its own — if you want a reminder at a number you choose, tap + to create one.'**
  String get alertsEmpty;

  /// FAB tooltip and screen title for creating an alert.
  ///
  /// In en, this message translates to:
  /// **'Add alert'**
  String get addAlert;

  /// Screen title when editing an existing alert.
  ///
  /// In en, this message translates to:
  /// **'Edit alert'**
  String get editAlert;

  /// Confirm-delete dialog title for an alert.
  ///
  /// In en, this message translates to:
  /// **'Delete alert'**
  String get deleteAlert;

  /// Confirm-delete dialog body for an alert.
  ///
  /// In en, this message translates to:
  /// **'Delete this alert? Your trips are not affected.'**
  String get deleteAlertConfirm;

  /// Optional user-given name for an alert.
  ///
  /// In en, this message translates to:
  /// **'Name (optional)'**
  String get alertLabelField;

  /// Numeric field: the user's own day target.
  ///
  /// In en, this message translates to:
  /// **'Notify me at this many days'**
  String get alertThresholdField;

  /// Numeric field: rolling window length in days.
  ///
  /// In en, this message translates to:
  /// **'Counted within the last (days)'**
  String get alertWindowField;

  /// Helper text converting months to days for the window field.
  ///
  /// In en, this message translates to:
  /// **'For example, 36 months is about 1095 days.'**
  String get alertWindowHelper;

  /// Time-of-day picker label for when the notification is delivered.
  ///
  /// In en, this message translates to:
  /// **'Delivery time'**
  String get alertTimeField;

  /// Section label for how far ahead of the reach date to notify.
  ///
  /// In en, this message translates to:
  /// **'Advance notice'**
  String get alertLeadField;

  /// Lead option: notify on the reach day, no advance.
  ///
  /// In en, this message translates to:
  /// **'On the day itself'**
  String get alertLeadNone;

  /// Numeric field: whole days of advance notice.
  ///
  /// In en, this message translates to:
  /// **'Days before'**
  String get alertLeadDaysField;

  /// Numeric field: additional hours of advance notice.
  ///
  /// In en, this message translates to:
  /// **'Hours before'**
  String get alertLeadHoursField;

  /// Switch label: whether the alert is scheduled.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get alertEnabledToggle;

  /// One-line description of an alert's target on the list screen.
  ///
  /// In en, this message translates to:
  /// **'{threshold} days within the last {window} days'**
  String alertSummary(int threshold, int window);

  /// Neutral projection line under an alert; date already formatted.
  ///
  /// In en, this message translates to:
  /// **'Projected to reach your target on {date}'**
  String alertProjectedReach(String date);

  /// Shown when the target is never reached with current data — neutral, not a pass/fail.
  ///
  /// In en, this message translates to:
  /// **'Not reached with your current and planned trips'**
  String get alertNotReached;

  /// Validation message for any numeric alert field outside its hard cap.
  ///
  /// In en, this message translates to:
  /// **'Enter a whole number between {min} and {max}.'**
  String alertRangeError(int min, int max);

  /// Shown when the OS notification permission is refused.
  ///
  /// In en, this message translates to:
  /// **'Notifications are turned off for SnowBird in your device settings, so this alert cannot be delivered.'**
  String get alertPermissionDenied;

  /// Default notification title when the alert has no user label. Neutral — the target is the user's.
  ///
  /// In en, this message translates to:
  /// **'Your day-count target'**
  String get alertNotificationTitle;

  /// Notification body when delivered on the reach day. Must stay neutral: no warning or judgment.
  ///
  /// In en, this message translates to:
  /// **'Today you reach {threshold} days within your {window}-day window — the target you set.'**
  String alertNotificationBodyToday(int threshold, int window);

  /// Notification body when delivered in advance of the reach date. Must stay neutral: no warning or judgment.
  ///
  /// In en, this message translates to:
  /// **'On {date}, you will reach {threshold} days within your {window}-day window — the target you set.'**
  String alertNotificationBodyAdvance(String date, int threshold, int window);

  /// Android notification channel name (visible in system settings).
  ///
  /// In en, this message translates to:
  /// **'Your day-count targets'**
  String get alertChannelName;

  /// Android notification channel description (visible in system settings).
  ///
  /// In en, this message translates to:
  /// **'Reminders you created for day-count targets you set yourself.'**
  String get alertChannelDescription;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
