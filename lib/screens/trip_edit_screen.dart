// EN: Create / edit / delete a single trip (FR-2, FR-4). Only the arrival and
//     departure dates are mandatory (FR-1); the trip name, notes, and every
//     per-crossing detail (time, zone, location, means, carrier) are optional and
//     tucked into collapsible sections so the common "just two dates" entry stays
//     one-tap-fast for an older user. Delete lives here behind a confirmation
//     dialog (FR-21) rather than a swipe, so a stray gesture can never wipe a trip.
//
//     Validation: the date fields are validated in [_save] (a picker cannot be
//     left half-typed the way a text field can); the model then re-validates and
//     length-caps everything in Trip.create, so a value the UI missed still cannot
//     reach storage out of range (FR-5).
//
// FR: Créer / modifier / supprimer un séjour (FR-2, FR-4). Seules les dates
//     d'arrivée et de départ sont obligatoires (FR-1) ; le nom du séjour, les
//     notes et chaque détail par passage (heure, fuseau, lieu, moyen,
//     transporteur) sont facultatifs et rangés dans des sections repliables pour
//     que la saisie courante « juste deux dates » reste rapide d'un toucher pour un
//     utilisateur plus âgé. La suppression vit ici derrière une boîte de
//     confirmation (FR-21) plutôt qu'un glissement, pour qu'un geste accidentel
//     n'efface jamais un séjour.
//
//     Validation : les champs de date sont validés dans [_save] (un sélecteur ne
//     peut pas rester à demi saisi comme un champ texte) ; le modèle revalide
//     ensuite et plafonne toute la longueur dans Trip.create, donc une valeur
//     échappée à l'interface ne peut toujours pas atteindre le stockage hors plage
//     (FR-5).

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:snowbird_in_usa_tracker/l10n/app_localizations.dart';
import 'package:snowbird_in_usa_tracker/logic/input_limits.dart';
import 'package:snowbird_in_usa_tracker/models/crossing_info.dart';
import 'package:snowbird_in_usa_tracker/models/trip.dart';
import 'package:snowbird_in_usa_tracker/screens/labeled_field.dart';
import 'package:snowbird_in_usa_tracker/screens/pickers.dart';
import 'package:snowbird_in_usa_tracker/screens/value_row.dart';
import 'package:snowbird_in_usa_tracker/services/storage_service.dart';
import 'package:snowbird_in_usa_tracker/state/trip_repository.dart';

class TripEditScreen extends StatefulWidget {
  // EN: Null → creating a new trip; non-null → editing that existing trip.
  // FR: Null → création d'un nouveau séjour ; non-null → modification de ce
  //     séjour existant.
  final Trip? existing;
  const TripEditScreen({super.key, this.existing});

  @override
  State<TripEditScreen> createState() => _TripEditScreenState();
}

class _TripEditScreenState extends State<TripEditScreen> {
  final _formKey = GlobalKey<FormState>();

  // EN: Trip-level fields.
  // FR: Champs au niveau du séjour.
  late final TextEditingController _name;
  late final TextEditingController _notes;
  TripStatus _status = TripStatus.actual;
  DateTime? _arrival;
  DateTime? _departure;

  // EN: "Still in the US" (FR-2). Only meaningful for an actual trip; it is an
  //     explicit choice so that a forgotten departure is never read as open.
  // FR: « Encore aux É.-U. » (FR-2). N'a de sens que pour un séjour réel ; c'est un
  //     choix explicite pour qu'un départ oublié ne soit jamais lu comme ouvert.
  bool _stillInUs = false;
  // EN: Problem with the dates, shown under the row concerned until it changes.
  // FR: Problème de dates, affiché sous la rangée concernée jusqu'à modification.
  String? _arrivalError;
  String? _departureError;
  final _arrivalKey = GlobalKey();
  final _departureKey = GlobalKey();

  void _clearErrors() {
    _arrivalError = null;
    _departureError = null;
  }

  // EN: Show an error and bring it into view: Save is at the bottom of a long form.
  // FR: Afficher une erreur et l'amener à l'écran : Enregistrer est au bas d'un long
  //     formulaire.
  void _showDateError({String? arrival, String? departure}) {
    setState(() {
      _arrivalError = arrival;
      _departureError = departure;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final target =
          (arrival != null ? _arrivalKey : _departureKey).currentContext;
      if (target != null) {
        Scrollable.ensureVisible(
          target,
          duration: const Duration(milliseconds: 200),
        );
      }
    });
  }

