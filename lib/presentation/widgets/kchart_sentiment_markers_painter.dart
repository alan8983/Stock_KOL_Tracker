import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'kchart_state_adapter.dart';
import '../theme/chart_theme_config.dart';
import 'chart_layout_config.dart';

/// 情緒標記繪製器（適配 flutter_chen_kchart）
/// 負責在正確位置繪製情緒標記（書籤形狀）
class KChartSentimentMarkersPainter extends CustomPainter {
  final KChartStateAdapter stateAdapter;
  final ChartThemeConfig theme;

  KChartSentimentMarkersPainter({
    required this.stateAdapter,
    required this.theme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 如果 Marker 不可見（正在交互中），直接返回
    if (!stateAdapter.markersVisible) return;
    
    if (stateAdapter.candles.isEmpty || stateAdapter.posts.isEmpty) return;

    for (final post in stateAdapter.posts) {
      // 1. 找到對應的 K 線索引（順延邏輯）
      final index = stateAdapter.findCandleIndexByDate(post.postedAt);

      if (index == null) continue;

      // 2. 檢查是否在可見範圍內
      if (index < stateAdapter.startIndex || index > stateAdapter.endIndex) {
        continue; // 超出範圍，跳過繪製
      }

      // 3. 計算 Marker 的精確位置
      final candle = stateAdapter.candles[index];
      final x = stateAdapter.indexToX(index);

      // Y 座標：看空在上方，看多/中性在下方
      final y = post.sentiment == 'Bearish'
          ? stateAdapter.priceToY(candle.high) -
              ChartLayoutConfig.markerOffsetFromCandle
          : stateAdapter.priceToY(candle.low) +
              ChartLayoutConfig.markerOffsetFromCandle;

      // 4. 繪製虛線輔助線（先繪製，讓 Marker 在上層）
      _drawDashedGuideLine(canvas, Offset(x, y), post.sentiment, index);

      // 5. 繪製書籤標記
      _drawBookmarkMarker(canvas, Offset(x, y), post.sentiment);
    }
  }

  /// 繪製書籤標記（正方形 + 等腰直角三角形）
  void _drawBookmarkMarker(Canvas canvas, Offset center, String sentiment) {
    final color = theme.getColorBySentiment(sentiment);
    final label = ChartThemeConfig.getSentimentLabel(sentiment);
    final size = ChartLayoutConfig.markerSize;

    // 判斷三角形朝向：Bearish 朝下，其他朝上
    final pointsDown = sentiment == 'Bearish';

    // 繪製書籤形狀
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = color.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final path = _createBookmarkPath(center, size, pointsDown);
    canvas.drawPath(path, paint);
    canvas.drawPath(path, borderPaint);

    // 繪製文字標籤（在正方形中央）
    final labelOffset = pointsDown
        ? Offset(center.dx, center.dy - size * 0.15) // Bearish: 正方形在上方
        : Offset(center.dx, center.dy + size * 0.15); // Bullish/Neutral: 正方形在下方
    _drawLabel(canvas, labelOffset, label, size);
  }

  /// 創建書籤路徑（正方形 + 等腰直角三角形）
  Path _createBookmarkPath(Offset center, double size, bool pointsDown) {
    final path = Path();
    final squareSize = size * 0.6;
    final halfSquare = squareSize / 2;
    final triangleHeight = squareSize / 2;

    if (pointsDown) {
      // Bearish: 正方形在上，三角形朝下
      // 正方形
      final squareTop = center.dy - size / 2;
      path.moveTo(center.dx - halfSquare, squareTop);
      path.lineTo(center.dx + halfSquare, squareTop);
      path.lineTo(center.dx + halfSquare, squareTop + squareSize);

      // 等腰直角三角形（斜邊接正方形底邊）
      path.lineTo(center.dx, squareTop + squareSize + triangleHeight); // 直角頂點
      path.lineTo(center.dx - halfSquare, squareTop + squareSize);
      path.close();
    } else {
      // Bullish/Neutral: 正方形在下，三角形朝上
      // 等腰直角三角形
      final squareBottom = center.dy + size / 2;
      path.moveTo(center.dx, squareBottom - squareSize - triangleHeight); // 直角頂點
      path.lineTo(center.dx + halfSquare, squareBottom - squareSize);

      // 正方形
      path.lineTo(center.dx + halfSquare, squareBottom);
      path.lineTo(center.dx - halfSquare, squareBottom);
      path.lineTo(center.dx - halfSquare, squareBottom - squareSize);
      path.close();
    }

    return path;
  }

  /// 繪製中央文字標籤
  void _drawLabel(Canvas canvas, Offset center, String label, double size) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.5,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();

    // 計算文字居中位置
    final textOffset = Offset(
      center.dx - textPainter.width / 2,
      center.dy - textPainter.height / 2,
    );

    textPainter.paint(canvas, textOffset);
  }

  /// 繪製虛線輔助線（從 Marker 的三角形直角頂點到 K 線）
  void _drawDashedGuideLine(
    Canvas canvas,
    Offset markerCenter,
    String sentiment,
    int candleIndex,
  ) {
    final color = theme.getColorBySentiment(sentiment).withOpacity(0.6);
    final size = ChartLayoutConfig.markerSize;
    final pointsDown = sentiment == 'Bearish';

    // 計算虛線起點：三角形的直角頂點
    final triangleHeight = size * 0.6 / 2;
    final startY = pointsDown
        ? markerCenter.dy + size / 2 - triangleHeight // Bearish: 三角形底部（直角頂點）
        : markerCenter.dy - size / 2 + triangleHeight; // Bullish: 三角形頂部（直角頂點）

    final startPoint = Offset(markerCenter.dx, startY);

    // 計算虛線終點：K 線的 high 或 low
    if (candleIndex < 0 || candleIndex >= stateAdapter.candles.length) return;
    final candle = stateAdapter.candles[candleIndex];
    final endY = pointsDown
        ? stateAdapter.priceToY(candle.high) // Bearish: 連接到 high
        : stateAdapter.priceToY(candle.low); // Bullish: 連接到 low

    final endPoint = Offset(markerCenter.dx, endY);

    // 繪製虛線
    _drawDashedLine(canvas, startPoint, endPoint, color);
  }

  /// 繪製虛線
  void _drawDashedLine(
    Canvas canvas,
    Offset start,
    Offset end,
    Color color,
  ) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    const dashWidth = 3.0;
    const dashSpace = 3.0;

    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final distance = math.sqrt(dx * dx + dy * dy);
    
    if (distance == 0) return;

    final unitX = dx / distance;
    final unitY = dy / distance;

    double currentDistance = 0;
    bool isDash = true;

    while (currentDistance < distance) {
      final segmentLength = isDash ? dashWidth : dashSpace;
      final nextDistance = math.min(currentDistance + segmentLength, distance);

      if (isDash) {
        final p1 = Offset(
          start.dx + unitX * currentDistance,
          start.dy + unitY * currentDistance,
        );
        final p2 = Offset(
          start.dx + unitX * nextDistance,
          start.dy + unitY * nextDistance,
        );
        canvas.drawLine(p1, p2, paint);
      }

      currentDistance = nextDistance;
      isDash = !isDash;
    }
  }

  @override
  bool shouldRepaint(covariant KChartSentimentMarkersPainter oldDelegate) {
    return oldDelegate.stateAdapter != stateAdapter ||
        oldDelegate.theme != theme;
  }
}

