import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/post_repository.dart';
import '../../data/repositories/kol_repository.dart';
import '../../data/repositories/stock_repository.dart';
import 'database_provider.dart';

/// 提供 PostRepository 實例
final postRepositoryProvider = Provider<PostRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return PostRepository(db);
});

/// 提供 KOLRepository 實例
final kolRepositoryProvider = Provider<KOLRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return KOLRepository(db);
});

/// 提供 StockRepository 實例
final stockRepositoryProvider = Provider<StockRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return StockRepository(db);
});
