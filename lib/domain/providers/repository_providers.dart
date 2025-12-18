import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../data/repositories/post_repository.dart';
import '../../data/repositories/kol_repository.dart';
import '../../data/repositories/stock_repository.dart';
import '../../data/repositories/stock_price_repository.dart';
import '../../data/services/Tiingo/tiingo_service.dart';
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

/// 提供 TiingoService 實例
final tiingoServiceProvider = Provider<TiingoService>((ref) {
  final apiToken = dotenv.env['TIINGO_API_TOKEN'] ?? '';
  return TiingoService(apiToken: apiToken);
});

/// 提供 StockPriceRepository 實例
final stockPriceRepositoryProvider = Provider<StockPriceRepository>((ref) {
  final db = ref.watch(databaseProvider);
  final tiingoService = ref.watch(tiingoServiceProvider);
  return StockPriceRepository(db, tiingoService);
});
