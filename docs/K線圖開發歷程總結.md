# K線圖開發歷程總結 - 遷移到 syncfusion_flutter_charts 參考

## 概述

本文檔整理過往 Agent 在 K線圖功能開發中的實現歷程，包含每個開發階段實現的功能、解決的問題和遇到的技術挑戰，作為遷移到 `syncfusion_flutter_charts` 的參考。

---

## K線圖-Dev 01: 初始實現（使用 candlesticks 套件）

### 實現日期
2025年12月15日

### 使用的技術
- **套件**: `candlesticks: ^2.1.0`
- **主要文件**: `lib/presentation/widgets/stock_chart_widget.dart`

### 實現的功能 ✅

1. **顏色配置系統**
   - 檔案: `lib/presentation/theme/chart_theme_config.dart`
   - 提供三種預設主題：defaultTheme（綠漲紅跌）、darkTheme、asianTheme（紅漲綠跌）
   - 支援動態切換和自定義配色
   - 提供情緒顏色映射功能

2. **自定義情緒標記組件**
   - 檔案: `lib/presentation/widgets/sentiment_marker.dart`
   - 使用 `CustomPaint` 繪製五邊形標記
   - 支援三種情緒類型：看多（綠色 L）、中性（灰色 N）、看空（紅色 S）

3. **股價數據 Provider**
   - 檔案: `lib/domain/providers/stock_price_provider.dart`
   - 新增 `stock90DayPricesProvider`，預設查詢最近 90 日數據

4. **數據格式轉換工具**
   - 檔案: `lib/presentation/utils/candle_data_converter.dart`
   - 實現 `StockPrice` 到 `Candle` 的格式轉換
   - 提供日期匹配算法（容錯範圍 7 天）

5. **K線圖組件基本功能**
   - ✅ 使用 `candlesticks` 套件繪製專業 K 線圖
   - ✅ 自動顯示交易量柱狀圖（在 K 線圖下方）
   - ✅ 支援雙指縮放（pinch to zoom）
   - ✅ 支援左右平移（swipe）
   - ✅ 預設顯示 90 日數據
   - ✅ 圖表高度限制在螢幕的 1/2
   - ✅ 最右側顯示最新交易日
   - ✅ 提供重新整理按鈕
   - ✅ 顯示情緒分布統計卡片（**替代方案**，因為無法精確疊加標記）

### 解決的問題

1. ✅ 基本的 K線圖顯示功能
2. ✅ 交易量圖表顯示
3. ✅ 基本的手勢交互（縮放、平移）

### 遇到的限制 ⚠️

1. **精確標記定位困難**
   - `candlesticks` 套件不提供座標映射 API
   - 無法將情緒標記精確疊加在對應日期的 K 線上方/下方
   - **採用替代方案**：在圖表下方顯示「90日內情緒分布」統計卡片

2. **套件 API 限制**
   - 不提供訪問內部縮放/平移狀態的 API
   - 日期格式自定義選項有限

### 關鍵設計決策

由於 `candlesticks` 套件限制，採用了**統計卡片替代方案**而非精確標記疊加，但保留了 `_buildSentimentMarkers()` 方法作為未來擴展接口。

---

## K線圖-Dev 02: 標記疊加層實現

### 實現日期
2025年12月15日

### 使用的技術
- **套件**: `candlesticks: ^2.1.0`（繼續使用）
- **新增文件**: 
  - `lib/presentation/widgets/chart_state_controller.dart`
  - `lib/presentation/widgets/sentiment_overlay.dart`

### 實現的功能 ✅

1. **ChartStateController 狀態管理器**
   - 管理 Candle 數據和圖表尺寸
   - 計算價格範圍（最高/最低價 + 10% padding）
   - 提供座標轉換方法：
     - `priceToY()`: 將股價轉換為螢幕 Y 座標
     - `candleIndexToX()`: 將 Candle 索引轉換為 X 座標
     - `getCandleIndex()`: 根據日期查找 Candle 索引

2. **SentimentOverlay 疊加層組件**
   - 使用 `CustomPaint` 在 K 線圖上繪製情緒標記
   - 自動監聽 `ChartStateController` 狀態變化
   - 根據情緒類型決定標記位置：
     - 看多 (Bullish): K棒下方，綠色五邊形，標註 "L"
     - 中性 (Neutral): K棒下方，灰色五邊形，標註 "N"
     - 看空 (Bearish): K棒上方，紅色五邊形，標註 "S"

