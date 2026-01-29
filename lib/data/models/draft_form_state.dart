import '../models/analysis_result.dart';
import '../repositories/post_stock_repository.dart';

class DraftFormState {
  final String content; // 主文內容
  // 向後兼容：保留舊欄位
  @Deprecated('使用 tickerAnalyses 代替')
  final String? ticker;
  @Deprecated('使用 tickerAnalyses 代替')
  final String sentiment;
  final List<TickerAnalysisData> tickerAnalyses; // 多標的分析資料
  final int? kolId; // KOL ID
  final DateTime? postedAt; // 發文時間
  final bool isAnalyzing; // AI 分析中
  final bool isSaving; // 儲存中
  final AnalysisResult? aiResult; // AI 分析結果
  final String? errorMessage; // 錯誤訊息

  const DraftFormState({
    this.content = '',
    this.ticker,
    this.sentiment = 'Neutral',
    this.tickerAnalyses = const [],
    this.kolId,
    this.postedAt,
    this.isAnalyzing = false,
    this.isSaving = false,
    this.aiResult,
    this.errorMessage,
  });

  DraftFormState copyWith({
    String? content,
    String? ticker,
    String? sentiment,
    List<TickerAnalysisData>? tickerAnalyses,
    int? kolId,
    DateTime? postedAt,
    bool? isAnalyzing,
    bool? isSaving,
    AnalysisResult? aiResult,
    String? errorMessage,
  }) {
    return DraftFormState(
      content: content ?? this.content,
      ticker: ticker ?? this.ticker,
      sentiment: sentiment ?? this.sentiment,
      tickerAnalyses: tickerAnalyses ?? this.tickerAnalyses,
      kolId: kolId ?? this.kolId,
      postedAt: postedAt ?? this.postedAt,
      isAnalyzing: isAnalyzing ?? this.isAnalyzing,
      isSaving: isSaving ?? this.isSaving,
      aiResult: aiResult ?? this.aiResult,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  /// 清除錯誤訊息
  DraftFormState clearError() {
    return copyWith(errorMessage: null);
  }

  /// 檢查是否可儲存
  bool get canSave {
    return content.isNotEmpty &&
        tickerAnalyses.isNotEmpty &&
        kolId != null &&
        postedAt != null;
  }
  
  /// 取得主要標的
  TickerAnalysisData? get primaryTicker {
    return tickerAnalyses.firstWhere(
      (t) => t.isPrimary,
      orElse: () => tickerAnalyses.isNotEmpty ? tickerAnalyses.first : throw StateError('No tickers'),
    );
  }
}

/// TickerAnalysis 資料傳輸物件（用於 DraftFormState）
class TickerAnalysisData {
  final String ticker;
  final String sentiment;
  final bool isPrimary;

  const TickerAnalysisData({
    required this.ticker,
    required this.sentiment,
    this.isPrimary = false,
  });
  
  TickerAnalysisData copyWith({
    String? ticker,
    String? sentiment,
    bool? isPrimary,
  }) {
    return TickerAnalysisData(
      ticker: ticker ?? this.ticker,
      sentiment: sentiment ?? this.sentiment,
      isPrimary: isPrimary ?? this.isPrimary,
    );
  }
}
