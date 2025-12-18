import 'package:flutter/material.dart';

/// 脈衝邊框卡片 Widget
/// 用於突出顯示需要用戶注意的必填欄位
class PulsingBorderCard extends StatefulWidget {
  final Widget child;
  final bool showPulse; // 是否顯示脈衝效果
  final List<Color> normalGradientColors; // 正常狀態的漸層色
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;

  const PulsingBorderCard({
    super.key,
    required this.child,
    required this.showPulse,
    required this.normalGradientColors,
    this.padding = const EdgeInsets.all(12),
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
  });

  @override
  State<PulsingBorderCard> createState() => _PulsingBorderCardState();
}

class _PulsingBorderCardState extends State<PulsingBorderCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (widget.showPulse) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(PulsingBorderCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showPulse != oldWidget.showPulse) {
      if (widget.showPulse) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
        _controller.reset();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.showPulse) {
      // 正常狀態：無脈衝效果
      return Container(
        padding: widget.padding,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: widget.borderRadius,
          border: Border.all(
            color: widget.normalGradientColors[0].withOpacity(0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: widget.normalGradientColors[0].withOpacity(0.08),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: widget.child,
      );
    }

    // 脈衝狀態：紅色脈衝邊框
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          padding: widget.padding,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: widget.borderRadius,
            border: Border.all(
              color: Colors.red.withOpacity(_animation.value),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(_animation.value * 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: widget.child,
        );
      },
    );
  }
}

