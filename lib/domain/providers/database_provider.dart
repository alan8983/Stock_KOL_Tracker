import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database/database.dart';

/// 提供全域的 AppDatabase 實例
final databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});
