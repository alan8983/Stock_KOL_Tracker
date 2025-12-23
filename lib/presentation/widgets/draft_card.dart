import 'package:flutter/material.dart';
import '../../data/database/database.dart';
import '../../core/utils/datetime_formatter.dart';

/// 草稿卡片元件（Email Inbox 樣式）
/// 支援向左滑動顯示刪除按鈕，向右滑動回歸原位
class DraftCard extends StatefulWidget {
  final Post draft;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const DraftCard({
    super.key,
    required this.draft,
    this.onTap,
    this.onDelete,
  });

  @override
  State<DraftCard> createState() => _DraftCardState();
}

class _DraftCardState extends State<DraftCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  
  double _dragExtent = 0.0;
  bool _isDeleteRevealed = false;
  
  static const double _deleteButtonWidth = 80.0;
  static const double _swipeThreshold = 60.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragExtent += details.primaryDelta ?? 0;
      // 限制向左滑動的範圍，不能超過刪除按鈕寬度
      _dragExtent = _dragExtent.clamp(-_deleteButtonWidth, 0.0);
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    // 如果滑動距離超過閾值，顯示刪除按鈕
    if (_dragExtent < -_swipeThreshold) {
      _animateTo(-_deleteButtonWidth);
      _isDeleteRevealed = true;
    } else {
      // 否則回歸原位
      _animateTo(0.0);
      _isDeleteRevealed = false;
    }
  }

  void _animateTo(double target) {
    _slideAnimation = Tween<Offset>(
      begin: Offset(_dragExtent, 0),
      end: Offset(target, 0),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward(from: 0).then((_) {
      setState(() {
        _dragExtent = target;
      });
    });
  }

  void _handleTap() {
    if (_isDeleteRevealed) {
      // 如果刪除按鈕已顯示，點擊卡片恢復原位
      _animateTo(0.0);
      _isDeleteRevealed = false;
    } else {
      widget.onTap?.call();
    }
  }

  void _handleDeleteTap() {
    widget.onDelete?.call();
  }

  /// 取得預覽文字（2-3行）
  String _getContentPreview() {
    final content = widget.draft.content;
    // 限制最多顯示 150 個字元
    if (content.length > 150) {
      return '${content.substring(0, 150)}...';
    }
    return content;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: Stack(
        children: [
          // 紅色刪除按鈕背景（右側）
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: _deleteButtonWidth,
            child: GestureDetector(
              onTap: _handleDeleteTap,
              child: Container(
                color: const Color(0xFFD32F2F), // 深紅色
                child: const Center(
                  child: Icon(
                    Icons.delete,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ),
          ),
          // 可滑動的卡片內容
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final offset = _controller.isAnimating
                  ? _slideAnimation.value.dx
                  : _dragExtent;
              return Transform.translate(
                offset: Offset(offset, 0),
                child: child,
              );
            },
            child: GestureDetector(
              onHorizontalDragUpdate: _handleDragUpdate,
              onHorizontalDragEnd: _handleDragEnd,
              onTap: _handleTap,
              child: Container(
                color: theme.scaffoldBackgroundColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 左側：草稿內容（2-3行）
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _getContentPreview(),
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.grey.shade800,
                              height: 1.4,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // 右側：編輯時間
                    Text(
                      DateTimeFormatter.formatRelative(widget.draft.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
