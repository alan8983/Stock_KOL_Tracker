/// 漲跌幅計算結果
/// 包含多個時間區間的漲跌幅資料
class PriceChangeResult {
  /// 貼文 ID
  final int postId;
  
  /// 股票代碼
  final String ticker;
  
  /// 發文時間
  final DateTime postedAt;
  
  /// 各時間區間的漲跌幅
  /// key: 時間區間（天數），例如 5, 30, 90, 365
  /// value: 漲跌幅百分比，null 表示資料不足
  final Map<int, double?> changes;
  
  /// 計算時間
  final DateTime calculatedAt;

  const PriceChangeResult({
    required this.postId,
    required this.ticker,
    required this.postedAt,
    required this.changes,
    required this.calculatedAt,
  });

  /// 5 天漲跌幅
  double? get change5d => changes[5];

  /// 30 天漲跌幅
  double? get change30d => changes[30];

  /// 90 天漲跌幅
  double? get change90d => changes[90];

  /// 365 天漲跌幅
  double? get change365d => changes[365];

  /// 是否有任何有效的漲跌幅資料
  bool get hasAnyData => changes.values.any((value) => value != null);

  /// 複製並修改部分屬性
  PriceChangeResult copyWith({
    int? postId,
    String? ticker,
    DateTime? postedAt,
    Map<int, double?>? changes,
    DateTime? calculatedAt,
  }) {
    return PriceChangeResult(
      postId: postId ?? this.postId,
      ticker: ticker ?? this.ticker,
      postedAt: postedAt ?? this.postedAt,
      changes: changes ?? this.changes,
      calculatedAt: calculatedAt ?? this.calculatedAt,
    );
  }

  @override
  String toString() {
    return 'PriceChangeResult(postId: $postId, ticker: $ticker, '
        'changes: $changes, calculatedAt: $calculatedAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is PriceChangeResult &&
        other.postId == postId &&
        other.ticker == ticker &&
        other.postedAt == postedAt &&
        _mapsEqual(other.changes, changes) &&
        other.calculatedAt == calculatedAt;
  }

  @override
  int get hashCode {
    return postId.hashCode ^
        ticker.hashCode ^
        postedAt.hashCode ^
        changes.hashCode ^
        calculatedAt.hashCode;
  }

  /// 比較兩個 Map 是否相等
  bool _mapsEqual(Map<int, double?> a, Map<int, double?> b) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || a[key] != b[key]) {
        return false;
      }
    }
    return true;
  }
}
