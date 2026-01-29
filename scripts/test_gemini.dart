import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  // 載入 .env 檔案（如果存在）
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    print('⚠️  無法載入 .env 檔案: $e');
  }
  
  // 從環境變數讀取 API Key（請勿硬編碼真實的 keys）
  final apiKey = dotenv.env['GEMINI_API_KEY'] ?? 
                 Platform.environment['GEMINI_API_KEY'] ?? '';
  
  if (apiKey.isEmpty) {
    print('❌ 錯誤: 未設定 GEMINI_API_KEY');
    print('   請在 .env 檔案中設定 GEMINI_API_KEY=your_key_here');
    print('   或使用環境變數: export GEMINI_API_KEY=your_key_here');
    exit(1);
  }
  
  final dio = Dio();
  
  print('\n📋 正在檢查 Gemini API 狀態...\n');
  
  try {
    // List available models
    final response = await dio.get(
      'https://generativelanguage.googleapis.com/v1beta/models',
      queryParameters: {'key': apiKey},
    );
    
    if (response.statusCode == 200) {
      final models = response.data['models'] as List;
      print('✅ API Key 有效！');
      print('\n可用的模型（支援 generateContent）：\n');
      
      for (var model in models) {
        final name = model['name'] as String;
        final supportedMethods = (model['supportedGenerationMethods'] as List?)?.cast<String>() ?? [];
        
        if (supportedMethods.contains('generateContent')) {
          print('   ✓ ${name.replaceAll('models/', '')}');
        }
      }
      
      print('\n開發階段請使用: gemini-2.5-flash');
    }
  } catch (e) {
    print('❌ 錯誤: $e');
  }
}
