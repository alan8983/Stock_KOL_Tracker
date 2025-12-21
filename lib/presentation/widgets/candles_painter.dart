import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;
import 'fl_chart_controller.dart';
import '../theme/chart_theme_config.dart';
import 'chart_layout_config.dart';

/// K 線繪製器
/// 負責繪製 K 線、網格、座標軸
class CandlesPainter extends CustomPainter {
  final FlChartController controller;
  final ChartThemeConfig theme;

  CandlesPainter({
    required this.controller,
    required this.theme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (controller.prices.isEmpty) return;

    // 1. 繪製背景
    _drawBackground(canvas, size);

    // 2. 繪製網格
    _drawGrid(canvas, size);

    // 3. 繪製 K 線
    _drawCandles(canvas, size);

    // 4. 繪製價格軸
    _drawPriceAxis(canvas, size);

    // 5. 繪製日期軸
    _drawDateAxis(canvas, size);
  }

  /// 繪製背景
  void _drawBackground(Canvas canvas, Size size) {
    final paint = Paint()..color = theme.backgroundColor;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  /// 繪製網格線
  void _drawGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = theme.gridLineColor
      ..strokeWidth = ChartLayoutConfig.gridLineWidth;

    final candleTop = ChartLayoutConfig.topPadding;
    final candleHeight = size.height * ChartLayoutConfig.candleAreaRatio;
    final left = ChartLayoutConfig.leftPadding;
    final right = size.width - ChartLayoutConfig.rightPadding;

    // 繪製水平網格線
    for (int i = 0; i <= ChartLayoutConfig.horizontalGridLines; i++) {
      final y = candleTop + (candleHeight / ChartLayoutConfig.horizontalGridLines) * i;
      canvas.drawLine(Offset(left, y), Offset(right, y), paint);
    }
  }

  /// 繪製 K 線
  void _drawCandles(Canvas canvas, Size size) {
    for (int i = controller.startIndex;
        i <= controller.endIndex && i < controller.prices.length;
        i++) {
      final price = controller.prices[i];
      final x = controller.indexToX(i);
      final candleWidth = controller.candleWidth;

      // 計算各部分的 Y 座標
      final openY = controller.priceToY(price.open);
      final closeY = controller.priceToY(price.close);
      final highY = controller.priceToY(price.high);
      final lowY = controller.priceToY(price.low);

      final isIncreasing = price.close >= price.open;
      final color =
          isIncreasing ? theme.increasingColor : theme.decreasingColor;

      // 繪製影線（上影線和下影線）
      _drawWick(canvas, x, highY, lowY, color);

      // 繪製實體
      _drawBody(canvas, x, openY, closeY, candleWidth, color, isIncreasing);
    }
  }

  /// 繪製影線
  void _drawWick(Canvas canvas, double x, double highY, double lowY, Color color) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = ChartLayoutConfig.wickWidth;

    canvas.drawLine(Offset(x, highY), Offset(x, lowY), paint);
  }

  /// 繪製 K 線實體
  void _drawBody(Canvas canvas, double x, double openY, double closeY,
      double candleWidth, Color color, bool isIncreasing) {
    final paint = Paint()..color = color;

    final top = openY < closeY ? openY : closeY;
    final height = (openY - closeY).abs();

    // 確保實體至少有 1 像素高（當開盤價 = 收盤價時）
    final actualHeight = height < 1.0 ? 1.0 : height;

    final rect = Rect.fromLTWH(
      x - candleWidth / 2,
      top,
      candleWidth,
      actualHeight,
    );

    if (isIncreasing) {
      // 上漲：空心（只畫邊框）
      canvas.drawRect(rect, paint..style = PaintingStyle.stroke..strokeWidth = 1.5);
    } else {
      // 下跌：實心
      canvas.drawRect(rect, paint..style = PaintingStyle.fill);
    }
  }

  /// 繪製價格軸
  void _drawPriceAxis(Canvas canvas, Size size) {
    if (controller.minPrice == controller.maxPrice) return;

    final candleTop = ChartLayoutConfig.topPadding;
    final candleHeight = size.height * ChartLayoutConfig.candleAreaRatio;
    final priceCount = ChartLayoutConfig.horizontalGridLines + 1;

    for (int i = 0; i < priceCount; i++) {
      final ratio = i / ChartLayoutConfig.horizontalGridLines;
      final price = controller.maxPrice - (controller.maxPrice - controller.minPrice) * ratio;
      final y = candleTop + candleHeight * ratio;

      // 格式化價格（最多保留3位小數，自動去掉尾部0）
      final priceText = _formatPrice(price);

      _drawText(
        canvas,
        priceText,
        Offset(5, y),
        ChartLayoutConfig.priceAxisFontSize,
        theme.textColor,
        TextAlign.left,
      );
    }
  }

  /// 格式化價格，最多顯示3位小數，自動去掉尾部0
  String _formatPrice(double price) {
    // 先四捨五入到3位小數
    final rounded = (price * 1000).round() / 1000.0;
    
    // 轉換為字符串，最多3位小數
    final formatted = rounded.toStringAsFixed(3);
    
    // 去掉尾部多餘的0和小數點
    if (formatted.contains('.')) {
      return formatted.replaceAll(RegExp(r'0*$'), '').replaceAll(RegExp(r'\.$'), '');
    }
    
    return formatted;
  }

  /// 繪製日期軸（mmm-dd 格式）
  void _drawDateAxis(Canvas canvas, Size size) {
    if (controller.prices.isEmpty) return;

    final dateFormat = DateFormat('MMM-dd', 'en_US');
    final labelInterval = _calculateLabelInterval();
    final bottom = size.height - 10;

    for (int i = controller.startIndex;
        i <= controller.endIndex && i < controller.prices.length;
        i += labelInterval) {
      final date = controller.prices[i].date;
      final x = controller.indexToX(i);
      final label = dateFormat.format(date);

      _drawText(
        canvas,
        label,
        Offset(x, bottom),
        ChartLayoutConfig.axisFontSize,
        theme.textColor,
        TextAlign.center,
      );
    }
  }

  /// 計算日期標籤間隔（避免重疊）
  int _calculateLabelInterval() {
    final candleWidth = controller.candleWidth;
    const labelWidth = 50.0; // 估計標籤寬度（mmm-dd 格式）

    if (candleWidth == 0) return 1;

    final interval = (labelWidth / candleWidth).ceil();
    return interval.clamp(1, controller.visibleCount ~/ 3);
  }

  /// 繪製文字
  void _drawText(
    Canvas canvas,
    String text,
    Offset position,
    double fontSize,
    Color color,
    TextAlign align,
  ) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontFamily: 'monospace',
        ),
      ),
      textDirection: ui.TextDirection.ltr,
      textAlign: align,
    );

    textPainter.layout();

    // 根據對齊方式調整位置
    double dx = position.dx;
    if (align == TextAlign.center) {
      dx -= textPainter.width / 2;
    } else if (align == TextAlign.right) {
      dx -= textPainter.width;
    }

    final offset = Offset(dx, position.dy - textPainter.height / 2);
    textPainter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant CandlesPainter oldDelegate) {
    return oldDelegate.controller != controller ||
        oldDelegate.theme != theme;
  }
}
