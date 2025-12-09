import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/providers/stock_list_provider.dart';
import '../../../data/database/database.dart';
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
      body: stocksAsync.when(
        data: (stocks) {
          if (stocks.isEmpty) {
            return Center(
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
            );
          }

          return ListView.builder(
            itemCount: stocks.length,
            itemBuilder: (context, index) {
              final stock = stocks[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
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
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => StockViewScreen(ticker: stock.ticker),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
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
    );
  }
}
