import 'package:drift/drift.dart';
import '../database/database.dart';

class PostStockRepository {
  final AppDatabase _db;

  PostStockRepository(this._db);

  /// 確保股票存在於資料庫中（如果不存在則創建）
  Future<void> _ensureStockExists(String ticker) async {
    final existingStock = await (_db.select(_db.stocks)
          ..where((tbl) => tbl.ticker.equals(ticker)))
        .getSingleOrNull();
    
    if (existingStock == null) {
      // 股票不存在，自動創建
      await _db.into(_db.stocks).insert(
        StocksCompanion.insert(
          ticker: ticker,
          lastUpdated: DateTime.now(),
        ),
      );
    }
  }

  /// 為 Post 建立多個標的關聯
  Future<void> createPostStocks(int postId, List<PostStockData> postStocks) async {
    if (postStocks.isEmpty) {
      return;
    }

    // 確保所有股票都存在
    for (final postStock in postStocks) {
      await _ensureStockExists(postStock.stockTicker);
    }

    // 批次插入
    await _db.batch((batch) {
      for (final postStock in postStocks) {
        batch.insert(
          _db.postStocks,
          PostStocksCompanion.insert(
            postId: postId,
            stockTicker: postStock.stockTicker,
            sentiment: postStock.sentiment,
            isPrimary: postStock.isPrimary,
          ),
        );
      }
    });
  }

  /// 更新 Post 的標的關聯（先刪除舊的，再建立新的）
  Future<void> updatePostStocks(int postId, List<PostStockData> postStocks) async {
    // 刪除舊的關聯
    await (_db.delete(_db.postStocks)..where((tbl) => tbl.postId.equals(postId))).go();
    
    // 建立新的關聯
    await createPostStocks(postId, postStocks);
  }

  /// 取得 Post 的所有標的關聯
  Future<List<PostStock>> getPostStocksByPostId(int postId) async {
    return await (_db.select(_db.postStocks)
          ..where((tbl) => tbl.postId.equals(postId))
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.isPrimary)])) // 主要標的排在前面
        .get();
  }

  /// 取得特定 Stock 的所有 Post 關聯
  Future<List<PostStock>> getPostStocksByTicker(String ticker) async {
    return await (_db.select(_db.postStocks)
          ..where((tbl) => tbl.stockTicker.equals(ticker)))
        .get();
  }

  /// 取得 Post 的主要標的
  Future<PostStock?> getPrimaryPostStock(int postId) async {
    return await (_db.select(_db.postStocks)
          ..where((tbl) => tbl.postId.equals(postId) & tbl.isPrimary.equals(true)))
        .getSingleOrNull();
  }

  /// 刪除 Post 的所有標的關聯
  Future<void> deletePostStocksByPostId(int postId) async {
    await (_db.delete(_db.postStocks)..where((tbl) => tbl.postId.equals(postId))).go();
  }

  /// 刪除單一標的關聯
  Future<void> deletePostStock(int postStockId) async {
    await (_db.delete(_db.postStocks)..where((tbl) => tbl.id.equals(postStockId))).go();
  }
}

/// PostStock 資料傳輸物件
class PostStockData {
  final String stockTicker;
  final String sentiment;
  final bool isPrimary;

  const PostStockData({
    required this.stockTicker,
    required this.sentiment,
    this.isPrimary = false,
  });
}

