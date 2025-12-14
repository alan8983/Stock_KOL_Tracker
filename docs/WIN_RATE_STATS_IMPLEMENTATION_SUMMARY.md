# KOL 與股票列表統計顯示功能實現總結

## 實現日期
2025-12-15

## 功能概述
在 KOL 列表和股票列表上顯示勝率統計、文檔數量、情緒分布和近期表現等綜合資訊，使用展開型卡片設計，勝率計算採用門檻版（±2%）。

## 需求來源
- BACKLOG Step 4.4：在 KOL 和股票列表上顯示統計資訊
- 勝率定義：門檻版（漲跌幅超過 ±2% 才算明確的漲/跌）
- 顯示方式：展開型卡片（多行統計資訊）

## 新增檔案

### 核心邏輯
1. **lib/core/utils/win_rate_calculator.dart**
   - 勝率計算器
   - 使用門檻版（±2%）計算方式
   - 支援批次評估多個 Post 的預測結果
   - 預測結果分類：正確、錯誤、震盪（不計入）、不適用（Neutral 情緒）

### 資料模型
2. **lib/data/models/win_rate_stats.dart**
   - `WinRateStats`：單一時間區間的勝率統計
   - `MultiPeriodWinRateStats`：多時間區間的勝率統計
   - 支援 5、30、90、365 天四個時間區間

3. **lib/data/models/stock_stats.dart**
   - `StockStats`：股票統計資料
   - 包含討論統計、市場共識、近期平均漲跌幅

### 狀態管理
4. **lib/domain/providers/kol_win_rate_provider.dart**
   - `KOLWinRateStats`：KOL 勝率統計資料模型
   - `kolWinRateStatsProvider`：單一 KOL 的勝率統計 Provider
   - `allKOLWinRateStatsProvider`：所有 KOL 的勝率統計 Provider（用於列表）

5. **lib/domain/providers/stock_stats_provider.dart**
   - `stockStatsProvider`：單一股票的統計 Provider
   - `allStockStatsProvider`：所有股票的統計 Provider（用於列表）

### UI 元件
6. **lib/presentation/widgets/kol_stats_card.dart**
   - KOL 統計卡片元件
   - 顯示勝率統計（4 個時間區間）
   - 顯示文檔數、股票數、情緒分布

7. **lib/presentation/widgets/stock_stats_card.dart**
   - 股票統計卡片元件
   - 顯示討論統計（KOL 數、文檔數）
   - 顯示市場共識（看多/看空/中立百分比）
   - 顯示近期表現（4 個時間區間的平均漲跌幅）

### 測試
8. **test/win_rate_calculator_test.dart**
   - 單元測試（15 個測試案例）
   - 測試正確預測、錯誤預測、震盪區間、Neutral 情緒、門檻邊界等

9. **test/integration/win_rate_stats_integration_test.dart**
   - 整合測試（2 個測試案例）
   - 測試完整流程：建立 KOL、Posts、計算勝率
   - 測試特殊情況：只有 Neutral 情緒的情況

## 修改檔案

1. **lib/presentation/screens/kol/kol_list_screen.dart**
   - 整合 `allKOLWinRateStatsProvider`
   - 在每個 KOL 卡片下方顯示統計資訊
   - 過濾「未分類」KOL (id=1)

2. **lib/presentation/screens/stocks/stock_list_screen.dart**
   - 整合 `allStockStatsProvider`
   - 在每個股票卡片下方顯示統計資訊
   - 過濾「臨時」股票 (ticker='TEMP')

## 技術細節

### 勝率計算邏輯（門檻版 ±2%）

```
對於每個 Post：

1. 取得漲跌幅 = PriceChangeCalculator.calculateChange()

2. 判斷實際走勢：
   - 漲跌幅 > +2%  → 實際看漲
   - 漲跌幅 < -2%  → 實際看跌
   - -2% ≤ 漲跌幅 ≤ +2% → 震盪（不計入勝率）

3. 判斷是否預測正確：
   - sentiment = Bullish 且 實際看漲 → 正確
   - sentiment = Bearish 且 實際看跌 → 正確
   - sentiment = Neutral → 不計入勝率
   - 其他情況 → 錯誤

4. 勝率 = 正確次數 / (正確次數 + 錯誤次數) × 100%
```

### 市場共識計算

```
總討論數 = bullishCount + bearishCount + neutralCount
看多共識 = bullishCount / 總討論數 × 100%
看空共識 = bearishCount / 總討論數 × 100%

共識標籤：
- 看多 > 70% → "強烈看多"
- 看多 > 55% → "看多"
- 看空 > 70% → "強烈看空"
- 看空 > 55% → "看空"
- 其他 → "分歧"
```

