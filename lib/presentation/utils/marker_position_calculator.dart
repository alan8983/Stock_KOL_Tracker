import '../../data/database/database.dart';
import '../models/candle_date_range.dart';
import 'candle_aggregator.dart';

/// Marker 位置計算器
/// 計算文檔與 Candlestick 的映射關係
class MarkerPositionCalculator {
  /// 計算每個 Candlestick 的日期區間
  /// 
  /// 規則：
  /// - 日K: 當根K線的前一根K線日期 + 1 天 到 當根K線日期
  /// - 週K/月K: 當根K線的前一根K線日期 + 1 天 到 下一根K線日期 - 1 天
  /// - 未開盤日期（週末、假日）歸入前一個交易日
  static List<CandleDateRange> calculateDateRanges(
    List<StockPrice> candles,
    CandleInterval interval,
  ) {
    if (candles.isEmpty) return [];

    final List<CandleDateRange> ranges = [];

    for (int i = 0; i < candles.length; i++) {
      final candle = candles[i];
      final candleDate = DateTime(
        candle.date.year,
        candle.date.month,
        candle.date.day,
      );

      DateTime startDate;
      DateTime endDate;

      if (i == 0) {
        // 第一根 K 線：從該日期往前延伸，覆蓋未開盤日期
        // 往前找最多 7 天，找到最近的交易日
        startDate = _findPreviousTradingDay(candleDate, candles);
        endDate = candleDate;
      } else {
        // 從前一根 K 線的日期 + 1 天開始
        final prevCandleDate = DateTime(
          candles[i - 1].date.year,
          candles[i - 1].date.month,
          candles[i - 1].date.day,
        );
        startDate = prevCandleDate.add(const Duration(days: 1));
        endDate = candleDate;
      }

      // 如果是週K/月K，需要延伸到下一根 K 線的前一天
      if (interval != CandleInterval.daily && i < candles.length - 1) {
        final nextCandleDate = DateTime(
          candles[i + 1].date.year,
          candles[i + 1].date.month,
          candles[i + 1].date.day,
        );
        endDate = nextCandleDate.subtract(const Duration(days: 1));
      }

      ranges.add(CandleDateRange(
        startDate: startDate,
        endDate: endDate,
        candleIndex: i,
        candle: candle,
      ));
    }

    return ranges;
  }

  /// 計算文檔與 Candlestick 的映射關係
  /// 
  /// 返回：Map<DateTime, List<Post>> 每個 Candlestick 日期 -> 相關文檔列表
  static Map<DateTime, List<Post>> calculatePositions(
    List<StockPrice> candles,
    List<Post> posts,
    CandleInterval interval,
  ) {
    if (candles.isEmpty || posts.isEmpty) return {};

    // 1. 計算每個 Candlestick 的日期區間
    final dateRanges = calculateDateRanges(candles, interval);

    // 2. 建立映射：Candlestick 日期 -> 文檔列表
    final Map<DateTime, List<Post>> result = {};

    for (final post in posts) {
      final postDate = DateTime(
        post.postedAt.year,
        post.postedAt.month,
        post.postedAt.day,
      );

      // 查找包含此日期的 Candlestick
      CandleDateRange? matchedRange;
      
      for (final range in dateRanges) {
        if (range.containsDate(postDate)) {
          matchedRange = range;
          break;
        }
      }

      // 如果找不到，嘗試順延邏輯（最多向後查找 7 天）
      if (matchedRange == null) {
        matchedRange = _findNextTradingDayRange(postDate, dateRanges);
      }

      if (matchedRange != null) {
        final candleDate = DateTime(
          matchedRange.candle.date.year,
          matchedRange.candle.date.month,
          matchedRange.candle.date.day,
        );
        result.putIfAbsent(candleDate, () => []).add(post);
      }
    }

    return result;
  }

  /// 往前找最近的交易日（用於第一根 K 線）
  static DateTime _findPreviousTradingDay(
    DateTime date,
    List<StockPrice> candles,
  ) {
    // 往前找最多 7 天
    for (int i = 1; i <= 7; i++) {
      final candidate = date.subtract(Duration(days: i));
      // 檢查是否是交易日（在 candles 中存在）
      final isTradingDay = candles.any((c) {
        final cDate = DateTime(c.date.year, c.date.month, c.date.day);
        return cDate.isAtSameMomentAs(candidate);
      });
      
      if (isTradingDay) {
        return candidate;
      }
    }
    
    // 如果找不到，返回原日期往前 7 天
    return date.subtract(const Duration(days: 7));
  }

  /// 查找下一個交易日的範圍（順延邏輯）
  /// 最多向後查找 7 天
  static CandleDateRange? _findNextTradingDayRange(
    DateTime postDate,
    List<CandleDateRange> ranges,
  ) {
    // 向後查找最多 7 天
    for (int i = 1; i <= 7; i++) {
      final candidateDate = postDate.add(Duration(days: i));
      
      for (final range in ranges) {
        if (range.containsDate(candidateDate)) {
          return range;
        }
      }
    }
    
    return null;
  }
}

