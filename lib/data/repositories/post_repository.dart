import 'package:drift/drift.dart';
import '../database/database.dart';
import '../models/post_with_details.dart';
import 'post_stock_repository.dart';

class PostRepository {
  final AppDatabase _db;
  final PostStockRepository _postStockRepository;

  PostRepository(this._db) : _postStockRepository = PostStockRepository(_db);

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

  /// 確保 KOL 存在於資料庫中（如果不存在則創建）
  Future<void> _ensureKOLExists(int kolId) async {
    final existingKOL = await (_db.select(_db.kOLs)
          ..where((tbl) => tbl.id.equals(kolId)))
        .getSingleOrNull();
    
    if (existingKOL == null) {
      // KOL 不存在，這不應該發生，但為了安全起見，我們跳過
      // 因為 KOL 應該由用戶手動創建
      throw Exception('KOL ID $kolId 不存在');
    }
  }

  /// 建立草稿
  /// [postStocks] 可選，如果提供則會建立標的關聯
  Future<int> createDraft(PostsCompanion post, {List<PostStockData>? postStocks}) async {
    // 確保 KOL 存在
    final kolId = post.kolId.value;
    if (kolId != null) {
      await _ensureKOLExists(kolId);
    }
    
    // 向後兼容：如果提供了舊的 stockTicker，確保股票存在
    final stockTicker = post.stockTicker.value;
    if (stockTicker != null && stockTicker.isNotEmpty) {
      await _ensureStockExists(stockTicker);
    }
    
    final postId = await _db.into(_db.posts).insert(post);
    
    // 如果提供了 postStocks，建立關聯
    if (postStocks != null && postStocks.isNotEmpty) {
      await _postStockRepository.createPostStocks(postId, postStocks);
    }
    
    return postId;
  }

  /// 更新貼文
  /// [postStocks] 可選，如果提供則會更新標的關聯
  Future<void> updatePost(int id, PostsCompanion post, {List<PostStockData>? postStocks}) async {
    // 確保 KOL 存在
    final kolId = post.kolId.value;
    if (kolId != null) {
      await _ensureKOLExists(kolId);
    }
    
    // 向後兼容：如果提供了舊的 stockTicker，確保股票存在
    final stockTicker = post.stockTicker.value;
    if (stockTicker != null && stockTicker.isNotEmpty) {
      await _ensureStockExists(stockTicker);
    }
    
    await (_db.update(_db.posts)..where((tbl) => tbl.id.equals(id))).write(post);
    
    // 如果提供了 postStocks，更新關聯
    if (postStocks != null) {
      await _postStockRepository.updatePostStocks(id, postStocks);
    }
  }

  /// 更新狀態
  Future<void> updateStatus(int id, String status) async {
    await (_db.update(_db.posts)..where((tbl) => tbl.id.equals(id)))
        .write(PostsCompanion(status: Value(status)));
  }

  /// 取得所有貼文
  Future<List<Post>> getAllPosts() async {
    return await (_db.select(_db.posts)).get();
  }

