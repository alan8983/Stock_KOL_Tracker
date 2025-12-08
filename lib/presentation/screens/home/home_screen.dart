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

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _textController = TextEditingController();
  bool _hasText = false;
  int _currentIndex = 0;

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

  void _onAnalyze() {
    final draftState = ref.read(draftStateProvider.notifier);
    draftState.updateContent(_textController.text);
    
    // 導航到詳細編輯頁面
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const DraftEditScreen(),
      ),
    );
    
    // 觸發 AI 分析
    Future.delayed(const Duration(milliseconds: 300), () {
      draftState.analyzeContent();
    });
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
