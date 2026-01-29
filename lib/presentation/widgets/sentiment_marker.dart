import 'package:flutter/material.dart';
import '../theme/chart_theme_config.dart';

/// 自定義情緒標記組件
/// 使用 CustomPaint 繪製方形，並在中央顯示文字標籤（L/N/S）
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
      painter: _SquarePainter(
        color: color,
        label: label,
      ),
    );
  }
}

/// 方形繪製器
class _SquarePainter extends CustomPainter {
  final Color color;
  final String label;

  _SquarePainter({
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

    // 繪製方形（稍微縮小以留邊距）
    const padding = 2.0;
    final rect = Rect.fromLTWH(
      padding,
      padding,
      size.width - padding * 2,
      size.height - padding * 2,
    );
    
    // 繪製圓角矩形（圓角半徑為2，看起來更現代）
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(2.0));
    canvas.drawRRect(rrect, paint);
    canvas.drawRRect(rrect, borderPaint);

    // 繪製文字標籤
    _drawLabel(canvas, size);
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
  bool shouldRepaint(covariant _SquarePainter oldDelegate) {
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
