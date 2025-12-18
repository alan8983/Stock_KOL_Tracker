import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database/database.dart';
import '../../data/models/post_with_details.dart';
import 'repository_providers.dart';

/// 按投資標的查詢文檔的 Provider（僅 Post）
final stockPostsProvider = FutureProvider.family<List<Post>, String>((ref, ticker) async {
  final postRepo = ref.watch(postRepositoryProvider);
  return await postRepo.getPostsByStock(ticker);
});

/// 按投資標的查詢文檔的 Provider（包含 KOL 和 Stock 詳細資訊）
final stockPostsWithDetailsProvider = FutureProvider.family<List<PostWithDetails>, String>((ref, ticker) async {
  final postRepo = ref.watch(postRepositoryProvider);
  return await postRepo.getPostsWithDetailsByStock(ticker);
});
