import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database/database.dart';
import '../../data/models/post_with_kol.dart';
import '../../data/repositories/post_repository.dart';
import '../../data/repositories/kol_repository.dart';
import 'repository_providers.dart';

/// PostListStateNotifier - 管理已發布貼文列表
class PostListStateNotifier extends StateNotifier<AsyncValue<List<PostWithKOL>>> {
  final PostRepository _postRepository;
  final KOLRepository _kolRepository;
  bool _ascending = false; // 預設為倒序（最新優先）

  PostListStateNotifier(this._postRepository, this._kolRepository)
      : super(const AsyncValue.loading()) {
    loadPosts();
  }

  /// 載入所有已發布的貼文（帶 KOL 資訊）
  Future<void> loadPosts() async {
    state = const AsyncValue.loading();
    try {
      // 取得已發布貼文
      final posts = await _postRepository.getPublishedPosts(ascending: _ascending);
      
      // 關聯查詢 KOL 資訊和標的關聯
      final postsWithKOL = <PostWithKOL>[];
      for (final post in posts) {
        final kol = await _kolRepository.getKOLById(post.kolId);
        if (kol != null) {
          // 載入標的關聯
          final postStocks = await _postRepository.getPostStocks(post.id);
          postsWithKOL.add(PostWithKOL(post: post, kol: kol, postStocks: postStocks));
        }
      }
      
      state = AsyncValue.data(postsWithKOL);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// 切換排序順序
  Future<void> toggleSortOrder() async {
    _ascending = !_ascending;
    await loadPosts();
  }

  /// 取得當前排序順序
  bool get isAscending => _ascending;
}

/// PostListProvider
final postListProvider =
    StateNotifierProvider<PostListStateNotifier, AsyncValue<List<PostWithKOL>>>((ref) {
  final postRepo = ref.watch(postRepositoryProvider);
  final kolRepo = ref.watch(kolRepositoryProvider);
  return PostListStateNotifier(postRepo, kolRepo);
});
