// EN: "My alerts" screen — list, create, edit, and delete the user's own
//     day-count alerts. POSITIONING (PLAN.md): the screen opens EMPTY. There is
//     no suggested threshold, no pre-filled value, no "recommended" number —
//     every figure is typed by the user (the 09:00 delivery time appears only
//     as the time picker's starting position, and the user must still confirm
//     it). Wording everywhere is neutral: a target the user set, never a limit
//     the app enforces.
//
//     SECURITY: numeric fields are digits-only, length-capped, parsed with
//     int.tryParse, and validated against InputLimits before an alert is
//     constructed — and DayAlert's constructor re-validates regardless, so a
//     value the UI missed still cannot exist in the data layer.
//
// FR: Écran « Mes alertes » — lister, créer, modifier et supprimer les alertes
//     de jours de l'utilisateur. POSITIONNEMENT (PLAN.md) : l'écran s'ouvre
//     VIDE. Aucun seuil suggéré, aucune valeur préremplie, aucun nombre
//     « recommandé » — chaque chiffre est saisi par l'utilisateur (le 9 h de
//     livraison n'apparaît que comme position de départ du sélecteur d'heure,
//     et l'utilisateur doit quand même le confirmer). Le libellé est partout
//     neutre : une cible fixée par l'utilisateur, jamais une limite imposée
//     par l'appli.
//
//     SÉCURITÉ : les champs numériques sont limités aux chiffres, plafonnés en
//     longueur, analysés avec int.tryParse et validés contre InputLimits avant
//     de construire une alerte — et le constructeur de DayAlert revalide de
//     toute façon, donc une valeur échappée à l'interface ne peut toujours pas
//     exister dans la couche de données.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:snowbird_in_usa_tracker/l10n/app_localizations.dart';
import 'package:snowbird_in_usa_tracker/logic/input_limits.dart';
import 'package:snowbird_in_usa_tracker/models/day_alert.dart';
import 'package:snowbird_in_usa_tracker/screens/labeled_field.dart';
import 'package:snowbird_in_usa_tracker/screens/pickers.dart';
import 'package:snowbird_in_usa_tracker/screens/section_heading.dart';
import 'package:snowbird_in_usa_tracker/screens/value_row.dart';
import 'package:snowbird_in_usa_tracker/services/alert_scheduler.dart';
import 'package:snowbird_in_usa_tracker/services/storage_service.dart';
import 'package:snowbird_in_usa_tracker/state/alert_repository.dart';
import 'package:snowbird_in_usa_tracker/state/trip_repository.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final repo = context.watch<AlertRepository>();
    final alerts = repo.alerts;

    return Scaffold(
      appBar: AppBar(title: Text(strings.alertsTitle)),
      body: alerts.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  strings.alertsEmpty,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            )
          : ListView.builder(
              itemCount: alerts.length,
              itemBuilder: (context, index) => _AlertTile(alert: alerts[index]),
            ),
      floatingActionButton: FloatingActionButton(
        tooltip: strings.addAlert,
        onPressed: () => _openEditor(context, existing: null),
        child: const Icon(Icons.add),
      ),
    );
  }
}

// EN: One alert in the list: name/summary, the neutral projection line, an
//     enable switch, and tap-to-edit. Delete lives inside the editor so a
//     stray swipe cannot silently destroy the user's numbers.
// FR: Une alerte dans la liste : nom/résumé, la ligne de projection neutre, un
//     interrupteur d'activation et l'édition au toucher. La suppression vit
//     dans l'éditeur pour qu'un glissement accidentel ne détruise pas
//     silencieusement les nombres de l'utilisateur.
class _AlertTile extends StatelessWidget {
  final DayAlert alert;
  const _AlertTile({required this.alert});

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final repo = context.read<AlertRepository>();

    // EN: Summary and the "no target yet" line both depend on the alert kind
    //     (FR-9 vs FR-10). For since-last-visit, "not reached" means the user has
    //     recorded no actual visit to measure from, not that a count fell short.
    // FR: Le résumé et la ligne « pas encore de cible » dépendent tous deux du type
    //     d'alerte (FR-9 vs FR-10). Pour « depuis le dernier séjour », « non
    //     atteinte » signifie qu'aucun séjour réel n'est enregistré comme point de
    //     départ, pas qu'un compte est insuffisant.
    final isSince = alert.kind == AlertKind.sinceLastVisit;
    final summary = isSince
        ? strings.alertSummarySince(alert.thresholdDays)
        : strings.alertSummary(alert.thresholdDays, alert.windowDays);
    final hasOpenTrip = context
        .read<TripRepository>()
        .trips
        .any((t) => t.departureDate == null);
    final noReachText = !isSince
        ? strings.alertNotReached
        : hasOpenTrip
            ? strings.alertInUsNow
            : strings.alertNoVisits;

