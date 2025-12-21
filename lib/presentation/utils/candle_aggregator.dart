import '../../data/database/database.dart';

/// K線間隔類型
enum CandleInterval {
  daily,    // 日K
  weekly,   // 周K
  monthly,  // 月K
  quarterly, // 季K
  yearly,   // 年K
}

/// K線數據聚合工具
/// 將日K數據聚合為周K、月K、季K、年K
class CandleAggregator {
  /// 將日K數據聚合為指定間隔的K線數據
  static List<StockPrice> aggregate(
    List<StockPrice> dailyPrices,
    CandleInterval interval,
  ) {
    if (dailyPrices.isEmpty) return [];
    if (interval == CandleInterval.daily) return dailyPrices;

    switch (interval) {
      case CandleInterval.weekly:
        return aggregateToWeekly(dailyPrices);
      case CandleInterval.monthly:
        return aggregateToMonthly(dailyPrices);
      case CandleInterval.quarterly:
        return aggregateToQuarterly(dailyPrices);
      case CandleInterval.yearly:
        return aggregateToYearly(dailyPrices);
      default:
        return dailyPrices;
    }
  }

  /// 將日K聚合為周K
  /// 周K規則：使用每周第一個交易日的開盤價、最後一個交易日的收盤價、
  /// 期間的最高價和最低價、期間的總交易量
  static List<StockPrice> aggregateToWeekly(List<StockPrice> dailyPrices) {
    if (dailyPrices.isEmpty) return [];

    final List<StockPrice> weeklyCandles = [];
    List<StockPrice> currentWeek = [];

    for (int i = 0; i < dailyPrices.length; i++) {
      final price = dailyPrices[i];
      final priceDate = DateTime(price.date.year, price.date.month, price.date.day);
      
      // 如果是第一筆數據，直接加入當前周
      if (currentWeek.isEmpty) {
        currentWeek.add(price);
        continue;
      }

      // 獲取當前周的第一個交易日
      final firstDayOfWeek = currentWeek.first.date;
      final firstDate = DateTime(firstDayOfWeek.year, firstDayOfWeek.month, firstDayOfWeek.day);
      
      // 計算兩個日期之間的天數差
      final daysDifference = priceDate.difference(firstDate).inDays;
      
      // 如果屬於同一周（7天內），加入當前周
      if (daysDifference < 7) {
        currentWeek.add(price);
      } else {
        // 完成當前周的聚合
        if (currentWeek.isNotEmpty) {
          weeklyCandles.add(_aggregatePeriod(currentWeek));
        }
        // 開始新的一周
        currentWeek = [price];
      }
    }

    // 處理最後一周
    if (currentWeek.isNotEmpty) {
      weeklyCandles.add(_aggregatePeriod(currentWeek));
    }

    return weeklyCandles;
  }

  /// 將日K聚合為月K
  static List<StockPrice> aggregateToMonthly(List<StockPrice> dailyPrices) {
    if (dailyPrices.isEmpty) return [];

    final List<StockPrice> monthlyCandles = [];
    List<StockPrice> currentMonth = [];

    for (int i = 0; i < dailyPrices.length; i++) {
      final price = dailyPrices[i];
      
      if (currentMonth.isEmpty) {
        currentMonth.add(price);
        continue;
      }

      final firstMonth = currentMonth.first.date.month;
      final firstYear = currentMonth.first.date.year;
      
      // 如果屬於同一個月，加入當前月
      if (price.date.month == firstMonth && price.date.year == firstYear) {
        currentMonth.add(price);
      } else {
        // 完成當前月的聚合
        if (currentMonth.isNotEmpty) {
          monthlyCandles.add(_aggregatePeriod(currentMonth));
        }
        // 開始新的一個月
        currentMonth = [price];
      }
    }

    // 處理最後一個月
    if (currentMonth.isNotEmpty) {
      monthlyCandles.add(_aggregatePeriod(currentMonth));
    }

    return monthlyCandles;
  }

  /// 將日K聚合為季K
  static List<StockPrice> aggregateToQuarterly(List<StockPrice> dailyPrices) {
    if (dailyPrices.isEmpty) return [];

    final List<StockPrice> quarterlyCandles = [];
    List<StockPrice> currentQuarter = [];

    for (int i = 0; i < dailyPrices.length; i++) {
      final price = dailyPrices[i];
      
      if (currentQuarter.isEmpty) {
        currentQuarter.add(price);
        continue;
      }

      final firstQuarter = _getQuarter(currentQuarter.first.date);
      final firstYear = currentQuarter.first.date.year;
      final currentQuarterNum = _getQuarter(price.date);
      
      // 如果屬於同一個季度，加入當前季度
      if (currentQuarterNum == firstQuarter && price.date.year == firstYear) {
        currentQuarter.add(price);
      } else {
        // 完成當前季度的聚合
        if (currentQuarter.isNotEmpty) {
          quarterlyCandles.add(_aggregatePeriod(currentQuarter));
        }
        // 開始新的一個季度
        currentQuarter = [price];
      }
    }

    // 處理最後一個季度
    if (currentQuarter.isNotEmpty) {
      quarterlyCandles.add(_aggregatePeriod(currentQuarter));
    }

    return quarterlyCandles;
  }

  /// 將日K聚合為年K
  static List<StockPrice> aggregateToYearly(List<StockPrice> dailyPrices) {
    if (dailyPrices.isEmpty) return [];

    final List<StockPrice> yearlyCandles = [];
    List<StockPrice> currentYear = [];

    for (int i = 0; i < dailyPrices.length; i++) {
      final price = dailyPrices[i];
      
      if (currentYear.isEmpty) {
        currentYear.add(price);
        continue;
      }

      final firstYear = currentYear.first.date.year;
      
      // 如果屬於同一年，加入當前年
      if (price.date.year == firstYear) {
        currentYear.add(price);
      } else {
        // 完成當年的聚合
        if (currentYear.isNotEmpty) {
          yearlyCandles.add(_aggregatePeriod(currentYear));
        }
        // 開始新的一年
        currentYear = [price];
      }
    }

    // 處理最後一年
    if (currentYear.isNotEmpty) {
      yearlyCandles.add(_aggregatePeriod(currentYear));
    }

    return yearlyCandles;
  }

  /// 獲取日期所在的季度（1-4）
  static int _getQuarter(DateTime date) {
    if (date.month <= 3) return 1;
    if (date.month <= 6) return 2;
    if (date.month <= 9) return 3;
    return 4;
  }

  /// 聚合一個時間段內的日K數據
  /// 規則：使用第一個交易日的開盤價、最後一個交易日的收盤價、
  /// 期間的最高價和最低價、期間的總交易量
  static StockPrice _aggregatePeriod(List<StockPrice> periodPrices) {
    if (periodPrices.isEmpty) {
      throw ArgumentError('periodPrices cannot be empty');
    }

    if (periodPrices.length == 1) {
      return periodPrices.first;
    }

    final first = periodPrices.first;
    final last = periodPrices.last;
    
    double high = periodPrices.map((p) => p.high).reduce((a, b) => a > b ? a : b);
    double low = periodPrices.map((p) => p.low).reduce((a, b) => a < b ? a : b);
    int volume = periodPrices.map((p) => p.volume).reduce((a, b) => a + b);

    return StockPrice(
      id: first.id, // 保留第一個的ID（如果有的話）
      ticker: first.ticker,
      date: first.date, // 使用第一個交易日的日期
      open: first.open,
      close: last.close,
      high: high,
      low: low,
      volume: volume,
    );
  }
}