### UI 設計

#### KOL 列表卡片

```
┌─────────────────────────────────────┐
│ [Avatar] KOL 名稱              >    │
│                                     │
│ 📊 勝率統計                         │
│ ┌────┬────┬────┬────┐              │
│ │5天 │30天│90天│365天│             │
│ │65% │58% │62% │70% │             │
│ │13/20│14/24│18/29│21/30│        │
│ └────┴────┴────┴────┘              │
│                                     │
│ 📝 48 篇文檔 | 🎯 12 檔股票         │
│ 📈 看多 60% | 📉 看空 25% | 平 15% │
└─────────────────────────────────────┘
```

#### 股票列表卡片

```
┌─────────────────────────────────────┐
│ [AA] AAPL - Apple Inc.          >  │
│                                     │
│ 💬 12 個 KOL 討論，共 48 篇文檔    │
│                                     │
│ 🎯 市場共識: 強烈看多 (70%)        │
│ ■■■■■■■□□□ (共識強度條)        │
│ 📈 70% | 📉 20% | ➖ 10%          │
│                                     │
│ 📊 近期表現:                        │
│ ┌────┬────┬────┬─────┐           │
│ │5天 │30天│90天│365天│            │
│ │+2.5%│+5.8%│+8.2%│+15.3%│       │
│ └────┴────┴────┴─────┘           │
└─────────────────────────────────────┘
```

### 顏色編碼

**勝率顏色**：
- 65% 以上：綠色（表現優秀）
- 50-65%：橙色（表現普通）
- 50% 以下：紅色（表現不佳）

**共識顏色**：
- 強烈看多（> 70%）：深綠色
- 看多（55-70%）：淺綠色
- 分歧：灰色
- 看空（55-70%）：淺紅色
- 強烈看空（> 70%）：深紅色

## 測試結果

### 單元測試
✅ 所有 15 個測試案例通過
- Bullish + 漲幅 > 2% = 正確
- Bearish + 跌幅 < -2% = 正確
- Bullish + 跌幅 < -2% = 錯誤
- Bearish + 漲幅 > 2% = 錯誤
- 震盪區間（-2% ~ +2%）= 不計入
- Neutral 情緒 = 不計入
- 門檻邊界測試
- 沒有價格資料 = 不計入

### 整合測試
✅ 所有 2 個測試案例通過
- 完整流程：建立 KOL、Posts、計算勝率
- 特殊情況：只有 Neutral 情緒

### 代碼分析
✅ 無語法錯誤
- 已修復所有 info 級別警告（unused import、const 優化）

## 效能考量

### 批次計算策略
1. **列表載入時**：
   - 使用 `allKOLWinRateStatsProvider` 和 `allStockStatsProvider`
   - 一次性計算所有 KOL/Stock 的統計
   - Riverpod 自動快取結果

2. **增量更新**：
   - 新增文檔後，使用 `ref.invalidate()` 更新相關統計
   - 只重新計算受影響的 KOL/Stock

3. **延遲載入**：
   - 使用 `FutureProvider` 實現異步計算
   - 顯示載入動畫，避免阻塞 UI

### 資料量限制
- MVP 階段處理 2023/01/01 後的資料
- 預估單個 KOL 最多 100-200 篇文檔
- 預估總共 10-20 個 KOL
- 總計算量：約 1000-4000 次漲跌幅計算

## 相依功能

此實現依賴於之前實現的功能：
- [PriceChangeCalculator](lib/core/utils/price_change_calculator.dart) - 漲跌幅計算
- [postPriceChangeProvider](lib/domain/providers/price_change_provider.dart) - 漲跌幅狀態管理
- [StockPriceRepository](lib/data/repositories/stock_price_repository.dart) - 股價資料存取

## 後續擴展建議

### Release 01 可能的優化
1. 勝率趨勢圖（折線圖顯示勝率變化）
2. KOL 排行榜（按勝率排序）
3. 股票熱度排行（按討論次數排序）
4. 勝率預警（勝率突然下降時通知）
5. 自訂門檻值（允許用戶調整 ±2% 門檻）
6. 時間範圍過濾（只看最近 3 個月的勝率）
7. 勝率資料持久化（減少重複計算）
8. 使用 Isolate 進行背景計算（提升效能）

## 已知問題
無

## 參考資料
- [計劃文件](c:\Users\alan8\.cursor\plans\kol與股票列表統計顯示_2d2e0d1d.plan.md)
- [BACKLOG.md](docs/BACKLOG.md) (Step 4.4)
- [漲跌幅實現總結](docs/PRICE_CHANGE_IMPLEMENTATION_SUMMARY.md)
