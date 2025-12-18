import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/providers/kol_list_provider.dart';
import '../../../domain/providers/kol_win_rate_provider.dart';
import '../../../domain/providers/repository_providers.dart';
import '../../../data/models/win_rate_stats.dart';
import '../../widgets/create_kol_dialog.dart';
import '../../widgets/kol_stats_card.dart';
import 'kol_view_screen.dart';

/// KOL列表頁面
/// 顯示所有KOL，支援搜尋和排序
class KOLListScreen extends ConsumerStatefulWidget {
  const KOLListScreen({super.key});

  @override
  ConsumerState<KOLListScreen> createState() => _KOLListScreenState();
}

class _KOLListScreenState extends ConsumerState<KOLListScreen> with AutomaticKeepAliveClientMixin {
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
    ref.read(kolListProvider.notifier).loadKOLs();
  }

  void _onSearch(String query) {
    ref.read(kolListProvider.notifier).searchKOLs(query);
  }

  Future<void> _showCreateKOLDialog() async {
    final kolRepository = ref.read(kolRepositoryProvider);
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => CreateKOLDialog(kolRepository: kolRepository),
    );

    if (result == true && mounted) {
      // 重新載入列表
      ref.invalidate(kolListProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final kolsAsync = ref.watch(kolListProvider);
    final kolStatsAsync = ref.watch(allKOLWinRateStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: '搜尋 KOL...',
                  border: InputBorder.none,
                ),
                onChanged: _onSearch,
              )
            : const Text('KOL'),
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
      body: kolsAsync.when(
        data: (kols) {
          if (kols.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.person_outline, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    _isSearching ? '找不到符合的 KOL' : '目前沒有 KOL',
                    style: const TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  if (!_isSearching) ...[
                    const SizedBox(height: 8),
                    const Text(
                      '點擊右下角按鈕新增 KOL',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ],
              ),
            );
          }

          // 過濾掉「未分類」KOL (id=1)
          final validKols = kols.where((kol) => kol.id != 1).toList();

          return ListView.builder(
            itemCount: validKols.length,
            itemBuilder: (context, index) {
              final kol = validKols[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => KOLViewScreen(kolId: kol.id),
                      ),
                    );
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // KOL 基本資訊
                      ListTile(
                        leading: CircleAvatar(
                          child: Text(
                            kol.name.isNotEmpty ? kol.name[0].toUpperCase() : '?',
                            style: const TextStyle(fontSize: 20),
                          ),
                        ),
                        title: Text(
                          kol.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: kol.bio != null
                            ? Text(
                                kol.bio!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              )
                            : null,
                        trailing: const Icon(Icons.chevron_right),
                      ),
                      
                      // 統計資訊
                      kolStatsAsync.when(
                        data: (statsList) {
                          final stats = statsList.firstWhere(
                            (s) => s.kolId == kol.id,
                            orElse: () => KOLWinRateStats(
                              kolId: kol.id,
                              kolName: kol.name,
                              totalPosts: 0,
                              stockCount: 0,
                              bullishCount: 0,
                              bearishCount: 0,
                              neutralCount: 0,
                              winRateStats: const MultiPeriodWinRateStats(periodStats: {}),
                            ),
                          );
                          
                          if (stats.totalPosts > 0) {
                            return Column(
                              children: [
                                const Divider(height: 1),
                                KOLStatsCard(stats: stats),
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
                  ref.invalidate(kolListProvider);
                },
                child: const Text('重試'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateKOLDialog,
        tooltip: '新增 KOL',
        child: const Icon(Icons.add),
      ),
    );
  }
}
