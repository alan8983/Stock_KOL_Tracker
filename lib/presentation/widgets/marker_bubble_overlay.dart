import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database/database.dart';
import '../../domain/providers/repository_providers.dart';
import '../screens/posts/post_detail_screen.dart';
import 'package:intl/intl.dart';

/// Marker 長按氣泡組件
/// 顯示該 Candlestick 日期區間內的所有文檔清單
class MarkerBubbleOverlay extends ConsumerWidget {
  final List<Post> posts;
  final Offset position;
  final VoidCallback onDismiss;

  const MarkerBubbleOverlay({
    super.key,
    required this.posts,
    required this.position,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Stack(
      children: [
        // 背景遮罩（點擊關閉）
        Positioned.fill(
          child: GestureDetector(
            onTap: onDismiss,
            child: Container(
              color: Colors.transparent,
            ),
          ),
        ),
        // 氣泡內容
        Positioned(
          left: position.dx.clamp(0, MediaQuery.of(context).size.width - 200),
          top: position.dy.clamp(0, MediaQuery.of(context).size.height - 300),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 250,
              constraints: const BoxConstraints(maxHeight: 300),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).dividerColor,
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 標題
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.description,
                          size: 16,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '文檔清單 (${posts.length})',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: onDismiss,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ],
                    ),
                  ),
                  // 文檔列表
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: posts.length,
                      itemBuilder: (context, index) {
                        final post = posts[index];
                        return _buildPostItem(context, ref, post);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPostItem(BuildContext context, WidgetRef ref, Post post) {
    // 查詢 KOL 信息
    final kolAsync = ref.watch(kolProvider(post.kolId));

    return kolAsync.when(
      data: (kol) => _buildPostItemContent(context, post, kol),
      loading: () => const ListTile(
        title: Text('載入中...'),
        dense: true,
      ),
      error: (_, __) => _buildPostItemContent(context, post, null),
    );
  }

  Widget _buildPostItemContent(BuildContext context, Post post, KOL? kol) {
    final kolName = kol?.name ?? '未知作者';
    final dateStr = DateFormat('yyyy/MM/dd HH:mm').format(post.postedAt);

    return ListTile(
      dense: true,
      leading: CircleAvatar(
        radius: 16,
        child: Text(
          kolName.substring(0, kolName.length >= 2 ? 2 : 1),
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ),
      title: Text(
        kolName,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        dateStr,
        style: TextStyle(
          fontSize: 11,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        ),
      ),
      trailing: _buildSentimentChip(context, post.sentiment),
      onTap: () {
        onDismiss();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PostDetailScreen(postId: post.id),
          ),
        );
      },
    );
  }

  Widget _buildSentimentChip(BuildContext context, String sentiment) {
    Color color;
    String label;

    switch (sentiment) {
      case 'Bullish':
        color = Colors.green;
        label = 'L';
        break;
      case 'Bearish':
        color = Colors.red;
        label = 'S';
        break;
      default:
        color = Colors.grey;
        label = 'N';
    }

    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

/// KOL Provider（用於查詢單個 KOL）
final kolProvider = FutureProvider.family<KOL?, int>((ref, kolId) async {
  final kolRepo = ref.watch(kolRepositoryProvider);
  return await kolRepo.getKOLById(kolId);
});

