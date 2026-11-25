// EN: Hard maximums for every user-supplied numeric value in the app. These are
//     a SECURITY boundary, not a UX nicety (PLAN.md → Positioning): all values
//     are validated against these caps at three places —
//       1. in the UI before a value is accepted,
//       2. in model constructors / fromJson when deserialising stored or
//          imported data (a backup file is untrusted input), and
//       3. in the pure engine functions that consume the values.
//     The goal is that a crafted or corrupted value can never overflow date
//     arithmetic, schedule pathological amounts of work (e.g. a threshold-search
//     loop over millions of days), or wrap a 64-bit integer somewhere downstream.
//
//     Why these specific numbers: 10 years (3 650 days) comfortably covers every
//     real residency window a snowbird could care about (the longest real-world
//     window is the 36-month IRS look-back); anything larger is either a typo or
//     an attack, and rejecting it loses nothing.
//
// FR: Maximums stricts pour chaque valeur numérique saisie par l'utilisateur.
//     C'est une frontière de SÉCURITÉ, pas un simple confort d'interface
//     (PLAN.md → Positionnement) : toutes les valeurs sont validées contre ces
//     plafonds à trois endroits —
//       1. dans l'interface avant d'accepter une valeur,
//       2. dans les constructeurs de modèles / fromJson lors de la
//          désérialisation de données stockées ou importées (un fichier de
//          sauvegarde est une entrée non fiable), et
//       3. dans les fonctions pures du moteur qui consomment ces valeurs.
//     L'objectif : une valeur forgée ou corrompue ne peut jamais faire déborder
//     l'arithmétique des dates, déclencher un travail pathologique (p. ex. une
//     boucle de recherche de seuil sur des millions de jours) ni faire boucler
//     un entier 64 bits en aval.
//
//     Pourquoi ces nombres : 10 ans (3 650 jours) couvre largement toute fenêtre
//     de résidence réelle (la plus longue fenêtre réelle est le regard en
//     arrière de 36 mois de l'IRS) ; toute valeur plus grande est soit une faute
//     de frappe, soit une attaque, et la rejeter ne coûte rien.

// EN: Namespace class — not instantiable, constants only.
// FR: Classe espace-de-noms — non instanciable, constantes uniquement.
abstract final class InputLimits {
  // EN: A user-defined day threshold (e.g. "notify me at 75 days") must be
  //     between 1 and 10 years' worth of days.
  // FR: Un seuil de jours défini par l'utilisateur (p. ex. « m'aviser à
  //     75 jours ») doit être entre 1 et l'équivalent de 10 ans de jours.
  static const int minThresholdDays = 1;
  static const int maxThresholdDays = 3650;

  // EN: A rolling window (e.g. "the last 36 months" ≈ 1 095 days) must be
  //     between 1 day and ~10 years. Slightly above maxThresholdDays so a
  //     10-year threshold can still fit inside a valid window.
  // FR: Une fenêtre glissante (p. ex. « les 36 derniers mois » ≈ 1 095 jours)
  //     doit être entre 1 jour et ~10 ans. Légèrement au-dessus de
  //     maxThresholdDays pour qu'un seuil de 10 ans tienne dans une fenêtre valide.
  static const int minWindowDays = 1;
  static const int maxWindowDays = 3660;

  // EN: How far in advance of the reach date a notification may fire: up to one
  //     year in whole days, plus up to 23 hours of finer adjustment. Zero of
  //     both means "on the day itself".
  // FR: Combien de temps avant la date d'atteinte une notification peut être
  //     émise : jusqu'à un an en jours entiers, plus jusqu'à 23 heures
  //     d'ajustement fin. Zéro pour les deux signifie « le jour même ».
  static const int minLeadDays = 0;
  static const int maxLeadDays = 365;
  static const int minLeadHours = 0;
  static const int maxLeadHours = 23;

