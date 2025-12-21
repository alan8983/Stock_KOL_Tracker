# flutter_chen_kchart 實現指南

根據 [pub.dev 文檔](https://pub.dev/packages/flutter_chen_kchart)，以下是實現指南。

## API 參考

根據 pub.dev 文檔，基本用法如下：

```dart
import 'package:flutter_chen_kchart/flutter_chen_kchart.dart';

final KChartController _controller = KChartController();

KChartWidget(
  datas,
  controller: _controller,
  enableTheme: true,
  minScale: 0.1,
  maxScale: 5.0,
  scaleSensitivity: 2.5,
  onScaleChanged: (scale) {
    print('Current scale: ${(scale * 100).toInt()}%');
  },
)
```

## 數據格式

根據文檔，`datas` 參數應該是一個包含 K 線數據的列表。常見格式可能是：

1. **List<Map<String, dynamic>>** - 每個 Map 包含：
   - `date`: DateTime 或 int（時間戳）
   - `open`: double
   - `high`: double
   - `low`: double
   - `close`: double
   - `volume`: double

2. **List<自定義類>** - 套件可能定義了自己的數據類

## 實現步驟

### 1. 確認導入路徑

嘗試以下導入路徑：

```dart
// 選項 1
import 'package:flutter_chen_kchart/flutter_chen_kchart.dart';

// 選項 2
import 'package:flutter_chen_kchart/kchart.dart';

// 選項 3 - 查看套件的 lib 文件夾結構
// 使用 `flutter pub deps` 查看套件路徑，然後檢查 lib 文件夾
```

### 2. 確認數據格式

查看套件的示例代碼或文檔，確認 `datas` 參數的格式。

如果使用 Map 格式，可以使用：

```dart
final kchartData = _stateAdapter.candles.map((d) => {
  'date': d.date.millisecondsSinceEpoch, // 或直接使用 d.date
  'open': d.open,
  'high': d.high,
  'low': d.low,
  'close': d.close,
  'volume': d.volume,
}).toList();
```

### 3. 實現 KChartWidget

在 `stock_chart_widget.dart` 中：

```dart
// 移除臨時的類定義，使用實際導入的類
KChartWidget(
  kchartData, // 根據實際格式調整
  controller: _kchartController,
  enableTheme: true,
  minScale: 0.1,
  maxScale: 5.0,
  scaleSensitivity: 2.5,
  onScaleChanged: (scale) {
    _stateAdapter.setScale(scale);
  },
)
```

### 4. Controller API

根據文檔，`KChartController` 可能提供以下功能：
- 控制圖表的縮放和平移
- 程序化設置可見範圍（如果支持）
- 聚焦到特定日期（如果支持）

### 5. 狀態同步

由於套件內建處理縮放和平移，我們需要：
1. 使用 `onScaleChanged` 回調來更新 `KChartStateAdapter` 的狀態
2. 確保情緒標記能正確跟隨圖表的變化

如果套件提供其他事件回調（如 `onScrollChanged`），也應該使用它們來同步狀態。

## 調試建議

1. **查看套件源代碼**：
   ```bash
   # 套件位置
   ~/.pub-cache/hosted/pub.dev/flutter_chen_kchart-1.3.0/
   ```

2. **查看示例代碼**：
   - 訪問 pub.dev 頁面的 "Example" 標籤
   - 查看 GitHub 倉庫的示例

3. **API 文檔**：
   - 訪問 pub.dev 頁面的 "Documentation" 鏈接
   - 查看自動生成的 API 文檔

## 當前狀態

- ✅ 數據轉換層已實現（`KChartData` 和 `KChartDataConverter`）
- ✅ 狀態適配器已實現（`KChartStateAdapter`）
- ✅ 情緒標記繪製器已實現（`KChartSentimentMarkersPainter`）
- ⚠️ `StockChartWidget` 需要根據實際 API 完成實現
- ⚠️ 導入路徑需要確認

## 下一步

1. 確認正確的導入路徑
2. 確認數據格式
3. 完成 `StockChartWidget` 的實現
4. 測試縮放、平移和情緒標記的同步
5. 實現聚焦功能（如果套件支持）

