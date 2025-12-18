import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/price_change_result.dart';
import '../../core/utils/price_change_calculator.dart';
import 'repository_providers.dart';

/// 提供 PriceChangeCalculator 實例
final priceChangeCalculatorProvider = Provider<PriceChangeCalculator>((ref) {
  return PriceChangeCalculator();
});

/// 單一 Post 的漲跌幅 Provider
/// 
/// 根據 postId 計算該貼文的股價漲跌幅
/// 支援 5、30、90、365 天四個時間區間
final postPriceChangeProvider = FutureProvider.family<PriceChangeResult, int>(
  (ref, postId) async {
    // 1. 獲取 Post 資訊
    final postRepo = ref.watch(postRepositoryProvider);
    final post = await postRepo.getPostById(postId);
    
    if (post == null) {
      throw Exception('Post not found: $postId');
    }

    // 2. 獲取股價資料
    final stockPriceRepo = ref.watch(stockPriceRepositoryProvider);
    
    // 計算需要的日期範圍：發文日期往前 7 天（以防週末），往後 365 + 7 天
    final startDate = post.postedAt.subtract(const Duration(days: 7));
    final endDate = post.postedAt.add(const Duration(days: 372));
    
    final prices = await stockPriceRepo.getStockPrices(
      post.stockTicker,
      startDate: startDate,
      endDate: endDate,
    );

    // 3. 計算漲跌幅
    final calculator = ref.watch(priceChangeCalculatorProvider);
    final changes = calculator.calculateMultiplePeriods(
      prices: prices,
      baseDate: post.postedAt,
      periods: [5, 30, 90, 365],
    );

    // 4. 返回結果
    return PriceChangeResult(
      postId: postId,
      ticker: post.stockTicker,
      postedAt: post.postedAt,
      changes: changes,
      calculatedAt: DateTime.now(),
    );
  },
);

/// 批次計算多個 Post 的漲跌幅 Provider
/// 
/// 用於列表頁面批次計算多個貼文的漲跌幅，提升效能
final batchPriceChangeProvider = FutureProvider.family<Map<int, PriceChangeResult>, List<int>>(
  (ref, postIds) async {
    final result = <int, PriceChangeResult>{};
    
    // 批次計算每個 Post 的漲跌幅
    for (final postId in postIds) {
      try {
        final priceChange = await ref.watch(postPriceChangeProvider(postId).future);
        result[postId] = priceChange;
      } catch (e) {
        // 如果某個 Post 計算失敗，繼續處理其他 Post
        // 靜默失敗，不影響其他 Post 的計算
      }
    }
    
    return result;
  },
);

/// Post 漲跌幅快取狀態
/// 
/// 用於檢查某個 Post 的漲跌幅是否已經計算過
class PriceChangeCache extends StateNotifier<Map<int, PriceChangeResult>> {
  PriceChangeCache() : super({});

  /// 更新快取
  void update(int postId, PriceChangeResult result) {
    state = {...state, postId: result};
  }

  /// 獲取快取
  PriceChangeResult? get(int postId) {
    return state[postId];
  }

  /// 清除快取
  void clear() {
    state = {};
  }

  /// 清除特定 Post 的快取
  void remove(int postId) {
    final newState = Map<int, PriceChangeResult>.from(state);
    newState.remove(postId);
    state = newState;
  }
}

/// 提供漲跌幅快取狀態
final priceChangeCacheProvider = StateNotifierProvider<PriceChangeCache, Map<int, PriceChangeResult>>((ref) {
  return PriceChangeCache();
});
