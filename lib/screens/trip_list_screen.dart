// EN: The primary screen — a day-count summary at the top, then the list of trips
//     newest-first (FR-4), with a tap to edit each one and a + to add. Actual and
//     planned trips are visually distinguished by a status chip. Counts in the
//     summary are NEUTRAL numbers (PLAN.md positioning): "this calendar year" and
//     "last 365 days" of ACTUAL presence — no colour of alarm, no verdict, just the
//     arithmetic the user could do by hand.
//
// FR: L'écran principal — un résumé de comptage de jours en haut, puis la liste des
//     séjours du plus récent au plus ancien (FR-4), avec un toucher pour modifier
//     chacun et un + pour ajouter. Les séjours réels et planifiés sont distingués
//     visuellement par une puce de statut. Les totaux du résumé sont des nombres
//     NEUTRES (positionnement PLAN.md) : « cette année civile » et « 365 derniers
//     jours » de présence RÉELLE — aucune couleur d'alarme, aucun verdict, juste
//     l'arithmétique que l'utilisateur pourrait faire à la main.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:snowbird_in_usa_tracker/models/place.dart';
import 'package:snowbird_in_usa_tracker/config/app_identity.dart';
import 'package:snowbird_in_usa_tracker/l10n/app_localizations.dart';
import 'package:snowbird_in_usa_tracker/logic/presence_record.dart';
import 'package:snowbird_in_usa_tracker/models/trip.dart';
import 'package:snowbird_in_usa_tracker/screens/about_screen.dart';
import 'package:snowbird_in_usa_tracker/screens/alerts_screen.dart';
import 'package:snowbird_in_usa_tracker/screens/explore_screen.dart';
import 'package:snowbird_in_usa_tracker/screens/move_flow.dart';
import 'package:snowbird_in_usa_tracker/screens/place_names.dart';
import 'package:snowbird_in_usa_tracker/screens/presence_table_card.dart';
import 'package:snowbird_in_usa_tracker/screens/visits_screen.dart';
import 'package:snowbird_in_usa_tracker/screens/reference_screen.dart';
import 'package:snowbird_in_usa_tracker/screens/settings_screen.dart';
import 'package:snowbird_in_usa_tracker/screens/trip_edit_screen.dart';
import 'package:snowbird_in_usa_tracker/services/record_exporter.dart';
import 'package:snowbird_in_usa_tracker/services/storage_service.dart';
import 'package:snowbird_in_usa_tracker/state/trip_repository.dart';

// EN: The ways to export the US Presence Record (FR-8).
// FR: Les façons d'exporter la fiche de présence (FR-8).
enum _ExportChoice { pdf, text, image, csv, print }

// EN: Overflow-menu destinations (FR-14/15/20).
// FR: Destinations du menu de débordement (FR-14/15/20).
enum _Menu { explore, visits, reference, settings, about }

class TripListScreen extends StatefulWidget {
  const TripListScreen({super.key});

  @override
  State<TripListScreen> createState() => _TripListScreenState();
}

// EN: The stay list filter (FEA-4): a country (or all), a year the stay touches
//     (or all) and actual or planned (or both). It narrows the list only; the
//     Days present table above always counts everything. Kept for the session,
//     not saved: a filter left on next week would hide stays without saying so.
// FR: Le filtre de la liste des séjours (FEA-4) : un pays (ou tous), une année
//     que touche le séjour (ou toutes) et réel ou planifié (ou les deux). Il ne
//     restreint que la liste ; le tableau des jours de présence au-dessus compte
//     toujours tout. Gardé pour la session, non enregistré : un filtre resté
//     actif la semaine suivante cacherait des séjours sans le dire.
class _StayFilter {
  final Place? country;
  final int? year;
  final TripStatus? status;

  const _StayFilter({this.country, this.year, this.status});

  bool get isActive => country != null || year != null || status != null;

  bool matches(Trip trip) {
    if (country != null && !country!.contains(trip.place)) return false;
    if (status != null && trip.status != status) return false;
    final y = year;
    if (y != null) {
      final now = DateTime.now();
      final last = trip.departureDate?.year ?? now.year;
      if (trip.arrivalDate.year > y || last < y) return false;
    }
    return true;
  }
}

class _TripListScreenState extends State<TripListScreen> {
  _StayFilter _filter = const _StayFilter();