  bool get _isOpen => _status == TripStatus.actual && _stillInUs;

  // EN: Per-crossing optional fields — entry then exit. Times are TimeOfDay?,
  //     null meaning "not recorded".
  // FR: Champs facultatifs par passage — entrée puis sortie. Les heures sont
  //     TimeOfDay?, null signifiant « non renseignée ».
  late final TextEditingController _entryTz;
  late final TextEditingController _entryLocation;
  late final TextEditingController _entryMeans;
  late final TextEditingController _entryCarrier;
  TimeOfDay? _entryTime;

  late final TextEditingController _exitTz;
  late final TextEditingController _exitLocation;
  late final TextEditingController _exitMeans;
  late final TextEditingController _exitCarrier;
  TimeOfDay? _exitTime;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _notes = TextEditingController(text: e?.notes ?? '');
    if (e != null) {
      _status = e.status;
      _arrival = e.arrivalDate;
      _departure = e.departureDate;
      _stillInUs = e.departureDate == null;
    }

    _entryTz = TextEditingController(text: e?.arrivalInfo?.timeZone ?? '');
    _entryLocation =
        TextEditingController(text: e?.arrivalInfo?.location ?? '');
    _entryMeans =
        TextEditingController(text: e?.arrivalInfo?.meansOfTravel ?? '');
    _entryCarrier = TextEditingController(text: e?.arrivalInfo?.carrier ?? '');
    _entryTime = _toTimeOfDay(e?.arrivalInfo?.timeMinutes);