  /// 取得所有草稿（依建立時間由新到舊排序）
  Future<List<Post>> getAllDrafts() async {
    return await (_db.select(_db.posts)
          ..where((tbl) => tbl.status.equals('Draft'))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  /// 取得所有已發布的貼文（依發文時間排序）
  Future<List<Post>> getPublishedPosts({bool ascending = false}) async {
    return await (_db.select(_db.posts)
          ..where((tbl) => tbl.status.equals('Published'))
          ..orderBy([(t) => ascending 
              ? OrderingTerm.asc(t.postedAt) 
              : OrderingTerm.desc(t.postedAt)]))
        .get();
  }

  /// 刪除單一草稿
  Future<void> deleteDraft(int id) async {
    await (_db.delete(_db.posts)..where((tbl) => tbl.id.equals(id))).go();
  }

  /// 批次刪除草稿
  Future<void> deleteDrafts(List<int> ids) async {
    await (_db.delete(_db.posts)..where((tbl) => tbl.id.isIn(ids))).go();
  }

  /// 刪除文檔（可刪除任何狀態的文檔）
  Future<void> deletePost(int id) async {
    await (_db.delete(_db.posts)..where((tbl) => tbl.id.equals(id))).go();
  }

  /// 取得特定草稿
  Future<Post?> getDraftById(int id) async {
    return await (_db.select(_db.posts)..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
  }

  /// 取得特定貼文（依 ID）
  Future<Post?> getPostById(int id) async {
    return await (_db.select(_db.posts)..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
  }

  /// 發布貼文（將狀態從 Draft 改為 Published）
  Future<void> publishPost(int id) async {
    await updateStatus(id, 'Published');
  }

  /// 建立快速草稿（只有內容，使用預設值）
  /// 使用預設值：kolId=1（未分類）
  Future<int> createQuickDraft(String content) async {
    if (content.trim().isEmpty) {
      throw Exception('內容不能為空');
    }

    // 確保預設 KOL 存在
    await _ensureKOLExists(1);

    final companion = PostsCompanion.insert(
      kolId: 1, // 預設 KOL：未分類
      content: content.trim(),
      postedAt: DateTime.now(),
      createdAt: DateTime.now(),
      status: 'Draft',
    );

    return await _db.into(_db.posts).insert(companion);
  }

  /// 按 Stock 查詢已發布的文檔
  /// 優先使用 PostStocks 表，向後兼容舊的 stockTicker 欄位
  Future<List<Post>> getPostsByStock(String ticker, {DateTime? afterDate}) async {
    final minDate = afterDate ?? DateTime(2023, 1, 1);
    
    // 從 PostStocks 表查詢
    final postStocks = await (_db.select(_db.postStocks)
          ..where((tbl) => tbl.stockTicker.equals(ticker)))
        .get();
    
    final postIds = postStocks.map((ps) => ps.postId).toSet();
    
    // 查詢這些 Post
    if (postIds.isNotEmpty) {
      return await (_db.select(_db.posts)
            ..where((tbl) => 
              tbl.id.isIn(postIds) & 
              tbl.status.equals('Published') &
              tbl.postedAt.isBiggerOrEqualValue(minDate))
            ..orderBy([(tbl) => OrderingTerm.desc(tbl.postedAt)]))
          .get();
    }
    
    // 向後兼容：如果 PostStocks 表中沒有，查詢舊的 stockTicker 欄位
    return await (_db.select(_db.posts)
          ..where((tbl) => 
            tbl.stockTicker.equals(ticker) & 
            tbl.status.equals('Published') &
            tbl.postedAt.isBiggerOrEqualValue(minDate))
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.postedAt)]))
        .get();
  }

  /// 按 KOL 查詢已發布的文檔
  Future<List<Post>> getPostsByKOL(int kolId, {DateTime? afterDate}) async {
    final minDate = afterDate ?? DateTime(2023, 1, 1);
    return await (_db.select(_db.posts)
          ..where((tbl) => 
            tbl.kolId.equals(kolId) & 
            tbl.status.equals('Published') &
            tbl.postedAt.isBiggerOrEqualValue(minDate))
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.postedAt)]))
        .get();
  }

  /// 按日期範圍查詢已發布的文檔
  Future<List<Post>> getPostsByDateRange(DateTime start, DateTime end) async {
    return await (_db.select(_db.posts)
          ..where((tbl) => 
            tbl.status.equals('Published') & 
            tbl.postedAt.isBiggerOrEqualValue(start) & 
            tbl.postedAt.isSmallerOrEqualValue(end))
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.postedAt)]))
        .get();
  }

  /// 按 Stock 查詢已發布的文檔（包含 KOL 和 Stock 詳細資訊）
  /// 優先使用 PostStocks 表，向後兼容舊的 stockTicker 欄位
  Future<List<PostWithDetails>> getPostsWithDetailsByStock(String ticker, {DateTime? afterDate}) async {
    final minDate = afterDate ?? DateTime(2023, 1, 1);
    
    // 從 PostStocks 表查詢
    final postStocks = await (_db.select(_db.postStocks)
          ..where((tbl) => tbl.stockTicker.equals(ticker)))
        .get();
    
    final postIds = postStocks.map((ps) => ps.postId).toSet();
    
    List<PostWithDetails> results = [];
    
    if (postIds.isNotEmpty) {
      // 透過 PostStocks 查詢
      final query = _db.select(_db.posts).join([
        leftOuterJoin(_db.kOLs, _db.kOLs.id.equalsExp(_db.posts.kolId)),
        leftOuterJoin(_db.postStocks, _db.postStocks.postId.equalsExp(_db.posts.id)),
        leftOuterJoin(_db.stocks, _db.stocks.ticker.equalsExp(_db.postStocks.stockTicker)),
      ])
        ..where(_db.posts.id.isIn(postIds) & 
                _db.posts.status.equals('Published') &
                _db.posts.postedAt.isBiggerOrEqualValue(minDate) &
                _db.postStocks.stockTicker.equals(ticker))
        ..orderBy([OrderingTerm.desc(_db.posts.postedAt)]);
      
      final queryResults = await query.get();
      results = queryResults.map((row) {
        final stock = row.readTableOrNull(_db.stocks);
        // 如果從 PostStocks 找不到 stock，嘗試從舊欄位取得
        if (stock == null) {
          final oldStock = row.readTableOrNull(_db.stocks);
          return PostWithDetails(
            post: row.readTable(_db.posts),
            kol: row.readTable(_db.kOLs),
            stock: oldStock ?? Stock(ticker: ticker, lastUpdated: DateTime.now()),
          );
        }
        return PostWithDetails(
          post: row.readTable(_db.posts),
          kol: row.readTable(_db.kOLs),
          stock: stock,
        );
      }).toList();
    }
    
    // 向後兼容：如果 PostStocks 表中沒有，查詢舊的 stockTicker 欄位
    if (results.isEmpty) {
      final query = _db.select(_db.posts).join([
        leftOuterJoin(_db.kOLs, _db.kOLs.id.equalsExp(_db.posts.kolId)),
        leftOuterJoin(_db.stocks, _db.stocks.ticker.equalsExp(_db.posts.stockTicker)),
      ])
        ..where(_db.posts.stockTicker.equals(ticker) & 
                _db.posts.status.equals('Published') &
                _db.posts.postedAt.isBiggerOrEqualValue(minDate))
        ..orderBy([OrderingTerm.desc(_db.posts.postedAt)]);
      
      final queryResults = await query.get();
      results = queryResults.map((row) {
        return PostWithDetails(
          post: row.readTable(_db.posts),
          kol: row.readTable(_db.kOLs),
          stock: row.readTable(_db.stocks),
        );
      }).toList();
    }
    
    return results;
  }
  
  /// 取得 Post 的所有標的關聯
  Future<List<PostStock>> getPostStocks(int postId) async {
    return await _postStockRepository.getPostStocksByPostId(postId);
  }
  
  /// 取得 Post 的主要標的
  Future<PostStock?> getPrimaryPostStock(int postId) async {
    return await _postStockRepository.getPrimaryPostStock(postId);
  }

  /// 按 KOL 查詢已發布的文檔（包含 KOL 和 Stock 詳細資訊）
  Future<List<PostWithDetails>> getPostsWithDetailsByKOL(int kolId, {DateTime? afterDate}) async {
    final minDate = afterDate ?? DateTime(2023, 1, 1);
    final query = _db.select(_db.posts).join([
      leftOuterJoin(_db.kOLs, _db.kOLs.id.equalsExp(_db.posts.kolId)),
      leftOuterJoin(_db.stocks, _db.stocks.ticker.equalsExp(_db.posts.stockTicker)),
    ])
      ..where(_db.posts.kolId.equals(kolId) & 
              _db.posts.status.equals('Published') &
              _db.posts.postedAt.isBiggerOrEqualValue(minDate))
      ..orderBy([OrderingTerm.desc(_db.posts.postedAt)]);
    
    final results = await query.get();
    return results.map((row) {
      return PostWithDetails(
        post: row.readTable(_db.posts),
        kol: row.readTable(_db.kOLs),
        stock: row.readTable(_db.stocks),
      );
    }).toList();
  }
}
