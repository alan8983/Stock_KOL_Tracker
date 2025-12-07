import '../../data/models/relative_time_input.dart';

class RelativeTimeParser {
  /// 解析相對時間字串，例如 "3小時前"、"2天前"、"1週前"
  static RelativeTimeInput? parse(String input) {
    final trimmed = input.trim();
    
    // 移除可能的 "前" 字
    final withoutSuffix = trimmed.replaceAll(RegExp(r'[前後]$'), '');
    
    // 匹配數字和單位
    final patterns = [
      RegExp(r'(\d+)\s*小時', caseSensitive: false),
      RegExp(r'(\d+)\s*天', caseSensitive: false),
      RegExp(r'(\d+)\s*週', caseSensitive: false),
      RegExp(r'(\d+)\s*周', caseSensitive: false),
      RegExp(r'(\d+)\s*月', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(withoutSuffix);
      if (match != null) {
        final value = int.tryParse(match.group(1) ?? '');
        if (value != null && value > 0) {
          TimeUnit unit;
          if (pattern == patterns[0]) {
            unit = TimeUnit.hour;
          } else if (pattern == patterns[1] || pattern == patterns[2] || pattern == patterns[3]) {
            unit = pattern == patterns[2] || pattern == patterns[3] ? TimeUnit.week : TimeUnit.day;
          } else {
            unit = TimeUnit.month;
          }
          return RelativeTimeInput(value: value, unit: unit);
        }
      }
    }

    return null;
  }

  /// 嘗試解析，若失敗則返回 null
  static DateTime? parseToDateTime(String input) {
    final relativeTime = parse(input);
    return relativeTime?.toAbsoluteTime();
  }
}
