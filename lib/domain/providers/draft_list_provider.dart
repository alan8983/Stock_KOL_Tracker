import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database/database.dart';
import '../../data/repositories/post_repository.dart';
import 'repository_providers.dart';

/// DraftListStateNotifier - 管理草稿列表
class DraftListStateNotifier extends StateNotifier<AsyncValue<List<Post>>> {
  final PostRepository _postRepository;

  DraftListStateNotifier(this._postRepository) : super(const AsyncValue.loading()) {
    loadDrafts();
  }

  /// 載入所有草稿
  Future<void> loadDrafts() async {
    state = const AsyncValue.loading();
    try {
      final drafts = await _postRepository.getAllDrafts();
      state = AsyncValue.data(drafts);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// 刪除單一草稿
  Future<void> deleteDraft(int id) async {
    try {
      await _postRepository.deleteDraft(id);
      await loadDrafts(); // 重新載入列表
    } catch (e) {
      // 錯誤處理
      rethrow;
    }
  }

  /// 批次刪除草稿
  Future<void> deleteDrafts(List<int> ids) async {
    try {
      await _postRepository.deleteDrafts(ids);
      await loadDrafts(); // 重新載入列表
    } catch (e) {
      // 錯誤處理
      rethrow;
    }
  }
}

/// DraftListProvider
final draftListProvider =
    StateNotifierProvider<DraftListStateNotifier, AsyncValue<List<Post>>>((ref) {
  final postRepo = ref.watch(postRepositoryProvider);
  return DraftListStateNotifier(postRepo);
});
