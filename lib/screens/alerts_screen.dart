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
import 'package:snowbird_in_usa_tracker/services/alert_scheduler.dart';
import 'package:snowbird_in_usa_tracker/state/alert_repository.dart';

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
              itemBuilder: (context, index) =>
                  _AlertTile(alert: alerts[index]),
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

    final reachDate = repo.projectedReachDate(alert);
    final projection = reachDate == null
        ? strings.alertNotReached
        : strings.alertProjectedReach(
            DateFormat.yMMMMd(strings.localeName).format(reachDate),
          );

    return ListTile(
      title: Text(
        alert.label ??
            strings.alertSummary(alert.thresholdDays, alert.windowDays),
      ),
      subtitle: Text(
        alert.label != null
            ? '${strings.alertSummary(alert.thresholdDays, alert.windowDays)}\n$projection'
            : projection,
      ),
      isThreeLine: alert.label != null,
      trailing: Switch(
        value: alert.enabled,
        onChanged: (value) =>
            repo.updateAlert(alert.copyWith(enabled: value)),
      ),
      onTap: () => _openEditor(context, existing: alert),
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
  bool _enabled = true;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
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
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _label,
              maxLength: kMaxAlertLabelLength,
              decoration:
                  InputDecoration(labelText: strings.alertLabelField),
            ),
            const SizedBox(height: 8),
            _numberField(
              controller: _threshold,
              label: strings.alertThresholdField,
              min: InputLimits.minThresholdDays,
              max: InputLimits.maxThresholdDays,
              strings: strings,
            ),
            const SizedBox(height: 16),
            _numberField(
              controller: _window,
              label: strings.alertWindowField,
              helper: strings.alertWindowHelper,
              min: InputLimits.minWindowDays,
              max: InputLimits.maxWindowDays,
              strings: strings,
            ),
            const SizedBox(height: 16),
            // EN: Time picker row — shows "—" until a time is chosen.
            // FR: Rangée du sélecteur d'heure — affiche « — » tant qu'aucune
            //     heure n'est choisie.
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(strings.alertTimeField),
              trailing: Text(
                _time == null ? '—' : _time!.format(context),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              onTap: _pickTime,
            ),
            const Divider(),
            Text(strings.alertLeadField,
                style: Theme.of(context).textTheme.titleSmall,),
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
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(4),
      ],
      decoration: InputDecoration(
        labelText: label,
        helperText: helper,
        counterText: '',
      ),
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
    final picked = await showTimePicker(
      context: context,
      // EN: 09:00 as the picker's STARTING position only (PLAN.md example) —
      //     nothing is saved until the user confirms a choice.
      // FR: 9 h comme position de DÉPART du sélecteur seulement (exemple du
      //     PLAN.md) — rien n'est enregistré tant que l'utilisateur ne
      //     confirme pas un choix.
      initialTime: _time ?? const TimeOfDay(hour: 9, minute: 0),
    );
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

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

    if (_time == null) {
      // EN: No delivery time chosen — prompt the picker instead of inventing
      //     a default behind the user's back.
      // FR: Aucune heure de livraison choisie — ouvrir le sélecteur plutôt que
      //     d'inventer un défaut dans le dos de l'utilisateur.
      await _pickTime();
      if (_time == null || !mounted) return;
    }

    final existing = widget.existing;
    if (existing == null) {
      await repo.addAlert(DayAlert.create(
        thresholdDays: int.parse(_threshold.text),
        windowDays: int.parse(_window.text),
        hour: _time!.hour,
        minute: _time!.minute,
        leadDays: int.parse(_leadDays.text),
        leadHours: int.parse(_leadHours.text),
        enabled: _enabled,
        label: _label.text,
      ),);
    } else {
      await repo.updateAlert(existing.copyWith(
        thresholdDays: int.parse(_threshold.text),
        windowDays: int.parse(_window.text),
        hour: _time!.hour,
        minute: _time!.minute,
        leadDays: int.parse(_leadDays.text),
        leadHours: int.parse(_leadHours.text),
        enabled: _enabled,
        label: _label.text.trim().isEmpty ? null : _label.text,
      ),);
    }

    // EN: Ask for OS permission AFTER the user has expressed intent by saving
    //     an alert — never at app launch. A refusal keeps the alert stored
    //     (the numbers are the user's) but tells them delivery is off.
    // FR: Demander la permission OS APRÈS que l'utilisateur a exprimé son
    //     intention en enregistrant une alerte — jamais au lancement. Un refus
    //     conserve l'alerte (les nombres appartiennent à l'utilisateur) mais
    //     l'informe que la livraison est coupée.
    final granted = await scheduler.ensurePermissions();
    if (!granted) {
      messenger.showSnackBar(
        SnackBar(content: Text(strings.alertPermissionDenied)),
      );
    }

    navigator.pop();
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final strings = AppLocalizations.of(context);
    final repo = context.read<AlertRepository>();
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
      await repo.deleteAlert(widget.existing!.id);
      navigator.pop();
    }
  }
}
