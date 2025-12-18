import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import '../../../domain/providers/repository_providers.dart';
import '../../../domain/providers/post_list_provider.dart';
import '../../../domain/providers/stock_posts_provider.dart';
import '../../../domain/providers/kol_posts_provider.dart';
import '../../../domain/providers/kol_win_rate_provider.dart';
import '../../../domain/providers/stock_stats_provider.dart';
import '../../../data/database/database.dart';
import '../../../data/models/analysis_result.dart';
import '../../widgets/focused_stock_chart_widget.dart';

/// 單篇文檔詳細頁面
/// 包含2個子頁籤：主文內容/K線圖
class PostDetailScreen extends ConsumerStatefulWidget {
  final int postId;

  const PostDetailScreen({
    super.key,
    required this.postId,
  });

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Post? _post;
  KOL? _kol;
  bool _isLoading = true;
  bool _isBookmarked = false;
  bool _isEditingContent = false;
  late TextEditingController _editContentController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _editContentController = TextEditingController();
    _loadPost();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _editContentController.dispose();
    super.dispose();
  }

  Future<void> _loadPost() async {
    try {
      final postRepo = ref.read(postRepositoryProvider);
      final kolRepo = ref.read(kolRepositoryProvider);
      
      final post = await postRepo.getPostById(widget.postId);
      KOL? kol;
      
      if (post != null) {
        kol = await kolRepo.getKOLById(post.kolId);
      }
      
      if (mounted) {
        setState(() {
          _post = post;
          _kol = kol;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('載入失敗: $e')),
        );
      }
    }
  }

  void _toggleBookmark() {
    setState(() {
      _isBookmarked = !_isBookmarked;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isBookmarked ? '已加入書籤' : '已移除書籤'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _toggleEditMode() {
    setState(() {
      if (_isEditingContent) {
        // 取消編輯，恢復原內容
        _editContentController.text = _post!.content;
      } else {
        // 進入編輯模式，初始化內容
        _editContentController.text = _post!.content;
      }
      _isEditingContent = !_isEditingContent;
    });
  }

  Future<void> _saveContent() async {
    final newContent = _editContentController.text.trim();
    if (newContent.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('內容不能為空'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      final postRepo = ref.read(postRepositoryProvider);
      
      // 先讀取現有文檔，確保所有欄位都有值
      final currentPost = await postRepo.getPostById(_post!.id);
      if (currentPost == null) {
        throw Exception('找不到此文檔');
      }

      // 使用現有資料建立 Companion，只更新 content
      await postRepo.updatePost(
        _post!.id,
        PostsCompanion(
          content: drift.Value(newContent),
          // 明確保留其他欄位，避免被設為 null
          kolId: drift.Value(currentPost.kolId),
          stockTicker: drift.Value(currentPost.stockTicker),
          sentiment: drift.Value(currentPost.sentiment),
          postedAt: drift.Value(currentPost.postedAt),
          createdAt: drift.Value(currentPost.createdAt),
          status: drift.Value(currentPost.status),
          aiAnalysisJson: currentPost.aiAnalysisJson != null
              ? drift.Value(currentPost.aiAnalysisJson)
              : const drift.Value.absent(),
        ),
      );

      // 重新載入文檔以獲取最新資料
      final updatedPost = await postRepo.getPostById(_post!.id);
      
      if (mounted) {
        setState(() {
          if (updatedPost != null) {
            _post = updatedPost;
          }
          _isEditingContent = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('儲存成功'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e, stackTrace) {
      print('儲存文檔內容失敗: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('儲存失敗: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Widget _buildHeader() {
    if (_post == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                child: Text(
                  _kol?.name.isNotEmpty == true
                      ? _kol!.name[0].toUpperCase()
                      : '?',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _kol?.name ?? '未知 KOL',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _formatDateTime(_post!.postedAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              _buildSentimentChip(_post!.sentiment),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.show_chart, size: 16),
              const SizedBox(width: 4),
              Text(
                _post!.stockTicker,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSentimentChip(String sentiment) {
    Color color;
    IconData icon;

    switch (sentiment.toLowerCase()) {
      case 'bullish':
      case '看多':
        color = Colors.green;
        icon = Icons.trending_up;
        break;
      case 'bearish':
      case '看空':
        color = Colors.red;
        icon = Icons.trending_down;
        break;
      default:
        color = Colors.grey;
        icon = Icons.trending_flat;
    }

    return Chip(
      avatar: Icon(icon, size: 16, color: color),
      label: Text(
        sentiment,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: color.withOpacity(0.1),
      side: BorderSide(color: color),
    );
  }

  Widget _buildContentTab() {
    if (_post == null) {
      return const Center(child: Text('無資料'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 文檔內容卡片
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: _isEditingContent
                  ? BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    )
                  : BorderSide.none,
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '文檔內容',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              _isEditingContent ? Icons.close : Icons.edit,
                              color: _isEditingContent
                                  ? Colors.grey
                                  : Theme.of(context).colorScheme.primary,
                            ),
                            onPressed: _toggleEditMode,
                            tooltip: _isEditingContent ? '取消編輯' : '編輯內容',
                          ),
                          IconButton(
                            icon: Icon(
                              _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                              color: _isBookmarked
                                  ? Theme.of(context).colorScheme.primary
                                  : null,
                            ),
                            onPressed: _toggleBookmark,
                            tooltip: _isBookmarked ? '移除書籤' : '加入書籤',
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 8),
                  // 編輯模式或顯示模式
                  if (_isEditingContent) ...[
                    TextField(
                      controller: _editContentController,
                      maxLines: null,
                      minLines: 10,
                      decoration: InputDecoration(
                        hintText: '輸入文檔內容...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.primary,
                            width: 2,
                          ),
                        ),
                      ),
                      style: const TextStyle(fontSize: 16, height: 1.5),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: _toggleEditMode,
                          child: const Text('取消'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _saveContent,
                          child: const Text('儲存'),
                        ),
                      ],
                    ),
                  ] else
                    Text(
                      _post!.content,
                      style: const TextStyle(fontSize: 16, height: 1.5),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // AI 摘要卡片（如果有）
          if (_post!.aiAnalysisJson != null) _buildAISummaryCard(),
          const SizedBox(height: 16),
          // 文檔資訊卡片
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '文檔資訊',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const Divider(),
                  const SizedBox(height: 8),
                  _buildInfoRow('建檔時間', _formatDateTime(_post!.createdAt)),
                  const SizedBox(height: 8),
                  _buildInfoRow('狀態', _post!.status),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// AI 分析摘要卡片
  Widget _buildAISummaryCard() {
    try {
      final aiAnalysisJson = _post!.aiAnalysisJson!;
      final analysisResult = AnalysisResult.fromJson(
        jsonDecode(aiAnalysisJson) as Map<String, dynamic>,
      );

      return Card(
        color: Colors.indigo.shade50,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.indigo.shade200),
        ),
        child: ExpansionTile(
          leading: Icon(Icons.auto_awesome, color: Colors.indigo.shade700),
          title: Text(
            'AI 分析摘要',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.indigo.shade900,
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 情緒判斷
                  Row(
                    children: [
                      const Text(
                        '情緒判斷：',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildSentimentChip(analysisResult.sentiment),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // 核心論述摘要
                  if (analysisResult.summary.isNotEmpty) ...[
                    const Text(
                      '核心論述：',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...analysisResult.summary.asMap().entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${entry.key + 1}. ',
                              style: TextStyle(
                                color: Colors.indigo.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                entry.value,
                                style: const TextStyle(fontSize: 14, height: 1.4),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                  // 推理說明
                  if (analysisResult.reasoning != null &&
                      analysisResult.reasoning!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text(
                      '推理說明：',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      analysisResult.reasoning!,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      return Card(
        color: Colors.red.shade50,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'AI 摘要解析失敗: $e',
            style: TextStyle(color: Colors.red.shade900),
          ),
        ),
      );
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.grey),
        ),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildChartTab() {
    if (_post == null) {
      return const Center(child: Text('無資料'));
    }

    return FocusedStockChartWidget(
      ticker: _post!.stockTicker,
      focusDate: _post!.postedAt, // 傳入文檔發布日期
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _deletePost() async {
    // 顯示確認對話框
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('確認刪除'),
        content: const Text('此操作無法復原，確定要刪除這篇文檔嗎？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('刪除'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final postRepo = ref.read(postRepositoryProvider);
      final deletedPost = _post!; // 保存被刪除的文檔資訊
      await postRepo.deletePost(_post!.id);

      if (mounted) {
        // 刷新所有相關的 provider
        ref.invalidate(postListProvider);
        
        // 刷新股票相關的 provider
        ref.invalidate(stockPostsProvider(deletedPost.stockTicker));
        ref.invalidate(stockPostsWithDetailsProvider(deletedPost.stockTicker));
        ref.invalidate(stockStatsProvider(deletedPost.stockTicker));
        
        // 刷新 KOL 相關的 provider
        ref.invalidate(kolPostsProvider(deletedPost.kolId));
        ref.invalidate(kolPostsWithDetailsProvider(deletedPost.kolId));
        ref.invalidate(kolPostsGroupedByStockProvider(deletedPost.kolId));
        ref.invalidate(kolPostStatsProvider(deletedPost.kolId));
        ref.invalidate(kolWinRateStatsProvider(deletedPost.kolId));
        ref.invalidate(allKOLWinRateStatsProvider);
        
        Navigator.of(context).pop(); // 返回上一頁
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('文檔已刪除'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('刪除失敗: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('載入中...'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_post == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('錯誤'),
        ),
        body: const Center(
          child: Text('找不到此文檔'),
        ),
      );
    }

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              title: Text(_post!.stockTicker),
              pinned: true,
              floating: false,
              forceElevated: innerBoxIsScrolled,
              actions: [
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: _deletePost,
                  tooltip: '刪除文檔',
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: _buildHeader(),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverAppBarDelegate(
                TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(text: '主文內容'),
                    Tab(text: 'K線圖'),
                  ],
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildContentTab(),
            _buildChartTab(),
          ],
        ),
      ),
    );
  }
}

/// SliverAppBarDelegate - 用於固定 TabBar
class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
