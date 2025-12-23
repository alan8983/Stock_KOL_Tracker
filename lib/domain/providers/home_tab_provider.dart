import 'package:flutter_riverpod/flutter_riverpod.dart';

/// HomeScreen 的 Tab 索引 Provider
/// 用於從外部控制 HomeScreen 的 Tab 切換
final homeTabIndexProvider = StateProvider<int>((ref) => 0);

