import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/providers/draft_state_provider.dart';
import '../../../domain/providers/post_list_provider.dart';
import '../../../domain/providers/stock_list_provider.dart';
import '../../../domain/providers/stock_posts_provider.dart';
import '../../../domain/providers/stock_stats_provider.dart';
import '../../../domain/providers/kol_posts_provider.dart';
import '../../../domain/providers/kol_win_rate_provider.dart';
import '../../../domain/providers/home_tab_provider.dart';
import '../../../data/models/draft_form_state.dart';
import '../../widgets/ticker_autocomplete_field.dart';
import '../../widgets/sentiment_selector.dart';
import '../../widgets/kol_selector.dart';
import '../../widgets/relative_time_picker.dart';
import '../../widgets/datetime_picker_field.dart';
import '../../widgets/pulsing_border_card.dart';
import '../../../core/utils/time_parser.dart';

/// 分析結果頁面
/// 顯示 AI 分析摘要和資料編輯區
class AnalysisResultScreen extends ConsumerStatefulWidget {
  const AnalysisResultScreen({super.key});

  @override
  ConsumerState<AnalysisResultScreen> createState() => _AnalysisResultScreenState();
}

class _AnalysisResultScreenState extends ConsumerState<AnalysisResultScreen> {
  bool _useRelativeTime = true;
  bool _isLoading = true;
  final Set<String> _cleanedRedundantKeys = {}; // 追蹤已清理的冗餘文字

