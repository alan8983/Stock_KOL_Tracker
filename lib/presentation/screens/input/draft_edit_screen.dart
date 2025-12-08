import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/providers/draft_state_provider.dart';
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
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

            // Ticker 自動完成
            TickerAutocompleteField(
              initialValue: state.ticker,
              onChanged: (ticker) => notifier.updateTicker(ticker),
            ),
            const SizedBox(height: 16),

            // Sentiment 選擇器
            SentimentSelector(
              selectedSentiment: state.sentiment,
              onChanged: (sentiment) => notifier.updateSentiment(sentiment),
            ),
            const SizedBox(height: 16),

            // KOL 選擇器
            KOLSelector(
              selectedKolId: state.kolId,
              onChanged: (kolId) => notifier.updateKOL(kolId),
            ),
            const SizedBox(height: 16),

            // 發文時間選擇
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
                    notifier.updatePostedAtFromAbsolute(dateTime),
              )
            else
              DateTimePickerField(
                initialDateTime: state.postedAt ?? DateTime.now(),
                onChanged: (dateTime) =>
                    notifier.updatePostedAtFromAbsolute(dateTime),
              ),
            const SizedBox(height: 32),

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

            // 確認建檔按鈕
            ElevatedButton(
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
          ],
        ),
      ),
    );
  }
}