  Future<void> _openFilter(List<Trip> trips) async {
    final strings = AppLocalizations.of(context);
    final countries = <Place>{for (final t in trips) t.place.country};
    final now = DateTime.now().year;
    final years = <int>{
      for (final t in trips)
        for (var y = t.arrivalDate.year;
            y <= (t.departureDate?.year ?? now);
            y++)
          y,
    }.toList()
      ..sort((a, b) => b.compareTo(a));
    var draft = _filter;
    final applied = await showModalBottomSheet<_StayFilter>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheet) => StatefulBuilder(
        builder: (sheet, setSheet) => SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<Place?>(
                  isExpanded: true,
                  initialValue: draft.country,
                  decoration: InputDecoration(labelText: strings.fieldPlace),
                  items: [
                    DropdownMenuItem(child: Text(strings.filterAll)),
                    for (final c in countries)
                      DropdownMenuItem(
                        value: c,
                        child: Text(placeFullName(strings, c)),
                      ),
                  ],
                  onChanged: (v) => setSheet(
                    () => draft = _StayFilter(
                      country: v,
                      year: draft.year,
                      status: draft.status,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int?>(
                  isExpanded: true,
                  initialValue: draft.year,
                  decoration: InputDecoration(labelText: strings.filterYear),
                  items: [
                    DropdownMenuItem(child: Text(strings.filterAll)),
                    for (final y in years)
                      DropdownMenuItem(value: y, child: Text('$y')),
                  ],
                  onChanged: (v) => setSheet(
                    () => draft = _StayFilter(
                      country: draft.country,
                      year: v,
                      status: draft.status,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<TripStatus?>(
                  isExpanded: true,
                  initialValue: draft.status,
                  decoration: InputDecoration(labelText: strings.tripTypeLabel),
                  items: [
                    DropdownMenuItem(child: Text(strings.filterAll)),
                    DropdownMenuItem(
                      value: TripStatus.actual,
                      child: Text(strings.tripStatusActual),
                    ),
                    DropdownMenuItem(
                      value: TripStatus.planned,
                      child: Text(strings.tripStatusPlanned),
                    ),
                  ],
                  onChanged: (v) => setSheet(
                    () => draft = _StayFilter(
                      country: draft.country,
                      year: draft.year,
                      status: v,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => Navigator.of(sheet).pop(draft),
                  child: Text(strings.filterApply),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (applied != null && mounted) setState(() => _filter = applied);
  }

  // EN: Locates the export button on screen, where an iPad anchors its share popover.
  // FR: Situe le bouton d'export à l'écran, où l'iPad ancre sa bulle de partage.
  final _exportButtonKey = GlobalKey();

  Rect _shareOrigin() {
    final box = _exportButtonKey.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.hasSize) {
      return const Rect.fromLTWH(0, 0, 1, 1);
    }
    return box.localToGlobal(Offset.zero) & box.size;
  }

  @override
  void initState() {
    super.initState();
    // EN: Run the one-time onboarding AFTER the first frame — showing a dialog
    //     during build is illegal, and we need a live Navigator/overlay.
    // FR: Exécuter l'accueil unique APRÈS la première image — afficher un dialogue
    //     pendant le build est interdit, et il faut un Navigator/overlay actif.
    WidgetsBinding.instance.addPostFrameCallback((_) => _runOnboarding());
  }

  // EN: Show the not-advice disclaimer (FR-14) once, then the single backup
  //     reminder (FR-11) once. Each is gated by a persisted flag so neither ever
  //     nags again. Both are non-dismissible-by-tap-outside so they are actually
  //     read, but each is a single "understood" acknowledgement — no decision.
  // FR: Montrer l'avertissement « pas un conseil » (FR-14) une fois, puis l'unique
  //     rappel de sauvegarde (FR-11) une fois. Chacun est protégé par un indicateur
  //     persistant pour ne jamais réapparaître. Les deux ne se ferment pas d'un
  //     toucher à l'extérieur afin d'être réellement lus, mais chacun n'est qu'un
  //     acquittement « compris » — aucune décision.
  Future<void> _runOnboarding() async {
    final storage = context.read<StorageService>();

    if (!storage.disclaimerAcknowledged) {
      if (!mounted) return;
      final strings = AppLocalizations.of(context);
      await _showAck(
        title: strings.appDisclaimerTitle,
        body: strings.appDisclaimerBody(AppIdentity.name),
        button: strings.appDisclaimerAcknowledge,
      );
      await storage.setDisclaimerAcknowledged();
    }

    if (!storage.backupReminderShown) {
      if (!mounted) return;
      final strings = AppLocalizations.of(context);
      await _showAck(
        title: strings.backupReminderTitle,
        body: strings.backupReminderBody(AppIdentity.name),
        button: strings.backupReminderAcknowledge,
      );
      await storage.setBackupReminderShown();
    }

    // EN: Shown at each launch while the problem lasts (the first successful save
    //     clears it): silence here would look like lost trips (FR-13).
    // FR: Montré à chaque lancement tant que le problème dure (le premier
    //     enregistrement réussi le règle) : le silence ferait croire à des séjours
    //     perdus (FR-13).
    // EN: One note, once, for someone upgrading with trips from before places
    //     (MIG-4): no question asked, only what is new. A new user never sees
    //     it; the flag is set either way so it can never come back.
    // FR: Une note, une seule fois, pour qui met à jour avec des séjours
    //     d'avant les lieux (MIG-4) : aucune question, seulement ce qui est
    //     nouveau. Un nouvel utilisateur ne la voit jamais ; le drapeau est posé
    //     dans tous les cas pour qu'elle ne revienne jamais.
    if (!storage.placesNoteShown) {
      if (storage.loadedOlderTrips) {
        if (!mounted) return;
        final strings = AppLocalizations.of(context);
        await _showAck(
          title: strings.whatsNewTitle,
          body: strings.whatsNewBody(AppIdentity.name),
          button: strings.backupReminderAcknowledge,
        );
      }
      await storage.setPlacesNoteShown();
    }
    if (storage.loadProblem != StorageLoadProblem.none) {
      if (!mounted) return;
      final strings = AppLocalizations.of(context);
      await _showAck(
        title: strings.storageProblemTitle,
        body: storage.loadProblem == StorageLoadProblem.newerVersion
            ? strings.storageNewerBody(AppIdentity.name)
            : strings.storageProblemBody,
        button: strings.backupReminderAcknowledge,
      );
    }
  }

  // EN: Open the export sheet (FR-8): build the record from the current trips, let
  //     the user pick a format, then generate + hand off to the OS (share sheet or
  //     print dialog). All context-bound objects are captured before the awaits.
  //     Any failure surfaces as a neutral snack bar rather than crashing.
  // FR: Ouvrir la feuille d'export (FR-8) : construire la fiche à partir des séjours
  //     actuels, laisser l'utilisateur choisir un format, puis générer + remettre à
  //     l'OS (feuille de partage ou boîte d'impression). Tous les objets liés au
  //     contexte sont capturés avant les await. Tout échec s'affiche en barre
  //     neutre plutôt que de planter.
  Future<void> _openExportSheet() async {
    final strings = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final trips = context.read<TripRepository>().trips;
    final localeName = strings.localeName;

    if (trips.isEmpty) {
      messenger.showSnackBar(SnackBar(content: Text(strings.exportEmpty)));
      return;
    }

    // EN: The record's figures include day visits, as one-day stays, so they
    //     match the summary on screen.
    // FR: Les chiffres du relevé incluent les visites d'un jour, comme séjours
    //     d'un jour, afin de concorder avec le résumé à l'écran.
    final record = PresenceRecord.build(
      trips: context.read<TripRepository>().countedStays,
    );

    final choice = await showModalBottomSheet<_ExportChoice>(
      context: context,
      // EN: Scrolls and may use the full height, or large text would push the last
      //     choices off screen.
      // FR: Défile et peut prendre toute la hauteur, sinon le grand texte pousserait
      //     les derniers choix hors de l'écran.
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.picture_as_pdf_outlined),
                title: Text(strings.exportAsPdf),
                onTap: () => Navigator.pop(ctx, _ExportChoice.pdf),
              ),
              ListTile(
                leading: const Icon(Icons.notes),
                title: Text(strings.exportAsText),
                onTap: () => Navigator.pop(ctx, _ExportChoice.text),
              ),
              ListTile(
                leading: const Icon(Icons.image_outlined),
                title: Text(strings.exportAsImage),
                onTap: () => Navigator.pop(ctx, _ExportChoice.image),
              ),
              ListTile(
                leading: const Icon(Icons.table_chart_outlined),
                title: Text(strings.exportAsCsv),
                onTap: () => Navigator.pop(ctx, _ExportChoice.csv),
              ),
              ListTile(
                leading: const Icon(Icons.print_outlined),
                title: Text(strings.exportPrint),
                onTap: () => Navigator.pop(ctx, _ExportChoice.print),
              ),
            ],
          ),
        ),
      ),
    );
    if (choice == null) return;

    try {
      switch (choice) {
        case _ExportChoice.pdf:
          await RecordExporter.sharePdf(
            record,
            strings: strings,
            localeName: localeName,
            origin: _shareOrigin(),
          );
        case _ExportChoice.text:
          await RecordExporter.shareText(
            record,
            strings: strings,
            localeName: localeName,
            origin: _shareOrigin(),
          );
        case _ExportChoice.image:
          await RecordExporter.shareImage(
            record,
            strings: strings,
            localeName: localeName,
            origin: _shareOrigin(),
          );
        case _ExportChoice.csv:
          await RecordExporter.shareCsv(record, origin: _shareOrigin());
        case _ExportChoice.print:
          await RecordExporter.printRecord(
            record,
            strings: strings,
            localeName: localeName,
          );
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(strings.exportError(e.toString()))),
      );
    }
  }

  // EN: Route an overflow-menu selection to its screen.
  // FR: Diriger une sélection du menu vers son écran.
  void _onMenu(BuildContext context, _Menu item) {
    final Widget screen = switch (item) {
      _Menu.explore => const ExploreScreen(),
      _Menu.visits => const VisitsScreen(),
      _Menu.reference => const ReferenceScreen(),
      _Menu.settings => const SettingsScreen(),
      _Menu.about => const AboutScreen(),
    };
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => screen),
    );
  }

  Future<void> _showAck({
    required String title,
    required String body,
    required String button,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(child: Text(body)),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(button),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final repo = context.watch<TripRepository>();
    final trips = repo.trips;
    // EN: The ongoing actual stay, if any: it offers "I have moved..." right on
    //     the main screen, the quickest path for a move (STY-3).
    // FR: Le séjour réel en cours, s'il y en a un : il offre « J'ai changé de
    //     lieu... » directement sur l'écran principal, le chemin le plus rapide
    //     pour un changement (STY-3).
    final shown = [
      for (final t in trips)
        if (_filter.matches(t)) t,
    ];
    final ongoing = trips
        .where((t) => t.status == TripStatus.actual && t.departureDate == null)
        .firstOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppIdentity.name),
        centerTitle: false,
        actions: [
          if (trips.isNotEmpty)
            IconButton(
              icon: Icon(
                _filter.isActive ? Icons.filter_alt : Icons.filter_alt_outlined,
              ),
              tooltip: strings.filterTooltip,
              onPressed: () => _openFilter(trips),
            ),
          IconButton(
            key: _exportButtonKey,
            icon: const Icon(Icons.ios_share_rounded),
            tooltip: strings.exportRecord,
            onPressed: _openExportSheet,
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            tooltip: strings.alertsTooltip,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const AlertsScreen()),
            ),
          ),
          PopupMenuButton<_Menu>(
            onSelected: (item) => _onMenu(context, item),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: _Menu.explore,
                child: Text(strings.exploreTitle),
              ),
              PopupMenuItem(
                value: _Menu.visits,
                child: Text(strings.visitsTitle),
              ),
              PopupMenuItem(
                value: _Menu.reference,
                child: Text(strings.menuReference),
              ),
              PopupMenuItem(
                value: _Menu.settings,
                child: Text(strings.menuSettings),
              ),
              PopupMenuItem(
                value: _Menu.about,
                child: Text(strings.menuAbout),
              ),
            ],
          ),
        ],
      ),
      body: trips.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  strings.tripListEmpty,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            )
          // EN: The summary scrolls WITH the list: pinned above it, large text left
          //     no room for the trips themselves (NFR-5).
          // FR: Le résumé défile AVEC la liste : épinglé au-dessus, le grand texte ne
          //     laissait aucune place aux séjours (NFR-5).
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 88),
              itemCount: shown.length + 1,
              itemBuilder: (context, index) => index == 0
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const PresenceTableCard(),
                        if (ongoing != null)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                            child: FilledButton.tonalIcon(
                              icon: const Icon(Icons.moving),
                              label: Text(strings.movedOn),
                              onPressed: () => startMove(context, ongoing),
                            ),
                          ),
                        const Divider(height: 1),
                        if (_filter.isActive)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                            child: Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 8,
                              children: [
                                Semantics(
                                  liveRegion: true,
                                  child: Text(
                                    shown.isEmpty
                                        ? strings.filterNone
                                        : strings.filterShown(
                                            shown.length,
                                            trips.length,
                                          ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => setState(
                                    () => _filter = const _StayFilter(),
                                  ),
                                  child: Text(strings.filterClear),
                                ),
                              ],
                            ),
                          ),
                      ],
                    )
                  : _TripTile(trip: shown[index - 1]),
            ),
      floatingActionButton: FloatingActionButton(
        tooltip: strings.addTrip,
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const TripEditScreen()),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}

