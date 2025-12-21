import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/providers/stock_list_provider.dart';
import '../../../domain/providers/stock_stats_provider.dart';
import '../../../data/models/stock_stats.dart';
import '../../widgets/stock_stats_card.dart';
import 'stock_view_screen.dart';

/// 投資標的列表頁面
/// 顯示所有投資標的，支援搜尋和排序
class StockListScreen extends ConsumerStatefulWidget {
  const StockListScreen({super.key});

  @override
  ConsumerState<StockListScreen> createState() => _StockListScreenState();
}

class _StockListScreenState extends ConsumerState<StockListScreen>
    with AutomaticKeepAliveClientMixin {
  final _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _startSearch() {
    setState(() {
      _isSearching = true;
    });
  }

  void _stopSearch() {
    setState(() {
      _isSearching = false;
      _searchController.clear();
    });
    ref.read(stockListProvider.notifier).loadStocks();
  }

  void _onSearch(String query) {
    ref.read(stockListProvider.notifier).searchStocks(query);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final stocksAsync = ref.watch(stockListProvider);
    final stockStatsAsync = ref.watch(allStockStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: '搜尋投資標的...',
                  border: InputBorder.none,
                ),
                onChanged: _onSearch,
              )
            : const Text('投資標的'),
        centerTitle: !_isSearching,
        actions: [
          if (_isSearching)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _stopSearch,
            )
          else
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: _startSearch,
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(stockListProvider.notifier).loadStocks();
          ref.invalidate(allStockStatsProvider);
        },
        child: stocksAsync.when(
          data: (stocks) {
            if (stocks.isEmpty) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: 400,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.show_chart, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          _isSearching ? '找不到符合的投資標的' : '目前沒有投資標的',
                          style: const TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        if (!_isSearching) ...[
                          const SizedBox(height: 8),
                          const Text(
                            '投資標的會在建檔時自動新增',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }

            // 過濾掉「臨時」股票 (ticker='TEMP')
            final validStocks = stocks.where((stock) => stock.ticker != 'TEMP').toList();

            return ListView.builder(
            itemCount: validStocks.length,
            itemBuilder: (context, index) {
              final stock = validStocks[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => StockViewScreen(ticker: stock.ticker),
                      ),
                    );
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 股票基本資訊
                      ListTile(
                        leading: CircleAvatar(
                          child: Text(
                            stock.ticker.substring(0, stock.ticker.length >= 2 ? 2 : 1),
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Row(
                          children: [
                            Text(
                              stock.ticker,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (stock.name != null) ...[
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  stock.name!,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),
                        subtitle: stock.exchange != null
                            ? Text(
                                stock.exchange!,
                                style: const TextStyle(fontSize: 12),
                              )
                            : null,
                        trailing: const Icon(Icons.chevron_right),
                      ),
                      
                      // 統計資訊
                      stockStatsAsync.when(
                        data: (statsList) {
                          final stats = statsList.firstWhere(
                            (s) => s.ticker == stock.ticker,
                            orElse: () => StockStats(
                              ticker: stock.ticker,
                              stockName: stock.name,
                              totalPosts: 0,
                              kolCount: 0,
                              bullishCount: 0,
                              bearishCount: 0,
                              neutralCount: 0,
                              avgPriceChanges: {},
                            ),
                          );
                          
                          if (stats.totalPosts > 0) {
                            return Column(
                              children: [
                                const Divider(height: 1),
                                StockStatsCard(stats: stats),
                              ],
                            );
                          }
                          return const SizedBox.shrink();
                        },
                        loading: () => const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        ),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                    ],
                  ),
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
                      onPressed: () {
                        ref.invalidate(stockListProvider);
                      },
                      child: const Text('重試'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
