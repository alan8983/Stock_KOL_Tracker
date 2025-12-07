enum TimeUnit {
  hour,
  day,
  week,
  month,
}

class RelativeTimeInput {
  final int value;
  final TimeUnit unit;

  const RelativeTimeInput({
    required this.value,
    required this.unit,
  });

  /// 將相對時間轉換為絕對時間
  DateTime toAbsoluteTime() {
    final now = DateTime.now();
    switch (unit) {
      case TimeUnit.hour:
        return now.subtract(Duration(hours: value));
      case TimeUnit.day:
        return now.subtract(Duration(days: value));
      case TimeUnit.week:
        return now.subtract(Duration(days: value * 7));
      case TimeUnit.month:
        return DateTime(now.year, now.month - value, now.day, now.hour, now.minute);
    }
  }

  @override
  String toString() {
    final unitStr = switch (unit) {
      TimeUnit.hour => '小時',
      TimeUnit.day => '天',
      TimeUnit.week => '週',
      TimeUnit.month => '月',
    };
    return '$value$unitStr前';
  }
}
