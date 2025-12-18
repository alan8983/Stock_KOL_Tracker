import 'package:flutter_test/flutter_test.dart';
import 'package:stock_kol_tracker/core/utils/price_change_calculator.dart';
import 'package:stock_kol_tracker/data/database/database.dart';

void main() {
  late PriceChangeCalculator calculator;

  setUp(() {
    calculator = PriceChangeCalculator();
  });

  group('PriceChangeCalculator', () {
    test('計算正常情況的漲跌幅', () {
      // 準備測試資料：基準價 100，5天後價格 105
      final prices = [
        StockPrice(
          id: 1,
          ticker: 'AAPL',
          date: DateTime(2023, 6, 1),
          open: 100.0,
          close: 100.0,
          high: 101.0,
          low: 99.0,
          volume: 1000000,
        ),
        StockPrice(
          id: 2,
          ticker: 'AAPL',
          date: DateTime(2023, 6, 6),
          open: 104.0,
          close: 105.0,
          high: 106.0,
          low: 103.0,
          volume: 1100000,
        ),
      ];

      final baseDate = DateTime(2023, 6, 1);
      final change = calculator.calculateChange(
        prices: prices,
        baseDate: baseDate,
        periodDays: 5,
      );

      expect(change, isNotNull);
      expect(change, closeTo(5.0, 0.01)); // (105-100)/100 * 100 = 5%
    });

    test('計算跌幅', () {
      // 準備測試資料：基準價 100，5天後價格 95
      final prices = [
        StockPrice(
          id: 1,
          ticker: 'AAPL',
          date: DateTime(2023, 6, 1),
          open: 100.0,
          close: 100.0,
          high: 101.0,
          low: 99.0,
          volume: 1000000,
        ),
        StockPrice(
          id: 2,
          ticker: 'AAPL',
          date: DateTime(2023, 6, 6),
          open: 96.0,
          close: 95.0,
          high: 97.0,
          low: 94.0,
          volume: 1200000,
        ),
      ];

      final baseDate = DateTime(2023, 6, 1);
      final change = calculator.calculateChange(
        prices: prices,
        baseDate: baseDate,
        periodDays: 5,
      );

      expect(change, isNotNull);
      expect(change, closeTo(-5.0, 0.01)); // (95-100)/100 * 100 = -5%
    });

    test('目標日期資料不足時返回 null', () {
      // 準備測試資料：只有基準日資料，沒有目標日資料
      final prices = [
        StockPrice(
          id: 1,
          ticker: 'AAPL',
          date: DateTime(2023, 6, 1),
          open: 100.0,
          close: 100.0,
          high: 101.0,
          low: 99.0,
          volume: 1000000,
        ),
      ];

      final baseDate = DateTime(2023, 6, 1);
      final change = calculator.calculateChange(
        prices: prices,
        baseDate: baseDate,
        periodDays: 30,
      );

      expect(change, isNull);
    });

    test('交易日對齊：基準日是週末，應找到最近的交易日', () {
      // 準備測試資料：週五和下週一的資料
      final prices = [
        StockPrice(
          id: 1,
          ticker: 'AAPL',
          date: DateTime(2023, 6, 2), // 週五
          open: 100.0,
          close: 100.0,
          high: 101.0,
          low: 99.0,
          volume: 1000000,
        ),
        StockPrice(
          id: 2,
          ticker: 'AAPL',
          date: DateTime(2023, 6, 5), // 下週一
          open: 104.0,
          close: 105.0,
          high: 106.0,
          low: 103.0,
          volume: 1100000,
        ),
      ];

      // 基準日設為週六（2023-06-03），應該找到週五的資料
      final baseDate = DateTime(2023, 6, 3); // 週六
      final change = calculator.calculateChange(
        prices: prices,
        baseDate: baseDate,
        periodDays: 2,
      );

      expect(change, isNotNull);
      expect(change, closeTo(5.0, 0.01)); // 週五 100 -> 週一 105
    });

    test('批次計算多個時間區間', () {
      // 準備測試資料：覆蓋 365 天的資料
      final prices = [
        StockPrice(
          id: 1,
          ticker: 'AAPL',
          date: DateTime(2023, 1, 1),
          open: 100.0,
          close: 100.0,
          high: 101.0,
          low: 99.0,
          volume: 1000000,
        ),
        StockPrice(
          id: 2,
          ticker: 'AAPL',
          date: DateTime(2023, 1, 6), // 5天後
          open: 102.0,
          close: 102.0,
          high: 103.0,
          low: 101.0,
          volume: 1100000,
        ),
        StockPrice(
          id: 3,
          ticker: 'AAPL',
          date: DateTime(2023, 1, 31), // 30天後
          open: 110.0,
          close: 110.0,
          high: 111.0,
          low: 109.0,
          volume: 1200000,
        ),
        StockPrice(
          id: 4,
          ticker: 'AAPL',
          date: DateTime(2023, 3, 31), // 90天後（約）
          open: 115.0,
          close: 115.0,
          high: 116.0,
          low: 114.0,
          volume: 1300000,
        ),
        StockPrice(
          id: 5,
          ticker: 'AAPL',
          date: DateTime(2024, 1, 1), // 365天後
          open: 120.0,
          close: 120.0,
          high: 121.0,
          low: 119.0,
          volume: 1400000,
        ),
      ];

      final baseDate = DateTime(2023, 1, 1);
      final changes = calculator.calculateMultiplePeriods(
        prices: prices,
        baseDate: baseDate,
        periods: [5, 30, 90, 365],
      );

      expect(changes[5], isNotNull);
      expect(changes[5], closeTo(2.0, 0.01)); // (102-100)/100 * 100 = 2%
      
      expect(changes[30], isNotNull);
      expect(changes[30], closeTo(10.0, 0.01)); // (110-100)/100 * 100 = 10%
      
      expect(changes[90], isNotNull);
      expect(changes[90], closeTo(15.0, 0.01)); // (115-100)/100 * 100 = 15%
      
      expect(changes[365], isNotNull);
      expect(changes[365], closeTo(20.0, 0.01)); // (120-100)/100 * 100 = 20%
    });

    test('空資料列表時返回 null', () {
      final prices = <StockPrice>[];
      final baseDate = DateTime(2023, 6, 1);
      
      final change = calculator.calculateChange(
        prices: prices,
        baseDate: baseDate,
        periodDays: 5,
      );

      expect(change, isNull);
    });

    test('基準日期太早，沒有資料時返回 null', () {
      final prices = [
        StockPrice(
          id: 1,
          ticker: 'AAPL',
          date: DateTime(2023, 6, 10),
          open: 100.0,
          close: 100.0,
          high: 101.0,
          low: 99.0,
          volume: 1000000,
        ),
      ];

      // 基準日期是 6/1，但最早的資料是 6/10（超過 7 天回溯範圍）
      final baseDate = DateTime(2023, 6, 1);
      final change = calculator.calculateChange(
        prices: prices,
        baseDate: baseDate,
        periodDays: 5,
      );

      expect(change, isNull);
    });
  });
}
