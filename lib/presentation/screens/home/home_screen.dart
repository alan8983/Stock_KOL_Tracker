import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/providers/draft_state_provider.dart';
import '../input/draft_edit_screen.dart';
import '../input/draft_list_screen.dart';

/// 主頁面 (Landing Page)
/// Phase 2 Backbone Step 0 - 真正的 HomeScreen
/// 一開啟就是文字框等待輸入，減少一個步驟
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with WidgetsBindingObserver {
  final _textController = TextEditingController();
  bool _hasText = false;
  int _currentIndex = 0;
  int? _lastSavedDraftId; // 記錄最後儲存的草稿 ID，避免重複儲存相同內容

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _textController.addListener(() {
      setState(() {
        _hasText = _textController.text.isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _textController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // 當 APP 進入背景或即將終止時，自動暫存內容
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      _autoSaveDraft();
    }
  }

  /// 自動暫存草稿（APP 進入背景時觸發）
  Future<void> _autoSaveDraft() async {
    final content = _textController.text.trim();
    if (content.isEmpty) {
      return; // 沒有內容時不儲存
    }

    try {
      final draftState = ref.read(draftStateProvider.notifier);
      final draftId = await draftState.saveQuickDraft(content);
      
      if (draftId != null) {
        _lastSavedDraftId = draftId;
        print('自動暫存成功，草稿 ID: $draftId');
      }
    } catch (e) {
      print('自動暫存失敗: $e');
    }
  }

  /// 手動儲存為草稿
  Future<void> _saveAsDraft() async {
    final content = _textController.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('請輸入內容後再儲存'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final draftState = ref.read(draftStateProvider.notifier);
      final draftId = await draftState.saveQuickDraft(content);
      
      if (draftId != null) {
        _lastSavedDraftId = draftId;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('已儲存為草稿'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
        // 清空文字框
        _textController.clear();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('儲存失敗，請稍後再試'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('儲存失敗: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _onAnalyze() async {
    // Bug 2 修復：驗證並修剪輸入內容
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
      
      // Bug 2 修復：使用 trim() 修剪空白字符
      draftState.updateContent(_textController.text.trim());
      
      // 確保狀態已更新後再導航
      await Future.delayed(const Duration(milliseconds: 100));
      
      // 導航到詳細編輯頁面
      if (mounted) {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const DraftEditScreen(),
          ),
        );
        
        // Bug 1 修復：檢查 mounted 狀態後再觸發 AI 分析
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

  Widget _buildInputPage() {
    return Padding(
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
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _hasText ? _onAnalyze : null,
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('分析'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _hasText ? _saveAsDraft : null,
                  icon: const Icon(Icons.save),
                  label: const Text('存為草稿'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock KOL Tracker'),
        centerTitle: true,
        elevation: 0,
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildInputPage(),
          const DraftListScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.edit),
            label: '輸入',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.drafts),
            label: '草稿',
          ),
        ],
      ),
    );
  }
}
