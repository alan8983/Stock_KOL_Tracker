import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database/database.dart';
import '../../domain/providers/repository_providers.dart';
import '../screens/posts/post_detail_screen.dart';
import 'package:intl/intl.dart';

/// Marker 長按氣泡組件
/// 顯示該 Candlestick 日期區間內的所有文檔清單
class MarkerBubbleOverlay extends ConsumerStatefulWidget {
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
  ConsumerState<MarkerBubbleOverlay> createState() => _MarkerBubbleOverlayState();
}

class _MarkerBubbleOverlayState extends ConsumerState<MarkerBubbleOverlay> {
  final GlobalKey _bubbleKey = GlobalKey();
  Offset? _adaptivePosition;

  @override
  void initState() {
    super.initState();
    // 使用 WidgetsBinding 在下一幀計算位置（此時已渲染完成）
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculateAdaptivePosition();
    });
  }

  void _calculateAdaptivePosition() {
    if (!mounted) return;
    
    final renderBox = _bubbleKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final bubbleSize = renderBox.size;
    final screenSize = MediaQuery.of(context).size;
    const padding = 8.0;

    double left = widget.position.dx;
    double top = widget.position.dy;

    // 確保不超出右邊界
    if (left + bubbleSize.width > screenSize.width - padding) {
      left = screenSize.width - bubbleSize.width - padding;
    }

    // 確保不超出左邊界
    if (left < padding) {
      left = padding;
    }

    // 確保不超出下邊界
    if (top + bubbleSize.height > screenSize.height - padding) {
      top = screenSize.height - bubbleSize.height - padding;
    }

    // 確保不超出上邊界
    if (top < padding) {
      top = padding;
    }

    setState(() {
      _adaptivePosition = Offset(left, top);
    });
  }

  @override
  Widget build(BuildContext context) {
    const bubbleWidth = 180.0;
    const maxBubbleHeight = 250.0;

    // 初始位置使用傳入的位置，渲染後會更新為自適應位置
    final currentPosition = _adaptivePosition ?? widget.position;

    return Stack(
      children: [
        // 背景遮罩（點擊關閉）
        Positioned.fill(
          child: GestureDetector(
            onTap: widget.onDismiss,
            child: Container(
              color: Colors.transparent,
            ),
          ),
        ),
        // 氣泡內容
        Positioned(
          left: currentPosition.dx,
          top: currentPosition.dy,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              key: _bubbleKey,
              width: bubbleWidth,
              constraints: const BoxConstraints(maxHeight: maxBubbleHeight),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).dividerColor,
                  width: 1,
                ),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: widget.posts.length,
                itemBuilder: (context, index) {
                  final post = widget.posts[index];
                  return _buildPostItem(context, post);
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPostItem(BuildContext context, Post post) {
    // 查詢 KOL 信息
    final kolAsync = ref.watch(kolProvider(post.kolId));

    return kolAsync.when(
      data: (kol) => _buildPostItemContent(context, widget.onDismiss, post, kol),
      loading: () => const ListTile(
        title: Text('載入中...'),
        dense: true,
      ),
      error: (_, __) => _buildPostItemContent(context, widget.onDismiss, post, null),
    );
  }

  Widget _buildPostItemContent(BuildContext context, VoidCallback onDismiss, Post post, KOL? kol) {
    final kolName = kol?.name ?? '未知作者';
    final dateStr = DateFormat('MM/dd').format(post.postedAt);

    return ListTile(
      dense: true,
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
      trailing: _buildSentimentChip(post.sentiment),
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

  Widget _buildSentimentChip(String sentiment) {
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

