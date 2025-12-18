/// 單一時間區間的勝率統計
class WinRateStats {
  /// 時間區間（天數）
  final int period;
  
  /// 總預測數（不含震盪和 Neutral）
  final int totalPredictions;
  
  /// 正確預測數
  final int correctPredictions;
  
  /// 錯誤預測數
  final int incorrectPredictions;
  
  /// 震盪區間數量（-2% ~ +2%）
  final int neutralCount;
  
  /// Neutral 情緒數量（不計入勝率）
  final int notApplicableCount;

  const WinRateStats({
    required this.period,
    required this.totalPredictions,
    required this.correctPredictions,
    required this.incorrectPredictions,
    required this.neutralCount,
    required this.notApplicableCount,
  });

  /// 勝率百分比（0-100）
  double get winRate {
    if (totalPredictions == 0) return 0.0;
    return (correctPredictions / totalPredictions) * 100;
  }

  /// 準確度（包含所有預測，含震盪區間）
  double get accuracy {
    final total = correctPredictions + incorrectPredictions + neutralCount;
    if (total == 0) return 0.0;
    return (correctPredictions / total) * 100;
  }

  /// 是否有足夠的資料（至少 10 筆有效預測）
  bool get hasEnoughData => totalPredictions >= 10;

  /// 勝率等級
  String get ratingLabel {
    if (!hasEnoughData) return '資料不足';
    if (winRate >= 70) return '優秀';
    if (winRate >= 60) return '良好';
    if (winRate >= 50) return '普通';
    return '待改進';
  }

  @override
  String toString() {
    return 'WinRateStats(period: $period, winRate: ${winRate.toStringAsFixed(1)}%, '
        'correct: $correctPredictions, incorrect: $incorrectPredictions, '
        'neutral: $neutralCount, N/A: $notApplicableCount)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WinRateStats &&
          runtimeType == other.runtimeType &&
          period == other.period &&
          totalPredictions == other.totalPredictions &&
          correctPredictions == other.correctPredictions &&
          incorrectPredictions == other.incorrectPredictions &&
          neutralCount == other.neutralCount &&
          notApplicableCount == other.notApplicableCount;

  @override
  int get hashCode =>
      period.hashCode ^
      totalPredictions.hashCode ^
      correctPredictions.hashCode ^
      incorrectPredictions.hashCode ^
      neutralCount.hashCode ^
      notApplicableCount.hashCode;
}

/// 多時間區間的勝率統計
class MultiPeriodWinRateStats {
  /// 各時間區間的統計資料
  final Map<int, WinRateStats> periodStats;

  const MultiPeriodWinRateStats({
    required this.periodStats,
  });

  /// 5 天勝率統計
  WinRateStats? get stats5d => periodStats[5];

  /// 30 天勝率統計
  WinRateStats? get stats30d => periodStats[30];

  /// 90 天勝率統計
  WinRateStats? get stats90d => periodStats[90];

  /// 365 天勝率統計
  WinRateStats? get stats365d => periodStats[365];

  /// 整體平均勝率（加權平均，權重為預測數）
  double get averageWinRate {
    if (periodStats.isEmpty) return 0.0;

    double totalWeightedWinRate = 0.0;
    int totalPredictions = 0;

    for (final stats in periodStats.values) {
      if (stats.totalPredictions > 0) {
        totalWeightedWinRate += stats.winRate * stats.totalPredictions;
        totalPredictions += stats.totalPredictions;
      }
    }

    if (totalPredictions == 0) return 0.0;
    return totalWeightedWinRate / totalPredictions;
  }

  /// 是否有任何有效資料
  bool get hasAnyData => periodStats.values.any((s) => s.totalPredictions > 0);

  /// 表現最好的時間區間
  int? get bestPeriod {
    if (periodStats.isEmpty) return null;

    WinRateStats? best;
    int? bestPeriod;

    for (final entry in periodStats.entries) {
      if (entry.value.hasEnoughData) {
        if (best == null || entry.value.winRate > best.winRate) {
          best = entry.value;
          bestPeriod = entry.key;
        }
      }
    }

    return bestPeriod;
  }

  @override
  String toString() {
    return 'MultiPeriodWinRateStats(avgWinRate: ${averageWinRate.toStringAsFixed(1)}%, '
        'periods: ${periodStats.keys.toList()})';
  }
}
