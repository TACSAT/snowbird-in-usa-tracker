// EN: Which days of a stay were worked (REQUIREMENTS-places.md section 7). The
//     user marks them quickly with a weekday pattern ("Monday to Friday"), then
//     corrects single days on a calendar (WRK-3): a day off is REMOVED from the
//     pattern, an extra Saturday is ADDED. A day worked is never inferred from
//     presence (WRK-2): no plan means no worked day.
//
//     A plan is only ever read inside its stay's dates, so changing a stay's
//     dates can never invent a worked day outside it (WRK-3); clippedTo() also
//     drops corrections that fall outside, so nothing stale is kept.
// FR: Les jours travaillés d'un séjour (REQUIREMENTS-places.md, section 7).
//     L'utilisateur les marque rapidement par un motif de jours de semaine (« du
//     lundi au vendredi »), puis corrige des jours isolés sur un calendrier
//     (WRK-3) : un jour de congé est RETIRÉ du motif, un samedi de plus est
//     AJOUTÉ. Un jour travaillé n'est jamais déduit de la présence (WRK-2) :
//     sans plan, aucun jour travaillé.
//
//     Un plan n'est jamais lu qu'à l'intérieur des dates de son séjour ; changer
//     les dates d'un séjour ne peut donc jamais inventer un jour travaillé hors
//     de celui-ci (WRK-3) ; clippedTo() retire aussi les corrections tombées
//     dehors, afin de ne rien garder de périmé.

class WorkPlan {
  // EN: A ceiling on single-day corrections, like every other list: ten years
  //     of daily corrections, far beyond any real use.
  // FR: Un plafond de corrections de jours isolés, comme pour toute autre
  //     liste : dix ans de corrections quotidiennes, bien au-delà de tout usage
  //     réel.
  static const int maxCorrections = 3660;

  // EN: Weekdays worked, as DateTime.monday (1) to DateTime.sunday (7).
  // FR: Jours de semaine travaillés, de DateTime.monday (1) à DateTime.sunday
  //     (7).
  final Set<int> weekdays;
  final Set<DateTime> added;
  final Set<DateTime> removed;

  WorkPlan({
    Set<int> weekdays = const {},
    Set<DateTime> added = const {},
    Set<DateTime> removed = const {},
  })  : weekdays = Set.unmodifiable(weekdays.where((d) => d >= 1 && d <= 7)),
        added = Set.unmodifiable(added.map(_dateOnly)),
        removed = Set.unmodifiable(removed.map(_dateOnly));

  static final WorkPlan none = WorkPlan();

  bool get isEmpty => weekdays.isEmpty && added.isEmpty;

  bool isWorked(DateTime date) {
    final d = _dateOnly(date);
    if (added.contains(d)) return true;
    return weekdays.contains(d.weekday) && !removed.contains(d);
  }

  // EN: The plan with a new weekday pattern; corrections are kept.
  // FR: Le plan avec un nouveau motif de jours ; les corrections sont gardées.
  WorkPlan withWeekdays(Set<int> days) =>
      WorkPlan(weekdays: days, added: added, removed: removed);

  // EN: Flip one date on the calendar. The correction is recorded against the
  //     pattern, so it survives a later change of the pattern for other days.
  // FR: Inverser une date sur le calendrier. La correction est notée par
  //     rapport au motif, afin de survivre à un changement ultérieur du motif
  //     pour les autres jours.
  WorkPlan toggled(DateTime date) {
    final d = _dateOnly(date);
    final byPattern = weekdays.contains(d.weekday);
    final nextAdded = {...added};
    final nextRemoved = {...removed};
    if (isWorked(d)) {
      nextAdded.remove(d);
      if (byPattern) nextRemoved.add(d);
    } else {
      nextRemoved.remove(d);
      if (!byPattern) nextAdded.add(d);
    }
    return WorkPlan(weekdays: weekdays, added: nextAdded, removed: nextRemoved);
  }

  // EN: Drops corrections outside [from]..[to] (the stay's dates).
  // FR: Retire les corrections hors de [from]..[to] (les dates du séjour).
  WorkPlan clippedTo(DateTime from, DateTime? to) {
    bool inside(DateTime d) =>
        !d.isBefore(_dateOnly(from)) && (to == null || !d.isAfter(to));
    return WorkPlan(
      weekdays: weekdays,
      added: added.where(inside).toSet(),
      removed: removed.where(inside).toSet(),
    );
  }

  Map<String, dynamic> toJson() => {
        'weekdays': [...weekdays]..sort(),
        if (added.isNotEmpty) 'added': _isoList(added),
        if (removed.isNotEmpty) 'removed': _isoList(removed),
      };

  factory WorkPlan.fromJson(Map<String, dynamic> json) {
    List<DateTime> dates(String key) {
      final raw = json[key];
      if (raw == null) return const [];
      if (raw is! List || raw.length > maxCorrections) {
        throw FormatException('Work plan "$key" must be a short list.');
      }
      return [
        for (final item in raw)
          DateTime.tryParse(item is String ? item : '') ??
              (throw FormatException('Work plan "$key" has a bad date.')),
      ];
    }

    final days = json['weekdays'];
    if (days is! List || days.any((d) => d is! int || d < 1 || d > 7)) {
      throw const FormatException('Work plan "weekdays" must be 1 to 7.');
    }
    return WorkPlan(
      weekdays: days.cast<int>().toSet(),
      added: dates('added').toSet(),
      removed: dates('removed').toSet(),
    );
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static List<String> _isoList(Set<DateTime> dates) => [
        for (final d in [...dates]..sort())
          '${d.year.toString().padLeft(4, '0')}-'
              '${d.month.toString().padLeft(2, '0')}-'
              '${d.day.toString().padLeft(2, '0')}',
      ];
}
