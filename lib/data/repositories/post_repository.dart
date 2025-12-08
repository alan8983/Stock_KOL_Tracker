import 'package:drift/drift.dart';
import '../database/database.dart';

class PostRepository {
  final AppDatabase _db;

  PostRepository(this._db);

  /// 建立草稿
  Future<int> createDraft(PostsCompanion post) async {
    return await _db.into(_db.posts).insert(post);
  }

  /// 更新貼文
  Future<void> updatePost(int id, PostsCompanion post) async {
    await (_db.update(_db.posts)..where((tbl) => tbl.id.equals(id))).write(post);
  }

  /// 更新狀態
  Future<void> updateStatus(int id, String status) async {
    await (_db.update(_db.posts)..where((tbl) => tbl.id.equals(id)))
        .write(PostsCompanion(status: Value(status)));
  }

  /// 取得所有貼文
  Future<List<Post>> getAllPosts() async {
    return await (_db.select(_db.posts)).get();
  }

  /// 取得所有草稿
  Future<List<Post>> getAllDrafts() async {
    return await (_db.select(_db.posts)
          ..where((tbl) => tbl.status.equals('Draft')))
        .get();
  }

  /// 刪除單一草稿
  Future<void> deleteDraft(int id) async {
    await (_db.delete(_db.posts)..where((tbl) => tbl.id.equals(id))).go();
  }

  /// 批次刪除草稿
  Future<void> deleteDrafts(List<int> ids) async {
    await (_db.delete(_db.posts)..where((tbl) => tbl.id.isIn(ids))).go();
  }

  /// 取得特定草稿
  Future<Post?> getDraftById(int id) async {
    return await (_db.select(_db.posts)..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
  }

  /// 發布貼文（將狀態從 Draft 改為 Published）
  Future<void> publishPost(int id) async {
    await updateStatus(id, 'Published');
  }

  /// 建立快速草稿（只有內容，使用預設值）
  /// 使用預設值：kolId=1（未分類）, stockTicker="TEMP"（臨時）
  Future<int> createQuickDraft(String content) async {
    if (content.trim().isEmpty) {
      throw Exception('內容不能為空');
    }

    final companion = PostsCompanion.insert(
      kolId: 1, // 預設 KOL：未分類
      stockTicker: 'TEMP', // 預設 Stock：臨時
      content: content.trim(),
      sentiment: const Value('Neutral'),
      postedAt: Value(DateTime.now()),
      createdAt: Value(DateTime.now()),
      status: const Value('Draft'),
    );

    return await _db.into(_db.posts).insert(companion);
  }
}
