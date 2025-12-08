import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() {
  setUpAll(() async {
    // 載入 .env 檔案（如果存在）
    try {
      await dotenv.load(fileName: '.env');
    } catch (e) {
      print('⚠️  無法載入 .env 檔案: $e');
    }
  });
  
  test('Gemini API Diagnostic - List Available Models', () async {
    // 從環境變數讀取 API Key（請勿硬編碼真實的 keys）
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? 
                   Platform.environment['GEMINI_API_KEY'] ?? '';
    
    if (apiKey.isEmpty) {
      print('❌ 錯誤: 未設定 GEMINI_API_KEY');
      print('   請在 .env 檔案中設定 GEMINI_API_KEY=your_key_here');
      print('   或使用環境變數: export GEMINI_API_KEY=your_key_here');
      fail('未設定 GEMINI_API_KEY');
      return;
    }
    
    final dio = Dio();
    
    try {
      // Try to list available models
      print('\n📋 正在查詢可用的 Gemini 模型...');
      final response = await dio.get(
        'https://generativelanguage.googleapis.com/v1beta/models',
        queryParameters: {'key': apiKey},
      );
      
      if (response.statusCode == 200) {
        final models = response.data['models'] as List;
        print('\n✅ API Key 有效！可用模型列表：');
        for (var model in models) {
          final name = model['name'] as String;
          final supportedMethods = model['supportedGenerationMethods'] as List?;
          if (supportedMethods != null && supportedMethods.contains('generateContent')) {
            print('   - $name (支援 generateContent)');
          }
        }
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 403 || e.response?.statusCode == 401) {
        print('\n❌ API Key 驗證失敗！');
        print('   錯誤: ${e.response?.data}');
        print('\n📝 可能原因：');
        print('   1. API Key 不正確');
        print('   2. Gemini API 未啟用');
        print('   3. API Key 的配額已用完');
        print('\n💡 解決方法：');
        print('   1. 前往 https://aistudio.google.com/');
        print('   2. 檢查 API Key 是否正確');
        print('   3. 確認 Gemini API 已啟用');
      } else if (e.response?.statusCode == 429) {
        print('\n⚠️  已達到速率限制！');
        print('   請稍後再試');
      } else {
        print('\n❌ 未知錯誤: ${e.message}');
        print('   Response: ${e.response?.data}');
      }
      fail('Gemini API 連線失敗');
    } catch (e) {
      print('\n❌ 發生錯誤: $e');
      fail('測試執行失敗');
    }
  }, timeout: const Timeout(Duration(seconds: 30)));
}