// EN: One trip row: a status chip (Actual / Planned), the trip name or date range
//     as the title, and a date-range + day-count subtitle. Tapping opens the
//     editor; delete lives inside the editor behind a confirmation (FR-21).
// FR: Une rangée de séjour : une puce de statut (Réel / Planifié), le nom du
//     séjour ou la plage de dates comme titre, et un sous-titre plage de dates +
//     nombre de jours. Le toucher ouvre l'éditeur ; la suppression vit dans
//     l'éditeur derrière une confirmation (FR-21).
class _TripTile extends StatelessWidget {
  final Trip trip;
  const _TripTile({required this.trip});

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final dateFmt = DateFormat.yMMMd(strings.localeName);

    final arrival = dateFmt.format(trip.arrivalDate);
    final departure = trip.departureDate == null
        ? strings.tripOngoing
        : dateFmt.format(trip.departureDate!);
    final now = DateTime.now();
    final isCurrent = trip.isInProgress(now);
    final days = strings.daysCount(trip.daysPresent(now));
    final isPlanned = trip.status == TripStatus.planned;

    // EN: At large text a trailing chip leaves no width for the dates, so it moves
    //     below them.
    // FR: En grand texte, une puce à droite ne laisse aucune largeur aux dates ; elle
    //     passe donc dessous.
    final largeText = MediaQuery.textScalerOf(context).scale(14) / 14 > 1.3;
    // EN: An unnamed trip already has its dates as title; do not repeat them.
    // FR: Un séjour sans nom a déjà ses dates pour titre ; ne pas les répéter.
    final hasName = trip.name?.isNotEmpty ?? false;
    final daysText = isCurrent ? strings.tripDaysSoFar(days) : days;
    final rest =
        hasName ? strings.tripSubtitle(arrival, departure, daysText) : daysText;
    // EN: Every stay shows its place (EXP-3 on screen too); the full name, so
    //     "Georgia" is never ambiguous.
    // FR: Chaque séjour montre son lieu (EXP-3 à l'écran aussi) ; le nom
    //     complet, afin que « Géorgie » ne soit jamais ambigu.
    final subtitle =
        strings.tripPlaceSubtitle(stayPlaceName(strings, trip), rest);
    final chip = Chip(
      label: Text(
        isPlanned
            ? strings.tripStatusPlanned
            : isCurrent
                ? strings.tripStatusCurrent
                : strings.tripStatusActual,
      ),
      visualDensity: VisualDensity.compact,
    );

    // EN: One stop for screen readers: the trip and its status together.
    // FR: Un seul arrêt pour les lecteurs d'écran : le séjour avec son statut.
    return MergeSemantics(
      child: ListTile(
        leading: Icon(
          isPlanned ? Icons.event_outlined : Icons.flight_land_rounded,
          color: isPlanned ? theme.colorScheme.secondary : null,
        ),
        title: Text(
          trip.name?.isNotEmpty == true ? trip.name! : '$arrival – $departure',
        ),
        subtitle: largeText
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [Text(subtitle), chip],
              )
            : Text(subtitle),
        trailing: largeText ? null : chip,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => TripEditScreen(existing: trip),
          ),
        ),
      ),
    );
  }
}