    final reachDate = repo.projectedReachDate(alert);
    // EN: A target met in the past is stated as such; a date still ahead (the next
    //     crossing) is shown as a projection.
    // FR: Une cible atteinte dans le passé est dite telle ; une date à venir (le
    //     prochain franchissement) est montrée comme projection.
    final reached = repo.isReached(alert);
    final isSincePast = isSince && reached;
    final projection = [
      if (reached) strings.alertReached,
      if (reachDate != null && !isSincePast)
        strings.alertProjectedReach(
          DateFormat.yMMMMd(strings.localeName).format(reachDate),
        ),
      if (reachDate == null && !reached) noReachText,
    ].join('\n');

    return ListTile(
      title: Text(alert.label ?? summary),
      subtitle: Text(
        alert.label != null ? '$summary\n$projection' : projection,
      ),
      isThreeLine: alert.label != null,
      // EN: A switch beside a row is its own control; it must say which alert it is.
      // FR: Un interrupteur à côté d'une rangée est un contrôle à part ; il doit dire
      //     de quelle alerte il s'agit.
      trailing: MergeSemantics(
        child: Semantics(
          label: strings.alertToggleLabel(
            alert.label == null ? summary : '${alert.label}, $summary',
          ),
          child: Switch(
            value: alert.enabled,
            onChanged: (value) async {
              final messenger = ScaffoldMessenger.of(context);
              final scheduler = context.read<AlertScheduler>();
              if (value) {
                await _askPermission(scheduler, messenger, strings);
              }
              await _orReport(
                messenger,
                strings,
                () => repo.updateAlert(alert.copyWith(enabled: value)),
              );
            },
          ),
        ),
      ),
      onTap: () => _openEditor(context, existing: alert),
    );
  }
}

// EN: Run a save and report a refused write. Returns whether it succeeded, so an
//     editor stays open with the user's input when it did not.
// FR: Exécuter un enregistrement et signaler une écriture refusée. Retourne le
//     succès, pour qu'un éditeur reste ouvert avec la saisie en cas d'échec.
Future<bool> _orReport(
  ScaffoldMessengerState messenger,
  AppLocalizations strings,
  Future<void> Function() save,
) async {
  try {
    await save();
    return true;
  } on StorageWriteException {
    messenger.showSnackBar(SnackBar(content: Text(strings.errorSaveFailed)));
    return false;
  }
}

// EN: Ask for OS permission once the user has expressed intent — saving or enabling
//     an alert, never at launch — and BEFORE scheduling, because iOS refuses what is
//     scheduled without it. A refusal keeps the alert (the numbers are the user's)
//     and says that delivery is off.
// FR: Demander la permission de l'OS une fois l'intention exprimée — enregistrer ou
//     activer une alerte, jamais au lancement — et AVANT de planifier, car iOS refuse
//     ce qui est planifié sans elle. Un refus conserve l'alerte (les nombres sont à
//     l'utilisateur) et indique que la livraison est coupée.
Future<void> _askPermission(
  AlertScheduler scheduler,
  ScaffoldMessengerState messenger,
  AppLocalizations strings,
) async {
  bool granted;
  try {
    granted = await scheduler.ensurePermissions();
  } catch (_) {
    granted = false;
  }
  if (!granted) {
    messenger.showSnackBar(
      SnackBar(content: Text(strings.alertPermissionDenied)),
    );
  }
}

Future<void> _openEditor(BuildContext context, {DayAlert? existing}) {
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => AlertEditScreen(existing: existing),
    ),
  );
}

// EN: Create/edit form. All fields start EMPTY for a new alert — the user
//     supplies every number (zero-defaults invariant).
// FR: Formulaire de création/édition. Tous les champs commencent VIDES pour
//     une nouvelle alerte — l'utilisateur fournit chaque nombre (invariant
//     zéro-défaut).
class AlertEditScreen extends StatefulWidget {
  final DayAlert? existing;
  const AlertEditScreen({super.key, this.existing});

  @override
  State<AlertEditScreen> createState() => _AlertEditScreenState();
}

