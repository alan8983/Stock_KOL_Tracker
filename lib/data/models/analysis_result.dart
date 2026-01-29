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

/// 單一標的分析結果
class TickerAnalysis {
  final String ticker; // 股票代號
  final String sentiment; // "Bullish", "Bearish", "Neutral"
  final bool isPrimary; // 是否為主要標的

  const TickerAnalysis({
    required this.ticker,
    required this.sentiment,
    this.isPrimary = false,
  });

  factory TickerAnalysis.fromJson(Map<String, dynamic> json) {
    return TickerAnalysis(
      ticker: json['ticker'] as String,
      sentiment: json['sentiment'] as String? ?? 'Neutral',
      isPrimary: json['isPrimary'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ticker': ticker,
      'sentiment': sentiment,
      'isPrimary': isPrimary,
    };
  }

  @override
  String toString() {
    return 'TickerAnalysis(ticker: $ticker, sentiment: $sentiment, isPrimary: $isPrimary)';
  }
}

class AnalysisResult {
  // 向後兼容：保留舊欄位，但優先使用 tickerAnalyses
  @Deprecated('使用 tickerAnalyses 代替')
  final String? sentiment; // "Bullish", "Bearish", "Neutral"
  @Deprecated('使用 tickerAnalyses 代替')
  final List<String>? tickers; // e.g., ["AAPL", "TSLA"]
  
  final List<TickerAnalysis> tickerAnalyses; // 每個標的的獨立分析
  final String? reasoning; // Optional explanation
  final List<String> summary; // 核心論述摘要（最多5點）
  final String? kolName; // KOL 名稱（AI 辨識）
  final String? postedAtText; // 發文時間文字（AI 辨識）
  final Map<String, RedundantTextInfo>? redundantText; // 冗餘文字識別結果

  const AnalysisResult({
    this.sentiment,
    this.tickers,
    this.tickerAnalyses = const [],
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

    // 優先使用新的 tickerAnalyses 格式
    List<TickerAnalysis> tickerAnalyses = [];
    if (json['tickerAnalyses'] != null) {
      final tickerAnalysesJson = json['tickerAnalyses'] as List<dynamic>;
      tickerAnalyses = tickerAnalysesJson
          .map((e) => TickerAnalysis.fromJson(e as Map<String, dynamic>))
          .toList();
    } else if (json['tickers'] != null) {
      // 向後兼容：從舊格式轉換
      final tickers = (json['tickers'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [];
      final sentiment = json['sentiment'] as String? ?? 'Neutral';
      
      if (tickers.isNotEmpty) {
        // 第一個 ticker 設為主要標的
        tickerAnalyses = tickers.asMap().entries.map((entry) {
          return TickerAnalysis(
            ticker: entry.value,
            sentiment: sentiment,
            isPrimary: entry.key == 0,
          );
        }).toList();
      }
    }

    return AnalysisResult(
      sentiment: json['sentiment'] as String?,
      tickers: (json['tickers'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList(),
      tickerAnalyses: tickerAnalyses,
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
      if (sentiment != null) 'sentiment': sentiment,
      if (tickers != null) 'tickers': tickers,
      if (tickerAnalyses.isNotEmpty)
        'tickerAnalyses': tickerAnalyses.map((e) => e.toJson()).toList(),
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
      tickerAnalyses: [],
      summary: [],
    );
  }

  /// 取得主要標的
  TickerAnalysis? get primaryTicker {
    return tickerAnalyses.firstWhere(
      (t) => t.isPrimary,
      orElse: () => tickerAnalyses.isNotEmpty ? tickerAnalyses.first : throw StateError('No tickers'),
    );
  }

  /// 取得所有標的代號列表
  List<String> get allTickers {
    return tickerAnalyses.map((t) => t.ticker).toList();
  }

  @override
  String toString() {
    return 'AnalysisResult(sentiment: $sentiment, tickers: $tickers, tickerAnalyses: $tickerAnalyses, reasoning: $reasoning, summary: $summary, kolName: $kolName, postedAtText: $postedAtText, redundantText: $redundantText)';
  }
}
