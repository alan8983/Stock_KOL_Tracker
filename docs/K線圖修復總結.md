# K 線圖標記與數據範圍修復總結

## 📋 修復概述

已完成兩個主要問題的修復：

1. ✅ **五角形 Marker 定位問題**
2. ✅ **K 線圖數據範圍限制問題**

## 🔧 詳細修改

### 1. 擴展股價數據範圍（問題 2）

**問題**：K 線圖只顯示約 90 天的股價資料

**解決方案**：創建新的 Provider 載入從 2023/01/01 至今的完整股價資訊

**修改文件**：
- `lib/domain/providers/stock_price_provider.dart`
  - ✅ 新增 `stockFullRangePricesProvider`
  - 數據範圍：2023/01/01 至今

- `lib/presentation/widgets/stock_chart_widget.dart`
  - ✅ 將 `stock90DayPricesProvider` 改為 `stockFullRangePricesProvider`
  - ✅ 更新刷新按鈕的 invalidate 調用

### 2. 修復 Marker 定位邏輯（問題 1）

#### 2.1 發布日順延邏輯

**問題**：發布日若無交易，Marker 不知道顯示在哪裡

**解決方案**：自動順延到下一個交易日（向後最多查找 7 天）

**修改文件**：
- `lib/presentation/utils/candle_data_converter.dart`
  - ✅ 重寫 `findCandleIndexByDate` 方法
  - 優先匹配精確日期
  - 若無交易，找下一個最近的交易日
  - 容錯範圍：7 天

#### 2.2 優化座標計算

**問題**：Marker 出現在錯誤的位置（畫面最右側）

**解決方案**：改進 X 和 Y 座標計算，匹配 candlesticks 套件的內部布局

**修改文件**：
- `lib/presentation/widgets/chart_state_controller.dart`
  
  **X 座標計算**：
  - ✅ 考慮左右邊距（各 5%）
  - ✅ 考慮 Candle 間隔（20% 的單元寬度）
  - ✅ 精確計算每個 Candle 的中心位置
  
  **Y 座標計算**：
  - ✅ 考慮上方留白（5%）
  - ✅ K 線圖區域（70%）
  - ✅ 下方交易量區域（20%）
  - ✅ 價格到 Y 座標的線性映射

#### 2.3 添加可見範圍檢查

**問題**：平移時，超出範圍的 Marker 仍然嘗試繪製

**解決方案**：檢查 X 座標，超出可視範圍的 Marker 自動隱藏

**修改文件**：
- `lib/presentation/widgets/sentiment_overlay.dart`
  - ✅ 添加 X 座標範圍檢查（0 到 size.width）
  - ✅ 超出範圍的 Marker 跳過繪製
  - ✅ 改進注釋說明

#### 2.4 確保數據排序

**問題**：數據順序可能影響索引計算

**解決方案**：確保 Candle 數據按時間順序排列（從舊到新）

**修改文件**：
- `lib/presentation/widgets/stock_chart_widget.dart`
  - ✅ 檢查數據是否已排序
  - ✅ 若未排序，使用 `sortCandlesByDate` 排序

#### 2.5 改進手勢監聽

**問題**：縮放/平移時，Marker 無法同步更新

**解決方案**：添加 NotificationListener 監聽手勢事件，觸發疊加層重繪

**修改文件**：
- `lib/presentation/widgets/stock_chart_widget.dart`
  - ✅ 使用 NotificationListener 包裹 Candlesticks
  - ✅ 監聽 ScrollNotification 和縮放事件
  - ✅ 延遲 50ms 後觸發 setState，重繪疊加層

## 📁 修改文件清單

1. ✅ `lib/domain/providers/stock_price_provider.dart` - 新增完整範圍 Provider
2. ✅ `lib/presentation/widgets/stock_chart_widget.dart` - 更新數據源和手勢監聽
3. ✅ `lib/presentation/widgets/chart_state_controller.dart` - 優化座標計算
4. ✅ `lib/presentation/widgets/sentiment_overlay.dart` - 添加可見範圍檢查
5. ✅ `lib/presentation/utils/candle_data_converter.dart` - 實現順延邏輯
6. ✅ `docs/K線圖標記修復說明.md` - 測試指南（新建）
7. ✅ `docs/K線圖修復總結.md` - 本文檔（新建）

