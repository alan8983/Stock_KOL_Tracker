import '../database/database.dart';

/// 貼文與 KOL 關聯資料（包含多標的）
class PostWithKOL {
  final Post post;
  final KOL kol;
  final List<PostStock> postStocks; // 多標的關聯

  const PostWithKOL({
    required this.post,
    required this.kol,
    this.postStocks = const [],
  });
  
  /// 取得主要標的
  PostStock? get primaryPostStock {
    return postStocks.firstWhere(
      (ps) => ps.isPrimary,
      orElse: () => postStocks.isNotEmpty ? postStocks.first : throw StateError('No post stocks'),
    );
  }
  
  /// 取得主要標的代號（向後兼容）
  String? get primaryTicker {
    try {
      return primaryPostStock?.stockTicker;
    } catch (e) {
      // 如果沒有 PostStocks，使用舊的 stockTicker 欄位
      return post.stockTicker;
    }
  }
  
  /// 取得主要標的情緒（向後兼容）
  String? get primarySentiment {
    try {
      return primaryPostStock?.sentiment;
    } catch (e) {
      // 如果沒有 PostStocks，使用舊的 sentiment 欄位
      return post.sentiment;
    }
  }
}
