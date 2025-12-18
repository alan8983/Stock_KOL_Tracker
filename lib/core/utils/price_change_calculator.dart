import '../../data/database/database.dart';

/// 漲跌幅計算器
/// 負責計算股價在不同時間區間的漲跌幅
class PriceChangeCalculator {
  /// 計算特定時間區間的漲跌幅
  /// 
  /// [prices] 股價資料列表（需按日期升序排列）
  /// [baseDate] 基準日期（發文日期）
  /// [periodDays] 時間區間（天數）
  /// 
  /// 返回漲跌幅百分比，如果資料不足返回 null
  double? calculateChange({
    required List<StockPrice> prices,
    required DateTime baseDate,
    required int periodDays,
  }) {
    if (prices.isEmpty) return null;

    // 1. 找到基準日期的收盤價
    final basePrice = _findPriceOnOrBefore(prices, baseDate);
    if (basePrice == null) return null;

    // 2. 計算目標日期
    final targetDate = baseDate.add(Duration(days: periodDays));

    // 3. 找到目標日期的收盤價（必須在基準日之後）
    final targetPrice = _findPriceOnOrBefore(prices, targetDate);
    if (targetPrice == null) return null;
    
    // 確保目標價格的日期在基準價格之後
    final basePriceDate = DateTime(
      basePrice.date.year,
      basePrice.date.month,
      basePrice.date.day,
    );
    final targetPriceDate = DateTime(
      targetPrice.date.year,
      targetPrice.date.month,
      targetPrice.date.day,
    );
    
    if (!targetPriceDate.isAfter(basePriceDate)) {
      return null; // 目標日期不在基準日之後，資料不足
    }

    // 4. 計算漲跌幅百分比
    final change = ((targetPrice.close - basePrice.close) / basePrice.close) * 100;
    return change;
  }

  /// 批次計算多個時間區間的漲跌幅
  /// 
  /// [prices] 股價資料列表（需按日期升序排列）
  /// [baseDate] 基準日期（發文日期）
  /// [periods] 時間區間列表（天數），例如 [5, 30, 90, 365]
  /// 
  /// 返回 Map，key 為時間區間，value 為漲跌幅百分比
  Map<int, double?> calculateMultiplePeriods({
    required List<StockPrice> prices,
    required DateTime baseDate,
    required List<int> periods,
  }) {
    final result = <int, double?>{};
    
    for (final period in periods) {
      result[period] = calculateChange(
        prices: prices,
        baseDate: baseDate,
        periodDays: period,
      );
    }
    
    return result;
  }

  /// 找到指定日期當天或之前最近的交易日股價
  /// 
  /// 向前查找最多 7 天，如果找不到則返回 null
  StockPrice? _findPriceOnOrBefore(List<StockPrice> prices, DateTime date) {
    // 將日期標準化為當天的 00:00:00
    final normalizedDate = DateTime(date.year, date.month, date.day);
    
    // 向前查找最多 7 天
    for (int i = 0; i <= 7; i++) {
      final searchDate = normalizedDate.subtract(Duration(days: i));
      
      // 使用二分搜尋提升效能
      final index = _binarySearchDate(prices, searchDate);
      
      if (index != -1) {
        return prices[index];
      }
    }
    
    return null;
  }

  /// 二分搜尋：找到指定日期的股價索引
  /// 
  /// 假設 prices 已按日期升序排列
  /// 返回找到的索引，如果沒找到返回 -1
  int _binarySearchDate(List<StockPrice> prices, DateTime targetDate) {
    int left = 0;
    int right = prices.length - 1;
    
    while (left <= right) {
      final mid = (left + right) ~/ 2;
      final midDate = DateTime(
        prices[mid].date.year,
        prices[mid].date.month,
        prices[mid].date.day,
      );
      
      if (midDate.isAtSameMomentAs(targetDate)) {
        return mid;
      } else if (midDate.isBefore(targetDate)) {
        left = mid + 1;
      } else {
        right = mid - 1;
      }
    }
    
    return -1; // 沒找到
  }
}
