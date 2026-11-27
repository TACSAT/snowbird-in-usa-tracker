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

  /// Title of the first-launch disclaimer dialog.
  ///
  /// In en, this message translates to:
  /// **'A personal tracking tool — not advice'**
  String get appDisclaimerTitle;

  /// Body of the first-launch disclaimer dialog.
  ///
  /// In en, this message translates to:
  /// **'{appName} counts your US trip days and lets you print or share that record. It does not give immigration, tax, or legal advice, and it does not tell you whether any stay is \'safe\'. Verify your own situation with a qualified professional.'**
  String appDisclaimerBody(String appName);

  /// Button label to dismiss the disclaimer dialog.
  ///
  /// In en, this message translates to:
  /// **'I understand'**
  String get appDisclaimerAcknowledge;

  /// Title of the one-time setup backup reminder (FR-11).
  ///
  /// In en, this message translates to:
  /// **'Keeping your data safe'**
  String get backupReminderTitle;

  /// Body of the one-time backup reminder. Shown once at setup, never repeated.
  ///
  /// In en, this message translates to:
  /// **'{appName} keeps everything on this device only — nothing is ever sent to us. Your trips are included in your phone\'s normal backup (iCloud or Google), so they move to a new phone automatically. Please make sure your phone backup is turned on.'**
  String backupReminderBody(String appName);

  /// Button label to dismiss the backup reminder.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get backupReminderAcknowledge;

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
  /// **'About {appName}'**
  String aboutTitle(String appName);

  /// Author credit line on the About screen.
  ///
  /// In en, this message translates to:
  /// **'Created and maintained by {maker}'**
  String aboutAuthor(String maker);

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
  /// **'No alerts.\n{appName} sets no limits of its own — if you want a reminder at a number you choose, tap + to create one.'**
  String alertsEmpty(String appName);

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
  /// **'Notifications are turned off for {appName} in your device settings, so this alert cannot be delivered.'**
  String alertPermissionDenied(String appName);

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

  /// Heading of the day-count summary card on the trip list screen.
  ///
  /// In en, this message translates to:
  /// **'Days in the US'**
  String get summaryHeading;

  /// Section label for the actual-vs-planned selector on the trip form.
  ///
  /// In en, this message translates to:
  /// **'Trip type'**
  String get tripTypeLabel;

  /// Label for the optional trip-name field.
  ///
  /// In en, this message translates to:
  /// **'Trip name (optional)'**
  String get fieldTripName;

  /// Helper text under the trip-name field.
  ///
  /// In en, this message translates to:
  /// **'A name to help you remember what this trip was for.'**
  String get fieldTripNameHelper;

  /// Expansion-tile title for the optional entry-crossing details.
  ///
  /// In en, this message translates to:
  /// **'Entry crossing (optional)'**
  String get entryDetailsTitle;

  /// Expansion-tile title for the optional exit-crossing details.
  ///
  /// In en, this message translates to:
  /// **'Exit crossing (optional)'**
  String get exitDetailsTitle;

  /// Label for the optional crossing time-of-day field.
  ///
  /// In en, this message translates to:
  /// **'Time (optional)'**
  String get fieldCrossingTime;

  /// Label for the optional time-zone field.
  ///
  /// In en, this message translates to:
  /// **'Time zone (optional)'**
  String get fieldTimeZone;

  /// Label for the optional crossing-location field.
  ///
  /// In en, this message translates to:
  /// **'Location (optional)'**
  String get fieldLocation;

  /// Label for the optional means-of-travel field (e.g. car, air).
  ///
  /// In en, this message translates to:
  /// **'Means of travel (optional)'**
  String get fieldMeansOfTravel;

  /// Label for the optional carrier field (e.g. airline, flight number).
  ///
  /// In en, this message translates to:
  /// **'Carrier (optional)'**
  String get fieldCarrier;

  /// Shown in place of an optional value the user has not entered (e.g. a time).
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get optionalNotSet;

  /// Validation error when no arrival date is chosen.
  ///
  /// In en, this message translates to:
  /// **'Select an arrival date.'**
  String get errorArrivalRequired;

  /// Validation error when no departure date is chosen.
  ///
  /// In en, this message translates to:
  /// **'Select a departure date.'**
  String get errorDepartureRequired;

  /// Trip list subtitle: date range and day count. 'days' is an already-formatted plural string.
  ///
  /// In en, this message translates to:
  /// **'{arrival} – {departure} · {days}'**
  String tripSubtitle(String arrival, String departure, String days);

  /// App-bar action / sheet title to export the US Presence Record.
  ///
  /// In en, this message translates to:
  /// **'Export record'**
  String get exportRecord;

  /// Export option: a PDF file.
  ///
  /// In en, this message translates to:
  /// **'PDF document'**
  String get exportAsPdf;

  /// Export option: a PNG image.
  ///
  /// In en, this message translates to:
  /// **'Image (PNG)'**
  String get exportAsImage;

  /// Export option: a CSV file.
  ///
  /// In en, this message translates to:
  /// **'Spreadsheet (CSV)'**
  String get exportAsCsv;

  /// Export option: open the system print dialog.
  ///
  /// In en, this message translates to:
  /// **'Print'**
  String get exportPrint;

  /// Snack bar shown when export fails.
  ///
  /// In en, this message translates to:
  /// **'Could not create the export: {reason}'**
  String exportError(String reason);

  /// Shown when the user tries to export with no trips.
  ///
  /// In en, this message translates to:
  /// **'Add a trip first — there is nothing to export yet.'**
  String get exportEmpty;

  /// Title printed at the top of the exported record.
  ///
  /// In en, this message translates to:
  /// **'US Presence Record'**
  String get recordHeading;

  /// The as-of date line on the record.
  ///
  /// In en, this message translates to:
  /// **'As of {date}'**
  String recordAsOf(String date);

  /// Not-advice line printed on the record.
  ///
  /// In en, this message translates to:
  /// **'This is a personal record, not advice. It gives no immigration, tax, or legal opinion. Verify your situation with a qualified professional.'**
  String get recordDisclaimer;

  /// Heading of the summary block on the record.
  ///
  /// In en, this message translates to:
  /// **'Days present in the US (actual)'**
  String get recordSummaryTitle;

  /// Label for the neutral SPT figure on the record.
  ///
  /// In en, this message translates to:
  /// **'Substantial Presence figure'**
  String get recordSptLabel;

  /// Neutral description of the SPT formula, printed under the figure.
  ///
  /// In en, this message translates to:
  /// **'current year + ⅓ prior year + ⅙ second-prior year'**
  String get recordSptFormula;

  /// Record table column: the trip's date range.
  ///
  /// In en, this message translates to:
  /// **'Dates'**
  String get recordColDates;

  /// Record table column: day count.
  ///
  /// In en, this message translates to:
  /// **'Days'**
  String get recordColDays;

  /// Record table column: actual or planned.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get recordColStatus;

  /// Record table column: name and crossing notes.
  ///
  /// In en, this message translates to:
  /// **'Trip / details'**
  String get recordColDetails;

  /// Footer credit line on the record.
  ///
  /// In en, this message translates to:
  /// **'Kept with {appName} · {maker}'**
  String recordAuthor(String appName, String maker);

  /// Overflow menu item opening Settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get menuSettings;

  /// Overflow menu item opening the About screen.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get menuAbout;

  /// Overflow menu item opening the neutral reference page.
  ///
  /// In en, this message translates to:
  /// **'Common day-count rules'**
  String get menuReference;

  /// Settings screen title.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// Settings section: app language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// Settings section: light/dark theme.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// Settings section: in-app text scale.
  ///
  /// In en, this message translates to:
  /// **'Text size in this app'**
  String get settingsTextSize;

  /// Option meaning 'use the phone's system setting'.
  ///
  /// In en, this message translates to:
  /// **'Follow phone'**
  String get optionFollowPhone;

  /// English language name (endonym; same in both locales).
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// French language name (endonym; same in both locales).
  ///
  /// In en, this message translates to:
  /// **'Français'**
  String get languageFrench;

  /// Light theme option.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// Dark theme option.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// Live preview line under the text-size control.
  ///
  /// In en, this message translates to:
  /// **'Sample text at this size'**
  String get textSizeSample;

  /// Version + build line on the About screen (FR-18).
  ///
  /// In en, this message translates to:
  /// **'Version {version} (build {build})'**
  String aboutVersion(String version, String build);

  /// About screen: privacy section heading.
  ///
  /// In en, this message translates to:
  /// **'Your privacy'**
  String get aboutPrivacyTitle;

  /// About screen: privacy statement.
  ///
  /// In en, this message translates to:
  /// **'{appName} has no account, no cloud, and no tracking. Everything you enter stays on this device and is never sent to the developer. Your data is included in your phone\'s normal backup (iCloud or Google), so it moves to a new phone with you.'**
  String aboutPrivacyBody(String appName);

  /// Button opening the public source repository.
  ///
  /// In en, this message translates to:
  /// **'View the source code'**
  String get aboutSourceButton;

  /// Shown when an external link cannot be opened.
  ///
  /// In en, this message translates to:
  /// **'Could not open the link.'**
  String get linkError;

  /// Reference screen title (FR-15).
  ///
  /// In en, this message translates to:
  /// **'Common day-count rules'**
  String get referenceTitle;

  /// Reference screen intro; restates the no-defaults, not-advice stance.
  ///
  /// In en, this message translates to:
  /// **'These are numbers people commonly track. {appName} sets none of them for you — you enter your own in Alerts. This page is background information, not advice: verify your own situation with a qualified professional.'**
  String referenceIntro(String appName);

  /// Reference item heading: IRS SPT.
  ///
  /// In en, this message translates to:
  /// **'US Substantial Presence Test'**
  String get referenceSptTitle;

  /// Reference item: neutral SPT description.
  ///
  /// In en, this message translates to:
  /// **'A US tax residency test based on a weighted count over three years: all your days this year, plus one third of last year, plus one sixth of the year before. {appName} shows this figure as a neutral number.'**
  String referenceSptBody(String appName);

  /// Reference item heading: provincial health.
  ///
  /// In en, this message translates to:
  /// **'Provincial health coverage'**
  String get referenceHealthTitle;

  /// Reference item: provincial health, no specific number asserted.
  ///
  /// In en, this message translates to:
  /// **'Many provincial health plans expect you to be physically present in your province for a minimum number of days each year. The exact number varies by province and changes over time — check your own plan\'s current rule.'**
  String get referenceHealthBody;

  /// Reference item heading: per-entry admission.
  ///
  /// In en, this message translates to:
  /// **'Length of a US visit'**
  String get referenceEntryTitle;

  /// Reference item: per-entry admission + I-94 gap.
  ///
  /// In en, this message translates to:
  /// **'A visitor is generally admitted for a limited period per entry, at the border officer\'s discretion. The admitted-until date is on your I-94 record — and land crossings are not always recorded, which is exactly why keeping your own dates matters.'**
  String get referenceEntryBody;

  /// Reference item heading: the 180-day myth.
  ///
  /// In en, this message translates to:
  /// **'There is no single cumulative limit'**
  String get referenceMythTitle;

  /// Reference item: why the app never renders a verdict.
  ///
  /// In en, this message translates to:
  /// **'There is no one cumulative \'days\' limit this app could enforce for you. Immigration lawyers often call the \'180-day rule\' a myth; the real constraints are the per-entry admission, the officer\'s discretion, and separate tax tests. That is why {appName} counts and never judges.'**
  String referenceMythBody(String appName);

  /// Required not-advice note shown next to the on-screen SPT figure (FR-7/FR-14).
  ///
  /// In en, this message translates to:
  /// **'A neutral figure, not advice — tap for context.'**
  String get sptDisclaimer;

  /// Section label for the alert-kind selector.
  ///
  /// In en, this message translates to:
  /// **'What to watch'**
  String get alertKindLabel;

  /// Alert-kind option: rolling day-count threshold (FR-9).
  ///
  /// In en, this message translates to:
  /// **'Days in a window'**
  String get alertKindDayCount;

  /// Alert-kind option: elapsed time since the last actual visit (FR-10).
  ///
  /// In en, this message translates to:
  /// **'Time since last visit'**
  String get alertKindSinceVisit;

  /// Numeric field label for the since-last-visit alert.
  ///
  /// In en, this message translates to:
  /// **'Notify me after this many days since my last visit'**
  String get alertThresholdSinceField;

  /// Helper text converting days to years for the since-last-visit field.
  ///
  /// In en, this message translates to:
  /// **'For example, 1825 days is about 5 years.'**
  String get alertSinceHelper;

  /// One-line description of a since-last-visit alert.
  ///
  /// In en, this message translates to:
  /// **'{threshold} days since the last visit'**
  String alertSummarySince(int threshold);

  /// Shown for a since-last-visit alert when no actual trip exists.
  ///
  /// In en, this message translates to:
  /// **'Add an actual trip first — there is no visit to measure from yet'**
  String get alertNoVisits;

  /// Notification body for a since-last-visit alert. Neutral, no judgment.
  ///
  /// In en, this message translates to:
  /// **'As of {date}, it has been {threshold} days since your last US visit — the target you set.'**
  String alertNotificationBodySince(String date, int threshold);

  /// No description provided for @tripStillInUs.
  ///
  /// In en, this message translates to:
  /// **'I am still here'**
  String get tripStillInUs;

  /// No description provided for @tripStillInUsHelper.
  ///
  /// In en, this message translates to:
  /// **'Leave on until you know your departure date. Days count through today.'**
  String get tripStillInUsHelper;

  /// No description provided for @tripOngoing.
  ///
  /// In en, this message translates to:
  /// **'ongoing'**
  String get tripOngoing;

  /// No description provided for @tripDaysSoFar.
  ///
  /// In en, this message translates to:
  /// **'{days} so far'**
  String tripDaysSoFar(String days);

  /// No description provided for @tripStatusCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get tripStatusCurrent;

  /// No description provided for @errorTripOverlap.
  ///
  /// In en, this message translates to:
  /// **'These dates overlap another actual trip. Leaving and returning on the same day is fine.'**
  String get errorTripOverlap;

  /// No description provided for @errorFutureArrival.
  ///
  /// In en, this message translates to:
  /// **'An actual trip cannot start in the future. Choose Planned instead.'**
  String get errorFutureArrival;

  /// No description provided for @errorSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Your change could not be saved on this device.'**
  String get errorSaveFailed;

  /// No description provided for @storageProblemTitle.
  ///
  /// In en, this message translates to:
  /// **'Some saved data could not be read'**
  String get storageProblemTitle;

  /// No description provided for @storageProblemBody.
  ///
  /// In en, this message translates to:
  /// **'Part of your saved data could not be read, so it is not shown or counted. Nothing has been erased: the original is kept on this device, even after you make changes.'**
  String get storageProblemBody;

  /// No description provided for @storageNewerBody.
  ///
  /// In en, this message translates to:
  /// **'Your data was saved by a newer version of {appName}. Please update the app. Until then, changes to that data cannot be saved, so nothing is overwritten.'**
  String storageNewerBody(String appName);

  /// No description provided for @alertInUsNow.
  ///
  /// In en, this message translates to:
  /// **'Will be measured once you record a departure from your current trip'**
  String get alertInUsNow;

  /// No description provided for @recordEntryLabel.
  ///
  /// In en, this message translates to:
  /// **'Entry: {details}'**
  String recordEntryLabel(String details);

  /// No description provided for @recordExitLabel.
  ///
  /// In en, this message translates to:
  /// **'Exit: {details}'**
  String recordExitLabel(String details);

  /// No description provided for @clearTime.
  ///
  /// In en, this message translates to:
  /// **'Clear time'**
  String get clearTime;

  /// No description provided for @errorTimeRequired.
  ///
  /// In en, this message translates to:
  /// **'Choose a delivery time.'**
  String get errorTimeRequired;

  /// No description provided for @alertReached.
  ///
  /// In en, this message translates to:
  /// **'Reached as of today'**
  String get alertReached;

  /// No description provided for @exploreTitle.
  ///
  /// In en, this message translates to:
  /// **'Explore days and plans'**
  String get exploreTitle;

  /// No description provided for @exploreRangeHeading.
  ///
  /// In en, this message translates to:
  /// **'Days in a period'**
  String get exploreRangeHeading;

  /// No description provided for @rangeFrom.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get rangeFrom;

  /// No description provided for @rangeTo.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get rangeTo;

  /// No description provided for @rangeActual.
  ///
  /// In en, this message translates to:
  /// **'Actual days so far: {days}'**
  String rangeActual(String days);

  /// No description provided for @rangeWithPlanned.
  ///
  /// In en, this message translates to:
  /// **'Including planned trips: {days}'**
  String rangeWithPlanned(String days);

  /// No description provided for @whatIfHeading.
  ///
  /// In en, this message translates to:
  /// **'What if I take this trip?'**
  String get whatIfHeading;

  /// No description provided for @whatIfIntro.
  ///
  /// In en, this message translates to:
  /// **'Choose possible dates to see your counts. Nothing is saved unless you choose to.'**
  String get whatIfIntro;

  /// No description provided for @whatIfArrival.
  ///
  /// In en, this message translates to:
  /// **'Possible arrival'**
  String get whatIfArrival;

  /// No description provided for @whatIfDeparture.
  ///
  /// In en, this message translates to:
  /// **'Possible departure'**
  String get whatIfDeparture;

  /// No description provided for @whatIfWithout.
  ///
  /// In en, this message translates to:
  /// **'Without this trip: {value}'**
  String whatIfWithout(String value);

  /// No description provided for @whatIfWith.
  ///
  /// In en, this message translates to:
  /// **'With this trip: {value}'**
  String whatIfWith(String value);

  /// No description provided for @whatIfYear.
  ///
  /// In en, this message translates to:
  /// **'Calendar year {year}, through {date}'**
  String whatIfYear(String year, String date);

  /// No description provided for @whatIfLast365.
  ///
  /// In en, this message translates to:
  /// **'365 days ending {date}'**
  String whatIfLast365(String date);

  /// No description provided for @whatIfSpt.
  ///
  /// In en, this message translates to:
  /// **'Substantial Presence figure, projected to {date}'**
  String whatIfSpt(String date);

  /// No description provided for @whatIfSave.
  ///
  /// In en, this message translates to:
  /// **'Save as a planned trip'**
  String get whatIfSave;

  /// No description provided for @whatIfSaved.
  ///
  /// In en, this message translates to:
  /// **'Planned trip saved.'**
  String get whatIfSaved;

  /// No description provided for @whatIfClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get whatIfClear;

  /// No description provided for @assumeOpenTrip.
  ///
  /// In en, this message translates to:
  /// **'Counts that include planned trips assume your current trip continues until you record a departure.'**
  String get assumeOpenTrip;

  /// No description provided for @assumeStalePlanned.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Includes 1 planned trip whose dates have passed. Mark it as actual or delete it.} other{Includes {count} planned trips whose dates have passed. Mark them as actual or delete them.}}'**
  String assumeStalePlanned(int count);

  /// No description provided for @errorTooManyTrips.
  ///
  /// In en, this message translates to:
  /// **'The limit of {count} trips is reached. Delete a trip to add another.'**
  String errorTooManyTrips(int count);

  /// No description provided for @alertToggleLabel.
  ///
  /// In en, this message translates to:
  /// **'Alert active: {name}'**
  String alertToggleLabel(String name);

  /// No description provided for @exportAsText.
  ///
  /// In en, this message translates to:
  /// **'Plain text (for screen readers)'**
  String get exportAsText;

  /// No description provided for @recordLine.
  ///
  /// In en, this message translates to:
  /// **'{label}: {value}'**
  String recordLine(String label, String value);

  /// No description provided for @recordTripNumber.
  ///
  /// In en, this message translates to:
  /// **'Trip {number} of {total}'**
  String recordTripNumber(int number, int total);

  /// No description provided for @recordTripName.
  ///
  /// In en, this message translates to:
  /// **'Trip name'**
  String get recordTripName;

  /// No description provided for @recordNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get recordNotes;

  /// No description provided for @settingsHighContrast.
  ///
  /// In en, this message translates to:
  /// **'High contrast and bold text'**
  String get settingsHighContrast;

  /// No description provided for @settingsHighContrastHelper.
  ///
  /// In en, this message translates to:
  /// **'When off, follows your phone\'s contrast and bold text settings where available.'**
  String get settingsHighContrastHelper;

  /// No description provided for @aboutHelpTitle.
  ///
  /// In en, this message translates to:
  /// **'Help and planning'**
  String get aboutHelpTitle;

  /// No description provided for @aboutReport.
  ///
  /// In en, this message translates to:
  /// **'Report a problem'**
  String get aboutReport;

  /// No description provided for @aboutRequest.
  ///
  /// In en, this message translates to:
  /// **'Request a feature'**
  String get aboutRequest;

  /// No description provided for @aboutStatus.
  ///
  /// In en, this message translates to:
  /// **'Track reports and requests'**
  String get aboutStatus;

  /// No description provided for @aboutRoadmap.
  ///
  /// In en, this message translates to:
  /// **'What is planned'**
  String get aboutRoadmap;

  /// No description provided for @aboutContribute.
  ///
  /// In en, this message translates to:
  /// **'Make a voluntary contribution'**
  String get aboutContribute;

  /// No description provided for @aboutContributeNote.
  ///
  /// In en, this message translates to:
  /// **'Contributions are optional and unlock nothing: every feature is free. These buttons open {maker}, or GitHub for the source code, in your browser.'**
  String aboutContributeNote(String maker);

  /// No description provided for @aboutPrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get aboutPrivacyPolicy;

  /// Official name of a place, from its ISO 3166 code with '-' replaced by '_'. 'other' shows the code itself, for a code from a newer version (PLC-8).
  ///
  /// In en, this message translates to:
  /// **'{code, select, CA{Canada} US{United States} MX{Mexico} PM{Saint Pierre and Miquelon} PR{Puerto Rico} VI{U.S. Virgin Islands} GU{Guam} AS{American Samoa} MP{Northern Mariana Islands} ZZ{Elsewhere} CA_AB{Alberta} CA_BC{British Columbia} CA_MB{Manitoba} CA_NB{New Brunswick} CA_NL{Newfoundland and Labrador} CA_NS{Nova Scotia} CA_NT{Northwest Territories} CA_NU{Nunavut} CA_ON{Ontario} CA_PE{Prince Edward Island} CA_QC{Quebec} CA_SK{Saskatchewan} CA_YT{Yukon} US_AL{Alabama} US_AK{Alaska} US_AZ{Arizona} US_AR{Arkansas} US_CA{California} US_CO{Colorado} US_CT{Connecticut} US_DE{Delaware} US_DC{District of Columbia} US_FL{Florida} US_GA{Georgia} US_HI{Hawaii} US_ID{Idaho} US_IL{Illinois} US_IN{Indiana} US_IA{Iowa} US_KS{Kansas} US_KY{Kentucky} US_LA{Louisiana} US_ME{Maine} US_MD{Maryland} US_MA{Massachusetts} US_MI{Michigan} US_MN{Minnesota} US_MS{Mississippi} US_MO{Missouri} US_MT{Montana} US_NE{Nebraska} US_NV{Nevada} US_NH{New Hampshire} US_NJ{New Jersey} US_NM{New Mexico} US_NY{New York} US_NC{North Carolina} US_ND{North Dakota} US_OH{Ohio} US_OK{Oklahoma} US_OR{Oregon} US_PA{Pennsylvania} US_RI{Rhode Island} US_SC{South Carolina} US_SD{South Dakota} US_TN{Tennessee} US_TX{Texas} US_UT{Utah} US_VT{Vermont} US_VA{Virginia} US_WA{Washington} US_WV{West Virginia} US_WI{Wisconsin} US_WY{Wyoming} MX_AGU{Aguascalientes} MX_BCN{Baja California} MX_BCS{Baja California Sur} MX_CAM{Campeche} MX_CHH{Chihuahua} MX_CHP{Chiapas} MX_CMX{Mexico City} MX_COA{Coahuila} MX_COL{Colima} MX_DUR{Durango} MX_GRO{Guerrero} MX_GUA{Guanajuato} MX_HID{Hidalgo} MX_JAL{Jalisco} MX_MEX{State of Mexico} MX_MIC{Michoacán} MX_MOR{Morelos} MX_NAY{Nayarit} MX_NLE{Nuevo León} MX_OAX{Oaxaca} MX_PUE{Puebla} MX_QUE{Querétaro} MX_ROO{Quintana Roo} MX_SIN{Sinaloa} MX_SLP{San Luis Potosí} MX_SON{Sonora} MX_TAB{Tabasco} MX_TAM{Tamaulipas} MX_TLA{Tlaxcala} MX_VER{Veracruz} MX_YUC{Yucatán} MX_ZAC{Zacatecas} other{{code}}}'**
  String placeName(String code);

  /// A region with its country, e.g. "Ontario, Canada". No preposition, so it reads correctly in French.
  ///
  /// In en, this message translates to:
  /// **'{region}, {country}'**
  String placeInCountry(String region, String country);

  /// A stay Elsewhere with the country name the user typed.
  ///
  /// In en, this message translates to:
  /// **'Elsewhere ({name})'**
  String placeElsewhereNamed(String name);

  /// Chooser entry for the whole country, with no province, territory or state.
  ///
  /// In en, this message translates to:
  /// **'{country}, region not recorded'**
  String placeWholeCountry(String country);

  /// Label of the place field on the stay screen.
  ///
  /// In en, this message translates to:
  /// **'Place'**
  String get fieldPlace;

  /// Shown when a stay is saved with no place.
  ///
  /// In en, this message translates to:
  /// **'Choose a place.'**
  String get errorPlaceRequired;

  /// Optional name for a stay Elsewhere.
  ///
  /// In en, this message translates to:
  /// **'Country name (optional)'**
  String get fieldElsewhereName;

  /// Title of the place chooser.
  ///
  /// In en, this message translates to:
  /// **'Choose a place'**
  String get placePickerTitle;

  /// Hint of the search field in the place chooser.
  ///
  /// In en, this message translates to:
  /// **'Search by name'**
  String get placeSearchHint;

  /// Heading of recently used places in the chooser.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get placeRecent;

  /// Heading of the list of countries in the chooser.
  ///
  /// In en, this message translates to:
  /// **'Countries'**
  String get placeCountries;

  /// Chooser search with no result.
  ///
  /// In en, this message translates to:
  /// **'No place matches that name.'**
  String get placeNoMatch;

  /// Heading of the list of regions of one country.
  ///
  /// In en, this message translates to:
  /// **'Province, territory or state'**
  String get placeChooseRegion;

  /// Stay list subtitle: place, then dates or days.
  ///
  /// In en, this message translates to:
  /// **'{place} · {rest}'**
  String tripPlaceSubtitle(String place, String rest);

  /// Starts a new stay beginning on the day this one ends (STY-2).
  ///
  /// In en, this message translates to:
  /// **'Add next stop'**
  String get addNextStop;

  /// Closes the ongoing stay and opens the next one on the same date (STY-3).
  ///
  /// In en, this message translates to:
  /// **'I have moved…'**
  String get movedOn;

  /// Title of the move confirmation.
  ///
  /// In en, this message translates to:
  /// **'New place: {place}'**
  String moveConfirmTitle(String place);

  /// Date field of the move confirmation.
  ///
  /// In en, this message translates to:
  /// **'Date of the move'**
  String get moveDateLabel;

  /// Body of the move confirmation.
  ///
  /// In en, this message translates to:
  /// **'The current stay ({from}) ends on this date, and a new stay ({to}) starts the same day. That day counts in both places.'**
  String moveExplain(String from, String to);

  /// Move date before the ongoing stay arrival.
  ///
  /// In en, this message translates to:
  /// **'The move cannot be before the current stay began.'**
  String get errorMoveBeforeArrival;

  /// Action: split a stay into two regions without retyping it (STY-9).
  ///
  /// In en, this message translates to:
  /// **'Split into two places'**
  String get splitStay;

  /// Title of the split screen.
  ///
  /// In en, this message translates to:
  /// **'Split this stay'**
  String get splitTitle;

  /// Date where the second part begins.
  ///
  /// In en, this message translates to:
  /// **'Second place from'**
  String get splitDateLabel;

  /// Place of the first part.
  ///
  /// In en, this message translates to:
  /// **'Place before that date'**
  String get splitBeforeLabel;

  /// Place of the second part.
  ///
  /// In en, this message translates to:
  /// **'Place from that date'**
  String get splitAfterLabel;

  /// Explanation on the split screen.
  ///
  /// In en, this message translates to:
  /// **'Both parts stay in {country}, so its total does not change. The date you choose ends the first part and starts the second, so it counts in both places.'**
  String splitExplain(String country);

  /// Split date outside the stay.
  ///
  /// In en, this message translates to:
  /// **'Choose a date within the stay.'**
  String get errorSplitDate;

  /// Title of the day visits screen.
  ///
  /// In en, this message translates to:
  /// **'Day visits'**
  String get visitsTitle;

  /// Explanation at the top of the day visits screen.
  ///
  /// In en, this message translates to:
  /// **'A day visit is part of a day in another place, without moving there: work, shopping or an appointment. It counts as a day present there, without a stay out and a stay back.'**
  String get visitsExplain;

  /// Empty day visits list.
  ///
  /// In en, this message translates to:
  /// **'No day visits recorded.'**
  String get visitsEmpty;

  /// Button to add a day visit.
  ///
  /// In en, this message translates to:
  /// **'Add day visit'**
  String get addVisit;

  /// Tooltip to delete a day visit.
  ///
  /// In en, this message translates to:
  /// **'Delete day visit'**
  String get deleteVisit;

  /// Date field of a day visit.
  ///
  /// In en, this message translates to:
  /// **'Date of the visit'**
  String get fieldVisitDate;

  /// Day visit limit reached.
  ///
  /// In en, this message translates to:
  /// **'You have reached the limit of {max} day visits.'**
  String errorTooManyVisits(int max);
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
