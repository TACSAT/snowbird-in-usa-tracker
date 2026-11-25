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
  String get backupReminderTitle => 'Garder vos données en sécurité';

  @override
  String get backupReminderBody =>
      'SnowBird conserve tout sur cet appareil uniquement — rien ne nous est jamais envoyé. Vos séjours sont inclus dans la sauvegarde normale de votre téléphone (iCloud ou Google) et se transfèrent donc automatiquement vers un nouveau téléphone. Assurez-vous que la sauvegarde de votre téléphone est activée.';

  @override
  String get backupReminderAcknowledge => 'Compris';

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

  @override
  String get summaryHeading => 'Jours aux États-Unis';

  @override
  String get tripTypeLabel => 'Type de séjour';

  @override
  String get fieldTripName => 'Nom du séjour (facultatif)';

  @override
  String get fieldTripNameHelper =>
      'Un nom pour vous rappeler le but de ce séjour.';

  @override
  String get entryDetailsTitle => 'Passage d\'entrée (facultatif)';

  @override
  String get exitDetailsTitle => 'Passage de sortie (facultatif)';

  @override
  String get fieldCrossingTime => 'Heure (facultatif)';

  @override
  String get fieldTimeZone => 'Fuseau horaire (facultatif)';

  @override
  String get fieldLocation => 'Lieu (facultatif)';

  @override
  String get fieldMeansOfTravel => 'Moyen de transport (facultatif)';

  @override
  String get fieldCarrier => 'Transporteur (facultatif)';

  @override
  String get optionalNotSet => 'Non renseigné';

  @override
  String get errorArrivalRequired => 'Sélectionnez une date d\'arrivée.';

  @override
  String get errorDepartureRequired => 'Sélectionnez une date de départ.';

  @override
  String tripSubtitle(String arrival, String departure, String days) {
    return '$arrival – $departure · $days';
  }

  @override
  String get exportRecord => 'Exporter la fiche';

  @override
  String get exportAsPdf => 'Document PDF';

  @override
  String get exportAsImage => 'Image (PNG)';

  @override
  String get exportAsCsv => 'Tableur (CSV)';

  @override
  String get exportPrint => 'Imprimer';

  @override
  String exportError(String reason) {
    return 'Impossible de créer l\'export : $reason';
  }

  @override
  String get exportEmpty =>
      'Ajoutez d\'abord un séjour — il n\'y a encore rien à exporter.';

  @override
  String get recordHeading => 'Fiche de présence aux États-Unis';

  @override
  String recordAsOf(String date) {
    return 'En date du $date';
  }

  @override
  String get recordDisclaimer =>
      'Ceci est une fiche personnelle, pas un conseil. Elle ne donne aucun avis en immigration, en fiscalité ni en droit. Vérifiez votre situation auprès d\'un professionnel qualifié.';

  @override
  String get recordSummaryTitle => 'Jours de présence aux États-Unis (réels)';

  @override
  String get recordSptLabel => 'Valeur de présence substantielle';

  @override
  String get recordSptFormula =>
      'année courante + ⅓ année précédente + ⅙ avant-précédente';

  @override
  String get recordColDates => 'Dates';

  @override
  String get recordColDays => 'Jours';

  @override
  String get recordColStatus => 'Type';

  @override
  String get recordColDetails => 'Séjour / détails';

  @override
  String get recordAuthor => 'Tenue avec SnowBird — Veiðimaður · veidimadur.ca';

  @override
  String get menuSettings => 'Réglages';

  @override
  String get menuAbout => 'À propos';

  @override
  String get menuReference => 'Règles courantes de comptage';

  @override
  String get settingsTitle => 'Réglages';

  @override
  String get settingsLanguage => 'Langue';

  @override
  String get settingsAppearance => 'Apparence';

  @override
  String get settingsTextSize => 'Taille du texte dans cette appli';

  @override
  String get optionFollowPhone => 'Suivre le téléphone';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageFrench => 'Français';

  @override
  String get themeLight => 'Clair';

  @override
  String get themeDark => 'Sombre';

  @override
  String get textSizeSample => 'Exemple de texte à cette taille';

  @override
  String aboutVersion(String version, String build) {
    return 'Version $version (build $build)';
  }

  @override
  String get aboutPrivacyTitle => 'Votre vie privée';

  @override
  String get aboutPrivacyBody =>
      'SnowBird n\'a aucun compte, aucun nuage et aucun suivi. Tout ce que vous saisissez reste sur cet appareil et n\'est jamais envoyé au développeur. Vos données sont incluses dans la sauvegarde normale de votre téléphone (iCloud ou Google) et vous suivent donc vers un nouveau téléphone.';

  @override
  String get aboutSourceButton => 'Voir le code source';

  @override
  String get linkError => 'Impossible d\'ouvrir le lien.';

  @override
  String get referenceTitle => 'Règles courantes de comptage';

  @override
  String get referenceIntro =>
      'Voici des nombres que les gens suivent souvent. SnowBird n\'en fixe aucun pour vous — vous saisissez les vôtres dans les Alertes. Cette page est une information générale, pas un conseil : vérifiez votre propre situation auprès d\'un professionnel qualifié.';

  @override
  String get referenceSptTitle => 'Test de présence substantielle (É.-U.)';

  @override
  String get referenceSptBody =>
      'Un test de résidence fiscale américaine fondé sur un compte pondéré sur trois ans : tous vos jours cette année, plus un tiers de l\'an dernier, plus un sixième de l\'année d\'avant. SnowBird affiche cette valeur comme un nombre neutre.';

  @override
  String get referenceHealthTitle => 'Couverture santé provinciale';

  @override
  String get referenceHealthBody =>
      'De nombreux régimes de santé provinciaux exigent une présence physique dans votre province un nombre minimal de jours par an. Le nombre exact varie selon la province et change avec le temps — vérifiez la règle actuelle de votre régime.';

  @override
  String get referenceEntryTitle => 'Durée d\'un séjour aux É.-U.';

  @override
  String get referenceEntryBody =>
      'Un visiteur est généralement admis pour une période limitée par entrée, à la discrétion de l\'agent frontalier. La date d\'admission figure sur votre fiche I-94 — et les passages terrestres ne sont pas toujours enregistrés, ce qui est précisément pourquoi tenir vos propres dates compte.';

  @override
  String get referenceMythTitle =>
      'Il n\'existe aucune limite cumulative unique';

  @override
  String get referenceMythBody =>
      'Il n\'existe aucune limite unique de « jours » cumulés que cette appli pourrait appliquer pour vous. Les avocats en immigration qualifient souvent la « règle des 180 jours » de mythe ; les vraies contraintes sont l\'admission par entrée, la discrétion de l\'agent et des tests fiscaux distincts. C\'est pourquoi SnowBird compte et ne juge jamais.';

  @override
  String get sptDisclaimer =>
      'Un nombre neutre, pas un conseil — touchez pour le contexte.';

  @override
  String get alertKindLabel => 'Quoi surveiller';

  @override
  String get alertKindDayCount => 'Jours dans une fenêtre';

  @override
  String get alertKindSinceVisit => 'Temps depuis le dernier séjour';

  @override
  String get alertThresholdSinceField =>
      'M\'aviser après ce nombre de jours depuis mon dernier séjour';

  @override
  String get alertSinceHelper =>
      'Par exemple, 1825 jours représentent environ 5 ans.';

  @override
  String alertSummarySince(int threshold) {
    return '$threshold jours depuis le dernier séjour';
  }

  @override
  String get alertNoVisits =>
      'Ajoutez d\'abord un séjour réel — il n\'y a pas encore de séjour comme point de départ';

  @override
  String alertNotificationBodySince(String date, int threshold) {
    return 'En date du $date, il s\'est écoulé $threshold jours depuis votre dernier séjour aux É.-U. — la cible que vous avez fixée.';
  }

  @override
  String get tripStillInUs => 'Je suis encore aux É.-U.';

  @override
  String get tripStillInUsHelper =>
      'Laissez activé jusqu\'à ce que votre date de départ soit connue. Les jours comptent jusqu\'à aujourd\'hui.';

  @override
  String get tripOngoing => 'en cours';

  @override
  String tripDaysSoFar(String days) {
    return '$days jusqu\'ici';
  }

  @override
  String get tripStatusCurrent => 'En cours';

  @override
  String get errorTripOverlap =>
      'Ces dates chevauchent un autre séjour réel. Sortir et revenir le même jour ne pose pas de problème.';

  @override
  String get errorFutureArrival =>
      'Un séjour réel ne peut pas commencer dans le futur. Choisissez plutôt Planifié.';

  @override
  String get errorSaveFailed =>
      'Votre changement n\'a pas pu être enregistré sur cet appareil.';

  @override
  String get storageProblemTitle => 'Des données enregistrées sont illisibles';

  @override
  String get storageProblemBody =>
      'Une partie de vos données enregistrées n\'a pas pu être lue; elle n\'est donc ni affichée ni comptée. Rien n\'a été effacé : l\'original est conservé sur cet appareil, même après vos modifications.';

  @override
  String get storageNewerBody =>
      'Vos données ont été enregistrées par une version plus récente de SnowBird. Veuillez mettre l\'appli à jour. D\'ici là, les changements à ces données ne peuvent pas être enregistrés, afin de ne rien écraser.';

  @override
  String get alertInUsNow =>
      'Sera mesuré quand vous aurez consigné le départ de votre séjour en cours';

  @override
  String recordEntryLabel(String details) {
    return 'Entrée : $details';
  }

  @override
  String recordExitLabel(String details) {
    return 'Sortie : $details';
  }

  @override
  String get clearTime => 'Effacer l\'heure';

  @override
  String get errorTimeRequired => 'Choisissez une heure de livraison.';

  @override
  String get alertReached => 'Atteinte en date d\'aujourd\'hui';
}
