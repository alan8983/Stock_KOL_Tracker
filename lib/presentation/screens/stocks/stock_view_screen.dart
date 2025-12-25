import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/repositories/stock_repository.dart';
import '../../../domain/providers/repository_providers.dart';
import '../../../domain/providers/stock_posts_provider.dart';
import '../../../domain/providers/stock_stats_provider.dart';
import '../../../data/database/database.dart';
import '../posts/post_detail_screen.dart';
import '../kol/kol_view_screen.dart';
import '../../widgets/syncfusion_stock_chart.dart';

/// 投資標的詳細頁面
/// 包含3個子頁籤：文檔清單/市場敘事/K線圖
class StockViewScreen extends ConsumerStatefulWidget {
  final String ticker;

  const StockViewScreen({
    super.key,
    required this.ticker,
  });

  @override
  ConsumerState<StockViewScreen> createState() => _StockViewScreenState();
}

class _StockViewScreenState extends ConsumerState<StockViewScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Stock? _stock;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadStock();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadStock() async {
    try {
      final stockRepo = ref.read(stockRepositoryProvider);
      final stock = await stockRepo.getStockByTicker(widget.ticker);
      if (mounted) {
        setState(() {
          _stock = stock;
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
    if (_stock == null) {
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
              _stock!.ticker.substring(0, _stock!.ticker.length >= 2 ? 2 : 1),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _stock!.ticker,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (_stock!.name != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _stock!.name!,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
                if (_stock!.exchange != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    _stock!.exchange!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                        ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostsTab() {
    final postsAsync = ref.watch(stockPostsWithDetailsProvider(widget.ticker));
    
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(stockPostsWithDetailsProvider(widget.ticker));
        ref.invalidate(stockPostsProvider(widget.ticker));
        ref.invalidate(stockStatsProvider(widget.ticker));
      },
      child: postsAsync.when(
        data: (postsWithDetails) {
          if (postsWithDetails.isEmpty) {
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
                        '此投資標的尚無文檔',
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
          itemCount: postsWithDetails.length,
          itemBuilder: (context, index) {
            final postWithDetails = postsWithDetails[index];
            final post = postWithDetails.post;
            final kol = postWithDetails.kol;
            
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  child: Text(
                    kol.name.substring(0, kol.name.length >= 2 ? 2 : 1),
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(
                  post.content.length > 50 
                    ? '${post.content.substring(0, 50)}...' 
                    : post.content,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Row(
                  children: [
                    Flexible(
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => KOLViewScreen(kolId: kol.id),
                            ),
                          );
                        },
                        child: Text(
                          kol.name,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ),
                    Text(' · ${_formatDate(post.postedAt)}'),
                  ],
                ),
                trailing: _buildSentimentChip(post.sentiment),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PostDetailScreen(postId: post.id),
                    ),
                  );
                },
              ),
            );
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
                    onPressed: () => ref.invalidate(stockPostsWithDetailsProvider(widget.ticker)),
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
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }

  Widget _buildNarrativeTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.auto_awesome, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            '市場敘事',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          SizedBox(height: 8),
          Text(
            'AI 彙整論點',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          SizedBox(height: 4),
          Text(
            '此功能將在 Release 01 推出',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildChartTab() {
    // 使用 LayoutBuilder 確保圖表有足夠空間
    // 移除額外的 padding，讓 K 線圖可以充分利用可用空間
    return LayoutBuilder(
      builder: (context, constraints) {
        return SyncfusionStockChart(ticker: widget.ticker);
      },
    );
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

    if (_stock == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('錯誤'),
        ),
        body: const Center(
          child: Text('找不到此投資標的'),
        ),
      );
    }

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              title: Text(_stock!.ticker),
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
                    Tab(text: '文檔清單'),
                    Tab(text: '市場敘事'),
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
            _buildPostsTab(),
            _buildNarrativeTab(),
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
