class DateTimeFormatter {
  /// 格式化為 "yyyy/MM/dd HH:mm"
  static String format(DateTime dt) {
    return '${dt.year.toString().padLeft(4, '0')}/'
           '${dt.month.toString().padLeft(2, '0')}/'
           '${dt.day.toString().padLeft(2, '0')} '
           '${dt.hour.toString().padLeft(2, '0')}:'
           '${dt.minute.toString().padLeft(2, '0')}';
  }

  /// 格式化為相對時間字串，例如 "3小時前"
  static String formatRelative(DateTime dt) {
    final now = DateTime.now();
    final difference = now.difference(dt);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '$years年前';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months個月前';
    } else if (difference.inDays > 7) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks週前';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}天前';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}小時前';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}分鐘前';
    } else {
      return '剛剛';
    }
  }

  /// 格式化為日期 "yyyy/MM/dd"
  static String formatDate(DateTime dt) {
    return '${dt.year.toString().padLeft(4, '0')}/'
           '${dt.month.toString().padLeft(2, '0')}/'
           '${dt.day.toString().padLeft(2, '0')}';
  }

  /// 格式化為時間 "HH:mm"
  static String formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:'
           '${dt.minute.toString().padLeft(2, '0')}';
  }
}
