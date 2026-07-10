// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'SnowBird';

  @override
  String get appDisclaimerTitle => 'Outil de suivi personnel — pas un conseil';

  @override
  String get appDisclaimerBody =>
      'SnowBird compte vos jours aux États-Unis et vous permet d\'imprimer ou de partager cet historique. Il ne donne pas de conseils en immigration, en fiscalité ou en droit, et n\'indique pas si un séjour est « sûr ». Vérifiez votre propre situation auprès d\'un professionnel qualifié.';

  @override
  String get appDisclaimerAcknowledge => 'Je comprends';

  @override
  String get tripStatusActual => 'Réel';

  @override
  String get tripStatusPlanned => 'Planifié';

  @override
  String daysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jours',
      one: '1 jour',
    );
    return '$_temp0';
  }

  @override
  String get tripListEmpty =>
      'Aucun séjour enregistré pour l\'instant.\nAppuyez sur + pour ajouter votre premier séjour.';

  @override
  String get addTrip => 'Ajouter un séjour';

  @override
  String get editTrip => 'Modifier le séjour';

  @override
  String get deleteTrip => 'Supprimer le séjour';

  @override
  String get deleteTripConfirm =>
      'Supprimer ce séjour ? Cette action est irréversible.';

  @override
  String get cancel => 'Annuler';

  @override
  String get delete => 'Supprimer';

  @override
  String get save => 'Enregistrer';

  @override
  String get fieldArrivalDate => 'Date d\'arrivée';

  @override
  String get fieldDepartureDate => 'Date de départ';

  @override
  String get fieldNotes => 'Notes (facultatif)';

  @override
  String get errorDepartureBefore =>
      'La date de départ doit être égale ou postérieure à l\'arrivée.';

  @override
  String get aboutTitle => 'À propos de SnowBird';

  @override
  String get aboutBody =>
      'SnowBird est un suivi de séjours gratuit, open source et respectueux de la vie privée. Vos données ne quittent jamais votre appareil.';

  @override
  String get aboutAuthor => 'Développé par Veiðimaður — veidimadur.ca';

  @override
  String get feedbackButton => 'Envoyer des commentaires';

  @override
  String get donateButton => 'Soutenir le développeur';

  @override
  String get exportBackup => 'Exporter la sauvegarde';

  @override
  String get importBackup => 'Importer la sauvegarde';

  @override
  String get importBackupConfirm =>
      'L\'importation remplacera toutes les données de séjour actuelles. Continuer ?';

  @override
  String get importSuccess => 'Sauvegarde importée avec succès.';

  @override
  String importError(String reason) {
    return 'Impossible d\'importer la sauvegarde : $reason';
  }

  @override
  String get windowLast365 => '365 derniers jours';

  @override
  String get windowThisYear => 'Cette année civile';

  @override
  String get windowLastYear => 'Année civile précédente';

  @override
  String get windowCustom => 'Plage personnalisée';

  @override
  String get alertsTitle => 'Mes alertes';

  @override
  String get alertsTooltip => 'Mes alertes';

  @override
  String get alertsEmpty =>
      'Aucune alerte.\nSnowBird ne fixe aucune limite de lui-même — si vous voulez un rappel à un nombre que vous choisissez, appuyez sur + pour en créer un.';

  @override
  String get addAlert => 'Ajouter une alerte';

  @override
  String get editAlert => 'Modifier l\'alerte';

  @override
  String get deleteAlert => 'Supprimer l\'alerte';

  @override
  String get deleteAlertConfirm =>
      'Supprimer cette alerte ? Vos séjours ne sont pas touchés.';

  @override
  String get alertLabelField => 'Nom (facultatif)';

  @override
  String get alertThresholdField => 'M\'aviser à ce nombre de jours';

  @override
  String get alertWindowField => 'Comptés dans les derniers (jours)';

  @override
  String get alertWindowHelper =>
      'Par exemple, 36 mois représentent environ 1095 jours.';

  @override
  String get alertTimeField => 'Heure de livraison';

  @override
  String get alertLeadField => 'Préavis';

  @override
  String get alertLeadNone => 'Le jour même';

  @override
  String get alertLeadDaysField => 'Jours avant';

  @override
  String get alertLeadHoursField => 'Heures avant';

  @override
  String get alertEnabledToggle => 'Active';

  @override
  String alertSummary(int threshold, int window) {
    return '$threshold jours dans les $window derniers jours';
  }

  @override
  String alertProjectedReach(String date) {
    return 'Atteinte de votre cible projetée le $date';
  }

  @override
  String get alertNotReached =>
      'Non atteinte avec vos séjours actuels et planifiés';

  @override
  String alertRangeError(int min, int max) {
    return 'Saisissez un nombre entier entre $min et $max.';
  }

  @override
  String get alertPermissionDenied =>
      'Les notifications sont désactivées pour SnowBird dans les réglages de votre appareil ; cette alerte ne peut donc pas être livrée.';

  @override
  String get alertNotificationTitle => 'Votre cible de jours';

  @override
  String alertNotificationBodyToday(int threshold, int window) {
    return 'Aujourd\'hui, vous atteignez $threshold jours dans votre fenêtre de $window jours — la cible que vous avez fixée.';
  }

  @override
  String alertNotificationBodyAdvance(String date, int threshold, int window) {
    return 'Le $date, vous atteindrez $threshold jours dans votre fenêtre de $window jours — la cible que vous avez fixée.';
  }

  @override
  String get alertChannelName => 'Vos cibles de jours';

  @override
  String get alertChannelDescription =>
      'Rappels que vous avez créés pour des cibles de jours que vous avez fixées vous-même.';
}
