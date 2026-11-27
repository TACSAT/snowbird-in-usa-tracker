// EN: Correct single worked days on a calendar (WRK-3), after the weekday
//     pattern did most of the work. Only the stay's own dates are shown, so no
//     worked day can be placed outside it. Each day is a toggle button that a
//     screen reader announces with its full date and state; worked days are
//     marked by a filled shape AND a check icon, never by colour alone (ACC-1).
// FR: Corriger des jours travaillés isolés sur un calendrier (WRK-3), une fois
//     que le motif de jours a fait l'essentiel. Seules les dates du séjour sont
//     montrées ; aucun jour travaillé ne peut donc être placé hors de celui-ci.
//     Chaque jour est un bouton à bascule qu'un lecteur d'écran annonce avec sa
//     date complète et son état ; les jours travaillés sont marqués par une
//     forme pleine ET une coche, jamais par la couleur seule (ACC-1).

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:snowbird_in_usa_tracker/l10n/app_localizations.dart';
import 'package:snowbird_in_usa_tracker/models/work_plan.dart';

// EN: Opens the calendar for [from]..[to] and returns the corrected plan, or
//     null when dismissed without "Done".
// FR: Ouvre le calendrier pour [from]..[to] et retourne le plan corrigé, ou
//     null s'il est fermé sans « Terminé ».
Future<WorkPlan?> correctWorkedDays(
  BuildContext context, {
  required DateTime from,
  required DateTime to,
  required WorkPlan plan,
}) =>
    Navigator.of(context).push<WorkPlan>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => WorkCalendarScreen(from: from, to: to, plan: plan),
      ),
    );

class WorkCalendarScreen extends StatefulWidget {
  final DateTime from;
  final DateTime to;
  final WorkPlan plan;

  const WorkCalendarScreen({
    super.key,
    required this.from,
    required this.to,
    required this.plan,
  });

  @override
  State<WorkCalendarScreen> createState() => _WorkCalendarScreenState();
}

class _WorkCalendarScreenState extends State<WorkCalendarScreen> {
  late WorkPlan _plan = widget.plan;

  // EN: The months the stay touches, first to last.
  // FR: Les mois que touche le séjour, du premier au dernier.
  List<DateTime> get _months {
    final months = <DateTime>[];
    var m = DateTime(widget.from.year, widget.from.month);
    while (!m.isAfter(DateTime(widget.to.year, widget.to.month))) {
      months.add(m);
      m = DateTime(m.year, m.month + 1);
    }
    return months;
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final months = _months;
    return Scaffold(
      appBar: AppBar(
        title: Text(strings.workHeading),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(_plan),
            child: Text(strings.workDone),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        itemCount: months.length + 1,
        itemBuilder: (context, index) => index == 0
            ? Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(strings.workCalendarHelp),
              )
            : _Month(
                month: months[index - 1],
                from: widget.from,
                to: widget.to,
                plan: _plan,
                onToggle: (day) => setState(() => _plan = _plan.toggled(day)),
              ),
      ),
    );
  }
}

class _Month extends StatelessWidget {
  final DateTime month;
  final DateTime from;
  final DateTime to;
  final WorkPlan plan;
  final ValueChanged<DateTime> onToggle;

  const _Month({
    required this.month,
    required this.from,
    required this.to,
    required this.plan,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final locale = strings.localeName;
    final fullDate = DateFormat.yMMMMEEEEd(locale);
    // EN: Weeks start on Monday in Canada (French), Mexico and France; the
    //     United States starts on Sunday. The app's languages follow Monday
    //     except English, which follows the US.
    // FR: Les semaines commencent le lundi au Canada (français), au Mexique et
    //     en France ; aux États-Unis, le dimanche. Les langues de l'application
    //     suivent le lundi, sauf l'anglais, qui suit les États-Unis.
    final firstWeekday = locale.startsWith('en') ? DateTime.sunday : 1;
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final lead = (DateTime(month.year, month.month).weekday - firstWeekday) % 7;
    final narrow = DateFormat.E(locale);

    final cells = <Widget>[
      for (var i = 0; i < 7; i++)
        ExcludeSemantics(
          child: Center(
            child: Text(
              narrow.format(DateTime(2026, 3, 1 + (firstWeekday % 7) + i)),
              style: theme.textTheme.labelSmall,
            ),
          ),
        ),
      for (var i = 0; i < lead; i++) const SizedBox(),
      for (var d = 1; d <= daysInMonth; d++)
        _dayCell(context, DateTime(month.year, month.month, d), fullDate),
    ];

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(
              DateFormat.yMMMM(locale).format(month),
              style: theme.textTheme.titleMedium,
            ),
          ),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
            children: cells,
          ),
        ],
      ),
    );
  }

  Widget _dayCell(BuildContext context, DateTime day, DateFormat fullDate) {
    final strings = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final inside = !day.isBefore(from) && !day.isAfter(to);
    // EN: Days outside the stay are left blank: they cannot be marked, and a
    //     faded number would fail the text-contrast guideline.
    // FR: Les jours hors du séjour restent vides : ils ne peuvent pas être
    //     marqués, et un chiffre estompé échouerait au critère de contraste.
    if (!inside) return const SizedBox();
    final worked = plan.isWorked(day);
    final label = worked
        ? strings.workDayWorked(fullDate.format(day))
        : strings.workDayNotWorked(fullDate.format(day));
    return Semantics(
      button: true,
      toggled: worked,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: worked ? scheme.primaryContainer : Colors.transparent,
        shape: CircleBorder(
          side: BorderSide(color: worked ? scheme.primary : scheme.outline),
        ),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => onToggle(day),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${day.day}',
                    style: TextStyle(
                      color:
                          worked ? scheme.onPrimaryContainer : scheme.onSurface,
                      fontWeight: worked ? FontWeight.bold : null,
                    ),
                  ),
                  if (worked)
                    Icon(
                      Icons.check,
                      size: 12,
                      color: scheme.onPrimaryContainer,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
