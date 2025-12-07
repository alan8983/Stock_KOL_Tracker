import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/draft_form_state.dart';
import '../../data/models/relative_time_input.dart';
import '../../data/database/database.dart';
import '../../data/repositories/post_repository.dart';
import '../../data/repositories/stock_repository.dart';
import '../../data/services/Gemini/gemini_service.dart';
import 'repository_providers.dart';
import 'service_providers.dart';

/// DraftStateNotifier - 管理單一草稿的編輯狀態
class DraftStateNotifier extends StateNotifier<DraftFormState> {
  final PostRepository _postRepository;
  final StockRepository _stockRepository;
  final GeminiService _geminiService;
  int? _draftId;

  DraftStateNotifier(
    this._postRepository,
    this._stockRepository,
    this._geminiService,
  ) : super(const DraftFormState());

  /// 載入現有草稿
  Future<void> loadDraft(int id) async {
    _draftId = id;
    final draft = await _postRepository.getDraftById(id);
    if (draft != null) {
      state = DraftFormState(
        content: draft.content,
        ticker: draft.stockTicker,
        sentiment: draft.sentiment,
        kolId: draft.kolId,
        postedAt: draft.postedAt,
      );
    } else {
      _draftId = null;
    }
  }

  /// 更新主文內容
  void updateContent(String content) {
    state = state.copyWith(content: content);
  }

  /// 更新標的
  void updateTicker(String? ticker) {
    state = state.copyWith(ticker: ticker);
  }

  /// 更新情緒
  void updateSentiment(String sentiment) {
    state = state.copyWith(sentiment: sentiment);
  }

  /// 更新 KOL
  void updateKOL(int? kolId) {
    state = state.copyWith(kolId: kolId);
  }

  /// 從相對時間更新發文時間
  void updatePostedAtFromRelative(RelativeTimeInput relativeTime) {
    state = state.copyWith(postedAt: relativeTime.toAbsoluteTime());
  }

  /// 從絕對時間更新發文時間
  void updatePostedAtFromAbsolute(DateTime dateTime) {
    state = state.copyWith(postedAt: dateTime);
  }

  /// 呼叫 Gemini 分析主文
  Future<void> analyzeContent() async {
    if (state.content.isEmpty) return;

    state = state.copyWith(isAnalyzing: true, errorMessage: null);

    try {
      final result = await _geminiService.analyzeText(state.content);
      
      // 自動填入 AI 分析結果
      String? ticker;
      if (result.tickers.isNotEmpty) {
        ticker = result.tickers.first;
        // 確保股票存在於資料庫中
        final stock = await _stockRepository.getStockByTicker(ticker);
        if (stock == null) {
          // 自動建立股票記錄
          await _stockRepository.upsertStock(
            StocksCompanion.insert(
              ticker: ticker,
              lastUpdated: DateTime.now(),
            ),
          );
        }
      }

      state = state.copyWith(
        isAnalyzing: false,
        aiResult: result,
        ticker: ticker ?? state.ticker,
        sentiment: result.sentiment,
      );
    } catch (e) {
      state = state.copyWith(
        isAnalyzing: false,
        errorMessage: 'AI 分析失敗: $e',
      );
    }
  }

  /// 自動儲存草稿
  Future<void> autoSaveDraft() async {
    if (!state.canSave) return;

    try {
      state = state.copyWith(isSaving: true);

      final companion = PostsCompanion.insert(
        kolId: state.kolId!,
        stockTicker: state.ticker!,
        content: state.content,
        sentiment: state.sentiment,
        postedAt: state.postedAt!,
        createdAt: DateTime.now(),
        status: 'Draft',
      );

      if (_draftId != null) {
        await _postRepository.updatePost(_draftId!, companion);
      } else {
        _draftId = await _postRepository.createDraft(companion);
      }

      state = state.copyWith(isSaving: false);
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: '儲存失敗: $e',
      );
    }
  }

  /// 發布貼文
  Future<void> publishPost() async {
    if (!state.canSave || _draftId == null) {
      throw Exception('無法發布：資料不完整或草稿不存在');
    }

    try {
      state = state.copyWith(isSaving: true);
      await _postRepository.publishPost(_draftId!);
      state = state.copyWith(isSaving: false);
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: '發布失敗: $e',
      );
      rethrow;
    }
  }

  /// 重置狀態
  void reset() {
    _draftId = null;
    state = const DraftFormState();
  }
}

/// DraftStateProvider
final draftStateProvider =
    StateNotifierProvider<DraftStateNotifier, DraftFormState>((ref) {
  final postRepo = ref.watch(postRepositoryProvider);
  final stockRepo = ref.watch(stockRepositoryProvider);
  final geminiService = ref.watch(geminiServiceProvider);
  return DraftStateNotifier(postRepo, stockRepo, geminiService);
});
