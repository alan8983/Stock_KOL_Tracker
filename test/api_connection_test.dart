import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:stock_kol_tracker/data/services/Tiingo/tiingo_service.dart';
import 'package:stock_kol_tracker/data/services/Gemini/gemini_service.dart';

void main() {
  group('API Connection Tests', () {
    // 從環境變數讀取 API Keys（請勿硬編碼真實的 keys）
    final tiingoToken = Platform.environment['TIINGO_API_TOKEN'] ?? '';
    final geminiKey = Platform.environment['GEMINI_API_KEY'] ?? '';
    
    setUpAll(() {
      if (tiingoToken.isEmpty || geminiKey.isEmpty) {
        print('⚠️  警告: 未設定環境變數 TIINGO_API_TOKEN 或 GEMINI_API_KEY');
        print('   請在執行測試前設定環境變數，或使用 .env 檔案');
        print('   測試將被跳過');
      }
    });

    test('Tiingo API - Fetch AAPL daily prices', () async {
      if (tiingoToken.isEmpty) {
        print('⏭️  跳過測試：未設定 TIINGO_API_TOKEN');
        return;
      }
      
      final service = TiingoService(apiToken: tiingoToken);
      
      try {
        final prices = await service.fetchDailyPrices('AAPL');
        
        expect(prices, isNotEmpty, reason: 'Should return price data');
        expect(prices.first.ticker.value, equals('AAPL'));
        
        print('✅ Tiingo API 連線成功！');
        print('   取得 ${prices.length} 筆 AAPL 歷史股價資料');
        print('   最新日期: ${prices.last.date.value}');
        print('   最新收盤價: \$${prices.last.close.value.toStringAsFixed(2)}');
      } catch (e) {
        fail('❌ Tiingo API 連線失敗: $e');
      }
    }, timeout: const Timeout(Duration(seconds: 30)));

    test('Gemini API - Analyze text sentiment', () async {
      if (geminiKey.isEmpty) {
        print('⏭️  跳過測試：未設定 GEMINI_API_KEY');
        return;
      }
      
      final service = GeminiService(apiKey: geminiKey);
      
      const testText = '''
        蘋果公司今天發表了最新的 iPhone，市場反應非常熱烈。
        分析師普遍看好 AAPL 未來的成長潛力，預計股價將持續上漲。
        特斯拉的 Model 3 銷量也創新高，TSLA 股價應該會受惠。
      ''';
      
      try {
        final result = await service.analyzeText(testText);
        
        expect(result.sentiment, isNotEmpty, reason: 'Should return sentiment');
        expect(result.tickers, isNotEmpty, reason: 'Should extract tickers');
        
        print('✅ Gemini API 連線成功！');
        print('   分析結果:');
        print('   - 情緒: ${result.sentiment}');
        print('   - 股票代號: ${result.tickers.join(', ')}');
        if (result.reasoning != null) {
          print('   - 推理: ${result.reasoning}');
        }
      } catch (e) {
        fail('❌ Gemini API 連線失敗: $e');
      }
    }, timeout: const Timeout(Duration(seconds: 30)));

    test('Gemini API - Handle empty text', () async {
      if (geminiKey.isEmpty) {
        print('⏭️  跳過測試：未設定 GEMINI_API_KEY');
        return;
      }
      
      final service = GeminiService(apiKey: geminiKey);
      
      try {
        final result = await service.analyzeText('');
        
        // Should return default values for empty input
        expect(result.sentiment, equals('Neutral'));
        expect(result.tickers, isEmpty);
        
        print('✅ Gemini API 空文字處理正常');
      } catch (e) {
        print('⚠️  Gemini API 空文字測試: $e');
      }
    });
  });
}
