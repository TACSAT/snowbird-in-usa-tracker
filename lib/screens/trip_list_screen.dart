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

import 'package:snowbird_in_usa_tracker/l10n/app_localizations.dart';
import 'package:snowbird_in_usa_tracker/logic/day_counter.dart';
import 'package:snowbird_in_usa_tracker/logic/presence_record.dart';
import 'package:snowbird_in_usa_tracker/models/trip.dart';
import 'package:snowbird_in_usa_tracker/screens/about_screen.dart';
import 'package:snowbird_in_usa_tracker/screens/alerts_screen.dart';
import 'package:snowbird_in_usa_tracker/screens/reference_screen.dart';
import 'package:snowbird_in_usa_tracker/screens/settings_screen.dart';
import 'package:snowbird_in_usa_tracker/screens/trip_edit_screen.dart';
import 'package:snowbird_in_usa_tracker/services/record_exporter.dart';
import 'package:snowbird_in_usa_tracker/services/storage_service.dart';
import 'package:snowbird_in_usa_tracker/state/trip_repository.dart';

// EN: The four ways to export the US Presence Record (FR-8).
// FR: Les quatre façons d'exporter la fiche de présence (FR-8).
enum _ExportChoice { pdf, image, csv, print }

// EN: Overflow-menu destinations (FR-14/15/20).
// FR: Destinations du menu de débordement (FR-14/15/20).
enum _Menu { reference, settings, about }

class TripListScreen extends StatefulWidget {
  const TripListScreen({super.key});

  @override
  State<TripListScreen> createState() => _TripListScreenState();
}

class _TripListScreenState extends State<TripListScreen> {
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
        body: strings.appDisclaimerBody,
        button: strings.appDisclaimerAcknowledge,
      );
      await storage.setDisclaimerAcknowledged();
    }

    if (!storage.backupReminderShown) {
      if (!mounted) return;
      final strings = AppLocalizations.of(context);
      await _showAck(
        title: strings.backupReminderTitle,
        body: strings.backupReminderBody,
        button: strings.backupReminderAcknowledge,
      );
      await storage.setBackupReminderShown();
    }

    // EN: Shown at each launch while the problem lasts (the first successful save
    //     clears it): silence here would look like lost trips (FR-13).
    // FR: Montré à chaque lancement tant que le problème dure (le premier
    //     enregistrement réussi le règle) : le silence ferait croire à des séjours
    //     perdus (FR-13).
    if (storage.loadProblem != StorageLoadProblem.none) {
      if (!mounted) return;
      final strings = AppLocalizations.of(context);
      await _showAck(
        title: strings.storageProblemTitle,
        body: storage.loadProblem == StorageLoadProblem.newerVersion
            ? strings.storageNewerBody
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

    final record = PresenceRecord.build(trips: trips);

    final choice = await showModalBottomSheet<_ExportChoice>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.picture_as_pdf_outlined),
              title: Text(strings.exportAsPdf),
              onTap: () => Navigator.pop(ctx, _ExportChoice.pdf),
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
    final trips = context.watch<TripRepository>().trips;

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.appTitle),
        centerTitle: false,
        actions: [
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
          : Column(
              children: [
                _SummaryCard(trips: trips),
                const Divider(height: 1),
                Expanded(
                  child: ListView.builder(
                    itemCount: trips.length,
                    itemBuilder: (context, index) =>
                        _TripTile(trip: trips[index]),
                  ),
                ),
              ],
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

// EN: Neutral day-count summary: actual days this calendar year and in the rolling
//     last 365 days. These are the two windows a snowbird checks most; both count
//     only ACTUAL trips so a planned trip never inflates a "days so far" figure.
// FR: Résumé neutre de comptage : jours réels cette année civile et sur les 365
//     derniers jours glissants. Ce sont les deux fenêtres qu'un snowbird consulte
//     le plus ; les deux ne comptent que les séjours RÉELS pour qu'un séjour
//     planifié ne gonfle jamais un chiffre « jours à ce jour ».
class _SummaryCard extends StatelessWidget {
  final List<Trip> trips;
  const _SummaryCard({required this.trips});

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final now = DateTime.now();

    final thisYear = DayCounter.countDaysInCalendarYear(
      trips: trips,
      year: now.year,
    );
    final last365 = DayCounter.countDaysInLastDays(trips: trips, days: 365);

    // EN: The IRS Substantial Presence figure (FR-7) — published arithmetic, shown
    //     as a NEUTRAL number, never compared to a threshold. Reuse PresenceRecord's
    //     exact formatter (whole when exact, else two decimals) so the on-screen
    //     figure matches the exported record to the digit.
    // FR: La valeur de présence substantielle de l'IRS (FR-7) — arithmétique
    //     publiée, affichée comme un nombre NEUTRE, jamais comparée à un seuil.
    //     Réutiliser le formateur exact de PresenceRecord (entier si exact, sinon
    //     deux décimales) pour que la valeur à l'écran corresponde au chiffre près à
    //     la fiche exportée.
    final theme = Theme.of(context);
    final sptText = PresenceRecord.build(trips: trips).formattedSpt;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(strings.summaryHeading, style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _StatBlock(
                  value: '$thisYear',
                  label: strings.windowThisYear,
                  days: strings.daysCount(thisYear),
                ),
              ),
              Expanded(
                child: _StatBlock(
                  value: '$last365',
                  label: strings.windowLast365,
                  days: strings.daysCount(last365),
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          // EN: SPT figure block — tapping it opens the neutral reference page so
          //     the number always travels with its context and its not-advice note.
          // FR: Bloc de la valeur SPT — le toucher ouvre la page de référence neutre
          //     pour que le nombre voyage toujours avec son contexte et sa mention
          //     « pas un conseil ».
          InkWell(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const ReferenceScreen()),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        strings.recordSptLabel,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    Text(sptText, style: theme.textTheme.titleLarge),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.info_outline,
                      size: 18,
                      color: theme.colorScheme.outline,
                    ),
                  ],
                ),
                Text(
                  strings.sptDisclaimer,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// EN: One large, high-contrast number with its window label — sized up for older
//     eyes (NFR-5). The number is a plain integer; the plural "days" word sits
//     beneath it as an accessible full-text label for screen readers.
// FR: Un grand nombre à fort contraste avec son étiquette de fenêtre — agrandi
//     pour des yeux plus âgés (NFR-5). Le nombre est un entier simple ; le mot
//     pluriel « jours » se place en dessous comme étiquette texte accessible aux
//     lecteurs d'écran.
class _StatBlock extends StatelessWidget {
  final String value;
  final String label;
  final String days;
  const _StatBlock({
    required this.value,
    required this.label,
    required this.days,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: '$label: $days',
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: theme.textTheme.headlineMedium),
            Text(label, style: theme.textTheme.bodyMedium),
          ],
        ),
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

    return ListTile(
      leading: Icon(
        isPlanned ? Icons.event_outlined : Icons.flight_land_rounded,
        color: isPlanned ? theme.colorScheme.secondary : null,
      ),
      title: Text(
        trip.name?.isNotEmpty == true ? trip.name! : '$arrival – $departure',
      ),
      subtitle: Text(
        strings.tripSubtitle(
          arrival,
          departure,
          isCurrent ? strings.tripDaysSoFar(days) : days,
        ),
      ),
      trailing: Chip(
        label: Text(
          isPlanned
              ? strings.tripStatusPlanned
              : isCurrent
                  ? strings.tripStatusCurrent
                  : strings.tripStatusActual,
        ),
        visualDensity: VisualDensity.compact,
      ),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => TripEditScreen(existing: trip),
        ),
      ),
    );
  }
}