3. **整合到 StockChartWidget**
   - 使用 `Stack` 疊加 `SentimentOverlay` 在 Candlesticks 上方
   - 使用 `IgnorePointer` 確保標記不干擾圖表手勢

### 解決的問題

1. ✅ 實現了標記疊加層的基礎架構
2. ✅ 建立了座標轉換系統

### 遇到的限制 ⚠️

1. **座標映射不準確**
   - `candlesticks` 套件不提供座標映射 API
   - 只能基於假設計算座標（假設 Candle 平均分布）
   - 標記位置是估算值，不會完全跟隨縮放

2. **縮放/平移同步問題**
   - 無法獲取套件的內部縮放/平移狀態
   - 標記無法跟隨圖表的縮放和平移動作

3. **日期格式問題**
   - 無法自定義日期格式（顯示時間而非 mm/dd）

### 技術挑戰

- 座標計算基於假設的布局參數（leftPadding=50px）
- X 座標計算假設所有 Candle 平均分布
- Y 座標計算需要考慮上方留白（5%）、K 線圖區域（70%）、交易量區域（20%）

---

## K線圖-Dev 03: 標記定位修復

### 實現日期
2025年12月（修復階段）

### 實現的功能 ✅

1. **擴展股價數據範圍**
   - 修改: `lib/domain/providers/stock_price_provider.dart`
   - 新增 `stockFullRangePricesProvider`
   - 數據範圍：從 2023/01/01 至今的完整股價資訊

2. **發布日順延邏輯**
   - 修改: `lib/presentation/utils/candle_data_converter.dart`
   - 更新 `findCandleIndexByDate` 方法
   - 若發布日無交易，自動順延到下一個交易日（最多向後查找 7 天）

3. **優化座標計算**
   - 修改: `lib/presentation/widgets/chart_state_controller.dart`
   - X 座標計算：考慮左右邊距（各 5%）、Candle 間隔（20% 的單元寬度）
   - Y 座標計算：考慮上方留白（5%）、K 線圖區域（70%）、交易量區域（20%）

4. **可見範圍檢查**
   - 修改: `lib/presentation/widgets/sentiment_overlay.dart`
   - 添加 X 座標範圍檢查（0 到 size.width）
   - 超出範圍的 Marker 跳過繪製

5. **數據排序確保**
   - 修改: `lib/presentation/widgets/stock_chart_widget.dart`
   - 確保 Candle 數據按時間順序排列（從舊到新）

6. **改進手勢監聽**
   - 使用 NotificationListener 監聽手勢事件
   - 延遲 50ms 後觸發 setState，重繪疊加層

### 解決的問題

1. ✅ 擴展了數據範圍（從 90天到完整範圍）
2. ✅ 實現了發布日順延邏輯
3. ✅ 優化了座標計算算法
4. ✅ 添加了可見範圍檢查，避免繪製超出範圍的標記

### 遇到的限制 ⚠️

**candlesticks 套件的根本限制**：
- 不提供訪問內部縮放/平移狀態的 API
- 無法獲取精確的可見範圍
- 標記位置同步仍然不完美

### 緩解措施

1. 使用 NotificationListener 嘗試捕獲手勢事件
2. 延遲觸發重繪（50ms）
3. 添加可見範圍檢查

### 效果評估

- ✅ 初始位置：應該正確
- ⚠️ 縮放同步：可能有輕微偏差
- ⚠️ 平移同步：需要實際測試驗證

---

## K線圖-Dev 04: 遷移到 flutter_chen_kchart

### 實現日期
2025年1月

### 使用的技術
- **套件**: `flutter_chen_kchart: ^2.4.1`（從 candlesticks 遷移）
- **主要文件**:
  - `lib/presentation/widgets/stock_chart_widget.dart`
  - `lib/presentation/widgets/kchart_state_adapter.dart`
  - `lib/presentation/widgets/kchart_sentiment_markers_painter.dart`
  - `lib/presentation/utils/kchart_data_converter.dart`

### 遷移原因

`candlesticks` 套件的限制：
1. 不提供座標映射 API
2. 不暴露內部縮放/平移狀態
3. 日期格式自定義選項有限

期望 `flutter_chen_kchart` 提供更好的 API 支持。

### 實現的功能 ✅

