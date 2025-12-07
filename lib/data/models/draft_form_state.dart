import '../models/analysis_result.dart';

class DraftFormState {
  final String content; // 主文內容
  final String? ticker; // 投資標的
  final String sentiment; // 走勢情緒
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
        ticker != null &&
        ticker!.isNotEmpty &&
        kolId != null &&
        postedAt != null;
  }
}
