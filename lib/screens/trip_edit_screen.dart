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
import 'package:snowbird_in_usa_tracker/models/place.dart';
import 'package:snowbird_in_usa_tracker/models/trip.dart';
import 'package:snowbird_in_usa_tracker/screens/move_flow.dart';
import 'package:snowbird_in_usa_tracker/screens/place_names.dart';
import 'package:snowbird_in_usa_tracker/screens/place_picker_screen.dart';
import 'package:snowbird_in_usa_tracker/screens/split_stay_screen.dart';
import 'package:snowbird_in_usa_tracker/screens/labeled_field.dart';
import 'package:snowbird_in_usa_tracker/screens/pickers.dart';
import 'package:snowbird_in_usa_tracker/screens/section_heading.dart';
import 'package:snowbird_in_usa_tracker/screens/value_row.dart';
import 'package:snowbird_in_usa_tracker/screens/weekday_chips.dart';
import 'package:snowbird_in_usa_tracker/services/storage_service.dart';
import 'package:snowbird_in_usa_tracker/models/work_plan.dart';
import 'package:snowbird_in_usa_tracker/screens/work_calendar_screen.dart';
import 'package:snowbird_in_usa_tracker/state/presence_settings.dart';
import 'package:snowbird_in_usa_tracker/state/trip_repository.dart';

class TripEditScreen extends StatefulWidget {
  // EN: Null → creating a new trip; non-null → editing that existing trip.
  // FR: Null → création d'un nouveau séjour ; non-null → modification de ce
  //     séjour existant.
  final Trip? existing;

  // EN: Starting values for a NEW stay. "Add next stop" (STY-2) passes the
  //     previous stay's departure as [initialArrival], so a border crossing is
  //     entered once, not twice. [initialPlace] defaults to the most recently
  //     used place: a user who only ever tracks one country chooses it once
  //     (section 18).
  // FR: Valeurs de départ d'un NOUVEAU séjour. « Ajouter l'étape suivante »
  //     (STY-2) passe le départ du séjour précédent comme [initialArrival], afin
  //     qu'un passage de frontière soit saisi une fois, pas deux. [initialPlace]
  //     vaut par défaut le dernier lieu utilisé : un utilisateur qui ne suit
  //     qu'un pays le choisit une seule fois (section 18).
  final DateTime? initialArrival;
  final TripStatus? initialStatus;
  final Place? initialPlace;

  const TripEditScreen({
    super.key,
    this.existing,
    this.initialArrival,
    this.initialStatus,
    this.initialPlace,
  });

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

  // EN: The stay's place (PLC-1: required) and, for Elsewhere, its optional
  //     name. Null only for a brand-new user's first stay, until chosen.
  // FR: Le lieu du séjour (PLC-1 : obligatoire) et, pour Ailleurs, son nom
  //     facultatif. Null seulement pour le premier séjour d'un nouvel
  //     utilisateur, jusqu'à ce qu'il soit choisi.
  Place? _place;
  late final TextEditingController _placeName;

