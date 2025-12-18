import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../theme/chart_theme_config.dart';

/// 自定義情緒標記組件
/// 使用 CustomPaint 繪製五邊形，並在中央顯示文字標籤（L/N/S）
class SentimentMarker extends StatelessWidget {
  final String sentiment;
  final Color color;
  final String label;
  final double size;

  const SentimentMarker({
    super.key,
    required this.sentiment,
    required this.color,
    required this.label,
    this.size = 24.0,
  });

  /// 從情緒類型創建標記（使用預設主題顏色）
  factory SentimentMarker.fromSentiment({
    required String sentiment,
    ChartThemeConfig theme = ChartThemeConfig.defaultTheme,
    double size = 24.0,
  }) {
    return SentimentMarker(
      sentiment: sentiment,
      color: theme.getColorBySentiment(sentiment),
      label: ChartThemeConfig.getSentimentLabel(sentiment),
      size: size,
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _PentagonPainter(
        color: color,
        label: label,
      ),
    );
  }
}

/// 五邊形繪製器
class _PentagonPainter extends CustomPainter {
  final Color color;
  final String label;

  _PentagonPainter({
    required this.color,
    required this.label,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = color.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // 繪製五邊形
    final path = _createPentagonPath(size);
    canvas.drawPath(path, paint);
    canvas.drawPath(path, borderPaint);

    // 繪製文字標籤
    _drawLabel(canvas, size);
  }

  /// 創建五邊形路徑（正五邊形，頂點朝上）
  Path _createPentagonPath(Size size) {
    final path = Path();
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final radius = size.width / 2 * 0.9; // 稍微縮小以留邊距

    // 五邊形的5個頂點
    // 從正上方開始（-90度），順時針繪製
    final angleOffset = -math.pi / 2; // 從頂部開始
    final angleStep = 2 * math.pi / 5; // 每個角72度

    for (int i = 0; i < 5; i++) {
      final angle = angleOffset + angleStep * i;
      final x = centerX + radius * math.cos(angle);
      final y = centerY + radius * math.sin(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    path.close();
    return path;
  }

  /// 繪製中央文字標籤
  void _drawLabel(Canvas canvas, Size size) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: Colors.white,
          fontSize: size.width * 0.5, // 標籤大小為圖示的一半
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();

    // 計算文字居中位置
    final textX = (size.width - textPainter.width) / 2;
    final textY = (size.height - textPainter.height) / 2;

    textPainter.paint(canvas, Offset(textX, textY));
  }

  @override
  bool shouldRepaint(covariant _PentagonPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.label != label;
  }
}

/// 帶有陰影效果的情緒標記
class SentimentMarkerWithShadow extends StatelessWidget {
  final String sentiment;
  final ChartThemeConfig theme;
  final double size;

  const SentimentMarkerWithShadow({
    super.key,
    required this.sentiment,
    this.theme = ChartThemeConfig.defaultTheme,
    this.size = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SentimentMarker.fromSentiment(
        sentiment: sentiment,
        theme: theme,
        size: size,
      ),
    );
  }
}
