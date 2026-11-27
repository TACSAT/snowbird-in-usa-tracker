// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appDisclaimerTitle => 'Outil de suivi personnel — pas un conseil';

  @override
  String appDisclaimerBody(String appName) {
    return '$appName compte vos jours aux États-Unis et vous permet d\'imprimer ou de partager cet historique. Il ne donne pas de conseils en immigration, en fiscalité ou en droit, et n\'indique pas si un séjour est « sûr ». Vérifiez votre propre situation auprès d\'un professionnel qualifié.';
  }

  @override
  String get appDisclaimerAcknowledge => 'Je comprends';

  @override
  String get backupReminderTitle => 'Garder vos données en sécurité';

  @override
  String backupReminderBody(String appName) {
    return '$appName conserve tout sur cet appareil uniquement — rien ne nous est jamais envoyé. Vos séjours sont inclus dans la sauvegarde normale de votre téléphone (iCloud ou Google) et se transfèrent donc automatiquement vers un nouveau téléphone. Assurez-vous que la sauvegarde de votre téléphone est activée.';
  }

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
      zero: '0 jour',
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
  String aboutTitle(String appName) {
    return 'À propos de $appName';
  }

  @override
  String aboutAuthor(String maker) {
    return 'Créé et maintenu par $maker';
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
  String alertsEmpty(String appName) {
    return 'Aucune alerte.\n$appName ne fixe aucune limite — si vous voulez un rappel à un nombre que vous choisissez, appuyez sur + pour en créer un.';
  }

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
  String alertPermissionDenied(String appName) {
    return 'Les notifications sont désactivées pour $appName dans les réglages de votre appareil ; cette alerte ne peut donc pas être livrée.';
  }

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
  String recordAuthor(String appName, String maker) {
    return 'Tenue avec $appName · $maker';
  }

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
  String aboutPrivacyBody(String appName) {
    return '$appName n\'a aucun compte, aucun nuage et aucun suivi. Tout ce que vous saisissez reste sur cet appareil et n\'est jamais envoyé au développeur. Vos données sont incluses dans la sauvegarde normale de votre téléphone (iCloud ou Google) et vous suivent donc vers un nouveau téléphone.';
  }

  @override
  String get aboutSourceButton => 'Voir le code source';

  @override
  String get linkError => 'Impossible d\'ouvrir le lien.';

  @override
  String get referenceTitle => 'Règles courantes de comptage';

  @override
  String referenceIntro(String appName) {
    return 'Voici des nombres que les gens suivent souvent. $appName n\'en fixe aucun pour vous — vous saisissez les vôtres dans les Alertes. Cette page est une information générale, pas un conseil : vérifiez votre propre situation auprès d\'un professionnel qualifié.';
  }

  @override
  String get referenceSptTitle => 'Test de présence substantielle (É.-U.)';

  @override
  String referenceSptBody(String appName) {
    return 'Un test de résidence fiscale américaine fondé sur un compte pondéré sur trois ans : tous vos jours cette année, plus un tiers de l\'an dernier, plus un sixième de l\'année d\'avant. $appName affiche cette valeur comme un nombre neutre.';
  }

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
  String referenceMythBody(String appName) {
    return 'Il n\'existe aucune limite unique de « jours » cumulés que cette appli pourrait appliquer pour vous. Les avocats en immigration qualifient souvent la « règle des 180 jours » de mythe ; les vraies contraintes sont l\'admission par entrée, la discrétion de l\'agent et des tests fiscaux distincts. C\'est pourquoi $appName compte et ne juge jamais.';
  }

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
  String get tripStillInUs => 'J\'y suis encore';

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
  String storageNewerBody(String appName) {
    return 'Vos données ont été enregistrées par une version plus récente de $appName. Veuillez mettre l\'appli à jour. D\'ici là, les changements à ces données ne peuvent pas être enregistrés, afin de ne rien écraser.';
  }

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

  @override
  String get exploreTitle => 'Explorer les jours et projets';

  @override
  String get exploreRangeHeading => 'Jours dans une période';

  @override
  String get rangeFrom => 'Du';

  @override
  String get rangeTo => 'Au';

  @override
  String rangeActual(String days) {
    return 'Jours réels à ce jour : $days';
  }

  @override
  String rangeWithPlanned(String days) {
    return 'Séjours planifiés compris : $days';
  }

  @override
  String get whatIfHeading => 'Et si je faisais ce séjour?';

  @override
  String get whatIfIntro =>
      'Choisissez des dates possibles pour voir vos comptes. Rien n\'est enregistré sans votre choix.';

  @override
  String get whatIfArrival => 'Arrivée possible';

  @override
  String get whatIfDeparture => 'Départ possible';

  @override
  String whatIfWithout(String value) {
    return 'Sans ce séjour : $value';
  }

  @override
  String whatIfWith(String value) {
    return 'Avec ce séjour : $value';
  }

  @override
  String whatIfYear(String year, String date) {
    return 'Année civile $year, jusqu\'au $date';
  }

  @override
  String whatIfLast365(String date) {
    return '365 jours se terminant le $date';
  }

  @override
  String whatIfSpt(String date) {
    return 'Valeur de présence substantielle, projetée au $date';
  }

  @override
  String get whatIfSave => 'Enregistrer comme séjour planifié';

  @override
  String get whatIfSaved => 'Séjour planifié enregistré.';

  @override
  String get whatIfClear => 'Effacer';

  @override
  String get assumeOpenTrip =>
      'Les comptes incluant les séjours planifiés supposent que votre séjour en cours se poursuit jusqu\'à ce que vous consigniez un départ.';

  @override
  String assumeStalePlanned(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Comprend $count séjours planifiés dont les dates sont passées. Marquez-les comme réels ou supprimez-les.',
      one:
          'Comprend 1 séjour planifié dont les dates sont passées. Marquez-le comme réel ou supprimez-le.',
      zero: 'Comprend 0 séjour planifié dont les dates sont passées.',
    );
    return '$_temp0';
  }

  @override
  String errorTooManyTrips(int count) {
    return 'La limite de $count séjours est atteinte. Supprimez un séjour pour en ajouter un autre.';
  }

  @override
  String alertToggleLabel(String name) {
    return 'Alerte active : $name';
  }

  @override
  String get exportAsText => 'Texte brut (pour lecteurs d\'écran)';

  @override
  String recordLine(String label, String value) {
    return '$label : $value';
  }

  @override
  String recordTripNumber(int number, int total) {
    return 'Séjour $number sur $total';
  }

  @override
  String get recordTripName => 'Nom du séjour';

  @override
  String get recordNotes => 'Notes';

  @override
  String get settingsHighContrast => 'Contraste élevé et texte gras';

  @override
  String get settingsHighContrastHelper =>
      'Si désactivé, suit les réglages de contraste et de texte gras de votre téléphone, s\'ils existent.';

  @override
  String get aboutHelpTitle => 'Aide et planification';

  @override
  String get aboutReport => 'Signaler un problème';

  @override
  String get aboutRequest => 'Demander une fonctionnalité';

  @override
  String get aboutStatus => 'Suivre signalements et demandes';

  @override
  String get aboutRoadmap => 'Ce qui est prévu';

  @override
  String get aboutContribute => 'Faire une contribution volontaire';

  @override
  String aboutContributeNote(String maker) {
    return 'Les contributions sont facultatives et ne débloquent rien : toutes les fonctionnalités sont gratuites. Ces boutons ouvrent $maker, ou GitHub pour le code source, dans votre navigateur.';
  }

  @override
  String get aboutPrivacyPolicy => 'Politique de confidentialité';

  @override
  String placeName(String code) {
    String _temp0 = intl.Intl.selectLogic(
      code,
      {
        'CA': 'Canada',
        'US': 'États-Unis',
        'MX': 'Mexique',
        'PM': 'Saint-Pierre-et-Miquelon',
        'PR': 'Porto Rico',
        'VI': 'Îles Vierges des États-Unis',
        'GU': 'Guam',
        'AS': 'Samoa américaines',
        'MP': 'Îles Mariannes du Nord',
        'ZZ': 'Ailleurs',
        'CA_AB': 'Alberta',
        'CA_BC': 'Colombie-Britannique',
        'CA_MB': 'Manitoba',
        'CA_NB': 'Nouveau-Brunswick',
        'CA_NL': 'Terre-Neuve-et-Labrador',
        'CA_NS': 'Nouvelle-Écosse',
        'CA_NT': 'Territoires du Nord-Ouest',
        'CA_NU': 'Nunavut',
        'CA_ON': 'Ontario',
        'CA_PE': 'Île-du-Prince-Édouard',
        'CA_QC': 'Québec',
        'CA_SK': 'Saskatchewan',
        'CA_YT': 'Yukon',
        'US_AL': 'Alabama',
        'US_AK': 'Alaska',
        'US_AZ': 'Arizona',
        'US_AR': 'Arkansas',
        'US_CA': 'Californie',
        'US_CO': 'Colorado',
        'US_CT': 'Connecticut',
        'US_DE': 'Delaware',
        'US_DC': 'District de Columbia',
        'US_FL': 'Floride',
        'US_GA': 'Géorgie',
        'US_HI': 'Hawaï',
        'US_ID': 'Idaho',
        'US_IL': 'Illinois',
        'US_IN': 'Indiana',
        'US_IA': 'Iowa',
        'US_KS': 'Kansas',
        'US_KY': 'Kentucky',
        'US_LA': 'Louisiane',
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
        'US_NM': 'Nouveau-Mexique',
        'US_NY': 'New York',
        'US_NC': 'Caroline du Nord',
        'US_ND': 'Dakota du Nord',
        'US_OH': 'Ohio',
        'US_OK': 'Oklahoma',
        'US_OR': 'Oregon',
        'US_PA': 'Pennsylvanie',
        'US_RI': 'Rhode Island',
        'US_SC': 'Caroline du Sud',
        'US_SD': 'Dakota du Sud',
        'US_TN': 'Tennessee',
        'US_TX': 'Texas',
        'US_UT': 'Utah',
        'US_VT': 'Vermont',
        'US_VA': 'Virginie',
        'US_WA': 'Washington',
        'US_WV': 'Virginie-Occidentale',
        'US_WI': 'Wisconsin',
        'US_WY': 'Wyoming',
        'MX_AGU': 'Aguascalientes',
        'MX_BCN': 'Basse-Californie',
        'MX_BCS': 'Basse-Californie-du-Sud',
        'MX_CAM': 'Campeche',
        'MX_CHH': 'Chihuahua',
        'MX_CHP': 'Chiapas',
        'MX_CMX': 'Mexico (ville)',
        'MX_COA': 'Coahuila',
        'MX_COL': 'Colima',
        'MX_DUR': 'Durango',
        'MX_GRO': 'Guerrero',
        'MX_GUA': 'Guanajuato',
        'MX_HID': 'Hidalgo',
        'MX_JAL': 'Jalisco',
        'MX_MEX': 'État de Mexico',
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
    return 'Ailleurs ($name)';
  }

  @override
  String placeWholeCountry(String country) {
    return '$country, région non précisée';
  }

  @override
  String get fieldPlace => 'Lieu';

  @override
  String get errorPlaceRequired => 'Choisissez un lieu.';

  @override
  String get fieldElsewhereName => 'Nom du pays (facultatif)';

  @override
  String get placePickerTitle => 'Choisir un lieu';

  @override
  String get placeSearchHint => 'Rechercher par nom';

  @override
  String get placeRecent => 'Récents';

  @override
  String get placeCountries => 'Pays';

  @override
  String get placeNoMatch => 'Aucun lieu ne correspond à ce nom.';

  @override
  String get placeChooseRegion => 'Province, territoire ou État';

  @override
  String tripPlaceSubtitle(String place, String rest) {
    return '$place · $rest';
  }

  @override
  String get addNextStop => 'Ajouter l\'étape suivante';

  @override
  String get movedOn => 'J\'ai changé de lieu…';

  @override
  String moveConfirmTitle(String place) {
    return 'Nouveau lieu : $place';
  }

  @override
  String get moveDateLabel => 'Date du changement';

  @override
  String moveExplain(String from, String to) {
    return 'Le séjour actuel ($from) se termine à cette date, et un nouveau séjour ($to) commence le même jour. Ce jour compte dans les deux lieux.';
  }

  @override
  String get errorMoveBeforeArrival =>
      'Le changement ne peut pas précéder le début du séjour actuel.';

  @override
  String get splitStay => 'Diviser en deux lieux';

  @override
  String get splitTitle => 'Diviser ce séjour';

  @override
  String get splitDateLabel => 'Second lieu à partir du';

  @override
  String get splitBeforeLabel => 'Lieu avant cette date';

  @override
  String get splitAfterLabel => 'Lieu à partir de cette date';

  @override
  String splitExplain(String country) {
    return 'Les deux parties restent dans le pays ($country) ; son total ne change donc pas. La date choisie termine la première partie et commence la seconde ; elle compte donc dans les deux lieux.';
  }

  @override
  String get errorSplitDate => 'Choisissez une date comprise dans le séjour.';

  @override
  String get visitsTitle => 'Visites d\'un jour';

  @override
  String get visitsExplain =>
      'Une visite d\'un jour est une partie de journée passée dans un autre lieu, sans y déménager : travail, courses ou rendez-vous. Elle compte comme un jour de présence dans ce lieu, sans séjour aller ni séjour retour.';

  @override
  String get visitsEmpty => 'Aucune visite d\'un jour enregistrée.';

  @override
  String get addVisit => 'Ajouter une visite d\'un jour';

  @override
  String get deleteVisit => 'Supprimer la visite d\'un jour';

  @override
  String get fieldVisitDate => 'Date de la visite';

  @override
  String errorTooManyVisits(int max) {
    return 'Vous avez atteint la limite de $max visites d\'un jour.';
  }
}