  @override
  void initState() {
    super.initState();
    // 觸發 AI 分析
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAnalysis();
    });
  }

  Future<void> _startAnalysis() async {
    final notifier = ref.read(draftStateProvider.notifier);
    await notifier.analyzeContent();
    
    if (mounted) {
      final state = ref.read(draftStateProvider);
      
      // 檢查是否有 JSON 解析錯誤
      if (state.errorMessage != null && 
          state.errorMessage!.contains('JSON 解析錯誤')) {
        // 導航回快速輸入頁，並傳遞錯誤標記
        Navigator.of(context).pop({'error': true, 'message': state.errorMessage});
        return;
      }
      
      setState(() {
        _isLoading = false;
        
        // 檢查 AI 分析結果中的時間類型，自動切換 Tab
        if (state.aiResult?.postedAtText != null && 
            state.aiResult!.postedAtText!.isNotEmpty) {
          final isAbsolute = TimeParser.isAbsoluteTime(state.aiResult!.postedAtText);
          _useRelativeTime = !isAbsolute; // 如果是絕對時間，則切換到絕對時間 Tab
        }
      });
    }
  }

  Future<void> _saveAndNavigate() async {
    final state = ref.read(draftStateProvider);
    if (!state.canSave) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('請填寫所有必填欄位'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final notifier = ref.read(draftStateProvider.notifier);
      await notifier.autoSaveDraft();
      await notifier.publishPost();

      if (mounted) {
        // 取得建檔的 ticker 和 kolId，用於刷新相關 Provider
        final draftState = ref.read(draftStateProvider);
        final ticker = draftState.ticker;
        final kolId = draftState.kolId;

        // 刷新所有相關的 Provider
        if (ticker != null && kolId != null) {
          // 刷新文檔列表
          ref.read(postListProvider.notifier).loadPosts();
          
          // 刷新股票相關 Provider
          ref.invalidate(stockPostsProvider(ticker));
          ref.invalidate(stockPostsWithDetailsProvider(ticker));
          ref.invalidate(stockStatsProvider(ticker));
          
          // 刷新股票列表（用於顯示新建立的股票）
          ref.read(stockListProvider.notifier).loadStocks();
          
          // 刷新所有股票的統計（因為可能新增了股票）
          ref.invalidate(allStockStatsProvider);
          
          // 刷新 KOL 相關 Provider
          ref.invalidate(kolPostsProvider(kolId));
          ref.invalidate(kolPostsWithDetailsProvider(kolId));
          ref.invalidate(kolPostsGroupedByStockProvider(kolId));
          ref.invalidate(kolPostStatsProvider(kolId));
          ref.invalidate(kolWinRateStatsProvider(kolId));
          ref.invalidate(allKOLWinRateStatsProvider);
        }

        // 設置 Tab 索引為 2（投資標的 Tab）
        ref.read(homeTabIndexProvider.notifier).state = 2;
        
        // 導航回 HomeScreen（第一個路由）
        Navigator.of(context).popUntil((route) => route.isFirst);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('建檔成功！'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('建檔失敗: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(draftStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('分析結果'),
        centerTitle: true,
      ),
      body: _isLoading
          ? _buildLoadingView()
          : _buildResultView(context, state),
    );
  }

  /// 載入中畫面
  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: CircularProgressIndicator(
              strokeWidth: 6,
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).primaryColor,
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            '思考中...',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'AI 正在分析您的內容',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  /// 結果展示畫面
  Widget _buildResultView(BuildContext context, DraftFormState state) {
    return Column(
      children: [
        // 可滾動內容區（包含摘要、冗餘文字、編輯區）
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // AI 摘要區（緊湊型）
                _buildSummarySection(state),
                
                // 冗餘文字清理區（如果有識別到冗餘文字）
                if (state.aiResult?.redundantText != null && 
                    state.aiResult!.redundantText!.isNotEmpty)
                  _buildRedundantTextSection(state),
                
                // 卡片編輯區
                _buildEditSection(state),
              ],
            ),
          ),
        ),
        
        // 底部：建檔按鈕（固定在底部）
        _buildActionButton(state),
      ],
    );
  }

  /// AI 摘要區
  Widget _buildSummarySection(DraftFormState state) {
    // 從 AI 結果生成摘要點
    final summaryPoints = _generateSummaryPoints(state);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF6366F1).withOpacity(0.08),
            const Color(0xFF8B5CF6).withOpacity(0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF6366F1).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF6366F1),
                      Color(0xFF8B5CF6),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'AI 分析摘要',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...summaryPoints.asMap().entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF6366F1),
                          Color(0xFF8B5CF6),
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      entry.value,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: Color(0xFF374151),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  /// 生成摘要點
  List<String> _generateSummaryPoints(DraftFormState state) {
    final points = <String>[];
    
    if (state.aiResult != null) {
      final result = state.aiResult!;
      
      // 優先使用 AI 生成的核心論述摘要
      if (result.summary.isNotEmpty) {
        points.addAll(result.summary);
      } else if (result.reasoning != null && result.reasoning!.isNotEmpty) {
        // 如果沒有 summary，使用 reasoning
        points.add(result.reasoning!);
      } else {
        // 降級方案：顯示基本資訊
        points.add('文章主要討論${result.tickers.isNotEmpty ? result.tickers.join('、') : '市場動態'}');
        final sentimentText = _getSentimentText(result.sentiment);
        points.add('整體觀點偏向$sentimentText');
      }
    } else if (state.errorMessage != null) {
      points.add('⚠️ ${state.errorMessage}');
    } else {
      points.add('等待分析結果...');
    }
    
    return points.take(5).toList(); // 最多 5 個點
  }

  String _getSentimentText(String sentiment) {
    switch (sentiment) {
      case 'Bullish':
        return '看漲 📈';
      case 'Bearish':
        return '看跌 📉';
      case 'Neutral':
        return '中性 ➖';
      default:
        return sentiment;
    }
  }

  /// 冗餘文字清理區
  Widget _buildRedundantTextSection(DraftFormState state) {
    final redundantText = state.aiResult!.redundantText!;
    
    // 分類：已自動填入的資訊 vs 其他冗餘文字
    final autoFilledItems = <String, dynamic>{};
    final otherRedundantItems = <String, dynamic>{};
    
    redundantText.forEach((key, info) {
      if ((info.category == 'author' && state.kolId != null) ||
          (info.category == 'publishTime' && state.postedAt != null)) {
        autoFilledItems[key] = info;
      } else {
        otherRedundantItems[key] = info;
      }
    });
    
    // 如果所有項目都已清理，不顯示此區塊
    if (autoFilledItems.isEmpty && otherRedundantItems.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: ExpansionTile(
        leading: Icon(Icons.cleaning_services, color: Colors.orange.shade700),
        title: Text(
          '偵測到冗餘文字',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.orange.shade900,
          ),
        ),
        subtitle: Text(
          '點擊展開查看詳情',
          style: TextStyle(fontSize: 12, color: Colors.orange.shade700),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 類別 A：已自動填入的資訊
                if (autoFilledItems.isNotEmpty) ...[
                  _buildRedundantCategory(
                    title: '✓ 已自動填入的資訊',
                    subtitle: '這些資訊已填入對應欄位，是否要從主文中移除？',
                    items: autoFilledItems,
                    categoryColor: Colors.green,
                  ),
                  if (otherRedundantItems.isNotEmpty) const SizedBox(height: 16),
                ],
                
                // 類別 B：其他冗餘文字
                if (otherRedundantItems.isNotEmpty)
                  _buildRedundantCategory(
                    title: '其他冗餘文字',
                    subtitle: '偵測到以下冗餘文字，是否要移除？',
                    items: otherRedundantItems,
                    categoryColor: Colors.orange,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 冗餘文字類別區塊
  Widget _buildRedundantCategory({
    required String title,
    required String subtitle,
    required Map<String, dynamic> items,
    required MaterialColor categoryColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
      Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: categoryColor.shade900,
        ),
      ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
        ),
        const SizedBox(height: 8),
        ...items.entries.map((entry) {
          final key = entry.key;
          final info = entry.value;
          final isCleaned = _cleanedRedundantKeys.contains(key);
          
          return _buildRedundantItem(
            key: key,
            info: info,
            isCleaned: isCleaned,
            categoryColor: categoryColor,
          );
        }).toList(),
      ],
    );
  }

  /// 單個冗餘文字項目
  Widget _buildRedundantItem({
    required String key,
    required dynamic info,
    required bool isCleaned,
    required MaterialColor categoryColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCleaned ? Colors.grey.shade100 : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isCleaned ? Colors.grey.shade300 : categoryColor.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getCategoryIcon(info.category),
                size: 16,
                color: isCleaned ? Colors.grey : categoryColor.shade700,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _getCategoryLabel(info.category),
                  style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isCleaned ? Colors.grey : categoryColor.shade800,
                ),
                ),
              ),
              Text(
                info.position == 'start' ? '開頭' : '結尾',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              info.text,
              style: TextStyle(
                fontSize: 13,
                color: isCleaned ? Colors.grey : Colors.black87,
                decoration: isCleaned ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (!isCleaned) ...[
                TextButton(
                  onPressed: () => _removeRedundantText(key, info.lineNumbers),
                  style: TextButton.styleFrom(
                    foregroundColor: categoryColor.shade700,
                  ),
                  child: const Text('清理'),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _cleanedRedundantKeys.add(key);
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey.shade700,
                  ),
                  child: const Text('保留'),
                ),
              ] else
                Text(
                  '已處理',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// 移除冗餘文字
  void _removeRedundantText(String key, List<int> lineNumbers) {
    final state = ref.read(draftStateProvider);
    final lines = state.content.split('\n');
    final linesToRemove = lineNumbers.map((lineNum) => lineNum - 1).toSet(); // 轉為 0-based index
    
    final cleanedLines = <String>[];
    for (int i = 0; i < lines.length; i++) {
      if (!linesToRemove.contains(i)) {
        cleanedLines.add(lines[i]);
      }
    }
    
    final cleanedContent = cleanedLines.join('\n').trim();
    
    // 更新 state
    ref.read(draftStateProvider.notifier).updateContent(cleanedContent);
    
    setState(() {
      _cleanedRedundantKeys.add(key);
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('已清理冗餘文字'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  /// 取得類別圖示
  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'author':
        return Icons.person_outline;
      case 'publishTime':
        return Icons.access_time;
      case 'readCount':
        return Icons.visibility_outlined;
      case 'social':
        return Icons.share_outlined;
      case 'disclaimer':
        return Icons.info_outline;
      case 'promotion':
        return Icons.campaign_outlined;
      default:
        return Icons.text_snippet_outlined;
    }
  }

  /// 取得類別標籤
  String _getCategoryLabel(String category) {
    switch (category) {
      case 'author':
        return '作者資訊';
      case 'publishTime':
        return '發布時間';
      case 'readCount':
        return '閱讀次數';
      case 'social':
        return '社群分享';
      case 'disclaimer':
        return '免責聲明';
      case 'promotion':
        return '廣告推廣';
      default:
        return '其他';
    }
  }

  /// 卡片編輯區
  Widget _buildEditSection(DraftFormState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Ticker 卡片
          _buildEditCard(
            title: '投資標的 (Ticker)',
            icon: Icons.show_chart,
            gradientColors: const [Color(0xFF3B82F6), Color(0xFF2563EB)],
            isRequired: true,
            isFilled: state.ticker != null && state.ticker!.isNotEmpty,
            child: TickerAutocompleteField(
              initialValue: state.ticker,
              onChanged: (ticker) => ref.read(draftStateProvider.notifier).updateTicker(ticker),
            ),
          ),
          const SizedBox(height: 8),

          // Sentiment 卡片
          _buildEditCard(
            title: '走勢情緒',
            icon: Icons.trending_up,
            gradientColors: const [Color(0xFF10B981), Color(0xFF059669)],
            isRequired: false,
            isFilled: true,
            child: SentimentSelector(
              selectedSentiment: state.sentiment,
              onChanged: (sentiment) => ref.read(draftStateProvider.notifier).updateSentiment(sentiment),
            ),
          ),
          const SizedBox(height: 8),

          // KOL 卡片
          _buildEditCard(
            title: 'KOL',
            icon: Icons.person,
            gradientColors: const [Color(0xFFA855F7), Color(0xFF9333EA)],
            isRequired: true,
            isFilled: state.kolId != null,
            child: KOLSelector(
              selectedKolId: state.kolId,
              onChanged: (kolId) => ref.read(draftStateProvider.notifier).updateKOL(kolId),
            ),
          ),
          const SizedBox(height: 8),

          // 時間卡片
          _buildTimeCard(
            title: '發文時間',
            icon: Icons.access_time,
            gradientColors: const [Color(0xFFF59E0B), Color(0xFFD97706)],
            state: state,
            isRequired: true,
            isFilled: state.postedAt != null,
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  /// 編輯卡片
  Widget _buildEditCard({
    required String title,
    required IconData icon,
    required List<Color> gradientColors,
    required Widget child,
    required bool isRequired,
    required bool isFilled,
  }) {
    final showPulse = isRequired && !isFilled;

    return PulsingBorderCard(
      showPulse: showPulse,
      normalGradientColors: gradientColors,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradientColors,
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: Colors.white, size: 14),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
                ),
              ),
              if (isRequired && !isFilled) ...[
                const SizedBox(width: 4),
                const Text(
                  '*',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  /// 時間卡片（特殊設計：按鈕在右上角）
  Widget _buildTimeCard({
    required String title,
    required IconData icon,
    required List<Color> gradientColors,
    required DraftFormState state,
    required bool isRequired,
    required bool isFilled,
  }) {
    final showPulse = isRequired && !isFilled;

    return PulsingBorderCard(
      showPulse: showPulse,
      normalGradientColors: gradientColors,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradientColors,
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: Colors.white, size: 14),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
                ),
              ),
              if (isRequired && !isFilled) ...[
                const SizedBox(width: 4),
                const Text(
                  '*',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
              const Spacer(),
              // 緊湊的時間模式切換按鈕
              Container(
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTimeToggleButton(
                      label: '相對',
                      isSelected: _useRelativeTime,
                      onTap: () => setState(() => _useRelativeTime = true),
                    ),
                    _buildTimeToggleButton(
                      label: '絕對',
                      isSelected: !_useRelativeTime,
                      onTap: () => setState(() => _useRelativeTime = false),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_useRelativeTime)
            RelativeTimePicker(
              initialDateTime: state.postedAt,
              onChanged: (dateTime) =>
                  ref.read(draftStateProvider.notifier).updatePostedAtFromAbsolute(dateTime),
            )
          else
            DateTimePickerField(
              initialDateTime: state.postedAt ?? DateTime.now(),
              onChanged: (dateTime) =>
                  ref.read(draftStateProvider.notifier).updatePostedAtFromAbsolute(dateTime),
            ),
        ],
      ),
    );
  }

  /// 時間切換按鈕
  Widget _buildTimeToggleButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                )
              : null,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? Colors.white : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }

  /// 建檔按鈕
  Widget _buildActionButton(DraftFormState state) {
    final isEnabled = state.canSave && !_isLoading;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isEnabled
                  ? const [
                      Color(0xFF6366F1), // Indigo
                      Color(0xFF8B5CF6), // Purple
                    ]
                  : [
                      Colors.grey.shade300,
                      Colors.grey.shade400,
                    ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: isEnabled
                ? [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isEnabled ? _saveAndNavigate : null,
              borderRadius: BorderRadius.circular(30),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isLoading)
                      const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    else
                      const Icon(
                        Icons.auto_awesome,
                        color: Colors.white,
                        size: 22,
                      ),
                    const SizedBox(width: 8),
                    const Text(
                      '建檔',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

