import 'package:flutter_riverpod/flutter_riverpod.dart';

/// BookmarkStateNotifier - 管理書籤狀態
class BookmarkStateNotifier extends StateNotifier<Set<int>> {
  BookmarkStateNotifier() : super({});

  /// 切換書籤狀態
  void toggleBookmark(int postId) {
    if (state.contains(postId)) {
      state = {...state}..remove(postId);
    } else {
      state = {...state, postId};
    }
  }

  /// 檢查是否已加入書籤
  bool isBookmarked(int postId) {
    return state.contains(postId);
  }

  /// 新增書籤
  void addBookmark(int postId) {
    if (!state.contains(postId)) {
      state = {...state, postId};
    }
  }

  /// 移除書籤
  void removeBookmark(int postId) {
    if (state.contains(postId)) {
      state = {...state}..remove(postId);
    }
  }

  /// 清除所有書籤
  void clearAll() {
    state = {};
  }
}

/// BookmarkProvider
final bookmarkProvider = StateNotifierProvider<BookmarkStateNotifier, Set<int>>((ref) {
  return BookmarkStateNotifier();
});