    _exitTz = TextEditingController(text: e?.departureInfo?.timeZone ?? '');
    _exitLocation =
        TextEditingController(text: e?.departureInfo?.location ?? '');
    _exitMeans =
        TextEditingController(text: e?.departureInfo?.meansOfTravel ?? '');
    _exitCarrier = TextEditingController(text: e?.departureInfo?.carrier ?? '');
    _exitTime = _toTimeOfDay(e?.departureInfo?.timeMinutes);
  }

  @override
  void dispose() {
    for (final c in [
      _name,
      _notes,
      _entryTz,
      _entryLocation,
      _entryMeans,
      _entryCarrier,
      _exitTz,
      _exitLocation,
      _exitMeans,
      _exitCarrier,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final isNew = widget.existing == null;
    String dateText(DateTime? d) => d == null
        ? strings.optionalNotSet
        : DateFormat.yMMMMd(strings.localeName).format(d);

    return Scaffold(
      appBar: AppBar(
        title: Text(isNew ? strings.addTrip : strings.editTrip),
        actions: [
          if (!isNew)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: strings.deleteTrip,
              onPressed: _confirmDelete,
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
              // EN: Actual vs planned. A segmented control reads clearly at a
              //     glance and needs no free typing.
              // FR: Réel ou planifié. Un contrôle segmenté se lit clairement d'un
              //     coup d'œil et n'exige aucune saisie libre.
              Text(
                strings.tripTypeLabel,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              SegmentedButton<TripStatus>(
                segments: [
                  ButtonSegment(
                    value: TripStatus.actual,
                    label: Text(strings.tripStatusActual),
                    icon: const Icon(Icons.check_circle_outline),
                  ),
                  ButtonSegment(
                    value: TripStatus.planned,
                    label: Text(strings.tripStatusPlanned),
                    icon: const Icon(Icons.event_outlined),
                  ),
                ],
                selected: {_status},
                onSelectionChanged: (s) => setState(() {
                  _status = s.first;
                  _clearErrors();
                }),
              ),
              const SizedBox(height: 16),

              // EN: The two mandatory dates.
              // FR: Les deux dates obligatoires.
              ValueRow(
                key: _arrivalKey,
                label: strings.fieldArrivalDate,
                value: dateText(_arrival),
                error: _arrivalError,
                onTap: () => _pickDate(isArrival: true),
              ),
              if (_status == TripStatus.actual)
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(strings.tripStillInUs),
                  subtitle:
                      _stillInUs ? Text(strings.tripStillInUsHelper) : null,
                  value: _stillInUs,
                  onChanged: (v) => setState(() {
                    _stillInUs = v;
                    _clearErrors();
                  }),
                ),
              if (!_isOpen)
                ValueRow(
                  key: _departureKey,
                  label: strings.fieldDepartureDate,
                  value: dateText(_departure),
                  error: _departureError,
                  onTap: () => _pickDate(isArrival: false),
                ),
              const SizedBox(height: 8),

              LabeledField(
                controller: _name,
                maxLength: InputLimits.maxTripNameLength,
                label: strings.fieldTripName,
                helper: strings.fieldTripNameHelper,
              ),
              const SizedBox(height: 8),
              LabeledField(
                controller: _notes,
                maxLength: InputLimits.maxNotesLength,
                maxLines: 3,
                label: strings.fieldNotes,
              ),
              const SizedBox(height: 8),

              // EN: Optional crossing detail sections, collapsed by default so the
              //     form is short unless the user wants the extra fields.
              // FR: Sections facultatives de détails de passage, repliées par défaut
              //     pour que le formulaire reste court sauf si l'utilisateur veut les
              //     champs supplémentaires.
              _CrossingSection(
                title: strings.entryDetailsTitle,
                time: _entryTime,
                timeLabel: strings.fieldCrossingTime,
                placeholder: strings.optionalNotSet,
                tz: _entryTz,
                location: _entryLocation,
                means: _entryMeans,
                carrier: _entryCarrier,
                strings: strings,
                onPickTime: () => _pickTime(isEntry: true),
                onClearTime: () => setState(() => _entryTime = null),
              ),
              if (!_isOpen)
                _CrossingSection(
                  title: strings.exitDetailsTitle,
                  time: _exitTime,
                  timeLabel: strings.fieldCrossingTime,
                  placeholder: strings.optionalNotSet,
                  tz: _exitTz,
                  location: _exitLocation,
                  means: _exitMeans,
                  carrier: _exitCarrier,
                  strings: strings,
                  onPickTime: () => _pickTime(isEntry: false),
                  onClearTime: () => setState(() => _exitTime = null),
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

  Future<void> _pickDate({required bool isArrival}) async {
    final initial =
        (isArrival ? _arrival : _departure) ?? _arrival ?? DateTime.now();
    final picked = await pickDate(
      context,
      initial: initial,
      first: DateTime(InputLimits.minTripYear),
      last: DateTime(DateTime.now().year + InputLimits.maxYearsAhead, 12, 31),
    );
    if (picked == null) return;
    setState(() {
      _clearErrors();
      if (isArrival) {
        _arrival = picked;
        // EN: If departure is now before arrival, clear it so the user re-picks a
        //     coherent value rather than saving an invalid pair.
        // FR: Si le départ est désormais avant l'arrivée, l'effacer pour que
        //     l'utilisateur en choisisse un cohérent plutôt que d'enregistrer une
        //     paire invalide.
        if (_departure != null && _departure!.isBefore(picked)) {
          _departure = null;
        }
      } else {
        _departure = picked;
      }
    });
  }

  Future<void> _pickTime({required bool isEntry}) async {
    final current = isEntry ? _entryTime : _exitTime;
    final picked = await pickTime(context, current ?? TimeOfDay.now());
    if (picked == null) return;
    setState(() {
      if (isEntry) {
        _entryTime = picked;
      } else {
        _exitTime = picked;
      }
    });
  }

  Future<void> _save() async {
    // EN: Resolve context-bound objects before any await (the widget may unmount).
    // FR: Résoudre les objets liés au contexte avant tout await (le widget peut
    //     être démonté).
    final strings = AppLocalizations.of(context);
    final repo = context.read<TripRepository>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    void complain(String message) {
      messenger.showSnackBar(SnackBar(content: Text(message)));
    }

    if (_arrival == null) {
      _showDateError(arrival: strings.errorArrivalRequired);
      return;
    }
    final departure = _isOpen ? null : _departure;
    if (departure == null && !_isOpen) {
      _showDateError(departure: strings.errorDepartureRequired);
      return;
    }
    if (departure != null && departure.isBefore(_arrival!)) {
      _showDateError(departure: strings.errorDepartureBefore);
      return;
    }

    final entryInfo = CrossingInfo.fromInput(
      timeMinutes: _fromTimeOfDay(_entryTime),
      timeZone: _entryTz.text,
      location: _entryLocation.text,
      meansOfTravel: _entryMeans.text,
      carrier: _entryCarrier.text,
    );
    // EN: An open stay has no exit crossing yet.
    // FR: Un séjour ouvert n'a pas encore de passage de sortie.
    final exitInfo = _isOpen
        ? null
        : CrossingInfo.fromInput(
            timeMinutes: _fromTimeOfDay(_exitTime),
            timeZone: _exitTz.text,
            location: _exitLocation.text,
            meansOfTravel: _exitMeans.text,
            carrier: _exitCarrier.text,
          );

    final existing = widget.existing;
    try {
      if (existing == null) {
        await repo.addTrip(
          Trip.create(
            arrivalDate: _arrival!,
            departureDate: departure,
            status: _status,
            name: _name.text,
            notes: _notes.text,
            arrivalInfo: entryInfo,
            departureInfo: exitInfo,
          ),
        );
      } else {
        await repo.updateTrip(
          existing.copyWith(
            arrivalDate: _arrival,
            departureDate: departure,
            status: _status,
            name: _name.text.trim().isEmpty ? null : _name.text.trim(),
            notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
            arrivalInfo: entryInfo,
            departureInfo: exitInfo,
          ),
        );
      }
    } on TripValidationException catch (e) {
      // EN: Not about the dates, so not shown under them.
      // FR: Ne concerne pas les dates, donc pas affiché dessous.
      if (e.problem == TripProblem.tooMany) {
        complain(strings.errorTooManyTrips(InputLimits.maxTrips));
        return;
      }
      if (!mounted) return;
      _showDateError(
        arrival: switch (e.problem) {
          TripProblem.overlap => strings.errorTripOverlap,
          TripProblem.futureArrival => strings.errorFutureArrival,
          TripProblem.tooMany => null,
        },
      );
      return;
    } on StorageWriteException {
      complain(strings.errorSaveFailed);
      return;
    }
    navigator.pop();
  }

  Future<void> _confirmDelete() async {
    final strings = AppLocalizations.of(context);
    final repo = context.read<TripRepository>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(strings.deleteTrip),
        content: Text(strings.deleteTripConfirm),
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
      try {
        await repo.deleteTrip(widget.existing!.id);
      } on StorageWriteException {
        messenger.showSnackBar(
          SnackBar(content: Text(strings.errorSaveFailed)),
        );
        return;
      }
      navigator.pop();
    }
  }

  // EN: minutes-of-day ↔ TimeOfDay conversions kept in one place.
  // FR: Conversions minutes-de-la-journée ↔ TimeOfDay regroupées à un endroit.
  static TimeOfDay? _toTimeOfDay(int? minutesOfDay) => minutesOfDay == null
      ? null
      : TimeOfDay(hour: minutesOfDay ~/ 60, minute: minutesOfDay % 60);

  static int? _fromTimeOfDay(TimeOfDay? t) =>
      t == null ? null : t.hour * 60 + t.minute;
}

// EN: One collapsible block of optional crossing detail fields, reused for entry
//     and exit. Kept stateless — it reads/writes the parent's controllers and time.
// FR: Un bloc repliable de champs facultatifs de passage, réutilisé pour l'entrée
//     et la sortie. Sans état — il lit/écrit les contrôleurs et l'heure du parent.
class _CrossingSection extends StatelessWidget {
  final String title;
  final TimeOfDay? time;
  final String timeLabel;
  final String placeholder;
  final TextEditingController tz;
  final TextEditingController location;
  final TextEditingController means;
  final TextEditingController carrier;
  final AppLocalizations strings;
  final VoidCallback onPickTime;
  final VoidCallback onClearTime;

  const _CrossingSection({
    required this.title,
    required this.time,
    required this.timeLabel,
    required this.placeholder,
    required this.tz,
    required this.location,
    required this.means,
    required this.carrier,
    required this.strings,
    required this.onPickTime,
    required this.onClearTime,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ExpansionTile(
        title: Text(title),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          ValueRow(
            label: timeLabel,
            value: time == null ? placeholder : time!.format(context),
            onTap: onPickTime,
            clearTooltip: strings.clearTime,
            onClear: time == null ? null : onClearTime,
          ),
          LabeledField(
            controller: location,
            maxLength: InputLimits.maxLocationLength,
            label: strings.fieldLocation,
          ),
          const SizedBox(height: 8),
          LabeledField(
            controller: means,
            maxLength: InputLimits.maxMeansOfTravelLength,
            label: strings.fieldMeansOfTravel,
          ),
          const SizedBox(height: 8),
          LabeledField(
            controller: carrier,
            maxLength: InputLimits.maxCarrierLength,
            label: strings.fieldCarrier,
          ),
          const SizedBox(height: 8),
          LabeledField(
            controller: tz,
            maxLength: InputLimits.maxTimeZoneLength,
            label: strings.fieldTimeZone,
          ),
        ],
      ),
    );
  }
}
