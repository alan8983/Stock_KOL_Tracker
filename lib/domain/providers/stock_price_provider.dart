import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database/database.dart';
import 'repository_providers.dart';

/// 按投資標的查詢股價資料的 Provider
final stockPricesProvider = FutureProvider.family<List<StockPrice>, String>((ref, ticker) async {
  final repo = ref.watch(stockPriceRepositoryProvider);
  return await repo.getStockPrices(ticker);
});

/// 按投資標的和日期範圍查詢股價資料的 Provider
final stockPricesWithRangeProvider = FutureProvider.family<List<StockPrice>, StockPriceQuery>((ref, query) async {
  final repo = ref.watch(stockPriceRepositoryProvider);
  return await repo.getStockPrices(
    query.ticker,
    startDate: query.startDate,
    endDate: query.endDate,
  );
});

/// 查詢最近 90 日股價資料的 Provider（用於 K 線圖顯示）
final stock90DayPricesProvider = FutureProvider.family<List<StockPrice>, String>((ref, ticker) async {
  final repo = ref.watch(stockPriceRepositoryProvider);
  final endDate = DateTime.now();
  final startDate = endDate.subtract(const Duration(days: 90));
  return await repo.getStockPrices(ticker, startDate: startDate, endDate: endDate);
});

/// 查詢 2023/01/01 至今的完整股價資料 Provider（用於完整 K 線圖顯示）
final stockFullRangePricesProvider = FutureProvider.family<List<StockPrice>, String>((ref, ticker) async {
  final repo = ref.watch(stockPriceRepositoryProvider);
  final endDate = DateTime.now();
  final startDate = DateTime(2023, 1, 1);
  return await repo.getStockPrices(ticker, startDate: startDate, endDate: endDate);
});

/// 股價查詢參數
class StockPriceQuery {
  final String ticker;
  final DateTime? startDate;
  final DateTime? endDate;

  const StockPriceQuery({
    required this.ticker,
    this.startDate,
    this.endDate,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StockPriceQuery &&
          runtimeType == other.runtimeType &&
          ticker == other.ticker &&
          startDate == other.startDate &&
          endDate == other.endDate;

  @override
  int get hashCode => ticker.hashCode ^ startDate.hashCode ^ endDate.hashCode;
}
