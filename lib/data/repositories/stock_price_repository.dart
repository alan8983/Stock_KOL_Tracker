import 'package:drift/drift.dart';
import '../database/database.dart';
import '../services/Tiingo/tiingo_service.dart';

class StockPriceRepository {
  final AppDatabase _db;
  final TiingoService _tiingoService;

  StockPriceRepository(this._db, this._tiingoService);

  /// 取得股價資料（含快取邏輯）
  /// 1. 先查本地資料庫
  /// 2. 判斷是否需要更新（最新日期 < 今天 - 1）
  /// 3. 如需要，呼叫 API 並儲存
  Future<List<StockPrice>> getStockPrices(
    String ticker, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    // 查詢本地資料
    final localPrices = await _queryLocalPrices(ticker, startDate, endDate);

    // 判斷是否需要從 API 更新
    final needsUpdate = _shouldFetchFromAPI(localPrices);

    if (needsUpdate) {
      try {
        await _fetchAndSaveFromAPI(ticker);
        return await _queryLocalPrices(ticker, startDate, endDate);
      } catch (e) {
        // 如果 API 失敗，返回本地資料（如果有的話）
        if (localPrices.isNotEmpty) {
          return localPrices;
        }
        rethrow;
      }
    }

    return localPrices;
  }

  /// 查詢本地資料庫的股價資料
  Future<List<StockPrice>> _queryLocalPrices(
    String ticker,
    DateTime? startDate,
    DateTime? endDate,
  ) async {
    var query = _db.select(_db.stockPrices)
      ..where((tbl) => tbl.ticker.equals(ticker));

    if (startDate != null) {
      query = query..where((tbl) => tbl.date.isBiggerOrEqualValue(startDate));
    }

    if (endDate != null) {
      query = query..where((tbl) => tbl.date.isSmallerOrEqualValue(endDate));
    }

    query = query..orderBy([(tbl) => OrderingTerm.asc(tbl.date)]);

    return await query.get();
  }

  /// 判斷是否需要從 API 取得資料
  bool _shouldFetchFromAPI(List<StockPrice> localPrices) {
    if (localPrices.isEmpty) {
      return true;
    }

    // 取得最新的本地資料日期
    final latestDate = localPrices
        .map((price) => price.date)
        .reduce((a, b) => a.isAfter(b) ? a : b);

    // 如果最新資料早於昨天，則需要更新
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final yesterdayDate = DateTime(yesterday.year, yesterday.month, yesterday.day);

    return latestDate.isBefore(yesterdayDate);
  }

  /// 從 API 取得資料並儲存到資料庫
  Future<void> _fetchAndSaveFromAPI(String ticker) async {
    // 呼叫 Tiingo API
    final pricesCompanions = await _tiingoService.fetchDailyPrices(ticker);

    if (pricesCompanions.isEmpty) {
      return;
    }

    // 使用批次插入提升效能
    await _db.batch((batch) {
      for (final priceCompanion in pricesCompanions) {
        batch.insert(
          _db.stockPrices,
          priceCompanion,
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  /// 手動儲存股價資料（用於測試或其他用途）
  Future<void> saveStockPrices(List<StockPricesCompanion> prices) async {
    if (prices.isEmpty) {
      return;
    }

    await _db.batch((batch) {
      for (final price in prices) {
        batch.insert(
          _db.stockPrices,
          price,
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  /// 刪除特定股票的所有股價資料（用於清理快取）
  Future<void> deleteStockPrices(String ticker) async {
    await (_db.delete(_db.stockPrices)..where((tbl) => tbl.ticker.equals(ticker))).go();
  }

  /// 取得最新的股價日期
  Future<DateTime?> getLatestPriceDate(String ticker) async {
    final query = _db.select(_db.stockPrices)
      ..where((tbl) => tbl.ticker.equals(ticker))
      ..orderBy([(tbl) => OrderingTerm.desc(tbl.date)])
      ..limit(1);

    final result = await query.getSingleOrNull();
    return result?.date;
  }
}
