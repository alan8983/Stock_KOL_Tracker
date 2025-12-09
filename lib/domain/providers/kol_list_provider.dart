import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database/database.dart';
import '../../data/repositories/kol_repository.dart';
import 'repository_providers.dart';

/// KOLListStateNotifier - 管理KOL列表
class KOLListStateNotifier extends StateNotifier<AsyncValue<List<KOL>>> {
  final KOLRepository _kolRepository;

  KOLListStateNotifier(this._kolRepository) : super(const AsyncValue.loading()) {
    loadKOLs();
  }

  /// 載入所有KOL
  Future<void> loadKOLs() async {
    state = const AsyncValue.loading();
    try {
      final kols = await _kolRepository.getAllKOLs();
      state = AsyncValue.data(kols);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// 搜尋KOL
  Future<void> searchKOLs(String query) async {
    if (query.isEmpty) {
      await loadKOLs();
      return;
    }
    
    state = const AsyncValue.loading();
    try {
      final kols = await _kolRepository.searchKOLs(query);
      state = AsyncValue.data(kols);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
}

/// KOLListProvider
final kolListProvider =
    StateNotifierProvider<KOLListStateNotifier, AsyncValue<List<KOL>>>((ref) {
  final kolRepo = ref.watch(kolRepositoryProvider);
  return KOLListStateNotifier(kolRepo);
});
