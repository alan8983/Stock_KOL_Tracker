import 'package:flutter/material.dart';
import '../../data/database/database.dart';
import '../../core/utils/datetime_formatter.dart';

/// 草稿卡片元件
/// 支援長按滑動刪除和 Dismissible 滑動刪除
class DraftCard extends StatefulWidget {
  final Post draft;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final bool isSelected;
  final ValueChanged<bool>? onSelectionChanged;

  const DraftCard({
    super.key,
    required this.draft,
    this.onTap,
    this.onDelete,
    this.isSelected = false,
    this.onSelectionChanged,
  });

  @override
  State<DraftCard> createState() => _DraftCardState();
}

class _DraftCardState extends State<DraftCard> {
  bool _isSlidOut = false;

  void _handleLongPress() {
    // 在多選模式下禁用長按滑動功能
    if (widget.onSelectionChanged != null) {
      return;
    }
    
    setState(() {
      _isSlidOut = true;
    });
  }

  void _handleTap() {
    if (_isSlidOut) {
      // 如果已滑出，恢復原狀
      setState(() {
        _isSlidOut = false;
      });
    } else {
      // 如果未滑出，執行原本的 onTap 行為
      widget.onTap?.call();
    }
  }

  void _handleDeleteTap() {
    setState(() {
      _isSlidOut = false;
    });
    widget.onDelete?.call();
  }

  @override
  Widget build(BuildContext context) {
    final contentPreview = widget.draft.content.length > 100
        ? '${widget.draft.content.substring(0, 100)}...'
        : widget.draft.content;

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final slideDistance = screenWidth * 0.25; // 25% 寬度
        final deleteButtonWidth = slideDistance;

        return Dismissible(
          key: Key('draft_${widget.draft.id}'),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            color: Colors.red,
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          onDismissed: (_) {
            widget.onDelete?.call();
          },
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: IntrinsicHeight(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // 刪除按鈕（右側，淡紅色背景）
                  Positioned(
                    right: 16, // 與 Card 的 margin 對齊
                    top: 0,
                    bottom: 0,
                    width: deleteButtonWidth,
                    child: GestureDetector(
                      onTap: _handleDeleteTap,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFCDD2), // 淡紅色
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.delete_outline,
                                color: Colors.red.shade700,
                                size: 28,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '刪除',
                                style: TextStyle(
                                  color: Colors.red.shade700,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // 卡片內容（可滑動）
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                    left: _isSlidOut ? -slideDistance : 0,
                    right: 0,
                    child: GestureDetector(
                      onLongPress: _handleLongPress,
                      child: Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        child: InkWell(
                          onTap: _handleTap,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                if (widget.onSelectionChanged != null)
                                  Checkbox(
                                    value: widget.isSelected,
                                    onChanged: (value) =>
                                        widget.onSelectionChanged?.call(value ?? false),
                                  ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Row(
                                        children: [
                                          Chip(
                                            label: Text(
                                              widget.draft.sentiment,
                                              style: const TextStyle(fontSize: 12),
                                            ),
                                            backgroundColor: _getSentimentColor(widget.draft.sentiment)
                                                .withOpacity(0.2),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            widget.draft.stockTicker,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        contentPreview,
                                        style: const TextStyle(fontSize: 14),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        DateTimeFormatter.formatRelative(widget.draft.postedAt),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getSentimentColor(String sentiment) {
    switch (sentiment) {
      case 'Bullish':
        return Colors.green;
      case 'Bearish':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
