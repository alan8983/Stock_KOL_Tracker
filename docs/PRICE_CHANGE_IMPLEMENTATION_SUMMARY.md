# 漲跌幅計算功能實現總結

## 實現日期
2025-12-15

## 功能概述
實現了在 PostCard 上顯示股價漲跌幅的功能，支援 5、30、90、365 天四個時間區間，透過左右滑動切換。股價資料預設從 2023/01/01 開始獲取。

## 新增檔案

### 核心邏輯
1. **lib/core/utils/price_change_calculator.dart**
   - 漲跌幅計算器
   - 支援單一和批次計算多個時間區間
   - 交易日對齊邏輯（向前查找最多 7 天）
   - 使用二分搜尋提升效能

2. **lib/data/models/price_change_result.dart**
   - 漲跌幅結果資料模型
   - 包含 postId, ticker, postedAt, changes, calculatedAt
   - 提供便捷的 getter (change5d, change30d, change90d, change365d)

### 狀態管理
3. **lib/domain/providers/price_change_provider.dart**
   - 單一 Post 的漲跌幅 Provider (`postPriceChangeProvider`)
   - 批次計算 Provider (`batchPriceChangeProvider`)
   - 快取管理 (`priceChangeCacheProvider`)

### UI 元件
4. **lib/presentation/widgets/price_change_indicator.dart**
   - 漲跌幅顯示元件
   - 支援左右滑動切換時間區間（使用 PageView）
   - 綠漲紅跌配色（美股慣例）
   - 顯示當前區間指示器（小圓點）
   - 三種狀態：計算中、顯示結果、載入失敗

### 測試
5. **test/price_change_calculator_test.dart**
   - 單元測試（7 個測試案例）
   - 測試正常計算、跌幅、資料不足、交易日對齊、批次計算等

6. **test/integration/price_change_integration_test.dart**
   - 整合測試（3 個測試案例）
   - 測試完整流程、日期過濾、資料不足處理

## 修改檔案

### 服務層
1. **lib/data/services/Tiingo/tiingo_service.dart**
   - 新增 startDate 和 endDate 參數
   - 預設從 2023-01-01 開始獲取股價資料

### Repository 層
2. **lib/data/repositories/post_repository.dart**
   - `getPostsByStock` 新增 afterDate 參數（預設 2023/01/01）
   - `getPostsByKOL` 新增 afterDate 參數（預設 2023/01/01）
   - `getPostsWithDetailsByStock` 新增 afterDate 參數
   - `getPostsWithDetailsByKOL` 新增 afterDate 參數

### UI 層
3. **lib/presentation/widgets/post_card.dart**
   - 在情緒標籤下方新增 PriceChangeIndicator 元件
   - 導入 price_change_indicator.dart

## 技術細節

### 漲跌幅計算邏輯
```
基準價 = postedAt 當天或最近前一個交易日的收盤價
目標價 = (postedAt + period 天) 當天或最近前一個交易日的收盤價
漲跌幅 = ((目標價 - 基準價) / 基準價) × 100%
```

### 交易日對齊策略
- 當指定日期無資料時，向前查找最近的交易日（最多 7 天）
- 確保目標日期在基準日期之後（避免返回 0.0）
- 如果 7 天內仍無資料，返回 null

### 時間區間定義
- 5 天：自然日 5 天
- 30 天：自然日 30 天
- 90 天：自然日 90 天
- 365 天：自然日 365 天

### 效能優化
- 使用二分搜尋提升查找效能
- Riverpod 自動快取已計算的結果
- 支援批次計算（預留功能）

## 測試結果

### 單元測試
✅ 所有 7 個測試案例通過
- 計算正常情況的漲跌幅
- 計算跌幅
- 目標日期資料不足時返回 null
- 交易日對齊：基準日是週末
- 批次計算多個時間區間
- 空資料列表時返回 null
- 基準日期太早，沒有資料時返回 null

### 整合測試
✅ 所有 3 個測試案例通過
- 完整流程：建立 Post、插入股價、計算漲跌幅
- 過濾 2023/01/01 之前的文檔
- 計算漲跌幅時處理資料不足的情況

### 代碼分析
✅ 新增檔案無語法錯誤
- 已修復所有 info 級別警告（print、withOpacity）

## UI 設計

### PostCard 佈局
```
┌────────────────────────────────────┐
│ [Avatar] KOL 名稱          [書籤]  │
│                                    │
│ [看多] AAPL                        │
│                                    │
│ ┌──────────────────────────────┐  │
│ │  📊 5天漲跌: +2.5%           │  │ ← 新增的漲跌幅元件
│ │     ● ○ ○ ○                  │  │   可左右滑動
│ └──────────────────────────────┘  │
│                                    │
│ 文章內容預覽...                    │
│                                    │
│ 3 小時前                      >    │
└────────────────────────────────────┘
```

### 漲跌幅顯示狀態
1. **計算中**：顯示載入動畫 + "計算中..."
2. **有資料**：顯示漲跌幅，綠色/紅色背景，向上/向下箭頭
3. **資料不足**：灰色背景 + "資料不足"
4. **載入失敗**：紅色背景 + "載入失敗"

## 資料範圍限制
- **MVP 階段**：只處理 2023/01/01 至今的貼文
- **股價資料**：Tiingo API 預設從 2023-01-01 開始獲取
- **自動過濾**：Repository 層自動過濾 2023/01/01 之前的文檔

## 後續擴展建議

### Release 01 可能的優化
1. 支援更多時間區間（7 天、180 天）
2. 支援自訂時間區間
3. 漲跌幅資料持久化（減少重複計算）
4. 勝率統計功能（情緒觀點 vs 實際漲跌）
5. K 線圖整合（在圖上標註發文時間點）
6. 批次載入優化（可見卡片批次計算）

### 效能優化
1. 實作記憶體快取機制
2. 延遲載入（進入視窗時才計算）
3. 背景計算（使用 Isolate）

## 相依套件
- flutter_riverpod: 狀態管理
- drift: 資料庫操作
- dio: HTTP 請求（Tiingo API）

## API 限制
- Tiingo API 免費額度：1000 次請求/天，500 檔股票/月
- 建議在正式環境使用前申請新的 API Token

## 已知問題
無

## 參考資料
- [計劃文件](c:\Users\alan8\.cursor\plans\漲跌幅計算功能實現_115a18de.plan.md)
- [BACKLOG.md](docs/BACKLOG.md) (行 145-150, 162-167)
