class AnalysisResult {
  final String sentiment; // "Bullish", "Bearish", "Neutral"
  final List<String> tickers; // e.g., ["AAPL", "TSLA"]
  final String? reasoning; // Optional explanation

  const AnalysisResult({
    required this.sentiment,
    required this.tickers,
    this.reasoning,
  });

  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    return AnalysisResult(
      sentiment: json['sentiment'] as String? ?? 'Neutral',
      tickers: (json['tickers'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      reasoning: json['reasoning'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sentiment': sentiment,
      'tickers': tickers,
      if (reasoning != null) 'reasoning': reasoning,
    };
  }

  factory AnalysisResult.empty() {
    return const AnalysisResult(
      sentiment: 'Neutral',
      tickers: [],
    );
  }

  @override
  String toString() {
    return 'AnalysisResult(sentiment: $sentiment, tickers: $tickers, reasoning: $reasoning)';
  }
}
