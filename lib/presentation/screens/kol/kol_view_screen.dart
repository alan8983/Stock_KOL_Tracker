import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/repositories/kol_repository.dart';
import '../../../domain/providers/repository_providers.dart';
import '../../../domain/providers/kol_posts_provider.dart';
import '../../../domain/providers/kol_win_rate_provider.dart';
import '../../../data/database/database.dart';
import '../posts/post_detail_screen.dart';
import '../stocks/stock_view_screen.dart';

/// KOL詳細頁面
/// 包含3個子頁籤：Overview/勝率統計/簡介
class KOLViewScreen extends ConsumerStatefulWidget {
  final int kolId;

  const KOLViewScreen({
    super.key,
    required this.kolId,
  });

  @override
  ConsumerState<KOLViewScreen> createState() => _KOLViewScreenState();
}

class _KOLViewScreenState extends ConsumerState<KOLViewScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  KOL? _kol;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadKOL();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadKOL() async {
    try {
      final kolRepo = ref.read(kolRepositoryProvider);
      final kol = await kolRepo.getKOLById(widget.kolId);
      if (mounted) {
        setState(() {
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

  Widget _buildHeader() {
    if (_kol == null) {
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
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            child: Text(
              _kol!.name.isNotEmpty ? _kol!.name[0].toUpperCase() : '?',
              style: const TextStyle(fontSize: 24),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _kol!.name,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (_kol!.bio != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _kol!.bio!,
                    style: Theme.of(context).textTheme.bodyMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    final groupedPostsAsync = ref.watch(kolPostsGroupedByStockProvider(widget.kolId));
    
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(kolPostsGroupedByStockProvider(widget.kolId));
        ref.invalidate(kolPostsProvider(widget.kolId));
        ref.invalidate(kolPostsWithDetailsProvider(widget.kolId));
        ref.invalidate(kolPostStatsProvider(widget.kolId));
        ref.invalidate(kolWinRateStatsProvider(widget.kolId));
      },
      child: groupedPostsAsync.when(
        data: (groupedPosts) {
          if (groupedPosts.isEmpty) {
            return const SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: 400,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.article_outlined, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        '此 KOL 尚無文檔',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
          
          return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: groupedPosts.length,
          itemBuilder: (context, index) {
            final group = groupedPosts[index];
            return _buildStockGroup(group);
          },
        );
        },
        loading: () => const SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: 400,
            child: Center(child: CircularProgressIndicator()),
          ),
        ),
        error: (error, stack) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: 400,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('載入失敗: $error'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.invalidate(kolPostsGroupedByStockProvider(widget.kolId)),
                    child: const Text('重試'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 建立投資標的分組卡片
  Widget _buildStockGroup(PostsGroupedByStock group) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 標的標題
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StockViewScreen(ticker: group.stock.ticker),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(context).dividerColor,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    child: Text(
                      group.stock.ticker.substring(0, group.stock.ticker.length >= 2 ? 2 : 1),
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          group.stock.ticker,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        if (group.stock.name != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            group.stock.name!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey,
                                ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${group.postCount} 篇文檔',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (group.bullishCount > 0) ...[
                            Icon(Icons.trending_up, size: 14, color: Colors.green),
                            Text(
                              '${group.bullishCount}',
                              style: const TextStyle(fontSize: 12, color: Colors.green),
                            ),
                            const SizedBox(width: 4),
                          ],
                          if (group.bearishCount > 0) ...[
                            Icon(Icons.trending_down, size: 14, color: Colors.red),
                            Text(
                              '${group.bearishCount}',
                              style: const TextStyle(fontSize: 12, color: Colors.red),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),
          ),
          // 文檔列表
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(12),
            itemCount: group.posts.length,
            separatorBuilder: (context, index) => const Divider(height: 16),
            itemBuilder: (context, index) {
              final post = group.posts[index];
              return _buildPostItem(post);
            },
          ),
        ],
      ),
    );
  }

  /// 建立單一文檔項目
  Widget _buildPostItem(Post post) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PostDetailScreen(postId: post.id),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.content.length > 100
                        ? '${post.content.substring(0, 100)}...'
                        : post.content,
                    style: Theme.of(context).textTheme.bodyMedium,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatDate(post.postedAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            _buildSentimentChip(post.sentiment),
          ],
        ),
      ),
    );
  }

  Widget _buildSentimentChip(String sentiment) {
    Color color;
    IconData icon;
    switch (sentiment) {
      case 'Bullish':
        color = Colors.green;
        icon = Icons.trending_up;
        break;
      case 'Bearish':
        color = Colors.red;
        icon = Icons.trending_down;
        break;
      default:
        color = Colors.grey;
        icon = Icons.trending_flat;
    }
    return Chip(
      label: Text(sentiment, style: const TextStyle(color: Colors.white, fontSize: 12)),
      backgroundColor: color,
      avatar: Icon(icon, color: Colors.white, size: 16),
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  Widget _buildPerformanceTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.trending_up, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            '勝率統計',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          SizedBox(height: 8),
          Text(
            '顯示各標的勝率統計',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          SizedBox(height: 4),
          Text(
            '此功能開發中...',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileTab() {
    if (_kol == null) {
      return const Center(child: Text('無資料'));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'KOL 簡介',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                if (_kol!.bio != null) ...[
                  Text(_kol!.bio!),
                  const SizedBox(height: 16),
                ] else ...[
                  const Text(
                    '尚未設定簡介',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                ],
                if (_kol!.socialLink != null) ...[
                  const Divider(),
                  const SizedBox(height: 12),
                  Text(
                    'SNS 連結',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () {
                      // TODO: 開啟外部連結
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('開啟連結: ${_kol!.socialLink}')),
                      );
                    },
                    child: Row(
                      children: [
                        const Icon(Icons.link, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _kol!.socialLink!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              decoration: TextDecoration.underline,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '統計資訊',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                _buildStatRow('建立時間', _formatDate(_kol!.createdAt)),
                const SizedBox(height: 8),
                _buildStatRowWithProvider(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static Widget _buildStatRow(String label, String value) {
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

  Widget _buildStatRowWithProvider() {
    final statsAsync = ref.watch(kolPostStatsProvider(widget.kolId));
    
    return statsAsync.when(
      data: (stats) => Column(
        children: [
          _buildStatRow('文檔數量', '${stats.totalPosts}'),
          const SizedBox(height: 8),
          _buildStatRow('追蹤標的數', '${stats.stockCount}'),
          const SizedBox(height: 8),
          _buildStatRow('主要情緒', stats.dominantSentiment),
        ],
      ),
      loading: () => Column(
        children: [
          _buildStatRow('文檔數量', '載入中...'),
          const SizedBox(height: 8),
          _buildStatRow('追蹤標的數', '載入中...'),
        ],
      ),
      error: (_, __) => Column(
        children: [
          _buildStatRow('文檔數量', '錯誤'),
          const SizedBox(height: 8),
          _buildStatRow('追蹤標的數', '錯誤'),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
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

    if (_kol == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('錯誤'),
        ),
        body: const Center(
          child: Text('找不到此 KOL'),
        ),
      );
    }

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              title: Text(_kol!.name),
              pinned: true,
              floating: false,
              forceElevated: innerBoxIsScrolled,
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
                    Tab(text: 'Overview'),
                    Tab(text: '勝率統計'),
                    Tab(text: '簡介'),
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
            _buildOverviewTab(),
            _buildPerformanceTab(),
            _buildProfileTab(),
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