1. **數據格式轉換**
   - 檔案: `lib/presentation/utils/kchart_data_converter.dart`
   - 實現 `StockPrice` 到 `KLineEntity` 的轉換
   - 使用 `KLineEntity.fromCustom()` 構造函數

2. **KChartStateAdapter 狀態適配器**
   - 檔案: `lib/presentation/widgets/kchart_state_adapter.dart`
   - 管理 K線數據（`List<KLineEntity>`）
   - 追蹤可見範圍（startIndex, endIndex, visibleCount）
   - 計算價格範圍和交易量範圍
   - 提供座標轉換方法（用於標記定位）

3. **KChartSentimentMarkersPainter**
   - 檔案: `lib/presentation/widgets/kchart_sentiment_markers_painter.dart`
   - 使用 CustomPaint 繪製情緒標記
   - 監聽 KChartStateAdapter 狀態變化

4. **整合 KChartWidget**
   - 使用 `KChartWidget` 繪製 K線圖
   - 配置 MainState.MA（移動平均線）
   - 配置縮放和平移參數
   - 使用 `onScaleChanged` 回調更新狀態

### 解決的問題

1. ✅ 成功遷移到新的圖表套件
2. ✅ 建立了新的狀態管理架構
3. ✅ 驗證了 API 使用正確性（參見 `docs/KCHART_API_VERIFICATION.md`）

### 遇到的限制 ⚠️

1. **API 限制仍然存在**
   - 雖然 `flutter_chen_kchart` 提供了 `KChartController`，但只提供 `currentScale`
   - 無法獲取 `mScrollX`（滾動偏移）
   - 無法獲取精確的可見範圍（`mStartIndex`, `mStopIndex`）

2. **狀態同步問題**
   - `KChartStateAdapter` 維護的可見範圍不與實際圖表狀態同步
   - 只能通過 `onScaleChanged` 回調獲取縮放比例
   - 沒有平移位置的回調

### API 驗證結果

根據 `docs/KCHART_API_VERIFICATION.md`：
- ✅ 所有使用的 API 都與源碼定義一致
- ✅ 編譯無錯誤
- ⚠️ 但 API 功能仍然有限

---

## K線圖-Dev 05: 狀態同步改進

### 實現日期
2025年1月

### 實現的功能 ✅

1. **改進 setScale() 方法**
   - 修改: `lib/presentation/widgets/kchart_state_adapter.dart`
   - 根據縮放比例計算並更新可見範圍
   - 添加 `_updateVisibleRangeFromScale()` 方法

2. **添加 setToLatest() 和 setToOldest() 方法**
   - 從 `onLoadMore(true)` 調用 `setToLatest()`
   - 從 `onLoadMore(false)` 調用 `setToOldest()`
   - 更新可見範圍以匹配邊界狀態

3. **添加 isOnDrag 回調監聽**
   - 修改: `lib/presentation/widgets/stock_chart_widget.dart`
   - 監聽拖拽狀態變化
   - 拖拽結束後重新計算可見範圍

4. **添加 onLoadMore 回調處理**
   - 檢測滾動到邊界的情況
   - 根據邊界位置更新可見範圍

5. **交互狀態管理**
   - 添加 `_isInteracting` 標誌
   - 交互時隱藏標記，交互結束後延遲顯示（使用 Timer 防抖）

### 解決的問題

1. ✅ 縮放後，標記位置會根據新的可見範圍更新
2. ✅ 拖拽結束後，標記位置會重新計算
3. ✅ 邊界位置（最新/最舊數據）的標記位置更準確
4. ✅ 改進了用戶體驗（交互時隱藏標記，避免視覺干擾）

### 仍然存在的限制 ⚠️

1. **精確的平移位置無法獲取**
   - 無法獲取 `mScrollX`（滾動偏移）
   - 無法獲取精確的可見範圍（`mStartIndex`, `mStopIndex`）
   - 只能通過估算和邊界檢測來近似

2. **中間位置的準確性**
   - 當用戶滾動到歷史數據的中間位置時，標記位置可能不準確
   - 只有在邊界位置（最新/最舊）時，位置才相對準確

3. **布局參數估算**
   - `indexToX()` 方法中的布局參數（leftPadding, rightPadding）是估算值
   - 可能需要通過實際測試調整

### 改進效果

**改進前**：
- ❌ 縮放後，標記位置不更新
- ❌ 平移後，標記位置錯誤
- ⚠️ 僅在初始狀態下位置較準確

