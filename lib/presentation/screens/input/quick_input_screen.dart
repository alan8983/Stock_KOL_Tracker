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
        
        // 如果建檔成功，清空表單
        if (result == true && mounted) {
          setState(() {
            _textController.clear();
          });
          draftState.reset();
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
                    // 固定在底部的分析按鈕
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
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
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
                        Container(
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
                          child: Material(
                            color: Colors.transparent,
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
                  ),
                );
        },
      ),
    );
  }
}
