import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../data/services/Gemini/gemini_service.dart';
import '../../data/services/Tiingo/tiingo_service.dart';
import 'package:dio/dio.dart';

/// 提供 GeminiService 實例
final geminiServiceProvider = Provider<GeminiService>((ref) {
  final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
  if (apiKey.isEmpty) {
    throw Exception('GEMINI_API_KEY not found in .env file');
  }
  return GeminiService(apiKey: apiKey);
});

/// 提供 TiingoService 實例
final tiingoServiceProvider = Provider<TiingoService>((ref) {
  final apiToken = dotenv.env['TIINGO_API_TOKEN'] ?? '';
  if (apiToken.isEmpty) {
    throw Exception('TIINGO_API_TOKEN not found in .env file');
  }
  return TiingoService(apiToken: apiToken, dio: Dio());
});
