import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';
import '../../data/models/stock_stats.dart';
import 'repository_providers.dart';
import 'price_change_provider.dart';

/// 單一股票的統計 Provider
final stockStatsProvider = FutureProvider.family<StockStats, String>(
  (ref, ticker) async {
    // 1. 獲取該股票的所有 Post（2023/01/01 後）
    final postRepo = ref.watch(postRepositoryProvider);
    final posts = await postRepo.getPostsByStock(ticker);

    // 2. 獲取股票資訊
    final stockRepo = ref.watch(stockRepositoryProvider);
    final stock = await stockRepo.getStockByTicker(ticker);

    if (posts.isEmpty) {
      return StockStats(
        ticker: ticker,
        stockName: stock?.name,
        totalPosts: 0,
        kolCount: 0,
        bullishCount: 0,
        bearishCount: 0,
        neutralCount: 0,
        avgPriceChanges: {},
      );
    }

    // 3. 計算討論統計
    final totalPosts = posts.length;
    final kolIds = posts.map((p) => p.kolId).toSet();
    final kolCount = kolIds.length;
    final bullishCount = posts.where((p) => p.sentiment == 'Bullish').length;
    final bearishCount = posts.where((p) => p.sentiment == 'Bearish').length;
    final neutralCount = posts.where((p) => p.sentiment == 'Neutral').length;

    // 4. 計算近期平均漲跌幅
    final avgPriceChanges = <int, double?>{};
    
    for (final period in [5, 30, 90, 365]) {
      final changes = <double>[];
      
      for (final post in posts) {
        try {
          final priceChange = await ref.watch(postPriceChangeProvider(post.id).future);
          final change = priceChange.changes[period];
          if (change != null) {
            changes.add(change);
          }
        } catch (e) {
          // 忽略計算失敗的 Post
        }
      }
      
      if (changes.isNotEmpty) {
        avgPriceChanges[period] = changes.average;
      } else {
        avgPriceChanges[period] = null;
      }
    }

    // 5. 返回結果
    return StockStats(
      ticker: ticker,
      stockName: stock?.name,
      totalPosts: totalPosts,
      kolCount: kolCount,
      bullishCount: bullishCount,
      bearishCount: bearishCount,
      neutralCount: neutralCount,
      avgPriceChanges: avgPriceChanges,
    );
  },
);

/// 所有股票的統計 Provider（用於列表）
final allStockStatsProvider = FutureProvider<List<StockStats>>(
  (ref) async {
    // 1. 獲取所有股票
    final stockRepo = ref.watch(stockRepositoryProvider);
    final stocks = await stockRepo.getAllStocks();

    // 過濾掉「臨時」股票 (ticker='TEMP')
    final validStocks = stocks.where((stock) => stock.ticker != 'TEMP').toList();

    if (validStocks.isEmpty) {
      return [];
    }

    // 2. 批次計算每個股票的統計
    final statsList = <StockStats>[];
    
    for (final stock in validStocks) {
      try {
        final stats = await ref.watch(stockStatsProvider(stock.ticker).future);
        // 只包含有討論的股票
        if (stats.totalPosts > 0) {
          statsList.add(stats);
        }
      } catch (e) {
        // 如果某個股票計算失敗，繼續處理其他股票
        continue;
      }
    }

    // 3. 按討論次數排序（降序）
    statsList.sort((a, b) => b.totalPosts.compareTo(a.totalPosts));

    return statsList;
  },
);