**改進後**：
- ✅ 縮放後，標記位置會根據新的可見範圍更新
- ✅ 拖拽結束後，標記位置會重新計算
- ✅ 邊界位置的標記位置更準確
- ⚠️ 中間位置（歷史數據）的標記位置仍有誤差

---

## 額外探索：fl_chart 自定義實現（未採用）

### 探索日期
2025年12月15日

### 探索原因

由於 `candlesticks` 套件的限制，考慮使用 `fl_chart` 進行完全自定義實現。

### 方案概述

使用 Flutter 的 CustomPainter 自定義實現完整的 K 線圖：
```
StockChartWidget (主組件)
  └─> FlChartController (狀態管理)
       ├─> CandlesPainter (K 線繪製器)
       ├─> VolumePainter (交易量繪製器)
       └─> SentimentMarkersPainter (情緒標記繪製器)
```

### 優點

1. ✅ 完全控制圖表渲染
2. ✅ 無同步問題（所有狀態自己管理）
3. ✅ 更靈活的自定義能力
4. ✅ 可以實現日期格式自定義（mmm-dd）

### 缺點

1. ❌ 開發工作量較大（預計 4-6 小時）
2. ❌ 需要自己實現所有功能（縮放、平移、繪製等）
3. ❌ 維護成本較高

### 決策

最終未採用此方案，選擇繼續使用現有套件並改進狀態同步。

---

## 當前實現狀態總結

### 使用的套件
- **當前**: `flutter_chen_kchart: ^2.4.1`

### 核心組件

1. **StockChartWidget**
   - 主組件，整合所有功能
   - 使用 `KChartWidget` 繪製 K線圖
   - 使用 `KChartSentimentMarkersPainter` 繪製情緒標記
   - 使用 `KChartStateAdapter` 管理狀態

2. **KChartStateAdapter**
   - 管理 K線數據和可見範圍
   - 提供座標轉換方法
   - 監聽縮放和平移事件
   - 管理交互狀態和標記可見性

3. **KChartSentimentMarkersPainter**
   - 使用 CustomPaint 繪製情緒標記
   - 根據可見範圍過濾標記
   - 根據情緒類型決定標記位置

4. **KChartDataConverter**
   - 將 `StockPrice` 轉換為 `KLineEntity`
   - 提供日期匹配功能

### 已實現的功能 ✅

1. ✅ K線圖顯示（使用 flutter_chen_kchart）
2. ✅ 交易量圖表顯示
3. ✅ 雙指縮放和平移
4. ✅ 情緒標記疊加（估算位置）
5. ✅ 縮放/平移狀態部分同步（邊界位置較準確）
6. ✅ 交互時隱藏標記（提升體驗）
7. ✅ 數據範圍：2023/01/01 至今
8. ✅ 發布日順延邏輯（無交易時順延到下一個交易日）
9. ✅ 顏色主題系統（支援多種主題）

### 已知限制 ⚠️

1. **座標映射精度**
   - 標記位置基於估算算法
   - 邊界位置較準確，中間位置可能有誤差

2. **API 限制**
   - 無法獲取精確的滾動偏移
   - 無法獲取精確的可見範圍
   - 只能通過回調和估算來近似

3. **日期格式**
   - 套件預設格式，無法自定義為 mmm-dd 格式

---

## 遷移到 syncfusion_flutter_charts 的建議

### 需要遷移的原因

1. **更好的 API 支持**
   - 期望 syncfusion_flutter_charts 提供更完善的狀態訪問 API
   - 期望能夠獲取精確的可見範圍和座標映射

2. **解決當前限制**
   - 解決標記位置精度問題
   - 解決狀態同步問題
   - 實現日期格式自定義

### 需要保留的功能

1. ✅ **顏色配置系統** (`chart_theme_config.dart`)
   - 三種預設主題
   - 情緒顏色映射

2. ✅ **情緒標記組件** (`sentiment_marker.dart`)
   - 五邊形繪製邏輯
   - 三種情緒類型（看多/中性/看空）

3. ✅ **數據轉換邏輯**
   - `StockPrice` 到圖表數據格式的轉換
   - 日期匹配算法（含順延邏輯）

4. ✅ **狀態管理架構**
   - 可見範圍管理
   - 座標轉換方法
   - 交互狀態管理

