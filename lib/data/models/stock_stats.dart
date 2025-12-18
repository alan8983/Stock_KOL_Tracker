/// 股票統計資料
class StockStats {
  /// 股票代碼
  final String ticker;
  
  /// 股票名稱
  final String? stockName;
  
  /// 總討論次數（文檔數）
  final int totalPosts;
  
  /// 討論過的 KOL 數量
  final int kolCount;
  
  /// 看多文檔數
  final int bullishCount;
  
  /// 看空文檔數
  final int bearishCount;
  
  /// 中立文檔數
  final int neutralCount;
  
  /// 近期平均漲跌幅（period -> 平均漲跌幅%）
  final Map<int, double?> avgPriceChanges;

  const StockStats({
    required this.ticker,
    this.stockName,
    required this.totalPosts,
    required this.kolCount,
    required this.bullishCount,
    required this.bearishCount,
    required this.neutralCount,
    required this.avgPriceChanges,
  });

  /// 看多共識百分比（0-100）
  double get bullishConsensus {
    if (totalPosts == 0) return 0.0;
    return (bullishCount / totalPosts) * 100;
  }

  /// 看空共識百分比（0-100）
  double get bearishConsensus {
    if (totalPosts == 0) return 0.0;
    return (bearishCount / totalPosts) * 100;
  }

  /// 中立百分比（0-100）
  double get neutralRatio {
    if (totalPosts == 0) return 0.0;
    return (neutralCount / totalPosts) * 100;
  }

  /// 主要情緒傾向
  String get dominantSentiment {
    if (totalPosts == 0) return 'unknown';
    
    if (bullishCount >= bearishCount && bullishCount >= neutralCount) {
      return 'bullish';
    } else if (bearishCount >= neutralCount) {
      return 'bearish';
    } else {
      return 'neutral';
    }
  }

  /// 共識強度（最高百分比）
  double get consensusStrength {
    return [bullishConsensus, bearishConsensus, neutralRatio].reduce(
      (a, b) => a > b ? a : b,
    );
  }

  /// 共識標籤
  String get consensusLabel {
    if (totalPosts == 0) return '無資料';

    if (bullishConsensus > 70) {
      return '強烈看多';
    } else if (bullishConsensus > 55) {
      return '看多';
    } else if (bearishConsensus > 70) {
      return '強烈看空';
    } else if (bearishConsensus > 55) {
      return '看空';
    } else {
      return '分歧';
    }
  }

  /// 共識顏色（用於 UI 顯示）
  String get consensusColor {
    if (bullishConsensus > 70) return 'darkGreen';
    if (bullishConsensus > 55) return 'lightGreen';
    if (bearishConsensus > 70) return 'darkRed';
    if (bearishConsensus > 55) return 'lightRed';
    return 'grey';
  }

  /// 5 天平均漲跌幅
  double? get avg5d => avgPriceChanges[5];

  /// 30 天平均漲跌幅
  double? get avg30d => avgPriceChanges[30];

  /// 90 天平均漲跌幅
  double? get avg90d => avgPriceChanges[90];

  /// 365 天平均漲跌幅
  double? get avg365d => avgPriceChanges[365];

  /// 是否有足夠的討論（至少 5 篇文檔）
  bool get hasEnoughDiscussion => totalPosts >= 5;

  @override
  String toString() {
    return 'StockStats(ticker: $ticker, posts: $totalPosts, '
        'consensus: $consensusLabel, kols: $kolCount)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StockStats &&
          runtimeType == other.runtimeType &&
          ticker == other.ticker &&
          stockName == other.stockName &&
          totalPosts == other.totalPosts &&
          kolCount == other.kolCount &&
          bullishCount == other.bullishCount &&
          bearishCount == other.bearishCount &&
          neutralCount == other.neutralCount;

  @override
  int get hashCode =>
      ticker.hashCode ^
      stockName.hashCode ^
      totalPosts.hashCode ^
      kolCount.hashCode ^
      bullishCount.hashCode ^
      bearishCount.hashCode ^
      neutralCount.hashCode;
}