class _AlertEditScreenState extends State<AlertEditScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _label;
  late final TextEditingController _threshold;
  late final TextEditingController _window;
  late final TextEditingController _leadDays;
  late final TextEditingController _leadHours;

  // EN: Null until the user has explicitly picked a time — saving is blocked
  //     until then. 09:00 is only the picker's initial position.
  // FR: Null tant que l'utilisateur n'a pas explicitement choisi une heure —
  //     l'enregistrement est bloqué jusque-là. 9 h n'est que la position
  //     initiale du sélecteur.
  TimeOfDay? _time;
  bool _timeMissing = false;
  bool _enabled = true;

  // EN: Which kind of alert this is (FR-9 day-count vs FR-10 time-since-last-visit).
  //     Defaults to the original day-count kind for a new alert.
  // FR: Quel type d'alerte (compte de jours FR-9 vs temps depuis le dernier séjour
  //     FR-10). Par défaut le type compte de jours d'origine pour une nouvelle alerte.
  AlertKind _kind = AlertKind.dayCountThreshold;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _kind = e?.kind ?? AlertKind.dayCountThreshold;
    _label = TextEditingController(text: e?.label ?? '');
    _threshold =
        TextEditingController(text: e == null ? '' : '${e.thresholdDays}');
    _window = TextEditingController(text: e == null ? '' : '${e.windowDays}');
    // EN: Lead fields default to the TEXT "0" — that is not a hidden threshold,
    //     it is the honest representation of "on the day itself".
    // FR: Les champs de préavis affichent « 0 » par défaut — ce n'est pas un
    //     seuil caché, c'est la représentation honnête de « le jour même ».
    _leadDays = TextEditingController(text: e == null ? '0' : '${e.leadDays}');
    _leadHours =
        TextEditingController(text: e == null ? '0' : '${e.leadHours}');
    if (e != null) {
      _time = TimeOfDay(hour: e.hour, minute: e.minute);
      _enabled = e.enabled;
    }
  }

  @override
  void dispose() {
    _label.dispose();
    _threshold.dispose();
    _window.dispose();
    _leadDays.dispose();
    _leadHours.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final isNew = widget.existing == null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isNew ? strings.addAlert : strings.editAlert),
        actions: [
          if (!isNew)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: strings.deleteAlert,
              onPressed: () => _confirmDelete(context),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        // EN: Not a lazy list: every field must exist for validation and for
        //     scrolling to an error, even when off screen.
        // FR: Pas une liste à la demande : chaque champ doit exister pour la
        //     validation et pour défiler vers une erreur, même hors écran.
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // EN: Choose what the alert watches (FR-9 vs FR-10). Switching hides or
              //     shows the rolling-window field below, since only the day-count
              //     kind uses a window.
              // FR: Choisir ce que l'alerte surveille (FR-9 vs FR-10). Le changement
              //     masque ou affiche le champ de fenêtre glissante ci-dessous, car
              //     seul le type compte de jours utilise une fenêtre.
              SectionHeading(
                strings.alertKindLabel,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              SegmentedButton<AlertKind>(
                segments: [
                  ButtonSegment(
                    value: AlertKind.dayCountThreshold,
                    label: Text(strings.alertKindDayCount),
                  ),
                  ButtonSegment(
                    value: AlertKind.sinceLastVisit,
                    label: Text(strings.alertKindSinceVisit),
                  ),
                ],
                selected: {_kind},
                onSelectionChanged: (s) => setState(() => _kind = s.first),
              ),
              const SizedBox(height: 16),
              LabeledField(
                controller: _label,
                maxLength: kMaxAlertLabelLength,
                label: strings.alertLabelField,
              ),
              const SizedBox(height: 8),
              _numberField(
                controller: _threshold,
                label: _kind == AlertKind.sinceLastVisit
                    ? strings.alertThresholdSinceField
                    : strings.alertThresholdField,
                helper: _kind == AlertKind.sinceLastVisit
                    ? strings.alertSinceHelper
                    : null,
                min: InputLimits.minThresholdDays,
                max: InputLimits.maxThresholdDays,
                strings: strings,
              ),
              // EN: The rolling-window field only applies to the day-count kind.
              // FR: Le champ de fenêtre glissante ne s'applique qu'au type compte de
              //     jours.
              if (_kind == AlertKind.dayCountThreshold) ...[
                const SizedBox(height: 16),
                _numberField(
                  controller: _window,
                  label: strings.alertWindowField,
                  helper: strings.alertWindowHelper,
                  min: InputLimits.minWindowDays,
                  max: InputLimits.maxWindowDays,
                  strings: strings,
                ),
              ],
              const SizedBox(height: 16),
              // EN: Time picker row — shows "—" until a time is chosen.
              // FR: Rangée du sélecteur d'heure — affiche « — » tant qu'aucune
              //     heure n'est choisie.
              ValueRow(
                label: strings.alertTimeField,
                value: _time == null
                    ? strings.optionalNotSet
                    : _time!.format(context),
                error: _timeMissing ? strings.errorTimeRequired : null,
                onTap: _pickTime,
              ),
              const Divider(),
              SectionHeading(
                strings.alertLeadField,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _numberField(
                      controller: _leadDays,
                      label: strings.alertLeadDaysField,
                      min: InputLimits.minLeadDays,
                      max: InputLimits.maxLeadDays,
                      strings: strings,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _numberField(
                      controller: _leadHours,
                      label: strings.alertLeadHoursField,
                      min: InputLimits.minLeadHours,
                      max: InputLimits.maxLeadHours,
                      strings: strings,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(strings.alertEnabledToggle),
                value: _enabled,
                onChanged: (v) => setState(() => _enabled = v),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _save,
                child: Text(strings.save),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // EN: Shared digits-only numeric field with hard-cap validation. maxLength 4
  //     already blocks absurd magnitudes at the keyboard; the validator then
  //     enforces the exact InputLimits range.
  // FR: Champ numérique partagé (chiffres seulement) avec validation des
  //     plafonds. maxLength 4 bloque déjà les grandeurs absurdes au clavier ;
  //     le validateur applique ensuite la plage InputLimits exacte.
  Widget _numberField({
    required TextEditingController controller,
    required String label,
    required int min,
    required int max,
    required AppLocalizations strings,
    String? helper,
  }) {
    return LabeledField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(4),
      ],
      label: label,
      helper: helper,
      validator: (raw) {
        final value = int.tryParse(raw ?? '');
        if (value == null || value < min || value > max) {
          return strings.alertRangeError(min, max);
        }
        return null;
      },
    );
  }

  Future<void> _pickTime() async {
    final picked = await pickTime(
      context,
      // EN: 09:00 as the picker's STARTING position only (PLAN.md example) —
      //     nothing is saved until the user confirms a choice.
      // FR: 9 h comme position de DÉPART du sélecteur seulement (exemple du
      //     PLAN.md) — rien n'est enregistré tant que l'utilisateur ne
      //     confirme pas un choix.
      _time ?? const TimeOfDay(hour: 9, minute: 0),
    );
    if (picked == null) return;
    setState(() {
      _time = picked;
      _timeMissing = false;
    });
  }

  Future<void> _save() async {
    // EN: No default time is invented; the missing choice is shown with the rest.
    // FR: Aucune heure par défaut n'est inventée ; le choix manquant est montré avec
    //     le reste.
    setState(() => _timeMissing = _time == null);
    if (!_formKey.currentState!.validate() || _timeMissing) return;

    // EN: Resolve everything context-dependent BEFORE any await — using a
    //     BuildContext across an async gap is unsound (the widget may have
    //     been disposed while the dialog was open).
    // FR: Résoudre tout ce qui dépend du contexte AVANT tout await — utiliser
    //     un BuildContext à travers un écart asynchrone est incorrect (le
    //     widget peut avoir été détruit pendant que le dialogue était ouvert).
    final strings = AppLocalizations.of(context);
    final repo = context.read<AlertRepository>();
    final scheduler = context.read<AlertScheduler>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final threshold = int.parse(_threshold.text);
    // EN: The since-last-visit kind has no window. The model still stores a valid
    //     windowDays (it is never read for this kind), so we set it equal to the
    //     threshold to satisfy the range check without inventing a meaningless
    //     value the user did not choose.
    // FR: Le type « depuis le dernier séjour » n'a pas de fenêtre. Le modèle stocke
    //     quand même un windowDays valide (jamais lu pour ce type), donc on le met
    //     égal au seuil pour satisfaire la validation de plage sans inventer une
    //     valeur dénuée de sens que l'utilisateur n'a pas choisie.
    final windowDays =
        _kind == AlertKind.sinceLastVisit ? threshold : int.parse(_window.text);

    if (_enabled) await _askPermission(scheduler, messenger, strings);

    final existing = widget.existing;
    final saved = await _orReport(messenger, strings, () async {
      if (existing == null) {
        await repo.addAlert(
          DayAlert.create(
            thresholdDays: threshold,
            windowDays: windowDays,
            hour: _time!.hour,
            minute: _time!.minute,
            leadDays: int.parse(_leadDays.text),
            leadHours: int.parse(_leadHours.text),
            enabled: _enabled,
            kind: _kind,
            label: _label.text,
          ),
        );
      } else {
        await repo.updateAlert(
          existing.copyWith(
            thresholdDays: threshold,
            windowDays: windowDays,
            hour: _time!.hour,
            minute: _time!.minute,
            leadDays: int.parse(_leadDays.text),
            leadHours: int.parse(_leadHours.text),
            enabled: _enabled,
            kind: _kind,
            label: _label.text.trim().isEmpty ? null : _label.text,
          ),
        );
      }
    });
    if (!saved) return;

    navigator.pop();
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final strings = AppLocalizations.of(context);
    final repo = context.read<AlertRepository>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(strings.deleteAlert),
        content: Text(strings.deleteAlertConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(strings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(strings.delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final deleted = await _orReport(
        messenger,
        strings,
        () => repo.deleteAlert(widget.existing!.id),
      );
      if (deleted) navigator.pop();
    }
  }
}
