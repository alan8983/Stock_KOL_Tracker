import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:markdown/markdown.dart' as md;
import '../../models/analysis_result.dart';

class GeminiService {
  final GenerativeModel _model;

  GeminiService({required String apiKey})
      : _model = GenerativeModel(
          model: 'gemini-2.5-flash', // 開發階段固定使用 gemini-2.5-flash
          apiKey: apiKey,
          generationConfig: GenerationConfig(
            temperature: 0.7,
            topK: 40,
            topP: 0.95,
            maxOutputTokens: 2048,
          ),
        ) {
    // Version check - if you see this, new code is loaded
    print('XXXXXXXXXX GeminiService INITIALIZED - NEW VERSION 2024-12-13-v2 XXXXXXXXXX');
  }

  Future<AnalysisResult> analyzeText(String text) async {
    // #region agent log
    print('🔬🔬🔬🔬🔬 NEW CODE IS RUNNING - VERSION 2024-12-13 🔬🔬🔬🔬🔬');
    // #endregion
    
    if (text.trim().isEmpty) {
      print('⚠️ GeminiService: 輸入文字為空');
      return AnalysisResult.empty();
    }

    try {
      print('🤖 GeminiService: 開始分析文字 (長度: ${text.length})');
      
      final prompt = _buildPrompt(text);
      final content = [Content.text(prompt)];
      
      final response = await _model.generateContent(content);
      
      // #region agent log
      print('🔬🔬🔬 RAW RESPONSE LENGTH: ${response.text?.length ?? 0}');
      print('🔬🔬🔬 RAW RESPONSE FULL TEXT START:');
      print('🔬🔬🔬 ${response.text}');
      print('🔬🔬🔬 RAW RESPONSE FULL TEXT END');
      // #endregion
      
      print('✅ GeminiService: 收到回應');

      if (response.text == null || response.text!.isEmpty) {
        print('⚠️ GeminiService: 回應內容為空');
        return AnalysisResult.empty();
      }

      print('📝 GeminiService: 原始回應長度: ${response.text!.length}');

      // Extract JSON from response (handle markdown code blocks)
      final jsonString = _extractJson(response.text!);
      
      // #region agent log
      print('🔬🔬🔬 EXTRACTED JSON LENGTH: ${jsonString.length}');
      print('🔬🔬🔬 EXTRACTED JSON START:');
      print('🔬🔬🔬 $jsonString');
      print('🔬🔬🔬 EXTRACTED JSON END');
      // #endregion
      
      print('📋 GeminiService: 提取的JSON: $jsonString');
      
      // 嘗試解析 JSON，如果不完整則嘗試修復
      Map<String, dynamic> jsonData;
      try {
        jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
      } on FormatException catch (e) {
        print('⚠️ GeminiService: JSON 解析失敗，嘗試修復不完整的 JSON...');
        print('   錯誤: $e');
        
        // 嘗試修復不完整的 JSON
        final repairedJson = _repairIncompleteJson(jsonString);
        if (repairedJson != null) {
          try {
            jsonData = jsonDecode(repairedJson) as Map<String, dynamic>;
            print('✅ GeminiService: JSON 修復成功');
          } catch (e2) {
            print('❌ GeminiService: JSON 修復後仍無法解析: $e2');
            // 嘗試從不完整的 JSON 中提取部分資料
            return _extractPartialResult(jsonString);
          }
        } else {
          // 無法修復，嘗試提取部分資料
          return _extractPartialResult(jsonString);
        }
      }
      
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
你是一個專業的美股金融分析助手。請分析以下 KOL 的投資觀點文字。

任務：
1. 情緒分類：Bullish (看多), Bearish (看空), Neutral (中立)
2. 提取提及的美股代號 (1-5個大寫字母，如 AAPL、TSLA)
3. 辨識 KOL 名稱（通常在文章開頭1-3行或結尾，如「蕭上農」、「IEObserve 國際經濟觀察」等）
4. 辨識發文時間（支援相對時間如「3小時前」、「16小時」，或絕對時間如「12月11日下午2:02」）
5. 提供核心論述摘要（3-5個要點，每點30字內）
   - 專注於投資論述、市場觀點、技術分析等內容
   - 避免重複 metadata（股票代號、情緒判斷等）
   - 用精簡、專業的語言呈現
6. 識別文章頭尾的冗餘文字（metadata 資訊）
   - **作者資訊**：如「作者：XXX」、「撰文：XXX」、「文/XXX」
   - **發布時間**：如「發布於 2023/12/16」、「2023-12-16 10:30」
   - **閱讀次數/統計**：如「已有 1,234 次閱讀」、「觀看次數：XXX」、「瀏覽 XXX 次」
   - **社群分享按鈕**：如「分享到 Facebook」、「按讚」、「留言」、「訂閱」
   - **免責聲明/版權**：如「本文僅供參考」、「版權所有」、「不構成投資建議」
   - **廣告/推廣**：如「訂閱頻道」、「加入 VIP」、「購買課程」、「了解更多」
   - 注意：只識別出現在文章**開頭（前3-5行）**或**結尾（後3-5行）**的冗餘文字
   - 記錄每段冗餘文字的**完整內容**、**位置**（start/end）、**行號**（1-based）

範例輸出：
{
  "sentiment": "Bullish",
  "tickers": ["AAPL", "TSLA"],
  "kolName": "蕭上農",
  "postedAtText": "3小時前",
  "reasoning": "看好科技股在 AI 浪潮下的成長潛力",
  "summary": [
    "蘋果新款 Vision Pro 預購超出預期，顯示市場對創新產品接受度高",
    "特斯拉 Q4 交車量創新高，產能爬升速度快於預期",
    "美聯儲轉向鴿派，降息預期提升科技股估值",
    "中國市場復甦帶動電動車需求回溫",
    "半導體供應鏈問題緩解，有利科技產業發展"
  ],
  "redundantText": {
    "author": {
      "text": "作者：蕭上農",
      "position": "start",
      "lineNumbers": [1],
      "category": "author"
    },
    "publishTime": {
      "text": "發布於 2023年12月16日",
      "position": "start",
      "lineNumbers": [2],
      "category": "publishTime"
    },
    "readCount": {
      "text": "已有 1,234 次閱讀",
      "position": "end",
      "lineNumbers": [50],
      "category": "readCount"
    },
    "disclaimer": {
      "text": "本文僅供參考，不構成投資建議",
      "position": "end",
      "lineNumbers": [51],
      "category": "disclaimer"
    }
  }
}

注意：
- 如果找不到 KOL 名稱、發文時間或冗餘文字，請將對應欄位設為 null 或省略
- KOL 名稱通常是個人名字或機構名稱，不要包含「發表者」、「作者」等詞彙
- 發文時間請保留原始格式，不要轉換
- redundantText 的 key 可以是任意唯一識別符（如 author、publishTime、readCount1、disclaimer1 等）
- 只識別明顯的冗餘資訊，不要把正文內容標記為冗餘
- **JSON 格式要求：所有 JSON 字串值中必須使用半形括號 ( )，禁止使用全形括號（ ）。例如應寫「輝達(NVDA)面臨」而非「輝達（NVDA）面臨」**

待分析文字：
$text

**重要：請直接回傳純 JSON 格式，不要使用 markdown 代碼塊（```json）包裹，直接從 { 開始，到 } 結束。確保 summary 陣列包含 3-5 個要點。所有 JSON 字串值中的括號必須使用半形括號 ( )，不可使用全形括號（ ）。**
''';
  }

  String _extractJson(String text) {
    // #region agent log
    print('🔬🔬🔬 _extractJson CALLED - INPUT LENGTH: ${text.length}');
    print('🔬🔬🔬 _extractJson INPUT: $text');
    // #endregion

    // 優先使用 markdown parser 找出第一個 code fence
    final fenced = _extractFromMarkdownFence(text);
    if (fenced != null && fenced.trim().isNotEmpty) {
      final fencedJson = _sliceJsonObject(fenced.trim()) ?? fenced.trim();
      print('🔬🔬🔬 FENCED JSON FOUND (length=${fencedJson.length})');
      return fencedJson;
    }

    // 若無 code fence，改用括號計數找出最外層 JSON 物件
    final sliced = _sliceJsonObject(text);
    if (sliced != null && sliced.trim().isNotEmpty) {
      print('🔬🔬🔬 BRACE-SLICED JSON FOUND (length=${sliced.length})');
      return sliced.trim();
    }

    // 若仍找不到，回傳原文 trimmed 讓上層判斷
    final fallback = text.trim();
    print('🔬🔬🔬 FALLBACK JSON STRING (length=${fallback.length})');
    return fallback;
  }

  String? _extractFromMarkdownFence(String text) {
    try {
      final doc = md.Document(encodeHtml: false);
      final nodes = doc.parseLines(const LineSplitter().convert(text));
      for (final node in nodes) {
        final code = _findFirstCode(node);
        if (code != null && code.trim().isNotEmpty) {
          return code;
        }
      }
    } catch (e) {
      print('🔬🔬🔬 markdown parse failed: $e');
    }
    return null;
  }

  String? _findFirstCode(md.Node node) {
    if (node is md.Element) {
      if (node.tag == 'code') {
        return node.textContent;
      }
      for (final child in node.children ?? const <md.Node>[]) {
        final code = _findFirstCode(child);
        if (code != null) return code;
      }
    }
    return null;
  }

  String? _sliceJsonObject(String source) {
    final text = source.trim();
    var inString = false;
    var escaped = false;
    var depth = 0;
    var start = -1;

    for (var i = 0; i < text.length; i++) {
      final char = text[i];

      if (escaped) {
        escaped = false;
        continue;
      }

      if (char == '\\') {
        escaped = true;
        continue;
      }

      if (char == '"') {
        inString = !inString;
        continue;
      }

      if (inString) continue;

      if (char == '{') {
        if (depth == 0) start = i;
        depth++;
      } else if (char == '}' && depth > 0) {
        depth--;
        if (depth == 0 && start != -1) {
          return text.substring(start, i + 1);
        }
      }
    }

    return null;
  }

  /// 修復不完整的 JSON（例如：未關閉的字串、陣列等）
  String? _repairIncompleteJson(String jsonString) {
    try {
      final text = jsonString.trim();
      if (!text.startsWith('{')) {
        return null;
      }

      var inString = false;
      var escaped = false;
      var braceDepth = 0;
      var bracketDepth = 0;
      var lastValidIndex = -1;

      // 找到最後一個有效的 JSON 結構位置
      for (var i = 0; i < text.length; i++) {
        final char = text[i];

        if (escaped) {
          escaped = false;
          continue;
        }

        if (char == '\\') {
          escaped = true;
          continue;
        }

        if (char == '"') {
          inString = !inString;
          continue;
        }

        if (inString) continue;

        if (char == '{') {
          braceDepth++;
          lastValidIndex = i;
        } else if (char == '}') {
          braceDepth--;
          if (braceDepth == 0) {
            lastValidIndex = i;
          }
        } else if (char == '[') {
          bracketDepth++;
        } else if (char == ']') {
          bracketDepth--;
        }
      }

      // 如果 JSON 看起來不完整，嘗試修復
      if (braceDepth > 0 || bracketDepth > 0 || inString) {
        var repaired = text.substring(0, lastValidIndex + 1);
        
        // 關閉未完成的字串
        if (inString) {
          // 找到最後一個未關閉的字串位置
          var lastQuoteIndex = repaired.lastIndexOf('"');
          if (lastQuoteIndex != -1) {
            // 檢查這個引號是否被轉義
            var beforeQuote = repaired.substring(0, lastQuoteIndex);
            var backslashCount = 0;
            for (var i = beforeQuote.length - 1; i >= 0 && beforeQuote[i] == '\\'; i--) {
              backslashCount++;
            }
            // 如果引號沒有被轉義（偶數個反斜線），則字串未關閉
            if (backslashCount % 2 == 0) {
              repaired += '"';
            }
          }
        }
        
        // 關閉未完成的陣列
        while (bracketDepth > 0) {
          repaired += ']';
          bracketDepth--;
        }
        
        // 關閉未完成的物件
        while (braceDepth > 0) {
          repaired += '}';
          braceDepth--;
        }
        
        return repaired;
      }

      return null;
    } catch (e) {
      print('🔬🔬🔬 _repairIncompleteJson 錯誤: $e');
      return null;
    }
  }

  /// 從不完整的 JSON 中提取部分可用的資料
  AnalysisResult _extractPartialResult(String jsonString) {
    print('🔧 GeminiService: 嘗試從不完整的 JSON 中提取部分資料...');
    
    try {
      final result = <String, dynamic>{};
      
      // 使用正則表達式提取基本欄位
      final sentimentMatch = RegExp(r'"sentiment"\s*:\s*"([^"]+)"').firstMatch(jsonString);
      if (sentimentMatch != null) {
        result['sentiment'] = sentimentMatch.group(1);
      }
      
      // 提取 tickers 陣列
      final tickersMatch = RegExp(r'"tickers"\s*:\s*\[(.*?)\]').firstMatch(jsonString);
      if (tickersMatch != null) {
        final tickersStr = tickersMatch.group(1);
        if (tickersStr != null && tickersStr.trim().isNotEmpty) {
          final tickers = tickersStr
              .split(',')
              .map((t) => t.trim().replaceAll('"', '').replaceAll("'", ''))
              .where((t) => t.isNotEmpty)
              .toList();
          result['tickers'] = tickers;
        } else {
          result['tickers'] = [];
        }
      }
      
      // 提取 kolName
      final kolNameMatch = RegExp(r'"kolName"\s*:\s*"([^"]+)"').firstMatch(jsonString);
      if (kolNameMatch != null) {
        result['kolName'] = kolNameMatch.group(1);
      }
      
      // 提取 postedAtText
      final postedAtMatch = RegExp(r'"postedAtText"\s*:\s*"([^"]+)"').firstMatch(jsonString);
      if (postedAtMatch != null) {
        result['postedAtText'] = postedAtMatch.group(1);
      }
      
      // 提取 summary 陣列（可能不完整）
      final summaryMatch = RegExp(r'"summary"\s*:\s*\[(.*?)(?:\]|$)').firstMatch(jsonString);
      if (summaryMatch != null) {
        final summaryStr = summaryMatch.group(1);
        if (summaryStr != null && summaryStr.trim().isNotEmpty) {
          // 嘗試提取完整的字串項目
          final summaryItems = <String>[];
          final itemPattern = RegExp(r'"([^"]*)"');
          final matches = itemPattern.allMatches(summaryStr);
          for (final match in matches) {
            final item = match.group(1);
            if (item != null && item.trim().isNotEmpty) {
              summaryItems.add(item);
            }
          }
          result['summary'] = summaryItems;
        } else {
          result['summary'] = [];
        }
      }
      
      // 如果至少提取到一些資料，使用它
      if (result.isNotEmpty) {
        print('✅ GeminiService: 成功提取部分資料 - 情緒: ${result['sentiment']}, 股票: ${result['tickers']}');
        return AnalysisResult.fromJson(result);
      }
    } catch (e) {
      print('❌ GeminiService: 提取部分資料時發生錯誤: $e');
    }
    
    // 如果無法提取任何資料，返回空結果
    print('⚠️ GeminiService: 無法從不完整的 JSON 中提取資料，返回空結果');
    return AnalysisResult.empty();
  }

  // 測試用入口，方便驗證 JSON 擷取行為
  String debugExtractJson(String text) => _extractJson(text);
}
