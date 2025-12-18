/// 時間解析工具
/// 支援相對時間（如「3小時前」）和中文日期（如「12月11日」）
class TimeParser {
  /// 解析時間文字，返回 DateTime 或 null
  static DateTime? parse(String? timeText) {
    if (timeText == null || timeText.trim().isEmpty) {
      return null;
    }

    final text = timeText.trim();
    final now = DateTime.now();

    // 嘗試解析相對時間
    final relativeTime = _parseRelativeTime(text, now);
    if (relativeTime != null) {
      return relativeTime;
    }

    // 嘗試解析中文日期
    final chineseDate = _parseChineseDate(text, now);
    if (chineseDate != null) {
      return chineseDate;
    }

    // 無法解析
    print('⚠️ TimeParser: 無法解析時間文字: $text');
    return null;
  }

  /// 解析相對時間（如「3小時前」、「2天前」、「16小時」）
  static DateTime? _parseRelativeTime(String text, DateTime now) {
    // 先檢查是否包含「月」「日」關鍵字，如果有則不是相對時間
    if (text.contains('月') && text.contains('日')) {
      return null;
    }
    
    // 相對時間正則：支援「N小時前」、「N天前」、「N分鐘前」等
    // 注意：必須要有「前」字或者是完整的「N小時」「N天」格式
    final patterns = [
      RegExp(r'^.*?(\d+)\s*小時(?:前|$)'),
      RegExp(r'^.*?(\d+)\s*分鐘(?:前|$)'),
      RegExp(r'^.*?(\d+)\s*天(?:前|$)'),
      RegExp(r'^.*?(\d+)\s*週(?:前|$)'),
      RegExp(r'^.*?(\d+)\s*個?月(?:前|$)'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final value = int.tryParse(match.group(1)!);
        if (value == null) continue;

        // 判斷單位
        if (text.contains('小時')) {
          return now.subtract(Duration(hours: value));
        } else if (text.contains('分鐘')) {
          return now.subtract(Duration(minutes: value));
        } else if (text.contains('天')) {
          return now.subtract(Duration(days: value));
        } else if (text.contains('週')) {
          return now.subtract(Duration(days: value * 7));
        } else if (text.contains('月')) {
          return DateTime(now.year, now.month - value, now.day, now.hour, now.minute);
        }
      }
    }

    return null;
  }

  /// 解析中文日期（如「12月11日」、「12月11日下午2:02」）
  static DateTime? _parseChineseDate(String text, DateTime now) {
    // 解析「12月11日」格式
    final datePattern = RegExp(r'(\d{1,2})月(\d{1,2})日');
    final dateMatch = datePattern.firstMatch(text);
    
    if (dateMatch != null) {
      final month = int.tryParse(dateMatch.group(1)!);
      final day = int.tryParse(dateMatch.group(2)!);
      
      if (month == null || day == null) return null;
      if (month < 1 || month > 12) return null;
      if (day < 1 || day > 31) return null;

      // 嘗試解析時間（如「下午2:02」、「上午11:25」）
      final timeMatch = _parseChineseTime(text);
      
      int hour = 0;
      int minute = 0;
      
      if (timeMatch != null) {
        hour = timeMatch['hour']!;
        minute = timeMatch['minute']!;
      }

      // 判斷年份（如果日期時間在未來，則為去年）
      int year = now.year;
      var tentativeDate = DateTime(year, month, day, hour, minute);
      if (tentativeDate.isAfter(now)) {
        year = now.year - 1;
        tentativeDate = DateTime(year, month, day, hour, minute);
      }

      return tentativeDate;
    }

    // 解析「12/11」格式
    final slashPattern = RegExp(r'(\d{1,2})/(\d{1,2})');
    final slashMatch = slashPattern.firstMatch(text);
    
    if (slashMatch != null) {
      final month = int.tryParse(slashMatch.group(1)!);
      final day = int.tryParse(slashMatch.group(2)!);
      
      if (month == null || day == null) return null;
      if (month < 1 || month > 12) return null;
      if (day < 1 || day > 31) return null;

      // 判斷年份（如果日期在未來，則為去年）
      int year = now.year;
      var tentativeDate = DateTime(year, month, day);
      if (tentativeDate.isAfter(now)) {
        year = now.year - 1;
        tentativeDate = DateTime(year, month, day);
      }

      return tentativeDate;
    }

    return null;
  }

