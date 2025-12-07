import 'package:drift/drift.dart';
import '../database/database.dart';

class StockRepository {
  final AppDatabase _db;

  StockRepository(this._db);

  /// 新增或更新股票
  Future<void> upsertStock(StocksCompanion stock) async {
    await _db.into(_db.stocks).insertOnConflictUpdate(stock);
  }

  /// 依代碼取得股票
  Future<Stock?> getStockByTicker(String ticker) async {
    return await (_db.select(_db.stocks)
          ..where((tbl) => tbl.ticker.equals(ticker)))
        .getSingleOrNull();
  }

  /// 搜尋股票（用於自動完成，模糊搜尋）
  Future<List<Stock>> searchStocks(String query) async {
    final upperQuery = query.toUpperCase();
    return await (_db.select(_db.stocks)
          ..where((tbl) => tbl.ticker.like('%$upperQuery%'))
          ..orderBy([(t) => OrderingTerm.asc(t.ticker)])
          ..limit(10))
        .get();
  }

  /// 取得所有股票
  Future<List<Stock>> getAllStocks() async {
    return await (_db.select(_db.stocks)..orderBy([(t) => OrderingTerm.asc(t.ticker)])).get();
  }
}