5. ✅ **UI 組件**
   - 圖例顯示
   - 刷新按鈕
   - 統計卡片

### 需要重新實現的部分

1. **圖表繪製**
   - 使用 syncfusion_flutter_charts 的 K線圖組件
   - 可能需要使用 `SfCartesianChart` 和 `CandleSeries`

2. **標記疊加**
   - 使用 syncfusion 的標記功能（如 `ChartDataMarker` 或自定義繪製）
   - 需要確保能夠精確定位

3. **座標轉換**
   - 利用 syncfusion 提供的座標轉換 API
   - 實現精確的 X/Y 座標計算

4. **手勢處理**
   - 使用 syncfusion 的手勢回調
   - 實現縮放和平移狀態同步

### 遷移時的關鍵檢查點

1. **API 驗證**
   - [ ] 檢查 syncfusion_flutter_charts 是否提供可見範圍訪問
   - [ ] 檢查是否提供座標轉換 API
   - [ ] 檢查是否支持自定義標記
   - [ ] 檢查日期格式自定義支持

2. **功能對比**
   - [ ] K線圖繪製
   - [ ] 交易量圖表
   - [ ] 縮放和平移
   - [ ] 標記疊加
   - [ ] 座標轉換精度

3. **性能測試**
   - [ ] 大量數據（500+ K線）的渲染性能
   - [ ] 縮放和平移的流暢度
   - [ ] 標記繪製的開銷

### 建議的遷移步驟

1. **階段 1: 基礎遷移**
   - 實現基本的 K線圖顯示
   - 實現交易量圖表
   - 驗證 API 可用性

2. **階段 2: 標記功能**
   - 實現情緒標記疊加
   - 驗證座標轉換精度
   - 測試標記位置準確性

3. **階段 3: 狀態同步**
   - 實現縮放狀態同步
   - 實現平移狀態同步
   - 優化用戶體驗

4. **階段 4: 優化與測試**
   - 性能優化
   - 邊界情況測試
   - 用戶體驗測試

---

## 相關文檔索引

### 實施文檔
- `docs/K_LINE_CHART_IMPLEMENTATION.md` - Dev 01 初始實現總結
- `docs/K_LINE_CHART_OVERLAY_IMPLEMENTATION.md` - Dev 02 標記疊加層實現總結
- `docs/K線圖修復總結.md` - Dev 03 標記定位修復總結
- `docs/K線圖標記修復說明.md` - Dev 03 測試指南
- `docs/KCHART_API_VERIFICATION.md` - Dev 04 API 驗證報告
- `docs/KCHART_STATE_SYNC_ANALYSIS.md` - Dev 05 狀態同步問題分析
- `docs/KCHART_STATE_SYNC_IMPROVEMENTS.md` - Dev 05 狀態同步改進實施總結
- `docs/KCHART_STATE_SYNC_CHECK_SUMMARY.md` - Dev 05 狀態同步檢查總結
- `docs/FL_CHART_IMPLEMENTATION.md` - fl_chart 自定義實現探索（未採用）

### 核心實現文件
- `lib/presentation/widgets/stock_chart_widget.dart` - 主組件
- `lib/presentation/widgets/kchart_state_adapter.dart` - 狀態適配器
- `lib/presentation/widgets/kchart_sentiment_markers_painter.dart` - 標記繪製器
- `lib/presentation/widgets/chart_interval_selector.dart` - 時間範圍選擇器
- `lib/presentation/utils/kchart_data_converter.dart` - 數據轉換工具
- `lib/presentation/theme/chart_theme_config.dart` - 顏色主題配置
- `lib/presentation/widgets/sentiment_marker.dart` - 情緒標記組件
- `lib/domain/providers/stock_price_provider.dart` - 股價數據 Provider

---

## 總結

K線圖功能經過多次迭代開發，從最初的 `candlesticks` 套件遷移到 `flutter_chen_kchart`，並進行了多次改進。雖然解決了許多問題，但仍然存在一些限制，特別是座標映射精度和狀態同步的問題。

建議在遷移到 `syncfusion_flutter_charts` 時：
1. 優先驗證 API 是否能夠解決當前的限制
2. 保留現有的核心邏輯（數據轉換、狀態管理架構）
3. 分階段遷移，確保每個階段的功能完整性
4. 重點關注座標轉換精度和狀態同步的實現

希望這份總結能夠為遷移工作提供有價值的參考。

