// EN: Tests for alerts by place (FEA-1, WRK-10): the ledger search gives the
//     same date as DayCounter for any-part presence over random histories; end
//     of day and days worked give the dates worked out by hand; old alerts read
//     as the United States; the repository watches only the alert's place.
// FR: Tests des alertes par lieu (FEA-1, WRK-10) : la recherche par registre
//     donne la même date que DayCounter pour la présence toute partie sur des
//     historiques aléatoires ; la fin de journée et les jours travaillés donnent
//     les dates calculées à la main ; les anciennes alertes se lisent comme les
//     États-Unis ; le dépôt ne surveille que le lieu de l'alerte.

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snowbird_in_usa_tracker/logic/alert_math.dart';
import 'package:snowbird_in_usa_tracker/logic/day_counter.dart';
import 'package:snowbird_in_usa_tracker/logic/presence_ledger.dart';
import 'package:snowbird_in_usa_tracker/models/day_alert.dart';
import 'package:snowbird_in_usa_tracker/models/place.dart';
import 'package:snowbird_in_usa_tracker/models/trip.dart';
import 'package:snowbird_in_usa_tracker/models/work_plan.dart';
import 'package:snowbird_in_usa_tracker/services/storage_service.dart';
import 'package:snowbird_in_usa_tracker/state/alert_repository.dart';
import 'package:snowbird_in_usa_tracker/state/trip_repository.dart';

final _today = DateTime(2026, 11, 26);
final _on = Place.parse('CA-ON');

