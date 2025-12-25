import '../../data/database/database.dart';

/// Candlestick 日期區間模型
/// 定義每個 Candlestick 覆蓋的日期範圍
class CandleDateRange {
  /// 區間開始日期（含）
  final DateTime startDate;
  
  /// 區間結束日期（含）
  final DateTime endDate;
  
  /// 對應的 Candlestick 索引
  final int candleIndex;
  
  /// 對應的 K 線數據
  final StockPrice candle;

  CandleDateRange({
    required this.startDate,
    required this.endDate,
    required this.candleIndex,
    required this.candle,
  });

  /// 判斷指定日期是否落在這個區間內
  bool containsDate(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    final normalizedStart = DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
    );
    final normalizedEnd = DateTime(
      endDate.year,
      endDate.month,
      endDate.day,
    );
    
    return !normalized.isBefore(normalizedStart) && 
           !normalized.isAfter(normalizedEnd);
  }

  @override
  String toString() {
    return 'CandleDateRange(index: $candleIndex, start: $startDate, end: $endDate)';
  }
}

