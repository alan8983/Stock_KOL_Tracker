import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/providers/draft_state_provider.dart';
import '../../../data/models/draft_form_state.dart';
import 'draft_list_screen.dart';
import 'analysis_result_screen.dart';

/// 快速輸入頁面 (Step 0.0)
/// 作為底部導覽的第一個Tab，支援貼上剪貼簿內容，自動暫存為草稿
class QuickInputScreen extends ConsumerStatefulWidget {
  const QuickInputScreen({super.key});

  @override
  ConsumerState<QuickInputScreen> createState() => _QuickInputScreenState();
}

class _QuickInputScreenState extends ConsumerState<QuickInputScreen> 
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  final _textController = TextEditingController();
  bool _hasText = false;
  Timer? _autoSaveTimer;
  int? _lastSavedDraftId;
  String _lastSavedContent = '';
  AppLifecycleState? _lastLifecycleState;

  @override
  bool get wantKeepAlive => true; // 保持狀態，避免Tab切換時重建

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _textController.addListener(() {
      setState(() {
        _hasText = _textController.text.isNotEmpty;
      });
    });
    _startAutoSaveTimer();
  }

  void _syncContentToProvider() {
    // 同步更新 Provider 狀態
    final notifier = ref.read(draftStateProvider.notifier);
    notifier.updateContent(_textController.text);
  }

  @override
  void dispose() {
    _stopAutoSaveTimer();
    WidgetsBinding.instance.removeObserver(this);
    _textController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    _lastLifecycleState = state;
    
    // 當 APP 進入背景或終止時，立即儲存
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      _autoSaveDraft();
      _stopAutoSaveTimer();
    } else if (state == AppLifecycleState.resumed) {
      // 當 APP 恢復時，重新啟動定期儲存
      _startAutoSaveTimer();
    }
  }

  /// 啟動定期自動儲存 Timer（每 30 秒）
  void _startAutoSaveTimer() {
    _stopAutoSaveTimer(); // 先停止現有的 Timer
    _autoSaveTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _autoSaveDraft();
    });
  }

  /// 停止定期自動儲存 Timer
  void _stopAutoSaveTimer() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = null;
  }

  /// 自動儲存草稿
  Future<void> _autoSaveDraft() async {
    final content = _textController.text.trim();
    
    // 檢查內容是否為空或與上次儲存的內容相同
    if (content.isEmpty || content == _lastSavedContent) {
      return;
    }

    try {
      // 先同步內容到 Provider
      _syncContentToProvider();
      
      final notifier = ref.read(draftStateProvider.notifier);
      final draftId = await notifier.saveQuickDraft(content);
      
      if (draftId != null && mounted) {
        _lastSavedDraftId = draftId;
        _lastSavedContent = content;
        print('✅ 自動儲存草稿成功 (ID: $draftId)');
      }
    } catch (e) {
      // 記錄錯誤但不中斷用戶體驗
      print('⚠️ 自動儲存草稿失敗: $e');
    }
  }

  /// 手動儲存草稿
  Future<void> _saveAsDraft() async {
    final content = _textController.text.trim();
    
    if (content.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('請輸入內容後再儲存為草稿'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    try {
      // 先同步內容到 Provider
      _syncContentToProvider();
      
      final notifier = ref.read(draftStateProvider.notifier);
      final draftId = await notifier.saveQuickDraft(content);
      
      if (draftId != null && mounted) {
        _lastSavedDraftId = draftId;
        _lastSavedContent = content;
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('草稿已儲存'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('儲存失敗: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
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
      
      // 更新最後儲存的內容，避免立即重複儲存
      _lastSavedContent = draft.content;
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

  /// 顯示錯誤對話框
  Future<void> _showErrorDialog(String errorMessage) async {
    if (!mounted) return;
    
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 24),
              SizedBox(width: 8),
              Text('AI 分析失敗'),
            ],
          ),
          content: Text(errorMessage),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                // 將文字框中的內容存成草稿
                final content = _textController.text.trim();
                if (content.isNotEmpty) {
                  try {
                    _syncContentToProvider();
                    final notifier = ref.read(draftStateProvider.notifier);
                    final draftId = await notifier.saveQuickDraft(content);
                    if (draftId != null && mounted) {
                      _lastSavedDraftId = draftId;
                      _lastSavedContent = content;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('已儲存為草稿'),
                          backgroundColor: Colors.green,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('儲存草稿失敗: $e'),
                          backgroundColor: Colors.red,
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    }
                  }
                }
              },
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // 清除錯誤狀態，重置無法修復的邏輯閘
                final notifier = ref.read(draftStateProvider.notifier);
                notifier.clearError();
                // 重新嘗試分析
                _onAnalyze();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('重送'),
            ),
          ],
        );
      },
    );
  }

  /// 分析並進入結果頁面
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
      
      // 使用側向平移動畫導航到分析結果頁面
      if (mounted) {
        final result = await Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const AnalysisResultScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              const begin = Offset(1.0, 0.0); // 從右側滑入
              const end = Offset.zero;
              const curve = Curves.easeInOut;

              var tween = Tween(begin: begin, end: end).chain(
                CurveTween(curve: curve),
              );

              return SlideTransition(
                position: animation.drive(tween),
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 400),
          ),
        );
        
        // 檢查返回結果
        if (result != null && mounted) {
          // 如果返回的是錯誤資訊
          if (result is Map && result['error'] == true) {
            // 顯示錯誤對話框
            _showErrorDialog(result['message'] as String? ?? 'AI 分析失敗');
            return;
          }
          
          // 如果建檔成功，清空表單
          if (result == true) {
            setState(() {
              _textController.clear();
            });
            draftState.reset();
            // 重置自動儲存相關變數
            _lastSavedContent = '';
            _lastSavedDraftId = null;
          }
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          final screenHeight = constraints.maxHeight;
          final initialHeight = screenHeight / 3;
          
          return _hasText
              ? Column(
                  children: [
                    // 可滾動的內容區
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              '有什麼好點子嗎？',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _textController,
                              maxLines: null,
                              minLines: 3,
                              maxLength: null,
                              decoration: const InputDecoration(
                                hintText: '請貼上或輸入 KOL 發文內容...',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.all(16),
                              ),
                              textAlignVertical: TextAlignVertical.top,
                            ),
                          ],
                        ),
                      ),
                    ),
                    // 固定在底部的按鈕區域（存為草稿 + 分析）
                    Container(
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
                        child: Row(
                          children: [
                            // 存為草稿按鈕（左側，40%）
                            Expanded(
                              flex: 2,
                              child: Container(
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: const Color(0xFF6366F1),
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: _saveAsDraft,
                                    borderRadius: BorderRadius.circular(30),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      alignment: Alignment.center,
                                      child: const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.save_outlined,
                                            color: Color(0xFF6366F1),
                                            size: 20,
                                          ),
                                          SizedBox(width: 6),
                                          Text(
                                            '存為草稿',
                                            style: TextStyle(
                                              color: Color(0xFF6366F1),
                                              fontSize: 14,
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
                            // 分析按鈕（右側，60%）
                            Expanded(
                              flex: 3,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF6366F1), // Indigo
                                      Color(0xFF8B5CF6), // Purple
                                    ],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                  borderRadius: BorderRadius.circular(30),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF6366F1).withOpacity(0.3),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: _onAnalyze,
                                    borderRadius: BorderRadius.circular(30),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      alignment: Alignment.center,
                                      child: const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.auto_awesome,
                                            color: Colors.white,
                                            size: 22,
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            '分析',
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
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          '有什麼好點子嗎？',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: initialHeight,
                            minHeight: initialHeight,
                          ),
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
                            // 存為草稿按鈕（左側，40%，禁用狀態）
                            Expanded(
                              flex: 2,
                              child: Container(
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: const Color(0xFF6366F1).withOpacity(0.3),
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  alignment: Alignment.center,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.save_outlined,
                                        color: const Color(0xFF6366F1).withOpacity(0.5),
                                        size: 20,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '存為草稿',
                                        style: TextStyle(
                                          color: const Color(0xFF6366F1).withOpacity(0.5),
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            // 分析按鈕（右側，60%，禁用狀態）
                            Expanded(
                              flex: 3,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      const Color(0xFF6366F1).withOpacity(0.5),
                                      const Color(0xFF8B5CF6).withOpacity(0.5),
                                    ],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  alignment: Alignment.center,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.auto_awesome,
                                        color: Colors.white.withOpacity(0.7),
                                        size: 22,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '分析',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.7),
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
                          ],
                        ),
                      ],
                    ),
                  ),
                );
        },
      ),
    );
  }
}
