// EN: The weekday pattern of days worked (WRK-3), as seven toggle chips: on a
//     stay and on a what-if stop. Each chip is one screen-reader item named
//     with the full weekday ("Monday"), says whether it is on, and can be
//     activated by the screen reader itself (its tap is exposed as the item's
//     own action, not left to a gesture on the hidden chip).
// FR: Le motif hebdomadaire des jours travaillés (WRK-3), en sept puces à
//     bascule : sur un séjour et sur une étape d'hypothèse. Chaque puce est un
//     seul élément pour le lecteur d'écran, nommé du jour complet (« lundi »),
//     qui dit s'il est activé et peut être activé par le lecteur d'écran
//     lui-même (son toucher est exposé comme action propre de l'élément, et non
//     laissé à un geste sur la puce cachée).

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:snowbird_in_usa_tracker/l10n/app_localizations.dart';
import 'package:snowbird_in_usa_tracker/models/work_plan.dart';

class WeekdayChips extends StatelessWidget {
  final WorkPlan plan;
  final ValueChanged<WorkPlan> onChanged;

  const WeekdayChips({super.key, required this.plan, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context).localeName;
    // EN: Weeks start on Sunday in English (US use), Monday otherwise.
    // FR: Les semaines commencent le dimanche en anglais (usage américain), le
    //     lundi sinon.
    final first = locale.startsWith('en') ? DateTime.sunday : DateTime.monday;
    final days = [for (var i = 0; i < 7; i++) (first - 1 + i) % 7 + 1];
    // EN: 2 March 2026 is a Monday: a fixed week to name the days from.
    // FR: Le 2 mars 2026 est un lundi : une semaine fixe pour nommer les jours.
    DateTime sample(int weekday) => DateTime(2026, 3, 1 + weekday);
    void toggle(int day) {
      final on = !plan.weekdays.contains(day);
      onChanged(
        plan.withWeekdays(
          on ? {...plan.weekdays, day} : ({...plan.weekdays}..remove(day)),
        ),
      );
    }

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final day in days)
          Semantics(
            label: DateFormat.EEEE(locale).format(sample(day)),
            toggled: plan.weekdays.contains(day),
            button: true,
            onTap: () => toggle(day),
            excludeSemantics: true,
            child: FilterChip(
              label: Text(DateFormat.E(locale).format(sample(day))),
              selected: plan.weekdays.contains(day),
              onSelected: (_) => toggle(day),
            ),
          ),
      ],
    );
  }
}