  // EN: Delivery time of day — a valid 24-hour clock time. There is no default;
  //     the user always picks it (09:00 is only a UI suggestion, never applied
  //     silently).
  // FR: Heure de livraison — une heure valide sur 24 h. Aucune valeur par
  //     défaut ; l'utilisateur la choisit toujours (09:00 n'est qu'une
  //     suggestion d'interface, jamais appliquée silencieusement).
  static const int minHour = 0;
  static const int maxHour = 23;
  static const int minMinute = 0;
  static const int maxMinute = 59;

  // EN: Upper bound on how many days into the future the threshold-reach search
  //     will scan, even if trip data claims dates centuries away (a trip date is
  //     itself user/import-controlled input). 20 years is beyond any honest
  //     planning horizon and keeps the worst-case loop small and constant.
  // FR: Borne supérieure du nombre de jours dans le futur que la recherche de
  //     date d'atteinte parcourra, même si des données de séjour prétendent des
  //     dates dans des siècles (une date de séjour est elle-même une entrée
  //     contrôlée par l'utilisateur ou l'import). 20 ans dépasse tout horizon de
  //     planification honnête et garde la boucle du pire cas petite et constante.
  static const int maxReachSearchDays = 7300;

  // EN: Upper bound on how many trips may be stored. A real snowbird accumulates
  //     at most a few dozen trips over a lifetime; this cap is far above any
  //     honest use and exists only so a crafted import cannot plant hundreds of
  //     thousands of records that would bog down counting or the export. It is a
  //     security ceiling (FR-5), not a real limit the user will ever meet.
  // FR: Borne supérieure du nombre de séjours stockés. Un vrai snowbird accumule
  //     tout au plus quelques dizaines de séjours dans sa vie ; ce plafond
  //     dépasse largement tout usage honnête et n'existe que pour qu'un import
  //     forgé ne puisse pas introduire des centaines de milliers
  //     d'enregistrements qui ralentiraient le comptage ou l'export. C'est un
  //     plafond de sécurité (FR-5), pas une limite réelle que l'utilisateur
  //     atteindra un jour.
  static const int maxTrips = 2000;

  // EN: Years offered by the date pickers: any living memory of a trip, and plans a
  //     decade ahead.
  // FR: Années offertes par les sélecteurs : tout souvenir de séjour, et des projets
  //     jusqu'à dix ans.
  static const int minTripYear = 1950;
  static const int maxYearsAhead = 10;

  // EN: A time of day expressed as minutes since local midnight, 0 (00:00) to
  //     1439 (23:59). Optional per-crossing field: null means "time not
  //     recorded", which is the common case for a land crossing the user only
  //     remembers the date of.
  // FR: Une heure de la journée exprimée en minutes depuis minuit local, de 0
  //     (00 h 00) à 1439 (23 h 59). Champ optionnel par passage : null signifie
  //     « heure non renseignée », le cas courant pour un passage terrestre dont
  //     l'utilisateur ne se rappelle que la date.
  static const int minMinuteOfDay = 0;
  static const int maxMinuteOfDay = 1439;

  // EN: Character caps for the optional free-text fields on a trip. These bound
  //     how much text a single record can carry so a crafted backup cannot
  //     smuggle megabytes into storage, the notification body, or the exported
  //     record. Over-length text from the UI is truncated (a usability matter),
  //     never a reason to reject an entire import — same policy as the alert
  //     label (see kMaxAlertLabelLength).
  // FR: Plafonds de caractères pour les champs texte libres optionnels d'un
  //     séjour. Ils bornent la quantité de texte qu'un enregistrement peut
  //     porter afin qu'une sauvegarde forgée ne puisse pas glisser des
  //     mégaoctets dans le stockage, le corps d'une notification ou le rapport
  //     exporté. Un texte trop long venant de l'interface est tronqué (question
  //     d'ergonomie), jamais un motif de rejet d'un import entier — même
  //     politique que l'étiquette d'alerte (voir kMaxAlertLabelLength).
  static const int maxTripNameLength = 80;
  static const int maxLocationLength = 120;
  static const int maxMeansOfTravelLength = 60;
  static const int maxCarrierLength = 120;
  static const int maxTimeZoneLength = 60;
  static const int maxNotesLength = 2000;
}
