# K 線圖標記修復說明

## 已完成的修復

### 1. 擴展股價數據範圍 ✅
- **修改內容**：創建 `stockFullRangePricesProvider`
- **數據範圍**：從 2023/01/01 至今的完整股價資訊
- **文件位置**：`lib/domain/providers/stock_price_provider.dart`

### 2. 發布日順延邏輯 ✅
- **修改內容**：更新 `findCandleIndexByDate` 方法
- **行為**：若發布日無交易，自動順延到下一個交易日（最多向後查找 7 天）
- **文件位置**：`lib/presentation/utils/candle_data_converter.dart`

### 3. 優化座標計算 ✅
- **X 座標計算**：考慮 candlesticks 套件的內部邊距和間隔
  - 左右各 5% 的邊距
  - Candle 間隔佔 20% 的單元寬度
- **Y 座標計算**：匹配 candlesticks 套件的布局
  - 上方留白：5%
  - K 線圖區域：70%
  - 下方交易量：20%
  - 底部留白：5%
- **文件位置**：`lib/presentation/widgets/chart_state_controller.dart`

### 4. 可見範圍檢查 ✅
- **修改內容**：添加 X 座標範圍檢查，超出可視範圍的 Marker 不繪製
- **文件位置**：`lib/presentation/widgets/sentiment_overlay.dart`

### 5. 數據排序確保 ✅
- **修改內容**：確保 Candle 數據按時間順序排列（從舊到新）
- **文件位置**：`lib/presentation/widgets/stock_chart_widget.dart`

## 測試步驟

### 基本功能測試

1. **Marker 初始位置測試**
   ```
   步驟：
   1. 打開任一股票的詳情頁面
   2. 查看 K 線圖
   3. 確認五角形 Marker 是否顯示在正確的日期上
   
   預期結果：
   - Marker 應該顯示在文檔發布日期對應的 K 線上（或下一個交易日）
   - 看多（綠色 L）在 K 棒下方
   - 看空（紅色 S）在 K 棒上方
   - 中性（黃色 N）在 K 棒下方
   ```

2. **縮放功能測試**
   ```
   步驟：
   1. 在 K 線圖上使用雙指縮放手勢
   2. 觀察 Marker 是否隨 K 線圖同步縮放
   
   預期結果：
   - K 線圖應該能正常縮放
   - 顯示的時間範圍應該改變（而非只改變框架大小）
   - Marker 應該保持在正確的位置（理想情況）
   ```

3. **平移功能測試**
   ```
   步驟：
   1. 在 K 線圖上使用左右滑動手勢
   2. 觀察能否查看更早或更晚的數據
   
   預期結果：
   - 可以平移查看 2023/01/01 至今的所有數據
   - 當 Marker 對應的日期移出可視範圍時，Marker 應該消失
   - 平移回來後，Marker 應該重新出現
   ```

4. **順延邏輯測試**
   ```
   步驟：
   1. 找一個週末或假日發布的文檔
   2. 查看其 Marker 是否顯示在下一個交易日
   
   預期結果：
   - Marker 應該出現在發布日之後的第一個交易日
   - 而非發布日當天（因為當天無交易）
   ```

### 已知限制

#### ⚠️ candlesticks 套件的限制

**問題**：candlesticks 2.1.0 套件不提供訪問內部縮放/平移狀態的 API。

**影響**：
- 初始狀態下，Marker 位置應該是正確的（基於我們的座標計算）
- 當用戶縮放或平移時，Marker **可能無法完全同步**，因為我們無法獲取 candlesticks 的內部狀態

**當前解決方案**：
1. 使用 NotificationListener 嘗試監聽手勢事件
2. 觸發疊加層重繪（延遲 50ms）
3. 添加可見範圍檢查，超出範圍的 Marker 不顯示

**效果評估**：
- ✅ 初始位置應該正確
- ⚠️ 縮放/平移時的同步可能不完美
- ✅ 超出範圍的 Marker 會自動隱藏

## 如果同步問題嚴重

### 備用方案：切換到 fl_chart

如果測試後發現 Marker 與 K 線圖的同步問題無法接受，建議切換到 `fl_chart` 套件：

**優點**：
- 提供完全的自定義能力
- 可以精確控制每個元素的繪製
- 官方支持添加自定義標記

**缺點**：
- 需要重新實現 K 線圖組件
- 開發工作量較大（預計 4-6 小時）

**實施步驟**：
1. 使用 fl_chart 的 `CandleStickChart` 或 `LineChart`
2. 自定義繪製 K 線
3. 在同一個 chart 中添加 Marker（作為 overlay 或 scatter points）
4. 完全控制縮放和平移邏輯

## 調試技巧

### 如果 Marker 位置不正確

1. **檢查日期匹配**
   - 在 `sentiment_overlay.dart` 的 `paint` 方法中添加 print：
   ```dart
   print('Post date: ${post.postedAt}, Candle index: $candleIndex, X: $x, Y: $y');
   ```

2. **檢查座標計算**
   - 在 `chart_state_controller.dart` 的 `candleIndexToX` 方法中添加 print：
   ```dart
   print('Index: $candleIndex, Total: ${_candles.length}, X: $x');
   ```

3. **檢查可見範圍**
   - 在 `sentiment_overlay.dart` 中檢查哪些 Marker 被跳過：
   ```dart
   if (x < 0 || x > size.width) {
     print('Marker out of bounds: ${post.postedAt}, X: $x');
     continue;
   }
   ```

## 優化建議

### 短期優化（當前方案）

1. **調整座標計算參數**
   - 如果 Marker 位置仍有偏差，可以微調 `chart_state_controller.dart` 中的參數：
     - `horizontalPaddingRatio`（當前 0.05）
     - `candleSpacingRatio`（當前 0.2）
     - `topPaddingRatio`（當前 0.05）
     - `candleAreaRatio`（當前 0.70）

2. **改進手勢監聽**
   - 嘗試使用 GestureDetector 包裹整個圖表
   - 更精確地追蹤縮放和平移事件

### 長期優化（如需要）

1. **Fork candlesticks 套件**
   - 添加狀態回調 API
   - 提供當前可見範圍的訪問接口
   - 維護自己的版本

2. **切換到 fl_chart**
   - 完全控制圖表渲染
   - 無同步問題
   - 更靈活的自定義能力

## 聯繫與反饋

測試完成後，請提供以下信息：

1. **Marker 初始位置**：是否正確？
2. **縮放行為**：Marker 是否能夠同步？有多大偏差？
3. **平移行為**：Marker 是否正確出現/消失？
4. **整體體驗**：是否可以接受？還是需要切換圖表庫？

根據反饋，我們可以：
- 微調座標計算參數
- 改進手勢監聽機制
- 或者實施備用方案（切換到 fl_chart）