var _n = 0;
Trip _stay(
  Place place,
  DateTime a,
  DateTime? d, {
  TripStatus status = TripStatus.actual,
  WorkPlan? work,
}) =>
    Trip(
      id: 's${_n++}',
      arrivalDate: a,
      departureDate: d,
      status: status,
      place: place,
      work: work,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('any part, present: the ledger search equals DayCounter', () {
    final r = Random(5);
    final places = [_on, Place.canada, Place.unitedStates, Place.mexico];
    var dated = 0;
    for (var n = 0; n < 150; n++) {
      final stays = <Trip>[];
      var day = DateTime(2025, 1, 1 + r.nextInt(300));
      for (var i = 0; i < 12 && day.isBefore(_today); i++) {
        final end = DateTime(day.year, day.month, day.day + r.nextInt(60));
        final open = i == 11 || (end.isAfter(_today) && r.nextBool());
        stays.add(
          _stay(
            places[r.nextInt(places.length)],
            day,
            open ? null : (end.isAfter(_today) ? _today : end),
          ),
        );
        if (open) break;
        day = DateTime(end.year, end.month, end.day + r.nextInt(20));
      }
      for (var k = r.nextInt(3); k > 0; k--) {
        final s = DateTime(2026, 12, 1 + r.nextInt(200));
        stays.add(
          _stay(
            places[r.nextInt(places.length)],
            s,
            DateTime(s.year, s.month, s.day + r.nextInt(90)),
            status: TripStatus.planned,
          ),
        );
      }
      final place = places[r.nextInt(places.length)];
      final window = [30, 180, 365][r.nextInt(3)];
      final threshold = 1 + r.nextInt(window);
      for (final crossing in [false, true]) {
        final mine = AlertMath.firstDateReaching(
          stays: stays,
          place: place,
          convention: CountingConvention.anyPart,
          measure: AlertMeasure.present,
          thresholdDays: threshold,
          windowDays: window,
          from: _today,
          crossingOnly: crossing,
        );
        if (mine != null) dated++;
        expect(
          mine,
          DayCounter.firstDateReachingThreshold(
            trips: stays,
            thresholdDays: threshold,
            windowDays: window,
            from: _today,
            crossingOnly: crossing,
            place: place,
          ),
          reason: 'history $n, ${place.code}, $threshold/$window',
        );
      }
    }
    // EN: The comparison must be about real dates, not two nulls.
    // FR: La comparaison doit porter sur de vraies dates, pas deux nulls.
    expect(dated, greaterThan(60));
  });

  test('end of day does not count the departure night', () {
    // EN: Ontario from 1 November to 10 December: 40 dates by any part, but
    //     only 39 nights by end of day (10 December's midnight is elsewhere).
    // FR: Ontario du 1er novembre au 10 décembre : 40 dates selon toute partie,
    //     mais seulement 39 nuits selon fin de journée (le minuit du 10
    //     décembre est ailleurs).
    final stays = [_stay(_on, DateTime(2026, 11, 1), DateTime(2026, 12, 10))];
    DateTime? reach(CountingConvention c) => AlertMath.firstDateReaching(
          stays: stays,
          place: _on,
          convention: c,
          measure: AlertMeasure.present,
          thresholdDays: 40,
          windowDays: 365,
          from: _today,
        );
    expect(reach(CountingConvention.anyPart), DateTime(2026, 12, 10));
    expect(
      reach(CountingConvention.endOfDay),
      isNull,
      reason: 'only 39 nights before 10 December',
    );
  });

  test('days worked: the 10th weekday worked from 16 November', () {
    final stays = [
      _stay(
        _on,
        DateTime(2026, 11, 16),
        null,
        work: WorkPlan(weekdays: {1, 2, 3, 4, 5}),
      ),
    ];
    final reach = AlertMath.firstDateReaching(
      stays: stays,
      place: _on,
      convention: CountingConvention.anyPart,
      measure: AlertMeasure.worked,
      thresholdDays: 10,
      windowDays: 30,
      from: _today,
    );
    // EN: 16 November 2026 is a Monday; the 10th weekday is Friday 27th.
    // FR: Le 16 novembre 2026 est un lundi ; le 10e jour ouvrable est le
    //     vendredi 27.
    expect(reach, DateTime(2026, 11, 27));
    expect(
      AlertMath.countInLastDays(
        stays: stays,
        place: _on,
        convention: CountingConvention.anyPart,
        measure: AlertMeasure.worked,
        windowDays: 30,
        today: _today,
      ),
      9,
    );
  });

  test('an alert saved before places reads as the United States, any part', () {
    final old = DayAlert.create(
      thresholdDays: 120,
      windowDays: 365,
      hour: 9,
      minute: 0,
    ).toJson()
      ..remove('place')
      ..remove('convention')
      ..remove('measure');
    final alert = DayAlert.fromJson(old);
    expect(alert.place, Place.unitedStates);
    expect(alert.convention, CountingConvention.anyPart);
    expect(alert.measure, AlertMeasure.present);
    final round = DayAlert.fromJson(
      alert
          .copyWith(
            place: _on,
            convention: CountingConvention.endOfDay,
            measure: AlertMeasure.worked,
          )
          .toJson(),
    );
    expect(round.place, _on);
    expect(round.convention, CountingConvention.endOfDay);
    expect(round.measure, AlertMeasure.worked);
    expect(
      () => DayAlert.fromJson({...old, 'place': 'Ontario'}),
      throwsFormatException,
    );
  });

  test('the repository watches only the alert\'s place', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = StorageService(await SharedPreferences.getInstance());
    final trips = TripRepository(storage, now: () => _today);
    final alerts = AlertRepository(storage, trips, now: () => _today);
    await trips.addTrip(
      _stay(Place.parse('US-FL'), DateTime(2026, 1, 1), DateTime(2026, 4, 30)),
    );
    await trips.addTrip(_stay(_on, DateTime(2026, 4, 30), null));
    final us = DayAlert.create(
      thresholdDays: 100,
      windowDays: 365,
      hour: 9,
      minute: 0,
    );
    final ontario = us.copyWith(place: _on);
    final sinceUs = DayAlert.create(
      thresholdDays: 30,
      windowDays: 30,
      hour: 9,
      minute: 0,
      kind: AlertKind.sinceLastVisit,
    );
    expect(alerts.isReached(us), isTrue, reason: '120 US days');
    expect(alerts.isReached(ontario), isTrue);
    expect(alerts.projectedReachDate(sinceUs), DateTime(2026, 5, 30));
    expect(
      alerts.projectedReachDate(sinceUs.copyWith(place: _on)),
      isNull,
      reason: 'still in Ontario: no departure to measure from',
    );
    final eod = ontario.copyWith(
      thresholdDays: 210,
      convention: CountingConvention.endOfDay,
    );
    expect(alerts.isReached(eod), isTrue);
    expect(
      alerts.isReached(eod.copyWith(thresholdDays: 211)),
      isFalse,
      reason: '30 April to 25 November: 210 nights; tonight has not ended',
    );
  });
}