  /// 解析中文時間（如「下午2:02」、「上午11:25」）
  static Map<String, int>? _parseChineseTime(String text) {
    // 解析「下午2:02」或「上午11:25」
    final amPmPattern = RegExp(r'(上午|下午)\s*(\d{1,2}):(\d{2})');
    final match = amPmPattern.firstMatch(text);
    
    if (match != null) {
      final period = match.group(1);
      var hour = int.tryParse(match.group(2)!);
      final minute = int.tryParse(match.group(3)!);
      
      if (hour == null || minute == null) return null;
      
      // 轉換為24小時制
      if (period == '下午' && hour < 12) {
        hour += 12;
      } else if (period == '上午' && hour == 12) {
        hour = 0;
      }
      
      return {'hour': hour, 'minute': minute};
    }

    // 解析「14:30」格式
    final timePattern = RegExp(r'(\d{1,2}):(\d{2})');
    final timeMatch = timePattern.firstMatch(text);
    
    if (timeMatch != null) {
      final hour = int.tryParse(timeMatch.group(1)!);
      final minute = int.tryParse(timeMatch.group(2)!);
      
      if (hour == null || minute == null) return null;
      if (hour < 0 || hour > 23) return null;
      if (minute < 0 || minute > 59) return null;
      
      return {'hour': hour, 'minute': minute};
    }

    return null;
  }

  /// 格式化相對時間（用於顯示）
  static String formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} 分鐘前';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} 小時前';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} 天前';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()} 週前';
    } else {
      return '${dateTime.month}月${dateTime.day}日';
    }
  }

  /// 判斷時間文字是否為絕對時間
  /// 返回 true 表示絕對時間，false 表示相對時間
  static bool isAbsoluteTime(String? timeText) {
    if (timeText == null || timeText.trim().isEmpty) {
      return false; // 預設為相對時間
    }

    final text = timeText.trim();
    final now = DateTime.now();

    // 優先檢查：如果包含相對時間的關鍵字（如「小時前」、「天前」），則為相對時間
    if (text.contains('小時前') || text.contains('分鐘前') || 
        text.contains('天前') || text.contains('週前') || 
        text.contains('月前')) {
      // 但要注意：如果同時包含「月」「日」，則可能是絕對時間（如「12月6日」）
      // 這種情況下，相對時間關鍵字可能是誤判
      if (text.contains('月') && text.contains('日')) {
        // 檢查是否真的是日期格式（如「12月6日」）
        final datePattern = RegExp(r'(\d{1,2})月(\d{1,2})日');
        if (datePattern.hasMatch(text)) {
          return true; // 絕對時間（日期格式）
        }
      }
      return false; // 相對時間
    }

    // 檢查是否包含「月」「日」關鍵字，如果有則為絕對時間
    if (text.contains('月') && text.contains('日')) {
      return true;
    }

    // 檢查是否包含日期格式（如「12/11」）
    final slashPattern = RegExp(r'(\d{1,2})/(\d{1,2})');
    if (slashPattern.hasMatch(text)) {
      return true;
    }

    // 檢查是否包含時間格式（如「14:30」、「下午2:02」）
    final timePattern = RegExp(r'(\d{1,2}):(\d{2})');
    final amPmPattern = RegExp(r'(上午|下午)\s*(\d{1,2}):(\d{2})');
    if (timePattern.hasMatch(text) || amPmPattern.hasMatch(text)) {
      // 如果有時間格式，再檢查是否有日期格式
      // 如果有日期格式（月日），則為絕對時間
      if (text.contains('月') || text.contains('日')) {
        return true;
      }
      // 如果只有時間格式且沒有相對時間關鍵字，可能是絕對時間
      // 但這種情況較少見，通常需要配合日期使用
      return false; // 預設為相對時間
    }

    // 嘗試解析相對時間，如果成功則為相對時間
    final relativeTime = _parseRelativeTime(text, now);
    if (relativeTime != null) {
      return false; // 相對時間
    }

    // 嘗試解析中文日期，如果成功則為絕對時間
    final chineseDate = _parseChineseDate(text, now);
    if (chineseDate != null) {
      return true; // 絕對時間
    }

    // 預設為相對時間
    return false;
  }
}

