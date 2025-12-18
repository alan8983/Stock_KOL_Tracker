import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';
import '../../data/database/database.dart';
import '../../data/models/post_with_details.dart';
import 'repository_providers.dart';

/// 按 KOL 查詢文檔的 Provider（僅 Post）
final kolPostsProvider = FutureProvider.family<List<Post>, int>((ref, kolId) async {
  final postRepo = ref.watch(postRepositoryProvider);
  return await postRepo.getPostsByKOL(kolId);
});

/// 按 KOL 查詢文檔的 Provider（包含 KOL 和 Stock 詳細資訊）
final kolPostsWithDetailsProvider = FutureProvider.family<List<PostWithDetails>, int>((ref, kolId) async {
  final postRepo = ref.watch(postRepositoryProvider);
  return await postRepo.getPostsWithDetailsByKOL(kolId);
});

/// 按投資標的分組的文檔資料結構
class PostsGroupedByStock {
  final Stock stock;
  final List<Post> posts;

  const PostsGroupedByStock({
    required this.stock,
    required this.posts,
  });

  /// 取得該標的的文檔數量
  int get postCount => posts.length;

  /// 取得最新文檔的發文時間
  DateTime? get latestPostDate {
    if (posts.isEmpty) return null;
    return posts.map((p) => p.postedAt).reduce((a, b) => a.isAfter(b) ? a : b);
  }

  /// 取得 Bullish 文檔數量
  int get bullishCount => posts.where((p) => p.sentiment == 'Bullish').length;

  /// 取得 Bearish 文檔數量
  int get bearishCount => posts.where((p) => p.sentiment == 'Bearish').length;

  /// 取得 Neutral 文檔數量
  int get neutralCount => posts.where((p) => p.sentiment == 'Neutral').length;
}

/// 按投資標的分組文檔的 Provider
/// 
/// 用於 KOL View Screen 的 Overview Tab
/// 將該 KOL 的所有文檔按投資標的分組，並按最新文檔時間排序
final kolPostsGroupedByStockProvider = FutureProvider.family<List<PostsGroupedByStock>, int>((ref, kolId) async {
  final postRepo = ref.watch(postRepositoryProvider);
  final stockRepo = ref.watch(stockRepositoryProvider);
  
  // 取得該 KOL 的所有文檔（包含詳細資訊）
  final postsWithDetails = await postRepo.getPostsWithDetailsByKOL(kolId);
  
  // 按 Stock 分組
  final groupedMap = groupBy(
    postsWithDetails,
    (PostWithDetails pwd) => pwd.stock.ticker,
  );
  
  // 轉換為 PostsGroupedByStock 物件列表
  final grouped = groupedMap.entries.map((entry) {
    final stock = postsWithDetails
        .firstWhere((pwd) => pwd.stock.ticker == entry.key)
        .stock;
    final posts = entry.value.map((pwd) => pwd.post).toList();
    
    // 按發文時間降序排序（最新的在前）
    posts.sort((a, b) => b.postedAt.compareTo(a.postedAt));
    
    return PostsGroupedByStock(stock: stock, posts: posts);
  }).toList();
  
  // 按每組的最新文檔時間降序排序
  grouped.sort((a, b) {
    final aDate = a.latestPostDate;
    final bDate = b.latestPostDate;
    if (aDate == null && bDate == null) return 0;
    if (aDate == null) return 1;
    if (bDate == null) return -1;
    return bDate.compareTo(aDate);
  });
  
  return grouped;
});

/// KOL 文檔統計資料
class KOLPostStats {
  final int totalPosts;
  final int stockCount;
  final int bullishCount;
  final int bearishCount;
  final int neutralCount;
  final DateTime? latestPostDate;
  final DateTime? oldestPostDate;

  const KOLPostStats({
    required this.totalPosts,
    required this.stockCount,
    required this.bullishCount,
    required this.bearishCount,
    required this.neutralCount,
    this.latestPostDate,
    this.oldestPostDate,
  });

  /// 計算 Bullish 比例（0.0 ~ 1.0）
  double get bullishRatio => totalPosts > 0 ? bullishCount / totalPosts : 0.0;

  /// 計算 Bearish 比例（0.0 ~ 1.0）
  double get bearishRatio => totalPosts > 0 ? bearishCount / totalPosts : 0.0;

  /// 計算 Neutral 比例（0.0 ~ 1.0）
  double get neutralRatio => totalPosts > 0 ? neutralCount / totalPosts : 0.0;

  /// 取得主要情緒傾向
  String get dominantSentiment {
    if (bullishCount >= bearishCount && bullishCount >= neutralCount) {
      return 'Bullish';
    } else if (bearishCount >= neutralCount) {
      return 'Bearish';
    } else {
      return 'Neutral';
    }
  }
}

/// KOL 文檔統計 Provider
/// 
/// 提供該 KOL 的整體統計資訊
final kolPostStatsProvider = FutureProvider.family<KOLPostStats, int>((ref, kolId) async {
  final posts = await ref.watch(kolPostsProvider(kolId).future);
  
  if (posts.isEmpty) {
    return const KOLPostStats(
      totalPosts: 0,
      stockCount: 0,
      bullishCount: 0,
      bearishCount: 0,
      neutralCount: 0,
    );
  }
  
  // 計算統計資料
  final totalPosts = posts.length;
  final stockCount = posts.map((p) => p.stockTicker).toSet().length;
  final bullishCount = posts.where((p) => p.sentiment == 'Bullish').length;
  final bearishCount = posts.where((p) => p.sentiment == 'Bearish').length;
  final neutralCount = posts.where((p) => p.sentiment == 'Neutral').length;
  
  final dates = posts.map((p) => p.postedAt).toList()..sort();
  final latestPostDate = dates.last;
  final oldestPostDate = dates.first;
  
  return KOLPostStats(
    totalPosts: totalPosts,
    stockCount: stockCount,
    bullishCount: bullishCount,
    bearishCount: bearishCount,
    neutralCount: neutralCount,
    latestPostDate: latestPostDate,
    oldestPostDate: oldestPostDate,
  );
});

