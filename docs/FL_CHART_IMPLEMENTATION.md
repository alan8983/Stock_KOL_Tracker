# K 線圖 - fl_chart 實施總結

## 實施完成日期
2025-12-15

## 問題回顧

原本使用 candlesticks 套件存在三個無法解決的問題：
1. **Marker 定位錯誤** - 五角形標記顯示在線圖右側座標軸上，而非對應的 K 線上
2. **縮放/平移無同步** - Marker 無法跟隨 K 線圖的縮放和平移動作
3. **日期格式錯誤** - 橫軸顯示 hh:mm 格式，無法改為 mmm-dd (如 Dec-15)

**根本原因**：candlesticks 2.1.0 套件不提供訪問內部狀態的 API，無法獲取縮放/平移狀態和座標映射信息。

## 解決方案

完全移除 candlesticks 套件，使用 Flutter 的 CustomPainter 自定義實現完整的 K 線圖。

## 實施架構

```
StockChartWidget (主組件)
  └─> FlChartController (狀態管理)
       ├─> CandlesPainter (K 線繪製器)
       ├─> VolumePainter (交易量繪製器)
       └─> SentimentMarkersPainter (情緒標記繪製器)
```

## 新增文件

### 1. chart_layout_config.dart
**位置**: `lib/presentation/widgets/chart_layout_config.dart`

**職責**: 定義圖表的所有布局參數和常量

**核心配置**:
- K 線區域佔 70%
- 交易量區域佔 20%
- 上下各 5% 留白
- 左側留 50px 給價格軸
- 底部留 30px 給日期軸
- 預設顯示 60 根 K 線
- 縮放範圍：20-200 根 K 線

### 2. fl_chart_controller.dart
**位置**: `lib/presentation/widgets/fl_chart_controller.dart`

**職責**: 管理圖表的完整狀態和座標轉換

**核心功能**:
- 管理可見範圍（startIndex, endIndex, visibleCount）
- 處理縮放和平移手勢
- 提供座標轉換方法：
  - `priceToY(double price)` - 價格 → Y 座標
  - `indexToX(int index)` - 索引 → X 座標
  - `xToIndex(double x)` - X 座標 → 索引
- 計算可見範圍內的價格範圍和交易量範圍
- 通過 ChangeNotifier 觸發所有 Painter 重繪

### 3. candles_painter.dart
**位置**: `lib/presentation/widgets/candles_painter.dart`

**職責**: 繪製 K 線、網格、座標軸

**繪製內容**:
- 背景和網格線
- K 線實體和影線（綠漲紅跌）
- 價格軸（左側，保留兩位小數）
- 日期軸（底部，**mmm-dd 格式**，使用 intl 套件）
- 智能調整日期標籤間隔，避免重疊

**日期格式實現**:
```dart
import 'package:intl/intl.dart';

final dateFormat = DateFormat('MMM-dd', 'en_US');
final label = dateFormat.format(date); // 輸出: Dec-15
```

### 4. volume_painter.dart
**位置**: `lib/presentation/widgets/volume_painter.dart`

**職責**: 繪製交易量柱狀圖

**特點**:
- 顯示在 K 線區域下方
- 柱子高度相對於最大交易量
- 根據漲跌顯示不同顏色（半透明）
- 繪製分隔線

### 5. sentiment_markers_painter.dart
**位置**: `lib/presentation/widgets/sentiment_markers_painter.dart`

**職責**: 在正確位置繪製情緒標記

**核心邏輯**:
- 找到發布日期對應的 K 線索引
- 若發布日無交易，自動順延到下一個交易日（最多 7 天）
- 檢查是否在可見範圍內，超出範圍則跳過繪製
- 計算精確位置：
  - X 座標：使用 `controller.indexToX(index)`
  - Y 座標：看空在 K 棒上方，看多/中性在下方
- 繪製五角形和文字標籤

## 修改文件

### stock_chart_widget.dart
完全重寫，移除對 candlesticks 套件的依賴

**主要變更**:
- 使用 `FlChartController` 替代舊的 `ChartStateController`
- 使用 `GestureDetector` 處理縮放和平移
- 使用 `ListenableBuilder` 監聽控制器狀態變化
- 使用 `Stack` 疊加三個 `CustomPaint` 層
- 添加刷新按鈕和使用提示

### pubspec.yaml
**新增依賴**:
```yaml
intl: ^0.19.0  # 日期格式化
```

**移除依賴**:
```yaml
# candlesticks: ^2.1.0  # 已註釋掉
```

## 刪除文件

1. `chart_state_controller.dart` (舊版) - 已刪除
2. `sentiment_overlay.dart` (舊版) - 已刪除

## 保留文件

1. `sentiment_marker.dart` - 五角形繪製邏輯可能在其他地方使用
2. `chart_theme_config.dart` - 顏色配置
3. `candle_data_converter.dart` - 數據轉換工具（雖然不再需要轉換為 Candle 格式，但可能有其他用途）

## 核心技術實現

### 1. 日期格式化（mmm-dd）

使用 intl 套件：
```dart
import 'package:intl/intl.dart';

final dateFormat = DateFormat('MMM-dd', 'en_US');
final label = dateFormat.format(date);
// 輸出: Dec-15
```

