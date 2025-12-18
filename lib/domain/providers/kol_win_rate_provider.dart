import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/win_rate_stats.dart';
import '../../core/utils/win_rate_calculator.dart';
import 'repository_providers.dart';
import 'price_change_provider.dart';

/// KOL 勝率統計資料
class KOLWinRateStats {
  final int kolId;
  final String kolName;
  
  // 基本統計
  final int totalPosts;
  final int stockCount;
  final int bullishCount;
  final int bearishCount;
  final int neutralCount;
  
  // 勝率統計
  final MultiPeriodWinRateStats winRateStats;

  const KOLWinRateStats({
    required this.kolId,
    required this.kolName,
    required this.totalPosts,
    required this.stockCount,
    required this.bullishCount,
    required this.bearishCount,
    required this.neutralCount,
    required this.winRateStats,
  });

  /// 看多比例（0.0 ~ 1.0）
  double get bullishRatio => totalPosts > 0 ? bullishCount / totalPosts : 0.0;

  /// 看空比例（0.0 ~ 1.0）
  double get bearishRatio => totalPosts > 0 ? bearishCount / totalPosts : 0.0;

  /// 中立比例（0.0 ~ 1.0）
  double get neutralRatio => totalPosts > 0 ? neutralCount / totalPosts : 0.0;

  /// 主要情緒傾向
  String get dominantSentiment {
    if (bullishCount >= bearishCount && bullishCount >= neutralCount) {
      return 'Bullish';
    } else if (bearishCount >= neutralCount) {
      return 'Bearish';
    } else {
      return 'Neutral';
    }
  }

  /// 綜合評級（根據勝率和文檔數量）
  String get overallRating {
    final avgWinRate = winRateStats.averageWinRate;
    
    if (totalPosts < 10) return 'N/A';
    
    if (avgWinRate >= 70 && totalPosts >= 30) return 'A+';
    if (avgWinRate >= 65 && totalPosts >= 20) return 'A';
    if (avgWinRate >= 60 && totalPosts >= 15) return 'B+';
    if (avgWinRate >= 55 && totalPosts >= 10) return 'B';
    if (avgWinRate >= 50) return 'C';
    return 'D';
  }

  @override
  String toString() {
    return 'KOLWinRateStats(kolId: $kolId, name: $kolName, '
        'avgWinRate: ${winRateStats.averageWinRate.toStringAsFixed(1)}%, '
        'posts: $totalPosts, rating: $overallRating)';
  }
}

/// 單一 KOL 的勝率統計 Provider
final kolWinRateStatsProvider = FutureProvider.family<KOLWinRateStats, int>(
  (ref, kolId) async {
    // 1. 獲取 KOL 資訊
    final kolRepo = ref.watch(kolRepositoryProvider);
    final kol = await kolRepo.getKOLById(kolId);
    
    if (kol == null) {
      throw Exception('KOL not found: $kolId');
    }

    // 2. 獲取 KOL 的所有 Post（2023/01/01 後）
    final postRepo = ref.watch(postRepositoryProvider);
    final posts = await postRepo.getPostsByKOL(kolId);

    if (posts.isEmpty) {
      return KOLWinRateStats(
        kolId: kolId,
        kolName: kol.name,
        totalPosts: 0,
        stockCount: 0,
        bullishCount: 0,
        bearishCount: 0,
        neutralCount: 0,
        winRateStats: const MultiPeriodWinRateStats(periodStats: {}),
      );
    }

    // 3. 計算基本統計
    final totalPosts = posts.length;
    final stockCount = posts.map((p) => p.stockTicker).toSet().length;
    final bullishCount = posts.where((p) => p.sentiment == 'Bullish').length;
    final bearishCount = posts.where((p) => p.sentiment == 'Bearish').length;
    final neutralCount = posts.where((p) => p.sentiment == 'Neutral').length;

    // 4. 批次計算所有 Post 的漲跌幅
    final priceChanges = <int, Map<int, double?>>{};
    
    for (final post in posts) {
      try {
        final priceChange = await ref.watch(postPriceChangeProvider(post.id).future);
        priceChanges[post.id] = priceChange.changes;
      } catch (e) {
        // 如果某個 Post 計算失敗，使用空資料
        priceChanges[post.id] = {5: null, 30: null, 90: null, 365: null};
      }
    }

    // 5. 計算勝率統計
    final calculator = WinRateCalculator();
    final periodStats = <int, WinRateStats>{};

    for (final period in [5, 30, 90, 365]) {
      final results = calculator.batchEvaluate(
        posts: posts,
        priceChanges: priceChanges,
        period: period,
      );

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

      periodStats[period] = WinRateStats(
        period: period,
        totalPredictions: correct + incorrect,
        correctPredictions: correct,
        incorrectPredictions: incorrect,
        neutralCount: neutral,
        notApplicableCount: notApplicable,
      );
    }

    // 6. 返回結果
    return KOLWinRateStats(
      kolId: kolId,
      kolName: kol.name,
      totalPosts: totalPosts,
      stockCount: stockCount,
      bullishCount: bullishCount,
      bearishCount: bearishCount,
      neutralCount: neutralCount,
      winRateStats: MultiPeriodWinRateStats(periodStats: periodStats),
    );
  },
);

/// 所有 KOL 的勝率統計 Provider（用於列表）
final allKOLWinRateStatsProvider = FutureProvider<List<KOLWinRateStats>>(
  (ref) async {
    // 1. 獲取所有 KOL
    final kolRepo = ref.watch(kolRepositoryProvider);
    final kols = await kolRepo.getAllKOLs();

    // 過濾掉「未分類」KOL (id=1)
    final validKols = kols.where((kol) => kol.id != 1).toList();

    if (validKols.isEmpty) {
      return [];
    }

    // 2. 批次計算每個 KOL 的勝率統計
    final statsList = <KOLWinRateStats>[];
    
    for (final kol in validKols) {
      try {
        final stats = await ref.watch(kolWinRateStatsProvider(kol.id).future);
        statsList.add(stats);
      } catch (e) {
        // 如果某個 KOL 計算失敗，繼續處理其他 KOL
        continue;
      }
    }

    // 3. 按平均勝率排序（降序）
    statsList.sort((a, b) => 
      b.winRateStats.averageWinRate.compareTo(a.winRateStats.averageWinRate)
    );

    return statsList;
  },
);
