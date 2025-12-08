import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/providers/draft_state_provider.dart';
import '../input/draft_edit_screen.dart';

/// 快速輸入頁面 (Step 0.0)
/// 支援貼上剪貼簿內容，自動暫存為草稿
class QuickInputScreen extends ConsumerStatefulWidget {
  const QuickInputScreen({super.key});

  @override
  ConsumerState<QuickInputScreen> createState() => _QuickInputScreenState();
}

class _QuickInputScreenState extends ConsumerState<QuickInputScreen> {
  final _textController = TextEditingController();
  bool _hasText = false;

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
      
      // 先更新狀態
      draftState.updateContent(_textController.text.trim());
      
      // 確保狀態已更新後再導航
      await Future.delayed(const Duration(milliseconds: 100));
      
      // 導航到詳細編輯頁面
      if (mounted) {
        await Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const DraftEditScreen(),
          ),
        );
        
        // 導航成功後觸發 AI 分析
        if (mounted) {
          Future.delayed(const Duration(milliseconds: 300), () {
            draftState.analyzeContent();
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('快速輸入'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
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
