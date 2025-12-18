import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:stock_kol_tracker/data/database/database.dart';
import '../fixtures/test_data.dart';

/// 測試用資料庫輔助工具
/// 提供記憶體資料庫建立、資料初始化和清理功能
class TestDatabaseHelper {
  /// 建立記憶體資料庫
  /// 
  /// 返回一個使用記憶體的 AppDatabase 實例，
  /// 適用於測試環境，不會寫入實際檔案
  static AppDatabase createInMemoryDatabase() {
    return _TestAppDatabase(NativeDatabase.memory(), skipDefaultData: true);
  }

  /// 插入測試資料到資料庫
  /// 
  /// 按順序插入：
  /// 1. KOLs（必須先插入，因為 Posts 有外鍵約束）
  /// 2. Stocks（必須先插入，因為 Posts 有外鍵約束）
  /// 3. Posts
  /// 
  /// [db] - 要插入資料的資料庫實例
  static Future<void> seedTestData(AppDatabase db) async {
    // 確保資料庫已初始化（觸發 migration）
    await db.doWhenOpened((e) async {});
    
    // 1. 插入 KOLs
    for (final kol in TestData.allKOLs) {
      await db.into(db.kOLs).insert(
            kol,
            mode: InsertMode.insertOrReplace,
          );
    }

    // 2. 插入 Stocks
    for (final stock in TestData.allStocks) {
      await db.into(db.stocks).insert(
            stock,
            mode: InsertMode.insertOrReplace,
          );
    }

    // 3. 插入 Posts
    for (final post in TestData.allPosts) {
      await db.into(db.posts).insert(
            post,
            mode: InsertMode.insertOrReplace,
          );
    }
  }

  /// 清理測試資料
  /// 
  /// 刪除所有測試資料，順序與插入相反：
  /// 1. Posts（先刪除，因為有外鍵約束）
  /// 2. Stocks
  /// 3. KOLs
  /// 
  /// [db] - 要清理資料的資料庫實例
  static Future<void> cleanupDatabase(AppDatabase db) async {
    // 1. 刪除 Posts
    await db.delete(db.posts).go();

    // 2. 刪除 Stocks（排除預設的 TEMP）
    await (db.delete(db.stocks)..where((tbl) => tbl.ticker.isNotValue('TEMP')))
        .go();

    // 3. 刪除 KOLs（排除預設的「未分類」）
    await (db.delete(db.kOLs)..where((tbl) => tbl.id.isNotValue(1))).go();
  }

  /// 插入特定 KOL 的測試資料
  /// 
  /// 只插入與指定 KOL 相關的資料
  /// 
  /// [db] - 資料庫實例
  /// [kolId] - KOL ID
  static Future<void> seedTestDataForKOL(AppDatabase db, int kolId) async {
    // 找到對應的 KOL
    final kol = TestData.allKOLs.firstWhere(
      (k) => k.id.value == kolId,
      orElse: () => throw Exception('找不到 KOL ID: $kolId'),
    );

    // 插入 KOL
    await db.into(db.kOLs).insert(
          kol,
          mode: InsertMode.insertOrReplace,
        );

    // 找到該 KOL 的所有 Posts
    final posts = TestData.getPostsByKOL(kolId);

    // 插入相關的 Stocks
    final stockTickers = posts.map((p) => p.stockTicker.value).toSet();
    for (final ticker in stockTickers) {
      final stock = TestData.allStocks.firstWhere(
        (s) => s.ticker.value == ticker,
        orElse: () => throw Exception('找不到 Stock: $ticker'),
      );
      await db.into(db.stocks).insert(
            stock,
            mode: InsertMode.insertOrReplace,
          );
    }

    // 插入 Posts
    for (final post in posts) {
      await db.into(db.posts).insert(
            post,
            mode: InsertMode.insertOrReplace,
          );
    }
  }

  /// 插入特定 Stock 的測試資料
  /// 
  /// 只插入與指定 Stock 相關的資料
  /// 
  /// [db] - 資料庫實例
  /// [ticker] - Stock ticker
  static Future<void> seedTestDataForStock(AppDatabase db, String ticker) async {
    // 找到對應的 Stock
    final stock = TestData.allStocks.firstWhere(
      (s) => s.ticker.value == ticker,
      orElse: () => throw Exception('找不到 Stock: $ticker'),
    );

    // 插入 Stock
    await db.into(db.stocks).insert(
          stock,
          mode: InsertMode.insertOrReplace,
        );

    // 找到該 Stock 的所有 Posts
    final posts = TestData.getPostsByStock(ticker);

    // 插入相關的 KOLs
    final kolIds = posts.map((p) => p.kolId.value).toSet();
    for (final kolId in kolIds) {
      final kol = TestData.allKOLs.firstWhere(
        (k) => k.id.value == kolId,
        orElse: () => throw Exception('找不到 KOL ID: $kolId'),
      );
      await db.into(db.kOLs).insert(
            kol,
            mode: InsertMode.insertOrReplace,
          );
    }

    // 插入 Posts
    for (final post in posts) {
      await db.into(db.posts).insert(
            post,
            mode: InsertMode.insertOrReplace,
          );
    }
  }

  /// 驗證資料是否正確插入
  /// 
  /// 返回一個包含統計資訊的 Map
  static Future<Map<String, int>> getDatabaseStats(AppDatabase db) async {
    final kolCount = await (db.select(db.kOLs)..where((tbl) => tbl.id.isBiggerOrEqualValue(100))).get().then((list) => list.length);
    final stockCount = await (db.select(db.stocks)..where((tbl) => tbl.ticker.isNotValue('TEMP'))).get().then((list) => list.length);
    final postCount = await (db.select(db.posts)..where((tbl) => tbl.id.isBiggerOrEqualValue(1000))).get().then((list) => list.length);

    return {
      'kols': kolCount,
      'stocks': stockCount,
      'posts': postCount,
    };
  }
}

/// 測試用資料庫實作
class _TestAppDatabase extends AppDatabase {
  _TestAppDatabase(QueryExecutor executor, {bool skipDefaultData = false})
      : super.customExecutor(executor, skipDefaultData: skipDefaultData);
}

