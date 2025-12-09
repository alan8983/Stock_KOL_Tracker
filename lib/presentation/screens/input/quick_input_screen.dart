import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/providers/draft_state_provider.dart';
import '../../../data/models/draft_form_state.dart';
import 'draft_list_screen.dart';
import 'draft_edit_screen.dart';

/// 快速輸入頁面 (Step 0.0)
/// 作為底部導覽的第一個Tab，支援貼上剪貼簿內容，自動暫存為草稿
class QuickInputScreen extends ConsumerStatefulWidget {
  const QuickInputScreen({super.key});

  @override
  ConsumerState<QuickInputScreen> createState() => _QuickInputScreenState();
}

class _QuickInputScreenState extends ConsumerState<QuickInputScreen> with AutomaticKeepAliveClientMixin {
  final _textController = TextEditingController();
  bool _hasText = false;

  @override
  bool get wantKeepAlive => true; // 保持狀態，避免Tab切換時重建

  @override
  void initState() {
    super.initState();
    _textController.addListener(() {
      setState(() {
        _hasText = _textController.text.isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  /// 從草稿數據填入表單
  void _loadFromDraft(DraftFormState draft) {
    if (mounted) {
      setState(() {
        _textController.text = draft.content;
      });
      // 同時更新Provider狀態
      final notifier = ref.read(draftStateProvider.notifier);
      notifier.updateContent(draft.content);
      if (draft.ticker != null) notifier.updateTicker(draft.ticker!);
      if (draft.sentiment != null) notifier.updateSentiment(draft.sentiment!);
      if (draft.kolId != null) notifier.updateKOL(draft.kolId!);
      if (draft.postedAt != null) notifier.updatePostedAtFromAbsolute(draft.postedAt!);
    }
  }

  /// 查看草稿列表
  Future<void> _viewDrafts() async {
    final draftData = await Navigator.of(context).push<DraftFormState>(
      MaterialPageRoute(
        builder: (context) => const DraftListScreen(),
      ),
    );

    // 如果選擇了草稿，填入表單
    if (draftData != null && mounted) {
      _loadFromDraft(draftData);
    }
  }

  /// 分析並進入編輯頁面
  Future<void> _onAnalyze() async {
    if (_textController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('請輸入內容後再進行分析'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final draftState = ref.read(draftStateProvider.notifier);
      
      // 更新內容到Provider
      draftState.updateContent(_textController.text.trim());
      
      // 確保狀態已更新後再導航
      await Future.delayed(const Duration(milliseconds: 100));
      
      // 導航到詳細編輯頁面
      if (mounted) {
        final result = await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const DraftEditScreen(),
          ),
        );
        
        // 如果建檔成功，清空表單
        if (result == true && mounted) {
          setState(() {
            _textController.clear();
          });
          draftState.reset();
        }
        
        // 導航成功後觸發 AI 分析
        if (mounted) {
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) {
              draftState.analyzeContent();
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('導航失敗: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // 必須調用以支持AutomaticKeepAliveClientMixin
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('快速輸入'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.drafts),
            onPressed: _viewDrafts,
            tooltip: '查看草稿',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '貼上或輸入內容',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TextField(
                controller: _textController,
                maxLines: null,
                expands: true,
                decoration: const InputDecoration(
                  hintText: '請貼上或輸入 KOL 發文內容...',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.all(16),
                ),
                textAlignVertical: TextAlignVertical.top,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _hasText ? _onAnalyze : null,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('分析'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