## ⚠️ 已知限制

### candlesticks 套件的限制

**核心問題**：candlesticks 2.1.0 套件**不提供**訪問內部縮放/平移狀態的 API。

**影響**：
- ✅ 初始狀態下，Marker 位置應該正確
- ⚠️ 縮放/平移時，Marker **可能無法完全同步**
- ✅ 超出範圍的 Marker 會自動隱藏

**當前緩解措施**：
1. 使用 NotificationListener 嘗試捕獲手勢事件
2. 延遲觸發重繪（50ms）
3. 添加可見範圍檢查

**效果評估**：
- 初始位置：✅ 應該正確
- 縮放同步：⚠️ 可能有輕微偏差
- 平移同步：⚠️ 需要實際測試驗證

## 🧪 測試步驟

請按照 `docs/K線圖標記修復說明.md` 中的測試步驟進行驗證：

### 必測項目

1. **初始位置測試**
   - 查看 Marker 是否顯示在正確的日期上
   - 檢查看多/看空/中性的位置（下方/上方/下方）

2. **縮放功能測試**
   - 雙指縮放手勢
   - 觀察時間窗口是否改變
   - 觀察 Marker 同步情況

3. **平移功能測試**
   - 左右滑動查看歷史數據
   - 確認能查看 2023/01/01 至今的數據
   - 觀察 Marker 出現/消失行為

4. **順延邏輯測試**
   - 找週末或假日發布的文檔
   - 驗證 Marker 是否顯示在下一個交易日

## 🔄 下一步行動

### 如果測試通過

✅ 修復完成，可以正常使用

### 如果同步問題嚴重

考慮以下方案：

#### 方案 A：微調參數
- 調整 `chart_state_controller.dart` 中的布局參數
- 改進手勢監聽機制

#### 方案 B：切換圖表庫（推薦）
- 使用 `fl_chart` 替代 `candlesticks`
- 優點：完全控制、無同步問題
- 缺點：需要重新實現（預計 4-6 小時）

## 📝 備註

### 為什麼不能完美同步？

candlesticks 套件的內部實現：
1. 使用 InteractiveViewer 處理縮放/平移
2. 維護內部狀態（可見範圍、Candle 寬度等）
3. **但不暴露這些狀態給外部**

我們的疊加層：
1. 是獨立的 CustomPaint widget
2. 無法訪問 candlesticks 的內部狀態
3. 只能基於**假設**計算座標

結果：
- 初始狀態：我們的假設與實際一致 → ✅ 正確
- 縮放/平移後：我們的假設可能不準確 → ⚠️ 可能偏差

### 理想解決方案

1. **candlesticks 套件提供回調**
   ```dart
   Candlesticks(
     candles: _candles,
     onViewportChanged: (startIndex, endIndex, scale) {
       // 更新疊加層狀態
     },
   )
   ```
   
2. **或提供狀態訪問**
   ```dart
   final controller = CandlesticksController();
   Candlesticks(
     controller: controller,
     candles: _candles,
   )
   // 然後在疊加層中使用 controller.visibleRange
   ```

但 candlesticks 2.1.0 **都不提供**這些功能。

### 替代方案：fl_chart

fl_chart 提供完整的自定義能力：

```dart
LineChart(
  LineChartData(
    // 自定義 K 線繪製
    // 自定義 Marker 繪製
    // 完全控制縮放和平移
  ),
)
```

如果需要，我可以協助實施切換方案。

## ✅ 總結

已完成：
1. ✅ 載入 2023/01/01 至今的完整股價數據
2. ✅ 實現發布日順延到下一個交易日的邏輯
3. ✅ 優化 Marker 的 X 和 Y 座標計算
4. ✅ 添加可見範圍檢查，自動隱藏超出範圍的 Marker
5. ✅ 改進手勢監聽，嘗試同步縮放/平移
6. ✅ 確保數據按正確順序排列

待測試：
- 實際運行效果
- 縮放/平移同步準確度
- 整體用戶體驗

根據測試結果決定是否需要進一步優化或切換圖表庫。
