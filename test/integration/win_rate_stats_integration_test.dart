import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:stock_kol_tracker/data/database/database.dart';
import 'package:stock_kol_tracker/data/repositories/post_repository.dart';
import 'package:stock_kol_tracker/data/repositories/stock_price_repository.dart';
import 'package:stock_kol_tracker/data/services/Tiingo/tiingo_service.dart';
import 'package:stock_kol_tracker/core/utils/win_rate_calculator.dart';
import 'package:dio/dio.dart';

void main() {
  late AppDatabase db;
  late PostRepository postRepo;
  late StockPriceRepository stockPriceRepo;
  late WinRateCalculator calculator;

  setUp(() async {
    // 建立記憶體資料庫（測試用）
    db = AppDatabase.customExecutor(
      NativeDatabase.memory(),
      skipDefaultData: true,
    );
    
    // 建立測試用的 TiingoService
    final tiingoService = TiingoService(
      apiToken: 'test_token',
      dio: Dio(),
    );
    
    postRepo = PostRepository(db);
    stockPriceRepo = StockPriceRepository(db, tiingoService);
    calculator = WinRateCalculator();
  });

  tearDown(() async {
    await db.close();
  });

  group('Win Rate Stats Integration Test', () {
    test('完整流程：建立 KOL、Posts、計算勝率', () async {
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

      // 3. 建立測試 Posts
      final posts = <Post>[];
      
      // Post 1: Bullish + 漲幅 5% = 正確
      final postId1 = await postRepo.createDraft(
        PostsCompanion.insert(
          kolId: kolId,
          stockTicker: 'AAPL',
          content: 'Bullish test 1',
          sentiment: 'Bullish',
          postedAt: DateTime(2023, 6, 1),
          createdAt: DateTime.now(),
          status: 'Published',
        ),
      );
      posts.add((await postRepo.getPostById(postId1))!);

      // Post 2: Bearish + 跌幅 4% = 正確
      final postId2 = await postRepo.createDraft(
        PostsCompanion.insert(
          kolId: kolId,
          stockTicker: 'AAPL',
          content: 'Bearish test 1',
          sentiment: 'Bearish',
          postedAt: DateTime(2023, 6, 8),
          createdAt: DateTime.now(),
          status: 'Published',
        ),
      );
      posts.add((await postRepo.getPostById(postId2))!);

      // Post 3: Bullish + 跌幅 3% = 錯誤
      final postId3 = await postRepo.createDraft(
        PostsCompanion.insert(
          kolId: kolId,
          stockTicker: 'AAPL',
          content: 'Bullish test 2',
          sentiment: 'Bullish',
          postedAt: DateTime(2023, 6, 15),
          createdAt: DateTime.now(),
          status: 'Published',
        ),
      );
      posts.add((await postRepo.getPostById(postId3))!);

      // Post 4: Bullish + 漲幅 1% = 震盪（不計入）
      final postId4 = await postRepo.createDraft(
        PostsCompanion.insert(
          kolId: kolId,
          stockTicker: 'AAPL',
          content: 'Bullish test 3',
          sentiment: 'Bullish',
          postedAt: DateTime(2023, 6, 22),
          createdAt: DateTime.now(),
          status: 'Published',
        ),
      );
      posts.add((await postRepo.getPostById(postId4))!);

      // Post 5: Neutral = 不計入
      final postId5 = await postRepo.createDraft(
        PostsCompanion.insert(
          kolId: kolId,
          stockTicker: 'AAPL',
          content: 'Neutral test',
          sentiment: 'Neutral',
          postedAt: DateTime(2023, 6, 29),
          createdAt: DateTime.now(),
          status: 'Published',
        ),
      );
      posts.add((await postRepo.getPostById(postId5))!);

      // 4. 插入股價資料
      final testPrices = [
        // Post 1: 6/1 基準價 100, 6/6 目標價 105 (漲幅 5%)
        StockPricesCompanion.insert(
          ticker: 'AAPL',
          date: DateTime(2023, 6, 1),
          open: 100.0,
          close: 100.0,
          high: 101.0,
          low: 99.0,
          volume: 1000000,
        ),
        StockPricesCompanion.insert(
          ticker: 'AAPL',
          date: DateTime(2023, 6, 6),
          open: 104.0,
          close: 105.0,
          high: 106.0,
          low: 103.0,
          volume: 1100000,
        ),
        
        // Post 2: 6/8 基準價 100, 6/13 目標價 96 (跌幅 4%)
        StockPricesCompanion.insert(
          ticker: 'AAPL',
          date: DateTime(2023, 6, 8),
          open: 100.0,
          close: 100.0,
          high: 101.0,
          low: 99.0,
          volume: 1000000,
        ),
        StockPricesCompanion.insert(
          ticker: 'AAPL',
          date: DateTime(2023, 6, 13),
          open: 96.5,
          close: 96.0,
          high: 97.0,
          low: 95.0,
          volume: 1200000,
        ),
        
        // Post 3: 6/15 基準價 100, 6/20 目標價 97 (跌幅 3%)
        StockPricesCompanion.insert(
          ticker: 'AAPL',
          date: DateTime(2023, 6, 15),
          open: 100.0,
          close: 100.0,
          high: 101.0,
          low: 99.0,
          volume: 1000000,
        ),
        StockPricesCompanion.insert(
          ticker: 'AAPL',
          date: DateTime(2023, 6, 20),
          open: 97.5,
          close: 97.0,
          high: 98.0,
          low: 96.0,
          volume: 1150000,
        ),
        
        // Post 4: 6/22 基準價 100, 6/27 目標價 101 (漲幅 1%)
        StockPricesCompanion.insert(
          ticker: 'AAPL',
          date: DateTime(2023, 6, 22),
          open: 100.0,
          close: 100.0,
          high: 101.0,
          low: 99.0,
          volume: 1050000,
        ),
        StockPricesCompanion.insert(
          ticker: 'AAPL',
          date: DateTime(2023, 6, 27),
          open: 100.5,
          close: 101.0,
          high: 102.0,
          low: 100.0,
          volume: 1050000,
        ),
        
        // Post 5: 6/29 基準價 100, 7/4 目標價 105 (任意，不影響結果)
        StockPricesCompanion.insert(
          ticker: 'AAPL',
          date: DateTime(2023, 6, 29),
          open: 100.0,
          close: 100.0,
          high: 101.0,
          low: 99.0,
          volume: 1000000,
        ),
        StockPricesCompanion.insert(
          ticker: 'AAPL',
          date: DateTime(2023, 7, 4),
          open: 104.0,
          close: 105.0,
          high: 106.0,
          low: 103.0,
          volume: 1100000,
        ),
      ];

      await stockPriceRepo.saveStockPrices(testPrices);

      // 5. 獲取股價資料並計算漲跌幅
      final prices = await stockPriceRepo.getStockPrices('AAPL');
      final priceChanges = <int, Map<int, double?>>{};
      
      for (final post in posts) {
        // 簡化：只計算 5 天的漲跌幅
        final basePrice = prices.firstWhere(
          (p) => p.date.year == post.postedAt.year &&
                 p.date.month == post.postedAt.month &&
                 p.date.day == post.postedAt.day,
          orElse: () => prices.first,
        );
        
        final targetDate = post.postedAt.add(const Duration(days: 5));
        final targetPrice = prices.firstWhere(
          (p) => p.date.year == targetDate.year &&
                 p.date.month == targetDate.month &&
                 p.date.day == targetDate.day,
          orElse: () => prices.last,
        );
        
        final change = ((targetPrice.close - basePrice.close) / basePrice.close) * 100;
        priceChanges[post.id] = {5: change};
      }

      // 6. 評估預測結果
      final results = calculator.batchEvaluate(
        posts: posts,
        priceChanges: priceChanges,
        period: 5,
      );

      // 7. 驗證結果
      expect(results[postId1]?.outcome, PredictionOutcome.correct); // Bullish + 漲
      expect(results[postId2]?.outcome, PredictionOutcome.correct); // Bearish + 跌
      expect(results[postId3]?.outcome, PredictionOutcome.incorrect); // Bullish + 跌
      expect(results[postId4]?.outcome, PredictionOutcome.neutral); // 震盪
      expect(results[postId5]?.outcome, PredictionOutcome.notApplicable); // Neutral

      // 8. 計算勝率
      int correct = 0;
      int incorrect = 0;
      int neutral = 0;
      int notApplicable = 0;

      for (final result in results.values) {
        switch (result.outcome) {
          case PredictionOutcome.correct:
            correct++;
            break;
          case PredictionOutcome.incorrect:
            incorrect++;
            break;
          case PredictionOutcome.neutral:
            neutral++;
            break;
          case PredictionOutcome.notApplicable:
            notApplicable++;
            break;
        }
      }

      expect(correct, 2); // Post 1, 2
      expect(incorrect, 1); // Post 3
      expect(neutral, 1); // Post 4
      expect(notApplicable, 1); // Post 5

      final totalPredictions = correct + incorrect;
      final winRate = (correct / totalPredictions) * 100;

      expect(totalPredictions, 3);
      expect(winRate, closeTo(66.67, 0.01)); // 2/3 = 66.67%
    });

    test('勝率計算：只有 Neutral 的情況', () async {
      // 1. 建立測試 KOL
      final kolId = await db.into(db.kOLs).insert(
        KOLsCompanion.insert(
          name: 'Neutral KOL',
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

      // 3. 建立 3 個 Neutral Posts
      final posts = <Post>[];
      for (int i = 0; i < 3; i++) {
        final postId = await postRepo.createDraft(
          PostsCompanion.insert(
            kolId: kolId,
            stockTicker: 'AAPL',
            content: 'Neutral post $i',
            sentiment: 'Neutral',
            postedAt: DateTime(2023, 6, i + 1),
            createdAt: DateTime.now(),
            status: 'Published',
          ),
        );
        posts.add((await postRepo.getPostById(postId))!);
      }

      // 4. 模擬漲跌幅資料
      final priceChanges = <int, Map<int, double?>>{};
      for (final post in posts) {
        priceChanges[post.id] = {5: 5.0}; // 任意漲幅
      }

      // 5. 評估結果
      final results = calculator.batchEvaluate(
        posts: posts,
        priceChanges: priceChanges,
        period: 5,
      );

      // 6. 驗證：所有都應該是 notApplicable
      for (final result in results.values) {
        expect(result.outcome, PredictionOutcome.notApplicable);
      }

      // 計算勝率時應該沒有有效預測
      final validPredictions = results.values.where((r) => r.countsTowardWinRate).length;
      expect(validPredictions, 0);
    });
  });
}
