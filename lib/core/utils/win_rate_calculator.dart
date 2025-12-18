import '../../data/database/database.dart';

/// 預測結果
enum PredictionOutcome {
  correct,       // 預測正確
  incorrect,     // 預測錯誤
  neutral,       // 震盪區間（不計入）
  notApplicable, // Neutral 情緒（不計入）
}

/// 預測結果詳情
class PredictionResult {
  final PredictionOutcome outcome;
  final String sentiment;
  final double? priceChange;

  const PredictionResult({
    required this.outcome,
    required this.sentiment,
    this.priceChange,
  });

  bool get countsTowardWinRate =>
      outcome == PredictionOutcome.correct || outcome == PredictionOutcome.incorrect;
}

/// 勝率計算器
/// 
/// 使用門檻版計算方式：
/// - 漲跌幅 > +2% = 實際看漲
/// - 漲跌幅 < -2% = 實際看跌
/// - -2% ≤ 漲跌幅 ≤ +2% = 震盪（不計入勝率）
class WinRateCalculator {
  /// 門檻值：±2%
  static const double threshold = 2.0;

  /// 判斷預測結果
  /// 
  /// [sentiment] 情緒觀點：'Bullish', 'Bearish', 'Neutral'
  /// [priceChange] 實際漲跌幅百分比
  PredictionResult evaluatePrediction({
    required String sentiment,
    required double? priceChange,
  }) {
    // Neutral 情緒不計入勝率
    if (sentiment.toLowerCase() == 'neutral') {
      return PredictionResult(
        outcome: PredictionOutcome.notApplicable,
        sentiment: sentiment,
        priceChange: priceChange,
      );
    }

    // 沒有價格資料，無法判斷
    if (priceChange == null) {
      return PredictionResult(
        outcome: PredictionOutcome.notApplicable,
        sentiment: sentiment,
        priceChange: priceChange,
      );
    }

    // 震盪區間（-2% ~ +2%），不計入勝率
    if (priceChange >= -threshold && priceChange <= threshold) {
      return PredictionResult(
        outcome: PredictionOutcome.neutral,
        sentiment: sentiment,
        priceChange: priceChange,
      );
    }

    // 判斷實際走勢
    final actualTrend = priceChange > threshold ? 'bullish' : 'bearish';
    final predictedTrend = sentiment.toLowerCase();

    // 判斷預測是否正確
    if ((predictedTrend == 'bullish' && actualTrend == 'bullish') ||
        (predictedTrend == 'bearish' && actualTrend == 'bearish')) {
      return PredictionResult(
        outcome: PredictionOutcome.correct,
        sentiment: sentiment,
        priceChange: priceChange,
      );
    } else {
      return PredictionResult(
        outcome: PredictionOutcome.incorrect,
        sentiment: sentiment,
        priceChange: priceChange,
      );
    }
  }

  /// 批次評估多個 Post 的預測結果
  /// 
  /// [posts] 文檔列表
  /// [priceChanges] 漲跌幅資料：postId -> period -> priceChange
  /// [period] 時間區間（5, 30, 90, 365）
  Map<int, PredictionResult> batchEvaluate({
    required List<Post> posts,
    required Map<int, Map<int, double?>> priceChanges,
    required int period,
  }) {
    final results = <int, PredictionResult>{};

    for (final post in posts) {
      final postPriceChanges = priceChanges[post.id];
      final priceChange = postPriceChanges?[period];

      results[post.id] = evaluatePrediction(
        sentiment: post.sentiment,
        priceChange: priceChange,
      );
    }

    return results;
  }
}
