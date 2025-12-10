import '../database/database.dart';

/// 診斷用的 Repository
/// 用於檢查資料庫狀態和草稿功能
class DiagnosticRepository {
  final AppDatabase _db;

  DiagnosticRepository(this._db);

  /// 檢查預設記錄是否存在
  Future<Map<String, dynamic>> checkDefaultRecords() async {
    final kols = await _db.select(_db.kOLs).get();
    final stocks = await _db.select(_db.stocks).get();
    
    final defaultKol = kols.where((k) => k.id == 1).firstOrNull;
    final defaultStock = stocks.where((s) => s.ticker == 'TEMP').firstOrNull;

    return {
      'totalKols': kols.length,
      'totalStocks': stocks.length,
      'hasDefaultKol': defaultKol != null,
      'defaultKolName': defaultKol?.name,
      'hasDefaultStock': defaultStock != null,
      'defaultStockName': defaultStock?.name,
    };
  }

  /// 檢查草稿狀態
  Future<Map<String, dynamic>> checkDrafts() async {
    final allPosts = await _db.select(_db.posts).get();
    final drafts = allPosts.where((p) => p.status == 'Draft').toList();
    
    return {
      'totalPosts': allPosts.length,
      'totalDrafts': drafts.length,
      'drafts': drafts.map((d) => {
        'id': d.id,
        'content': d.content.substring(0, d.content.length > 50 ? 50 : d.content.length),
        'status': d.status,
        'kolId': d.kolId,
        'stockTicker': d.stockTicker,
      }).toList(),
      'allStatuses': allPosts.map((p) => p.status).toSet().toList(),
    };
  }

  /// 手動建立預設記錄（如果不存在）
  Future<void> ensureDefaultRecords() async {
    await _db.customStatement('''
      INSERT OR IGNORE INTO kols (id, name, createdAt) 
      VALUES (1, '未分類', datetime('now'));
    ''');
    
    await _db.customStatement('''
      INSERT OR IGNORE INTO stocks (ticker, name, lastUpdated) 
      VALUES ('TEMP', '臨時', datetime('now'));
    ''');
  }
}
