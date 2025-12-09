import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database/database.dart';
import '../../data/repositories/stock_repository.dart';
import 'repository_providers.dart';

/// StockListStateNotifier - 管理投資標的列表
class StockListStateNotifier extends StateNotifier<AsyncValue<List<Stock>>> {
  final StockRepository _stockRepository;

  StockListStateNotifier(this._stockRepository)
      : super(const AsyncValue.loading()) {
    loadStocks();
  }

  /// 載入所有投資標的
  Future<void> loadStocks() async {
    state = const AsyncValue.loading();
    try {
      final stocks = await _stockRepository.getAllStocks();
      state = AsyncValue.data(stocks);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// 搜尋投資標的
  Future<void> searchStocks(String query) async {
    if (query.isEmpty) {
      await loadStocks();
      return;
    }

    state = const AsyncValue.loading();
    try {
      final stocks = await _stockRepository.searchStocks(query);
      state = AsyncValue.data(stocks);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
}

/// StockListProvider
final stockListProvider = StateNotifierProvider<StockListStateNotifier,
    AsyncValue<List<Stock>>>((ref) {
  final stockRepo = ref.watch(stockRepositoryProvider);
  return StockListStateNotifier(stockRepo);
});
