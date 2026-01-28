enum TimePeriod {
  oneWeek,
  oneMonth,
  threeMonths,
  sixMonths,
  oneYear,
  allTime,
}

class TimePeriodHelper {
  static DateTime getStartDate(TimePeriod period) {
    final now = DateTime.now();
    switch (period) {
      case TimePeriod.oneWeek:
        return now.subtract(const Duration(days: 7));
      case TimePeriod.oneMonth:
        return DateTime(now.year, now.month - 1, now.day);
      case TimePeriod.threeMonths:
        return DateTime(now.year, now.month - 3, now.day);
      case TimePeriod.sixMonths:
        return DateTime(now.year, now.month - 6, now.day);
      case TimePeriod.oneYear:
        return DateTime(now.year - 1, now.month, now.day);
      case TimePeriod.allTime:
        return DateTime.fromMillisecondsSinceEpoch(0);
    }
  }

  static String getDisplayName(TimePeriod period) {
    switch (period) {
      case TimePeriod.oneWeek:
        return '1 Week';
      case TimePeriod.oneMonth:
        return '1 Month';
      case TimePeriod.threeMonths:
        return '3 Months';
      case TimePeriod.sixMonths:
        return '6 Months';
      case TimePeriod.oneYear:
        return '1 Year';
      case TimePeriod.allTime:
        return 'All Time';
    }
  }

  // Alias for tests
  static DateTime getDateRange(TimePeriod period) => getStartDate(period);
}
