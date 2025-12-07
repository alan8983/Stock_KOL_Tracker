import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../models/analysis_result.dart';

class GeminiService {
  final GenerativeModel _model;

  GeminiService({required String apiKey})
      : _model = GenerativeModel(
          model: 'gemini-pro',
          apiKey: apiKey,
        );

  Future<AnalysisResult> analyzeText(String text) async {
    try {
      final prompt = _buildPrompt(text);
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);

      if (response.text == null || response.text!.isEmpty) {
        return AnalysisResult.empty();
      }

      // Extract JSON from response (handle markdown code blocks)
      final jsonString = _extractJson(response.text!);
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;

      return AnalysisResult.fromJson(jsonData);
    } catch (e) {
      // Log error in production, return default for now
      print('GeminiService error: $e');
      return AnalysisResult.empty();
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
