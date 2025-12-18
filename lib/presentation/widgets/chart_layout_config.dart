/// 圖表布局配置
/// 定義 K 線圖的各種布局參數和常量
class ChartLayoutConfig {
  // 區域高度比例
  static const double candleAreaRatio = 0.70; // K 線區域佔 70%
  static const double volumeAreaRatio = 0.20; // 交易量區域佔 20%
  static const double paddingRatio = 0.05; // 上下各 5% 留白

  // K 線寬度和間距
  static const double candleWidthRatio = 0.7; // Candle 寬度佔 70%
  static const double candleSpacingRatio = 0.3; // 間距佔 30%

  // 邊距
  static const double leftPadding = 50.0; // 左側留給價格軸
  static const double rightPadding = 10.0; // 右側留白
  static const double topPadding = 20.0; // 頂部留白
  static const double bottomPadding = 30.0; // 底部留給日期軸

  // 字體大小
  static const double axisFontSize = 11.0;
  static const double priceAxisFontSize = 10.0;

  // 網格線
  static const int horizontalGridLines = 5; // 水平網格線數量
  static const double gridLineWidth = 0.5;

  // 影線寬度
  static const double wickWidth = 1.0;

  // 縮放限制
  static const int minVisibleCandles = 5; // 最少顯示 5 根 K 線
  static const int maxVisibleCandles = 365; // 最多顯示 365 根 K 線
  static const int defaultVisibleCandles = 60; // 預設顯示 60 根 K 線

  // Marker 設置
  static const double markerSize = 20.0;
  static const double markerOffsetFromCandle = 25.0;
}