### 2. 精確的座標映射

**X 座標計算**（索引 → 螢幕 X）:
```dart
double indexToX(int index) {
  final drawableWidth = chartSize.width - leftPadding - rightPadding;
  final unitWidth = drawableWidth / visibleCount;
  final relativeIndex = index - startIndex;
  return leftPadding + relativeIndex * unitWidth + unitWidth / 2;
}
```

**Y 座標計算**（價格 → 螢幕 Y）:
```dart
double priceToY(double price) {
  final candleTop = ChartLayoutConfig.topPadding;
  final candleHeight = chartSize.height * ChartLayoutConfig.candleAreaRatio;
  final normalized = (price - minPrice) / (maxPrice - minPrice);
  return candleTop + candleHeight * (1 - normalized); // Y 軸反轉
}
```

### 3. 手勢處理

**縮放**（雙指）:
- 調整 `visibleCount`（20-200 根 K 線）
- 保持焦點位置不變
- 重新計算可見範圍和價格範圍

**平移**（單指）:
- 根據手指移動距離計算索引變化
- 更新 `startIndex`
- 限制在數據範圍內

### 4. 順延邏輯

若發布日無交易，找下一個交易日：
```dart
int? _findCandleIndex(DateTime targetDate) {
  for (int i = 0; i < controller.prices.length; i++) {
    final priceDate = DateTime(
      controller.prices[i].date.year,
      controller.prices[i].date.month,
      controller.prices[i].date.day,
    );
    
    if (priceDate.isAtSameMomentAs(normalizedTarget)) {
      return i; // 精確匹配
    }
    
    if (priceDate.isAfter(normalizedTarget)) {
      // 找到下一個交易日（最多 7 天）
      if (priceDate.difference(normalizedTarget).inDays <= 7) {
        return i;
      }
      break;
    }
  }
  
  return null;
}
```

### 5. 智能日期標籤間隔

避免標籤重疊：
```dart
int _calculateLabelInterval() {
  final candleWidth = controller.candleWidth;
  const labelWidth = 50.0; // 估計標籤寬度（mmm-dd 格式）
  
  if (candleWidth == 0) return 1;
  
  final interval = (labelWidth / candleWidth).ceil();
  return interval.clamp(1, controller.visibleCount ~/ 3);
}
```

## 預期效果

完成後應實現：

1. ✅ **Marker 位置正確** - 顯示在對應日期的 K 線上
2. ✅ **縮放平移同步** - 所有圖層（K 線、交易量、Marker）完全同步
3. ✅ **自動隱藏** - 超出可視範圍的 Marker 不繪製
4. ✅ **日期格式正確** - 顯示 mmm-dd（如 Dec-15）
5. ✅ **性能優化** - 只繪製可見範圍內的元素

## 測試指南

### 基本顯示測試
1. 打開任一股票詳情頁面
2. 確認 K 線、交易量、Marker 是否正確顯示
3. 檢查日期格式是否為 mmm-dd

### 縮放測試
1. 使用雙指縮放手勢
2. 觀察時間窗口是否改變（K 線數量增減）
3. 確認 Marker 是否隨 K 線同步移動

### 平移測試
1. 使用單指左右滑動
2. 確認能查看 2023/01/01 至今的所有數據
3. 觀察 Marker 是否在移出可視範圍時消失

### 順延邏輯測試
1. 找一個週末或假日發布的文檔
2. 確認 Marker 是否顯示在下一個交易日

### 邊界測試
1. 滑動到數據最開始位置
2. 滑動到數據最新位置
3. 嘗試縮放到最小和最大限制

## 性能考量

### 優化措施
1. **只繪製可見範圍** - 只遍歷 startIndex 到 endIndex 的數據
2. **智能標籤間隔** - 根據縮放級別調整日期標籤密度
3. **ChangeNotifier** - 只在狀態變化時觸發重繪
4. **shouldRepaint** - 正確實現以避免不必要的重繪

### 已知限制
- 數據量超過 500 根 K 線時，縮放到最大可能會有輕微延遲
- 快速連續縮放可能需要優化防抖動

## 後續優化建議

1. **十字線功能** - 長按顯示當前價格和日期
2. **均線指標** - MA5, MA10, MA20
3. **更多技術指標** - MACD, RSI, KDJ 等
4. **價格提示框** - 顯示 OHLC 數據
5. **交易量移動平均** - 在交易量區域添加均線
6. **暗色主題支持** - 使用 theme.brightness 自動切換顏色

## 依賴項

- **flutter**: SDK
- **flutter_riverpod**: ^2.5.1 - 狀態管理
- **intl**: ^0.19.0 - 日期格式化
- **drift**: ^2.16.0 - 數據庫（StockPrice 模型）

## 兼容性

- Flutter SDK: >=3.2.0 <4.0.0
- 支持 iOS、Android、Web、Desktop

## 總結

通過完全自定義實現，我們獲得了：
- ✅ 完全的控制權（座標、縮放、平移）
- ✅ 精確的 Marker 定位
- ✅ 自定義的日期格式
- ✅ 完美的同步效果
- ✅ 更好的可維護性和可擴展性

雖然開發時間較長（約 6 小時），但解決了 candlesticks 套件的所有限制，為未來的功能擴展打下了良好基礎。
