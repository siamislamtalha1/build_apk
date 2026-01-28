import 'package:Bloomee/model/time_period.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TimePeriod Helper Tests', () {
    test('getDisplayName returns correct string', () {
      expect(TimePeriodHelper.getDisplayName(TimePeriod.oneWeek), '1W');
      expect(TimePeriodHelper.getDisplayName(TimePeriod.allTime), 'All');
    });

    test('getDateRange returns correct start date', () {
      final now = DateTime.now();

      final range1W = TimePeriodHelper.getDateRange(TimePeriod.oneWeek);
      // Rough check (within 1 second tolerance of expected calculation)
      final expected1W = now.subtract(const Duration(days: 7));
      expect(range1W.difference(expected1W).inSeconds.abs() <= 1, true);

      final rangeAll = TimePeriodHelper.getDateRange(TimePeriod.allTime);
      expect(rangeAll.year, 2000); // Epoch start as defined
    });
  });
}
