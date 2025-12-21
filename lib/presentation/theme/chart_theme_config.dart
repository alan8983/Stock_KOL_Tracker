import 'package:flutter/material.dart';

/// 圖表顏色配置
/// 支持動態切換配色方案，為後續 UI 調整功能預留擴展空間
class ChartThemeConfig {
  // 情緒標記顏色（可配置）
  final Color bullishColor;
  final Color neutralColor;
  final Color bearishColor;

  // K線顏色（漲跌）
  final Color increasingColor;
  final Color decreasingColor;

  // 圖表背景和網格
  final Color backgroundColor;
  final Color gridLineColor;
  final Color textColor;

  // 交易量柱狀圖顏色
  final Color volumeIncreasingColor;
  final Color volumeDecreasingColor;

  const ChartThemeConfig({
    required this.bullishColor,
    required this.neutralColor,
    required this.bearishColor,
    required this.increasingColor,
    required this.decreasingColor,
    required this.backgroundColor,
    required this.gridLineColor,
    required this.textColor,
    required this.volumeIncreasingColor,
    required this.volumeDecreasingColor,
  });

  /// 預設配色方案 - 綠漲紅跌（歐美風格）
  static const ChartThemeConfig defaultTheme = ChartThemeConfig(
    // 情緒標記顏色
    bullishColor: Color(0xFF4CAF50), // 綠色 - 看多
    neutralColor: Color(0xFF9E9E9E), // 灰色 - 中性
    bearishColor: Color(0xFFF44336), // 紅色 - 看空

    // K線顏色
    increasingColor: Color(0xFF26A69A), // 青綠色 - 上漲
    decreasingColor: Color(0xFFEF5350), // 紅色 - 下跌

    // 圖表背景和網格
    backgroundColor: Color(0xFFFFFFFF), // 白色背景
    gridLineColor: Color(0xFFE0E0E0), // 淺灰色網格線
    textColor: Color(0xFF424242), // 深灰色文字

    // 交易量顏色
    volumeIncreasingColor: Color(0xFF26A69A), // 與漲相同
    volumeDecreasingColor: Color(0xFFEF5350), // 與跌相同
  );

  /// 暗色配色方案
  static const ChartThemeConfig darkTheme = ChartThemeConfig(
    // 情緒標記顏色
    bullishColor: Color(0xFF66BB6A), // 亮綠色 - 看多
    neutralColor: Color(0xFFBDBDBD), // 亮灰色 - 中性
    bearishColor: Color(0xFFEF5350), // 亮紅色 - 看空

    // K線顏色
    increasingColor: Color(0xFF26A69A), // 青綠色 - 上漲
    decreasingColor: Color(0xFFFF5252), // 亮紅色 - 下跌

    // 圖表背景和網格
    backgroundColor: Color(0xFF212121), // 深灰色背景
    gridLineColor: Color(0xFF424242), // 灰色網格線
    textColor: Color(0xFFE0E0E0), // 淺灰色文字

    // 交易量顏色
    volumeIncreasingColor: Color(0xFF26A69A),
    volumeDecreasingColor: Color(0xFFFF5252),
  );

  /// 亞洲配色方案 - 紅漲綠跌（台灣/中國風格）
  static const ChartThemeConfig asianTheme = ChartThemeConfig(
    // 情緒標記顏色（調換紅綠）
    bullishColor: Color(0xFFF44336), // 紅色 - 看多
    neutralColor: Color(0xFF9E9E9E), // 灰色 - 中性
    bearishColor: Color(0xFF4CAF50), // 綠色 - 看空

    // K線顏色
    increasingColor: Color(0xFFEF5350), // 紅色 - 上漲
    decreasingColor: Color(0xFF26A69A), // 綠色 - 下跌

    // 圖表背景和網格
    backgroundColor: Color(0xFFFFFFFF),
    gridLineColor: Color(0xFFE0E0E0),
    textColor: Color(0xFF424242),

    // 交易量顏色
    volumeIncreasingColor: Color(0xFFEF5350),
    volumeDecreasingColor: Color(0xFF26A69A),
  );

  /// 複製並修改部分屬性
  ChartThemeConfig copyWith({
    Color? bullishColor,
    Color? neutralColor,
    Color? bearishColor,
    Color? increasingColor,
    Color? decreasingColor,
    Color? backgroundColor,
    Color? gridLineColor,
    Color? textColor,
    Color? volumeIncreasingColor,
    Color? volumeDecreasingColor,
  }) {
    return ChartThemeConfig(
      bullishColor: bullishColor ?? this.bullishColor,
      neutralColor: neutralColor ?? this.neutralColor,
      bearishColor: bearishColor ?? this.bearishColor,
      increasingColor: increasingColor ?? this.increasingColor,
      decreasingColor: decreasingColor ?? this.decreasingColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      gridLineColor: gridLineColor ?? this.gridLineColor,
      textColor: textColor ?? this.textColor,
      volumeIncreasingColor: volumeIncreasingColor ?? this.volumeIncreasingColor,
      volumeDecreasingColor: volumeDecreasingColor ?? this.volumeDecreasingColor,
    );
  }

  /// 根據情緒類型獲取對應顏色
  Color getColorBySentiment(String sentiment) {
    switch (sentiment) {
      case 'Bullish':
        return bullishColor;
      case 'Bearish':
        return bearishColor;
      default:
        return neutralColor;
    }
  }

  /// 獲取情緒標籤
  static String getSentimentLabel(String sentiment) {
    switch (sentiment) {
      case 'Bullish':
        return 'L'; // Long
      case 'Bearish':
        return 'S'; // Short
      default:
        return 'N'; // Neutral
    }
  }

  /// 轉換為 flutter_chen_kchart 主題配置 Map
  /// 注意：實際的屬性名稱需要根據 flutter_chen_kchart 的實際 API 進行調整
  Map<String, dynamic> toKChartTheme() {
    return {
      // K線顏色
      'increasingColor': increasingColor,
      'decreasingColor': decreasingColor,
      // 背景和網格
      'backgroundColor': backgroundColor,
      'gridLineColor': gridLineColor,
      'textColor': textColor,
      // 交易量顏色（如果套件支持）
      'volumeIncreasingColor': volumeIncreasingColor,
      'volumeDecreasingColor': volumeDecreasingColor,
    };
  }

  /// 創建適合 flutter_chen_kchart 的顏色配置
  /// 返回一個 Map，包含所有顏色配置
  Map<String, Color> getKChartColorConfig() {
    return {
      'increasing': increasingColor,
      'decreasing': decreasingColor,
      'background': backgroundColor,
      'grid': gridLineColor,
      'text': textColor,
      'volumeUp': volumeIncreasingColor,
      'volumeDown': volumeDecreasingColor,
    };
  }
}
