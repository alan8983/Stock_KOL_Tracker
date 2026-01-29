import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import '../../data/models/draft_form_state.dart';
import '../../data/models/relative_time_input.dart';
import '../../data/database/database.dart';
import '../../data/repositories/post_repository.dart';
import '../../data/repositories/post_stock_repository.dart';
import '../../data/repositories/stock_repository.dart';
import '../../data/repositories/kol_repository.dart';
import '../../data/services/Gemini/gemini_service.dart';
import '../../core/utils/time_parser.dart';
import '../../core/utils/kol_matcher.dart';
import 'repository_providers.dart';
import 'service_providers.dart';

/// DraftStateNotifier - 管理單一草稿的編輯狀態
class DraftStateNotifier extends StateNotifier<DraftFormState> {
  final PostRepository _postRepository;
  final StockRepository _stockRepository;
  final KOLRepository _kolRepository;
  final GeminiService _geminiService;
  int? _draftId;
  int? _quickDraftId; // 追蹤快速草稿 ID

  DraftStateNotifier(
    this._postRepository,
    this._stockRepository,
    this._kolRepository,
    this._geminiService,
  ) : super(const DraftFormState());

  /// 載入現有草稿
  Future<void> loadDraft(int id) async {
    _draftId = id;
    final draft = await _postRepository.getDraftById(id);
    if (draft != null) {
      // 載入標的關聯
      final postStocks = await _postRepository.getPostStocks(id);
      final tickerAnalyses = postStocks.map((ps) => TickerAnalysisData(
        ticker: ps.stockTicker,
        sentiment: ps.sentiment,
        isPrimary: ps.isPrimary,
      )).toList();
      
      // 如果沒有標的關聯，使用舊的欄位（向後兼容）
      if (tickerAnalyses.isEmpty && draft.stockTicker != null && draft.stockTicker!.isNotEmpty) {
        tickerAnalyses.add(TickerAnalysisData(
          ticker: draft.stockTicker!,
          sentiment: draft.sentiment ?? 'Neutral',
          isPrimary: true,
        ));
      }
      
      state = DraftFormState(
        content: draft.content,
        ticker: draft.stockTicker,
        sentiment: draft.sentiment ?? 'Neutral',
        tickerAnalyses: tickerAnalyses,
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

  /// 更新標的（向後兼容）
  @Deprecated('使用 updateTickerAnalyses 代替')
  void updateTicker(String? ticker) {
    state = state.copyWith(ticker: ticker);
  }

  /// 更新情緒（向後兼容）
  @Deprecated('使用 updateTickerAnalyses 代替')
  void updateSentiment(String sentiment) {
    state = state.copyWith(sentiment: sentiment);
  }
  
  /// 更新多標的分析
  void updateTickerAnalyses(List<TickerAnalysisData> tickerAnalyses) {
    state = state.copyWith(tickerAnalyses: tickerAnalyses);
  }
  
  /// 更新單一標的情緒
  void updateTickerSentiment(int index, String sentiment) {
    final updated = List<TickerAnalysisData>.from(state.tickerAnalyses);
    if (index >= 0 && index < updated.length) {
      updated[index] = updated[index].copyWith(sentiment: sentiment);
      state = state.copyWith(tickerAnalyses: updated);
    }
  }
  
  /// 切換主要標的
  void setPrimaryTicker(int index) {
    final updated = state.tickerAnalyses.map((t, i) {
      return t.copyWith(isPrimary: i == index);
    }).toList();
    state = state.copyWith(tickerAnalyses: updated);
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

  /// 清除錯誤訊息
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  /// 呼叫 Gemini 分析主文
  Future<void> analyzeContent() async {
    if (state.content.isEmpty) {
      print('⚠️ DraftStateNotifier: 內容為空，無法分析');
      return;
    }

    print('🔄 DraftStateNotifier: 開始AI分析...');
    state = state.copyWith(isAnalyzing: true, errorMessage: null);

    try {
      final result = await _geminiService.analyzeText(state.content);
      
      print('📊 DraftStateNotifier: 收到分析結果 - tickerAnalyses: ${result.tickerAnalyses.length}, KOL: ${result.kolName}, 時間: ${result.postedAtText}');
      
      // 處理多標的分析結果
      List<TickerAnalysisData> tickerAnalyses = [];
      if (result.tickerAnalyses.isNotEmpty) {
        // 使用新的 tickerAnalyses 格式
        for (final tickerAnalysis in result.tickerAnalyses) {
          print('📈 DraftStateNotifier: 檢查股票 ${tickerAnalysis.ticker} 是否存在於資料庫...');
          
          // 確保股票存在於資料庫中
          final stock = await _stockRepository.getStockByTicker(tickerAnalysis.ticker);
          if (stock == null) {
            print('➕ DraftStateNotifier: 自動建立股票記錄: ${tickerAnalysis.ticker}');
            await _stockRepository.upsertStock(
              StocksCompanion.insert(
                ticker: tickerAnalysis.ticker,
                lastUpdated: DateTime.now(),
              ),
            );
          } else {
            print('✓ DraftStateNotifier: 股票 ${tickerAnalysis.ticker} 已存在');
          }
          
          tickerAnalyses.add(TickerAnalysisData(
            ticker: tickerAnalysis.ticker,
            sentiment: tickerAnalysis.sentiment,
            isPrimary: tickerAnalysis.isPrimary,
          ));
        }
      } else if (result.tickers != null && result.tickers!.isNotEmpty) {
        // 向後兼容：使用舊的 tickers 格式
        final sentiment = result.sentiment ?? 'Neutral';
        for (int i = 0; i < result.tickers!.length; i++) {
          final ticker = result.tickers![i];
          print('📈 DraftStateNotifier: 檢查股票 $ticker 是否存在於資料庫...');
          
          final stock = await _stockRepository.getStockByTicker(ticker);
          if (stock == null) {
            print('➕ DraftStateNotifier: 自動建立股票記錄: $ticker');
            await _stockRepository.upsertStock(
              StocksCompanion.insert(
                ticker: ticker,
                lastUpdated: DateTime.now(),
              ),
            );
          }
          
          tickerAnalyses.add(TickerAnalysisData(
            ticker: ticker,
            sentiment: sentiment,
            isPrimary: i == 0, // 第一個設為主要標的
          ));
        }
      }

      // 處理 KOL 匹配
      int? kolId;
      if (result.kolName != null && result.kolName!.isNotEmpty) {
        print('👤 DraftStateNotifier: 嘗試匹配 KOL "${result.kolName}"...');
        final allKols = await _kolRepository.getAllKOLs();
        kolId = KOLMatcher.findBestMatch(result.kolName, allKols);
        
        if (kolId != null) {
          print('✅ DraftStateNotifier: 已自動選擇 KOL (ID: $kolId)');
        } else {
          print('⚠️ DraftStateNotifier: 未找到匹配的 KOL，需手動選擇');
        }
      }

      // 處理時間解析
      DateTime? postedAt;
      if (result.postedAtText != null && result.postedAtText!.isNotEmpty) {
        print('🕐 DraftStateNotifier: 嘗試解析時間 "${result.postedAtText}"...');
        postedAt = TimeParser.parse(result.postedAtText);
        
        if (postedAt != null) {
          print('✅ DraftStateNotifier: 已自動填入發文時間: $postedAt');
        } else {
          print('⚠️ DraftStateNotifier: 無法解析時間，需手動輸入');
        }
      }

      // 向後兼容：設定舊的 ticker 和 sentiment（使用主要標的）
      final primaryTicker = tickerAnalyses.isNotEmpty 
          ? tickerAnalyses.firstWhere((t) => t.isPrimary, orElse: () => tickerAnalyses.first)
          : null;
      
      state = state.copyWith(
        isAnalyzing: false,
        aiResult: result,
        ticker: primaryTicker?.ticker ?? state.ticker,
        sentiment: primaryTicker?.sentiment ?? result.sentiment ?? state.sentiment,
        tickerAnalyses: tickerAnalyses,
        kolId: kolId ?? state.kolId,
        postedAt: postedAt ?? state.postedAt,
      );
      
      print('✅ DraftStateNotifier: AI分析完成並已更新狀態');
    } on JsonParseException catch (e) {
      // JSON 解析失敗的特殊處理
      print('❌ DraftStateNotifier: JSON 解析失敗');
      print('   錯誤: $e');
      
      state = state.copyWith(
        isAnalyzing: false,
        errorMessage: 'AI 分析失敗: JSON 解析錯誤，請重試',
      );
    } catch (e, stackTrace) {
      print('❌ DraftStateNotifier: AI分析失敗');
      print('   錯誤: $e');
      print('   Stack trace: $stackTrace');
      
      String errorMessage;
      if (e.toString().contains('API key')) {
        errorMessage = 'AI 分析失敗: API金鑰無效，請檢查.env設定';
      } else if (e.toString().contains('network') || e.toString().contains('timeout')) {
        errorMessage = 'AI 分析失敗: 網路連線問題，請檢查網路後重試';
      } else if (e.toString().contains('quota')) {
        errorMessage = 'AI 分析失敗: API配額已用完';
      } else {
        errorMessage = 'AI 分析失敗: ${e.toString()}';
      }
      
      state = state.copyWith(
        isAnalyzing: false,
        errorMessage: errorMessage,
      );
    }
  }

  /// 自動儲存草稿
  Future<void> autoSaveDraft() async {
    if (!state.canSave) return;

    try {
      state = state.copyWith(isSaving: true);

      // 將 AI 分析結果轉為 JSON 字串
      String? aiAnalysisJson;
      if (state.aiResult != null) {
        try {
          aiAnalysisJson = jsonEncode(state.aiResult!.toJson());
        } catch (e) {
          print('⚠️ DraftStateNotifier: AI 分析結果序列化失敗: $e');
        }
      }

      // 轉換 tickerAnalyses 為 PostStockData
      final postStocks = state.tickerAnalyses.map((t) => PostStockData(
        stockTicker: t.ticker,
        sentiment: t.sentiment,
        isPrimary: t.isPrimary,
      )).toList();

      // 向後兼容：設定舊的 stockTicker 和 sentiment（使用主要標的）
      final primaryTicker = state.primaryTicker;
      
      final companion = PostsCompanion.insert(
        kolId: state.kolId!,
        stockTicker: primaryTicker?.ticker != null 
            ? drift.Value(primaryTicker!.ticker)
            : const drift.Value.absent(),
        content: state.content,
        sentiment: primaryTicker?.sentiment != null
            ? drift.Value(primaryTicker!.sentiment)
            : const drift.Value.absent(),
        postedAt: state.postedAt!,
        createdAt: DateTime.now(),
        status: 'Draft',
        aiAnalysisJson: aiAnalysisJson != null 
            ? drift.Value(aiAnalysisJson)
            : const drift.Value.absent(),
      );

      if (_draftId != null) {
        await _postRepository.updatePost(_draftId!, companion, postStocks: postStocks);
      } else {
        _draftId = await _postRepository.createDraft(companion, postStocks: postStocks);
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

  /// 儲存快速草稿（只有內容，使用預設值）
  /// 用於自動暫存或手動暫存只有內容的草稿
  Future<int?> saveQuickDraft(String content) async {
    if (content.trim().isEmpty) {
      return null;
    }

    try {
      // 使用預設值建立快速草稿
      final draftId = await _postRepository.createQuickDraft(content.trim());
      _quickDraftId = draftId; // 儲存快速草稿 ID
      return draftId;
    } catch (e) {
      // 記錄錯誤但不拋出，避免影響用戶體驗
      print('儲存快速草稿失敗: $e');
      return null;
    }
  }

  /// 取得當前快速草稿 ID
  int? getCurrentQuickDraftId() {
    return _quickDraftId;
  }

  /// 重置狀態
  void reset() {
    _draftId = null;
    _quickDraftId = null; // 清除快速草稿 ID
    state = const DraftFormState();
  }
}

/// DraftStateProvider
final draftStateProvider =
    StateNotifierProvider<DraftStateNotifier, DraftFormState>((ref) {
  final postRepo = ref.watch(postRepositoryProvider);
  final stockRepo = ref.watch(stockRepositoryProvider);
  final kolRepo = ref.watch(kolRepositoryProvider);
  final geminiService = ref.watch(geminiServiceProvider);
  return DraftStateNotifier(postRepo, stockRepo, kolRepo, geminiService);
});
