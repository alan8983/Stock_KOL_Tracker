import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/providers/draft_state_provider.dart';
import '../../../domain/providers/repository_providers.dart';
import '../../../data/models/draft_form_state.dart';
import '../../widgets/ticker_autocomplete_field.dart';
import '../../widgets/sentiment_selector.dart';
import '../../widgets/kol_selector.dart';
import '../../widgets/relative_time_picker.dart';
import '../../widgets/datetime_picker_field.dart';
import '../input/preview_screen.dart';

/// 詳細編輯頁面 (Step 1b.1-1b.5)
/// 完整編輯介面，包含所有欄位
class DraftEditScreen extends ConsumerStatefulWidget {
  final int? draftId;

  const DraftEditScreen({
    super.key,
    this.draftId,
  });

  @override
  ConsumerState<DraftEditScreen> createState() => _DraftEditScreenState();
}

class _DraftEditScreenState extends ConsumerState<DraftEditScreen> {
  final _contentController = TextEditingController();
  bool _useRelativeTime = true;
  bool _hasAnalyzed = false; // 追蹤是否已完成 AI 分析

  @override
  void initState() {
    super.initState();
    if (widget.draftId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(draftStateProvider.notifier).loadDraft(widget.draftId!);
      });
    } else {
      // 從快速輸入頁面進入時，立即同步內容
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final state = ref.read(draftStateProvider);
        if (state.content.isNotEmpty && _contentController.text.isEmpty) {
          _contentController.text = state.content;
        }
      });
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _saveDraft() async {
    final notifier = ref.read(draftStateProvider.notifier);
    await notifier.autoSaveDraft();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('草稿已儲存')),
      );
    }
  }

  Future<void> _goToPreview() async {
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

    // 先儲存草稿
    await _saveDraft();

    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const PreviewScreen(),
        ),
      );
    }
  }

  /// 建立底部區域（精簡摘要卡片 + 預覽建檔按鈕）
  Widget _buildBottomArea(BuildContext context, DraftFormState state) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 精簡摘要卡片
          _buildSummaryCard(context, state),
          // 預覽建檔按鈕
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: state.canSave && !state.isSaving ? _goToPreview : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: state.isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('預覽並確認建檔'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 建立精簡摘要卡片
  Widget _buildSummaryCard(BuildContext context, DraftFormState state) {
    return InkWell(
      onTap: () => _showEditBottomSheet(context, state),
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  // Ticker 標籤
                  if (state.ticker != null && state.ticker!.isNotEmpty)
                    _buildChip(
                      context,
                      label: state.ticker!,
                      icon: Icons.show_chart,
                      color: Colors.blue,
                    )
                  else
                    _buildChip(
                      context,
                      label: '未設定',
                      icon: Icons.show_chart,
                      color: Colors.grey,
                    ),
                  
                  // Sentiment 標籤
                  _buildChip(
                    context,
                    label: _getSentimentLabel(state.sentiment),
                    icon: _getSentimentIcon(state.sentiment),
                    color: _getSentimentColor(state.sentiment),
                  ),
                  
                  // KOL 標籤
                  FutureBuilder<String>(
                    future: _getKOLName(state.kolId),
                    builder: (context, snapshot) {
                      final kolName = snapshot.data ?? '未選擇';
                      return _buildChip(
                        context,
                        label: kolName,
                        icon: Icons.person,
                        color: state.kolId != null ? Colors.purple : Colors.grey,
                      );
                    },
                  ),
                  
                  // 時間標籤
                  if (state.postedAt != null)
                    _buildChip(
                      context,
                      label: _formatRelativeTime(state.postedAt!),
                      icon: Icons.access_time,
                      color: Colors.orange,
                    )
                  else
                    _buildChip(
                      context,
                      label: '未設定',
                      icon: Icons.access_time,
                      color: Colors.grey,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.edit, size: 20, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  /// 建立標籤 Chip
  Widget _buildChip(BuildContext context, {
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// 取得 KOL 名稱
  Future<String> _getKOLName(int? kolId) async {
    if (kolId == null) return '未選擇';
    final kolRepo = ref.read(kolRepositoryProvider);
    final kol = await kolRepo.getKOLById(kolId);
    return kol?.name ?? '未知';
  }

  /// 取得情緒標籤
  String _getSentimentLabel(String sentiment) {
    switch (sentiment) {
      case 'Bullish':
        return '看漲';
      case 'Bearish':
        return '看跌';
      case 'Neutral':
        return '中性';
      default:
        return sentiment;
    }
  }

  /// 取得情緒圖示
  IconData _getSentimentIcon(String sentiment) {
    switch (sentiment) {
      case 'Bullish':
        return Icons.trending_up;
      case 'Bearish':
        return Icons.trending_down;
      case 'Neutral':
        return Icons.trending_flat;
      default:
        return Icons.help_outline;
    }
  }

  /// 取得情緒顏色
  Color _getSentimentColor(String sentiment) {
    switch (sentiment) {
      case 'Bullish':
        return Colors.green;
      case 'Bearish':
        return Colors.red;
      case 'Neutral':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  /// 格式化相對時間
  String _formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}分鐘前';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}小時前';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}天前';
    } else {
      return '${dateTime.month}/${dateTime.day}';
    }
  }

  /// 顯示編輯 Bottom Sheet
  void _showEditBottomSheet(BuildContext context, DraftFormState state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // 拖曳把手
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // 標題
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '編輯資料',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                // 編輯欄位
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Ticker 自動完成
                      const Text(
                        '投資標的',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TickerAutocompleteField(
                        initialValue: state.ticker,
                        onChanged: (ticker) => ref.read(draftStateProvider.notifier).updateTicker(ticker),
                      ),
                      const SizedBox(height: 16),

                      // Sentiment 選擇器
                      const Text(
                        '走勢情緒',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SentimentSelector(
                        selectedSentiment: state.sentiment,
                        onChanged: (sentiment) => ref.read(draftStateProvider.notifier).updateSentiment(sentiment),
                      ),
                      const SizedBox(height: 16),

                      // KOL 選擇器
                      const Text(
                        'KOL',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      KOLSelector(
                        selectedKolId: state.kolId,
                        onChanged: (kolId) => ref.read(draftStateProvider.notifier).updateKOL(kolId),
                      ),
                      const SizedBox(height: 16),

                      // 發文時間選擇
                      const Text(
                        '發文時間',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: SegmentedButton<bool>(
                              segments: const [
                                ButtonSegment(value: true, label: Text('相對時間')),
                                ButtonSegment(value: false, label: Text('絕對時間')),
                              ],
                              selected: {_useRelativeTime},
                              onSelectionChanged: (Set<bool> selected) {
                                setState(() {
                                  _useRelativeTime = selected.first;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
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
                      const SizedBox(height: 24),

                      // 確認按鈕
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('確認'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(draftStateProvider);
    final notifier = ref.read(draftStateProvider.notifier);

    // 同步內容到 controller（避免重複設定）
    if (widget.draftId != null) {
      // 從草稿載入時，等待 state 更新後再同步
      if (state.content.isNotEmpty && _contentController.text != state.content) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _contentController.text != state.content) {
            _contentController.text = state.content;
          }
        });
      }
    } else {
      // 從快速輸入頁面進入時，立即同步內容
      if (state.content.isNotEmpty && _contentController.text != state.content) {
        _contentController.text = state.content;
      }
    }

    // 監聽分析完成狀態
    if (!state.isAnalyzing && state.aiResult != null && !_hasAnalyzed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _hasAnalyzed = true;
          });
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('編輯記錄'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveDraft,
            tooltip: '儲存草稿',
          ),
        ],
      ),
      body: Stack(
        children: [
          // 主要內容區（可滾動）
          SingleChildScrollView(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: _hasAnalyzed ? 100 : 16, // 如果顯示底部卡片，留出空間
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 主文內容
                const Text(
                  '主文內容',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _contentController,
                  maxLines: 8,
                  decoration: const InputDecoration(
                    hintText: '請輸入或貼上內容...',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => notifier.updateContent(value),
                ),
                const SizedBox(height: 16),

                // AI 分析按鈕
                if (state.content.isNotEmpty)
                  ElevatedButton.icon(
                    onPressed: state.isAnalyzing ? null : () => notifier.analyzeContent(),
                    icon: state.isAnalyzing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.auto_awesome),
                    label: Text(state.isAnalyzing ? '分析中...' : 'AI 分析'),
                  ),
                const SizedBox(height: 16),

                // 錯誤訊息
                if (state.errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      state.errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
              ],
            ),
          ),

          // 固定底部的精簡摘要卡片和按鈕
          if (_hasAnalyzed)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildBottomArea(context, state),
            ),
        ],
      ),
    );
  }
}
