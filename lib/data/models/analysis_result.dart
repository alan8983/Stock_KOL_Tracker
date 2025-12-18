/// 冗餘文字資訊
class RedundantTextInfo {
  final String text; // 冗餘文字內容
  final String position; // 位置（'start' 或 'end'）
  final List<int> lineNumbers; // 行號列表（1-based）
  final String category; // 類別（author/publishTime/readCount/social/disclaimer/promotion）

  const RedundantTextInfo({
    required this.text,
    required this.position,
    required this.lineNumbers,
    required this.category,
  });

  factory RedundantTextInfo.fromJson(Map<String, dynamic> json) {
    return RedundantTextInfo(
      text: json['text'] as String,
      position: json['position'] as String,
      lineNumbers: (json['lineNumbers'] as List<dynamic>)
          .map((e) => e as int)
          .toList(),
      category: json['category'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'position': position,
      'lineNumbers': lineNumbers,
      'category': category,
    };
  }

  @override
  String toString() {
    return 'RedundantTextInfo(text: $text, position: $position, lineNumbers: $lineNumbers, category: $category)';
  }
}

class AnalysisResult {
  final String sentiment; // "Bullish", "Bearish", "Neutral"
  final List<String> tickers; // e.g., ["AAPL", "TSLA"]
  final String? reasoning; // Optional explanation
  final List<String> summary; // 核心論述摘要（最多5點）
  final String? kolName; // KOL 名稱（AI 辨識）
  final String? postedAtText; // 發文時間文字（AI 辨識）
  final Map<String, RedundantTextInfo>? redundantText; // 冗餘文字識別結果

  const AnalysisResult({
    required this.sentiment,
    required this.tickers,
    this.reasoning,
    this.summary = const [],
    this.kolName,
    this.postedAtText,
    this.redundantText,
  });

  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    Map<String, RedundantTextInfo>? redundantTextMap;
    if (json['redundantText'] != null) {
      final redundantTextJson = json['redundantText'] as Map<String, dynamic>;
      redundantTextMap = redundantTextJson.map(
        (key, value) => MapEntry(
          key,
          RedundantTextInfo.fromJson(value as Map<String, dynamic>),
        ),
      );
    }

    return AnalysisResult(
      sentiment: json['sentiment'] as String? ?? 'Neutral',
      tickers: (json['tickers'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      reasoning: json['reasoning'] as String?,
      summary: (json['summary'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      kolName: json['kolName'] as String?,
      postedAtText: json['postedAtText'] as String?,
      redundantText: redundantTextMap,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sentiment': sentiment,
      'tickers': tickers,
      if (reasoning != null) 'reasoning': reasoning,
      if (summary.isNotEmpty) 'summary': summary,
      if (kolName != null) 'kolName': kolName,
      if (postedAtText != null) 'postedAtText': postedAtText,
      if (redundantText != null)
        'redundantText': redundantText!.map(
          (key, value) => MapEntry(key, value.toJson()),
        ),
    };
  }

  factory AnalysisResult.empty() {
    return const AnalysisResult(
      sentiment: 'Neutral',
      tickers: [],
      summary: [],
    );
  }

  @override
  String toString() {
    return 'AnalysisResult(sentiment: $sentiment, tickers: $tickers, reasoning: $reasoning, summary: $summary, kolName: $kolName, postedAtText: $postedAtText, redundantText: $redundantText)';
  }
}
