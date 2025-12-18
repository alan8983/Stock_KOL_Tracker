import 'package:flutter/material.dart';
import 'fl_chart_controller.dart';
import '../theme/chart_theme_config.dart';
import 'chart_layout_config.dart';

/// 交易量繪製器
/// 負責繪製交易量柱狀圖
class VolumePainter extends CustomPainter {
  final FlChartController controller;
  final ChartThemeConfig theme;

  VolumePainter({
    required this.controller,
    required this.theme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (controller.prices.isEmpty || controller.maxVolume == 0) return;

    // 計算交易量區域的位置和高度
    final volumeTop = ChartLayoutConfig.topPadding +
        size.height * ChartLayoutConfig.candleAreaRatio;
    final volumeHeight = size.height * ChartLayoutConfig.volumeAreaRatio;

    for (int i = controller.startIndex;
        i <= controller.endIndex && i < controller.prices.length;
        i++) {
      final price = controller.prices[i];
      final x = controller.indexToX(i);
      final barWidth = controller.candleWidth;

      // 計算柱子高度（相對於最大交易量）
      final heightRatio = price.volume / controller.maxVolume;
      final barHeight = volumeHeight * heightRatio * 0.8; // 最高 80%

      // 根據漲跌選擇顏色
      final isIncreasing = price.close >= price.open;
      final color = isIncreasing
          ? theme.volumeIncreasingColor.withOpacity(0.5)
          : theme.volumeDecreasingColor.withOpacity(0.5);

      // 繪製柱子
      final rect = Rect.fromLTWH(
        x - barWidth / 2,
        volumeTop + volumeHeight - barHeight,
        barWidth,
        barHeight,
      );

      canvas.drawRect(rect, Paint()..color = color);
    }

    // 繪製交易量區域分隔線
    _drawSeparatorLine(canvas, size, volumeTop);
  }

  /// 繪製分隔線
  void _drawSeparatorLine(Canvas canvas, Size size, double y) {
    final paint = Paint()
      ..color = theme.gridLineColor
      ..strokeWidth = 1.0;

    final left = ChartLayoutConfig.leftPadding;
    final right = size.width - ChartLayoutConfig.rightPadding;

    canvas.drawLine(Offset(left, y), Offset(right, y), paint);
  }

  @override
  bool shouldRepaint(covariant VolumePainter oldDelegate) {
    return oldDelegate.controller != controller ||
        oldDelegate.theme != theme;
  }
}
