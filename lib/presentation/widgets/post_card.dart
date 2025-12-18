import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/post_with_kol.dart';
import '../../core/utils/datetime_formatter.dart';
import '../../domain/providers/bookmark_provider.dart';
import 'price_change_indicator.dart';

/// 貼文卡片元件
/// 顯示已發布的貼文，支援書籤功能
class PostCard extends ConsumerWidget {
  final PostWithKOL postWithKOL;
  final VoidCallback? onTap;

  const PostCard({
    super.key,
    required this.postWithKOL,
    this.onTap,
  });

  Color _getSentimentColor(String sentiment) {
    switch (sentiment.toLowerCase()) {
      case 'bullish':
      case '看多':
        return Colors.green;
      case 'bearish':
      case '看空':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getSentimentIcon(String sentiment) {
    switch (sentiment.toLowerCase()) {
      case 'bullish':
      case '看多':
        return Icons.trending_up;
      case 'bearish':
      case '看空':
        return Icons.trending_down;
      default:
        return Icons.trending_flat;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final post = postWithKOL.post;
    final kol = postWithKOL.kol;
    final contentPreview = post.content.length > 100
        ? '${post.content.substring(0, 100)}...'
        : post.content;
    
    final isBookmarked = ref.watch(bookmarkProvider).contains(post.id);
    final sentimentColor = _getSentimentColor(post.sentiment);
    final sentimentIcon = _getSentimentIcon(post.sentiment);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: KOL 名稱 + 書籤按鈕
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        child: Text(
                          kol.name.isNotEmpty ? kol.name[0].toUpperCase() : '?',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        kol.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(
                      isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                      color: isBookmarked
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey,
                    ),
                    onPressed: () {
                      ref.read(bookmarkProvider.notifier).toggleBookmark(post.id);
                    },
                    tooltip: isBookmarked ? '移除書籤' : '加入書籤',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // 情緒標籤 + 股票代碼
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: sentimentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: sentimentColor),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(sentimentIcon, size: 14, color: sentimentColor),
                        const SizedBox(width: 4),
                        Text(
                          post.sentiment,
                          style: TextStyle(
                            fontSize: 12,
                            color: sentimentColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.show_chart, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    post.stockTicker,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // 漲跌幅顯示
              PriceChangeIndicator(postId: post.id),
              const SizedBox(height: 12),
              // 內容預覽
              Text(
                contentPreview,
                style: const TextStyle(fontSize: 14, height: 1.5),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              // 發文時間
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateTimeFormatter.formatRelative(post.postedAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: Colors.grey.shade400,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
