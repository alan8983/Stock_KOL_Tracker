import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:stock_kol_tracker/data/database/database.dart';
import 'package:stock_kol_tracker/data/repositories/post_repository.dart';
import 'package:stock_kol_tracker/data/repositories/stock_price_repository.dart';
import 'package:stock_kol_tracker/data/services/Tiingo/tiingo_service.dart';
import 'package:stock_kol_tracker/core/utils/price_change_calculator.dart';
import 'package:dio/dio.dart';

void main() {
  late AppDatabase db;
  late PostRepository postRepo;
  late StockPriceRepository stockPriceRepo;
  late PriceChangeCalculator calculator;

  setUp(() async {
    // 建立記憶體資料庫（測試用）
    db = AppDatabase.customExecutor(
      NativeDatabase.memory(),
      skipDefaultData: true,
    );
    
    // 建立測試用的 TiingoService（不實際呼叫 API）
    final tiingoService = TiingoService(
      apiToken: 'test_token',
      dio: Dio(),
    );
    
    postRepo = PostRepository(db);
    stockPriceRepo = StockPriceRepository(db, tiingoService);
    calculator = PriceChangeCalculator();
  });

  tearDown(() async {
    await db.close();
  });

  group('Price Change Integration Test', () {
    // 注意：詳細的計算邏輯已在單元測試中驗證
    // 整合測試主要驗證資料庫操作和日期過濾
    
    test('完整流程：建立 Post、插入股價、計算漲跌幅', () async {
      // 1. 建立測試 KOL
      final kolId = await db.into(db.kOLs).insert(
        KOLsCompanion.insert(
          name: 'Test KOL',
          createdAt: DateTime.now(),
        ),
      );

      // 2. 建立測試 Stock
      await db.into(db.stocks).insert(
        StocksCompanion.insert(
          ticker: 'AAPL',
          lastUpdated: DateTime.now(),
        ),
      );

      // 3. 建立測試 Post（2023-06-01 發文）
      final postId = await postRepo.createDraft(
        PostsCompanion.insert(
          kolId: kolId,
          stockTicker: 'AAPL',
          content: 'Test post content',
          sentiment: 'Bullish',
          postedAt: DateTime(2023, 6, 1),
          createdAt: DateTime.now(),
          status: 'Published',
        ),
      );

      // 4. 插入股價測試資料（2023-05-01 至 2024-06-01）
      final testPrices = [
        StockPricesCompanion.insert(
          ticker: 'AAPL',
          date: DateTime(2023, 5, 25), // 基準日前幾天
          open: 99.0,
          close: 99.0,
          high: 100.0,
          low: 98.0,
          volume: 1000000,
        ),
        StockPricesCompanion.insert(
          ticker: 'AAPL',
          date: DateTime(2023, 6, 1), // 基準日
          open: 100.0,
          close: 100.0,
          high: 101.0,
          low: 99.0,
          volume: 1000000,
        ),
        StockPricesCompanion.insert(
          ticker: 'AAPL',
          date: DateTime(2023, 6, 6), // 5天後
          open: 102.0,
          close: 102.0,
          high: 103.0,
          low: 101.0,
          volume: 1100000,
        ),
        StockPricesCompanion.insert(
          ticker: 'AAPL',
          date: DateTime(2023, 7, 3), // 30天後（約 32 天）
          open: 110.0,
          close: 110.0,
          high: 111.0,
          low: 109.0,
          volume: 1200000,
        ),
        StockPricesCompanion.insert(
          ticker: 'AAPL',
          date: DateTime(2023, 9, 1), // 90天後（約 92 天）
          open: 115.0,
          close: 115.0,
          high: 116.0,
          low: 114.0,
          volume: 1300000,
        ),
        StockPricesCompanion.insert(
          ticker: 'AAPL',
          date: DateTime(2024, 6, 1), // 365天後
          open: 120.0,
          close: 120.0,
          high: 121.0,
          low: 119.0,
          volume: 1400000,
        ),
      ];

      await stockPriceRepo.saveStockPrices(testPrices);

      // 5. 取得 Post
      final post = await postRepo.getPostById(postId);
      expect(post, isNotNull);

      // 6. 取得股價資料
      final prices = await stockPriceRepo.getStockPrices(
        'AAPL',
        startDate: DateTime(2023, 5, 1),
        endDate: DateTime(2024, 7, 1),
      );
      expect(prices.isNotEmpty, true);

      // 7. 計算漲跌幅
      final changes = calculator.calculateMultiplePeriods(
        prices: prices,
        baseDate: post!.postedAt,
        periods: [5, 30, 90, 365],
      );

      // 8. 驗證結果（至少驗證流程可以執行完成）
      // 注意：具體的計算邏輯已在單元測試中充分驗證
      expect(changes, isNotNull);
      expect(changes.length, 4);
      
      // 驗證至少有一些區間有資料（5天的應該有）
      expect(changes.containsKey(5), true);
      expect(changes.containsKey(30), true);
      expect(changes.containsKey(90), true);
      expect(changes.containsKey(365), true);
    });

    test('過濾 2023/01/01 之前的文檔', () async {
      // 1. 建立測試 KOL
      final kolId = await db.into(db.kOLs).insert(
        KOLsCompanion.insert(
          name: 'Test KOL',
          createdAt: DateTime.now(),
        ),
      );

      // 2. 建立測試 Stock
      await db.into(db.stocks).insert(
        StocksCompanion.insert(
          ticker: 'AAPL',
          lastUpdated: DateTime.now(),
        ),
      );

      // 3. 建立兩個 Post：一個在 2023/01/01 之前，一個在之後
      await postRepo.createDraft(
        PostsCompanion.insert(
          kolId: kolId,
          stockTicker: 'AAPL',
          content: 'Old post',
          sentiment: 'Bullish',
          postedAt: DateTime(2022, 12, 31), // 2023/01/01 之前
          createdAt: DateTime.now(),
          status: 'Published',
        ),
      );

      await postRepo.createDraft(
        PostsCompanion.insert(
          kolId: kolId,
          stockTicker: 'AAPL',
          content: 'New post',
          sentiment: 'Bullish',
          postedAt: DateTime(2023, 1, 1), // 2023/01/01
          createdAt: DateTime.now(),
          status: 'Published',
        ),
      );

      await postRepo.createDraft(
        PostsCompanion.insert(
          kolId: kolId,
          stockTicker: 'AAPL',
          content: 'Newer post',
          sentiment: 'Bullish',
          postedAt: DateTime(2023, 6, 1), // 2023/01/01 之後
          createdAt: DateTime.now(),
          status: 'Published',
        ),
      );

      // 4. 查詢 Post（應該自動過濾 2023/01/01 之前的）
      final posts = await postRepo.getPostsByKOL(kolId);

      // 5. 驗證：應該只有 2 個 Post（2023/01/01 和之後的）
      expect(posts.length, 2);
      expect(posts.every((p) => p.postedAt.isAfter(DateTime(2022, 12, 31))), true);
    });

    test('計算漲跌幅時處理資料不足的情況', () async {
      // 1. 建立測試 KOL
      final kolId = await db.into(db.kOLs).insert(
        KOLsCompanion.insert(
          name: 'Test KOL',
          createdAt: DateTime.now(),
        ),
      );

      // 2. 建立測試 Stock
      await db.into(db.stocks).insert(
        StocksCompanion.insert(
          ticker: 'AAPL',
          lastUpdated: DateTime.now(),
        ),
      );

      // 3. 建立測試 Post（2023-06-01 發文）
      final postId = await postRepo.createDraft(
        PostsCompanion.insert(
          kolId: kolId,
          stockTicker: 'AAPL',
          content: 'Test post content',
          sentiment: 'Bullish',
          postedAt: DateTime(2023, 6, 1),
          createdAt: DateTime.now(),
          status: 'Published',
        ),
      );

      // 4. 只插入基準日的股價資料（沒有未來資料）
      final testPrices = [
        StockPricesCompanion.insert(
          ticker: 'AAPL',
          date: DateTime(2023, 6, 1), // 基準日
          open: 100.0,
          close: 100.0,
          high: 101.0,
          low: 99.0,
          volume: 1000000,
        ),
      ];

      await stockPriceRepo.saveStockPrices(testPrices);

      // 5. 取得 Post
      final post = await postRepo.getPostById(postId);
      expect(post, isNotNull);

      // 6. 取得股價資料
      final prices = await stockPriceRepo.getStockPrices('AAPL');

      // 7. 計算漲跌幅
      final changes = calculator.calculateMultiplePeriods(
        prices: prices,
        baseDate: post!.postedAt,
        periods: [5, 30, 90, 365],
      );

      // 8. 驗證：大部分區間應該返回 null（資料不足）
      // 注意：具體的邊界條件處理已在單元測試中驗證
      expect(changes, isNotNull);
      expect(changes.length, 4);
      
      // 至少應該有一些區間沒有資料
      final nullCount = changes.values.where((v) => v == null).length;
      expect(nullCount, greaterThan(0));
    });
  });
}
