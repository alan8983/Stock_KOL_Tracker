import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../data/services/Gemini/gemini_service.dart';
import '../../data/services/Tiingo/tiingo_service.dart';
import 'package:dio/dio.dart';

/// 提供 GeminiService 實例
final geminiServiceProvider = Provider<GeminiService>((ref) {
  String apiKey = '';
  
  try {
    // 安全地讀取環境變數
    // 使用 try-catch 來處理 NotInitializedError
    try {
      apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    } catch (e) {
      // 如果 dotenv 未初始化，會拋出 NotInitializedError
      throw Exception('DotEnv not initialized. Please ensure .env file is loaded in main() before using this provider. Error: $e');
    }
    
    if (apiKey.isEmpty) {
      throw Exception('GEMINI_API_KEY not found. Please check your .env file and ensure it contains GEMINI_API_KEY=your_key_here');
    }
    
    return GeminiService(apiKey: apiKey);
  } catch (e) {
    throw Exception('Failed to initialize GeminiService: $e');
  }
});

/// 提供 TiingoService 實例
final tiingoServiceProvider = Provider<TiingoService>((ref) {
  String apiToken = '';
  
  try {
    // 安全地讀取環境變數
    // 使用 try-catch 來處理 NotInitializedError
    try {
      apiToken = dotenv.env['TIINGO_API_TOKEN'] ?? '';
    } catch (e) {
      // 如果 dotenv 未初始化，會拋出 NotInitializedError
      throw Exception('DotEnv not initialized. Please ensure .env file is loaded in main() before using this provider. Error: $e');
    }
    
    if (apiToken.isEmpty) {
      throw Exception('TIINGO_API_TOKEN not found. Please check your .env file and ensure it contains TIINGO_API_TOKEN=your_token_here');
    }
    
    return TiingoService(apiToken: apiToken, dio: Dio());
  } catch (e) {
    throw Exception('Failed to initialize TiingoService: $e');
  }
});