  // EN: Days worked during this stay (section 7). Edited only when work is
  //     turned on; otherwise the saved plan is left exactly as it was.
  // FR: Jours travaillés pendant ce séjour (section 7). Modifiés seulement si
  //     le travail est activé ; sinon le plan enregistré reste tel quel.
  late WorkPlan _work = widget.existing?.work ?? WorkPlan.none;
  late StayPurpose? _purpose = widget.existing?.purpose;
  late final TextEditingController _jobLabel =
      TextEditingController(text: widget.existing?.label ?? '');
  String? _placeError;
  final _placeKey = GlobalKey();
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
    } else {
      _arrival = widget.initialArrival;
      _status = widget.initialStatus ?? TripStatus.actual;
    }
    final recent = context.read<TripRepository>().recentPlaces(limit: 1);
    _place = e?.place ??
        widget.initialPlace ??
        (recent.isEmpty ? null : recent.first);
    _placeName = TextEditingController(text: e?.placeName ?? '');

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
      _placeName,
      _jobLabel,
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
              SectionHeading(
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
              ValueRow(
                key: _placeKey,
                label: strings.fieldPlace,
                value: _place == null
                    ? strings.optionalNotSet
                    : placeFullName(strings, _place!),
                error: _placeError,
                onTap: _pickPlace,
              ),
              if (_place == Place.elsewhere)
                LabeledField(
                  controller: _placeName,
                  maxLength: InputLimits.maxPlaceNameLength,
                  label: strings.fieldElsewhereName,
                ),

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
              if (context.watch<PresenceSettings>().workEnabled)
                _WorkSection(
                  plan: _work,
                  from: _arrival,
                  to: _workEnd(),
                  onChanged: (plan) => setState(() => _work = plan),
                  purpose: _purpose,
                  onPurpose: (p) => setState(() => _purpose = p),
                  jobLabel: _jobLabel,
                ),

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
              // EN: Quick steps from a saved stay (section 5). They act on the
              //     stay as saved, so they are offered only when editing.
              // FR: Étapes rapides depuis un séjour enregistré (section 5).
              //     Elles portent sur le séjour tel qu'enregistré ; elles ne
              //     sont donc offertes qu'en modification.
              if (widget.existing case final stay?) ...[
                const SizedBox(height: 16),
                if (stay.departureDate != null)
                  OutlinedButton.icon(
                    icon: const Icon(Icons.east),
                    label: Text(strings.addNextStop),
                    onPressed: () => Navigator.of(context).pushReplacement(
                      MaterialPageRoute<void>(
                        builder: (_) => TripEditScreen(
                          initialArrival: stay.departureDate,
                          initialStatus: stay.status,
                        ),
                      ),
                    ),
                  ),
                if (stay.status == TripStatus.actual &&
                    stay.departureDate == null)
                  OutlinedButton.icon(
                    icon: const Icon(Icons.moving),
                    label: Text(strings.movedOn),
                    onPressed: () async {
                      final navigator = Navigator.of(context);
                      if (await startMove(context, stay)) navigator.pop();
                    },
                  ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  icon: const Icon(Icons.call_split),
                  label: Text(strings.splitStay),
                  onPressed: () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute<void>(
                      builder: (_) => SplitStayScreen(stay: stay),
                    ),
                  ),
                ),
              ],
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

  // EN: Recently used places first (PLC-9). Choosing clears the place error.
  // FR: Les lieux récents d'abord (PLC-9). Choisir efface l'erreur de lieu.
  Future<void> _pickPlace() async {
    final picked = await pickPlace(
      context,
      recent: context.read<TripRepository>().recentPlaces(),
    );
    if (picked == null) return;
    setState(() {
      _place = picked;
      _placeError = null;
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

    // EN: Checked after the dates, so date errors keep their order; the field
    //     is scrolled into view either way.
    // FR: Vérifié après les dates, afin que les erreurs de date gardent leur
    //     ordre ; le champ est ramené à l'écran dans les deux cas.
    final place = _place;
    if (place == null) {
      setState(() => _placeError = strings.errorPlaceRequired);
      final target = _placeKey.currentContext;
      if (target != null) Scrollable.ensureVisible(target);
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
            place: place,
            placeName: _placeName.text,
            work: _work,
            purpose: _purpose,
            label: _jobLabel.text,
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
            place: place,
            placeName: _placeName.text,
            work: _work,
            purpose: _purpose,
            label: _jobLabel.text,
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
          TripProblem.tooMany ||
          TripProblem.moveBeforeArrival ||
          TripProblem.splitDate =>
            null,
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
  // EN: The last date whose work can be counted: the departure, or today for
  //     an ongoing or still-running stay (actual days stop at today).
  // FR: La dernière date dont le travail peut compter : le départ, ou
  //     aujourd'hui pour un séjour en cours (les jours réels s'arrêtent à
  //     aujourd'hui).
  DateTime? _workEnd() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final departure = _isOpen ? null : _departure;
    if (_status == TripStatus.planned) return departure;
    if (departure == null || departure.isAfter(today)) return today;
    return departure;
  }

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
// EN: The weekday pattern (WRK-3, first half), a running count, and the way
//     into the calendar for single-day corrections (second half).
// FR: Le motif de jours de semaine (WRK-3, première moitié), un compte à jour,
//     et l'accès au calendrier pour les corrections de jours isolés (seconde
//     moitié).
// EN: A stay purpose in words.
// FR: Un but de séjour en mots.
String purposeName(AppLocalizations strings, StayPurpose p) => switch (p) {
      StayPurpose.personal => strings.purposePersonal,
      StayPurpose.work => strings.purposeWork,
      StayPurpose.transit => strings.purposeTransit,
      StayPurpose.other => strings.purposeOther,
    };

class _WorkSection extends StatelessWidget {
  final WorkPlan plan;
  final DateTime? from;
  final DateTime? to;
  final ValueChanged<WorkPlan> onChanged;
  final StayPurpose? purpose;
  final ValueChanged<StayPurpose?> onPurpose;
  final TextEditingController jobLabel;

  const _WorkSection({
    required this.plan,
    required this.from,
    required this.to,
    required this.onChanged,
    required this.purpose,
    required this.onPurpose,
    required this.jobLabel,
  });

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final start = from;
    final end = to;
    var count = 0;
    if (start != null && end != null) {
      for (var d = start;
          !d.isAfter(end);
          d = DateTime(d.year, d.month, d.day + 1)) {
        if (plan.isWorked(d)) count++;
      }
    }
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionHeading(
              strings.workHeading,
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Text(strings.workWeekdaysLabel),
            const SizedBox(height: 4),
            WeekdayChips(plan: plan, onChanged: onChanged),
            const SizedBox(height: 8),
            Text(strings.workStayCount(count)),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                icon: const Icon(Icons.calendar_month_outlined),
                label: Text(strings.workCorrectDays),
                onPressed: start == null || end == null
                    ? null
                    : () async {
                        final corrected = await correctWorkedDays(
                          context,
                          from: start,
                          to: end,
                          plan: plan,
                        );
                        if (corrected != null) onChanged(corrected);
                      },
              ),
            ),
            // EN: Purpose and label (WRK-7): optional, free, and changing no
            //     count; no wages, hours or employer details (WRK-9).
            // FR: But et étiquette (WRK-7) : facultatifs, libres, et ne
            //     changeant aucun compte ; ni salaire, ni heures, ni détails
            //     sur l'employeur (WRK-9).
            const SizedBox(height: 8),
            // EN: The label sits above the menu so it can wrap at large text;
            //     inside the field it would be cut off.
            // FR: L'étiquette est au-dessus du menu afin de pouvoir passer à la
            //     ligne en grand texte ; dans le champ, elle serait tronquée.
            Text(strings.workPurposeLabel),
            Semantics(
              label: strings.workPurposeLabel,
              child: DropdownButtonFormField<StayPurpose?>(
                isExpanded: true,
                initialValue: purpose,
                items: [
                  DropdownMenuItem(child: Text(strings.purposeNotSet)),
                  for (final p in StayPurpose.values)
                    DropdownMenuItem(
                      value: p,
                      child: Text(purposeName(strings, p)),
                    ),
                ],
                onChanged: onPurpose,
              ),
            ),
            const SizedBox(height: 8),
            LabeledField(
              controller: jobLabel,
              maxLength: InputLimits.maxStayLabelLength,
              label: strings.workLabelField,
            ),
          ],
        ),
      ),
    );
  }
}

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
