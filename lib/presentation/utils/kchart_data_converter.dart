import 'package:flutter_chen_kchart/k_chart.dart';
import '../../data/database/database.dart';

/// K線圖數據模型
/// 適配 flutter_chen_kchart 套件的數據格式
/// 注意：現在直接使用 KLineEntity，保留此類作為輔助
class KChartData {
  final DateTime date;
  final double open;
  final double high;
  final double low;
  final double close;
  final double volume;

  const KChartData({
    required this.date,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
  });

  /// 從 StockPrice 創建 KChartData
  factory KChartData.fromStockPrice(StockPrice price) {
    return KChartData(
      date: price.date,
      open: price.open,
      high: price.high,
      low: price.low,
      close: price.close,
      volume: price.volume.toDouble(),
    );
  }

  /// 轉換為 Map（如果套件需要 Map 格式）
  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'open': open,
      'high': high,
      'low': low,
      'close': close,
      'volume': volume,
    };
  }
}

/// 數據格式轉換工具
/// 將 StockPrice 轉換為 flutter_chen_kchart 套件所需的格式
class KChartDataConverter {
  /// 將 StockPrice 列表轉換為 KLineEntity 列表
  static List<KLineEntity> convertToKLineEntities(List<StockPrice> prices) {
    if (prices.isEmpty) {
      return [];
    }

    return prices.map((price) {
      return KLineEntity.fromCustom(
        open: price.open,
        high: price.high,
        low: price.low,
        close: price.close,
        vol: price.volume.toDouble(),
        time: price.date.millisecondsSinceEpoch,
      );
    }).toList();
  }

  /// 將 StockPrice 列表轉換為 KChartData 列表（保留用於兼容）
  static List<KChartData> convertToKChartData(List<StockPrice> prices) {
    if (prices.isEmpty) {
      return [];
    }

    return prices.map((price) => KChartData.fromStockPrice(price)).toList();
  }

  /// 找到與指定日期最接近的 K線索引
  /// 若發布日無交易，自動順延到下一個交易日（未來最近的交易日）
  /// 容錯範圍：向後查找最多 7 天
  static int? findCandleIndexByDate(
    DateTime targetDate,
    List<KChartData> candles, {
    int maxDaysDifference = 7,
  }) {
    if (candles.isEmpty) {
      return null;
    }

    // 標準化目標日期（只保留日期部分，去除時間）
    final normalizedTarget = DateTime(
      targetDate.year,
      targetDate.month,
      targetDate.day,
    );

    int? nextTradingDayIndex;
    Duration? minForwardDifference;

    for (int i = 0; i < candles.length; i++) {
      final candleDate = DateTime(
        candles[i].date.year,
        candles[i].date.month,
        candles[i].date.day,
      );

      // 完全匹配
      if (candleDate.isAtSameMomentAs(normalizedTarget)) {
        return i;
      }

      // 查找下一個交易日（candleDate 在 targetDate 之後）
      if (candleDate.isAfter(normalizedTarget)) {
        final difference = candleDate.difference(normalizedTarget);
        
        // 在容錯範圍內
        if (difference.inDays <= maxDaysDifference) {
          // 找最接近的下一個交易日
          if (minForwardDifference == null || difference < minForwardDifference) {
            minForwardDifference = difference;
            nextTradingDayIndex = i;
          }
        }
      }
    }

    // 優先返回順延的下一個交易日
    return nextTradingDayIndex;
  }

  /// 將 KChartData 數據按日期排序（從舊到新）
  static List<KChartData> sortCandlesByDate(List<KChartData> candles) {
    final sortedCandles = List<KChartData>.from(candles);
    sortedCandles.sort((a, b) => a.date.compareTo(b.date));
    return sortedCandles;
  }

  /// 檢查 KChartData 數據是否已按時間順序排列
  static bool isSorted(List<KChartData> candles) {
    if (candles.length <= 1) {
      return true;
    }

    for (int i = 1; i < candles.length; i++) {
      if (candles[i].date.isBefore(candles[i - 1].date)) {
        return false;
      }
    }

    return true;
  }

  /// 獲取最新的交易日期
  static DateTime? getLatestTradingDate(List<KChartData> candles) {
    if (candles.isEmpty) {
      return null;
    }

    return candles
        .map((candle) => candle.date)
        .reduce((a, b) => a.isAfter(b) ? a : b);
  }

  /// 獲取指定範圍的 KChartData 數據
  static List<KChartData> getCandlesInRange(
    List<KChartData> candles,
    DateTime startDate,
    DateTime endDate,
  ) {
    return candles.where((candle) {
      return candle.date.isAfter(startDate) && candle.date.isBefore(endDate) ||
          candle.date.isAtSameMomentAs(startDate) ||
          candle.date.isAtSameMomentAs(endDate);
    }).toList();
  }
}

