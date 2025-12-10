import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../models/analysis_result.dart';

class GeminiService {
  final GenerativeModel _model;

  GeminiService({required String apiKey})
      : _model = GenerativeModel(
          model: 'gemini-flash-latest', // 免費層支援的最新 Flash 模型
          apiKey: apiKey,
          generationConfig: GenerationConfig(
            temperature: 0.7,
            topK: 40,
            topP: 0.95,
            maxOutputTokens: 1024,
          ),
        );

  Future<AnalysisResult> analyzeText(String text) async {
    if (text.trim().isEmpty) {
      print('⚠️ GeminiService: 輸入文字為空');
      return AnalysisResult.empty();
    }

    try {
      print('🤖 GeminiService: 開始分析文字 (長度: ${text.length})');
      
      final prompt = _buildPrompt(text);
      final content = [Content.text(prompt)];
      
      final response = await _model.generateContent(content);
      
      print('✅ GeminiService: 收到回應');

      if (response.text == null || response.text!.isEmpty) {
        print('⚠️ GeminiService: 回應內容為空');
        return AnalysisResult.empty();
      }

      print('📝 GeminiService: 原始回應長度: ${response.text!.length}');

      // Extract JSON from response (handle markdown code blocks)
      final jsonString = _extractJson(response.text!);
      print('📋 GeminiService: 提取的JSON: $jsonString');
      
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
      final result = AnalysisResult.fromJson(jsonData);
      
      print('✅ GeminiService: 分析完成 - 情緒: ${result.sentiment}, 股票: ${result.tickers}');

      return result;
    } on GenerativeAIException catch (e) {
      // Gemini API 特定錯誤
      print('❌ GeminiService API錯誤: ${e.message}');
      print('   錯誤類型: ${e.runtimeType}');
      rethrow; // 重新拋出以便上層處理
    } on FormatException catch (e) {
      // JSON 解析錯誤
      print('❌ GeminiService JSON解析錯誤: $e');
      print('   請檢查API回應格式');
      return AnalysisResult.empty();
    } catch (e, stackTrace) {
      // 其他未預期的錯誤
      print('❌ GeminiService 未知錯誤: $e');
      print('   Stack trace: $stackTrace');
      rethrow; // 重新拋出以便上層處理
    }
  }

  String _buildPrompt(String text) {
    return '''
你是一個專業的美股金融分析助手。請分析以下文字的投資情緒，並提取提及的美股代號。

規則：
1. 情緒分類：Bullish (看多), Bearish (看空), Neutral (中立)
2. 只提取有效的美股代號 (1-5個大寫字母)
3. 必須以 JSON 格式回傳

範例輸出：
{
  "sentiment": "Bullish",
  "tickers": ["AAPL", "TSLA"],
  "reasoning": "文章提到蘋果新產品熱銷，特斯拉交車量增長"
}

待分析文字：
$text
''';
  }

  String _extractJson(String text) {
    // Remove markdown code blocks if present
    final codeBlockPattern = RegExp(r'```(?:json)?\s*([\s\S]*?)\s*```');
    final match = codeBlockPattern.firstMatch(text);
    
    if (match != null) {
      return match.group(1)!.trim();
    }

    // Try to find JSON object in text
    final jsonPattern = RegExp(r'\{[\s\S]*\}');
    final jsonMatch = jsonPattern.firstMatch(text);
    
    if (jsonMatch != null) {
      return jsonMatch.group(0)!.trim();
    }

    // Return as-is and let JSON parser handle it
    return text.trim();
  }
}
