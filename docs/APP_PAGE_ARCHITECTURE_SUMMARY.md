# APP 頁面架構統整報告

> **生成日期**: 2025-12-13  
> **參考文件**: README.md, BACKLOG.md

---

## 📐 整體架構設計

### 導覽架構

APP 採用 **底部導覽（Bottom Navigation Bar）** 作為主要導覽方式，包含 4 個主要 Tab：

```
HomeScreen (底部導覽容器)
├── Tab 1: 快速輸入 (QuickInputScreen)
├── Tab 2: KOL (KOLListScreen)
├── Tab 3: 投資標的 (StockListScreen)
└── Tab 4: 更多 (MoreScreen)
```

**技術實現**：
- 使用 `IndexedStack` 保持各 Tab 狀態，避免切換時重新載入
- 使用 `BottomNavigationBar` 提供固定 4 個 Tab 的導覽
- 每個 Tab 頁面使用 `AutomaticKeepAliveClientMixin` 保持狀態

---

## 📱 頁面架構詳解

### 1. 輸入流程相關頁面

#### 1.1 QuickInputScreen（快速輸入）
- **位置**: Tab 1 - 底部導覽首頁
- **功能**: 
  - ✅ 文字輸入與貼上
  - ✅ AI 分析按鈕
  - ✅ 查看草稿按鈕
  - ✅ 自動暫存機制
- **完成度**: ✅ **100%** - 核心功能已完成
- **導航**: 
  - → `DraftListScreen` (查看草稿)
  - → `AnalysisResultScreen` (AI 分析結果)
  - → `DraftEditScreen` (編輯草稿)

#### 1.2 AnalysisResultScreen（分析結果）
- **位置**: 從 QuickInputScreen 導航進入
- **功能**:
  - ✅ 顯示 AI 分析結果
  - ✅ 自動填入 KOL 名稱（AI 辨識）
  - ✅ 自動填入發文時間（AI 辨識）
  - ✅ 自動填入投資標的（AI 辨識）
  - ✅ 可編輯所有欄位
- **完成度**: ✅ **100%** - 最新功能（2025-12-13）
- **導航**: → `DraftEditScreen` (確認後編輯)

#### 1.3 DraftEditScreen（草稿編輯）
- **位置**: 從 QuickInputScreen 或 AnalysisResultScreen 進入
- **功能**:
  - ✅ 完整表單編輯（文本、KOL、時間、投資標的、情緒）
  - ✅ 表單驗證與錯誤處理
  - ✅ 必填欄位脈衝邊框提醒
  - ✅ 相對時間輸入支援
  - ✅ 絕對時間輸入支援
- **完成度**: ✅ **95%** - 核心功能完成，部分優化待處理
- **導航**: → `PreviewScreen` (預覽確認)

#### 1.4 DraftListScreen（草稿列表）
- **位置**: 從 QuickInputScreen 進入
- **功能**:
  - ✅ 顯示所有草稿列表
  - ✅ 點擊草稿返回 QuickInputScreen（帶入內容）
  - ✅ 滑動刪除（部分實現）
- **完成度**: 🔄 **80%** - 基本功能完成，多選刪除待實現
- **待實現**:
  - ⏳ 左右滑動刪除
  - ⏳ 長按多選刪除

#### 1.5 PreviewScreen（預覽確認）
- **位置**: 從 DraftEditScreen 進入
- **功能**:
  - ✅ 建檔前確認彈窗
  - ✅ 顯示完整文檔資訊
- **完成度**: ✅ **100%** - 基本功能完成

---

### 2. KOL 相關頁面

#### 2.1 KOLListScreen（KOL 列表）
- **位置**: Tab 2 - 底部導覽第二頁
- **功能**:
  - ✅ KOL 列表顯示
  - ✅ 搜尋功能
  - ✅ KOL 卡片展示
  - ✅ FAB 按鈕創建新 KOL
- **完成度**: ✅ **100%** - 核心功能完成
- **導航**: → `KOLViewScreen` (點擊 KOL)

#### 2.2 KOLViewScreen（KOL 詳情）
- **位置**: 從 KOLListScreen 進入
- **架構**: 凍結 Header + 3 個子頁籤
- **子頁籤**:
  1. **Overview（概覽）**
     - ✅ 依投資標的分組顯示文檔
     - ✅ 依最近更新排序
     - ✅ 每個 Group 顯示最新 3 筆文檔
     - ✅ 文檔標題旁顯示發表時間
     - ✅ 顯示情緒觀點
     - 🔄 漲跌幅計算（部分完成）
     - ⏳ 左右滑動顯示 30/90/365 日漲跌幅
  2. **勝率統計**
     - 🔄 部分完成 - Grouping 已實作
     - ⏳ 顯示 5/30/90/365 日漲跌幅
     - ⏳ 計算各標的勝率
     - ⏳ 計算 KOL 整體勝率
  3. **簡介**
     - ✅ 顯示 KOL 簡介
     - ✅ 顯示 SNS 連結
     - ⏳ 長按編輯功能（Release 01）
- **完成度**: 🔄 **60%** - 基本架構完成，勝率計算待實現
- **導航**: → `PostDetailScreen` (點擊文檔) / → `StockViewScreen` (點擊標的 Logo)

---

### 3. 投資標的相關頁面

#### 3.1 StockListScreen（股票列表）
- **位置**: Tab 3 - 底部導覽第三頁
- **功能**:
  - ✅ 股票列表顯示
  - ✅ 搜尋功能
  - ✅ 股票卡片展示
- **完成度**: ✅ **100%** - 核心功能完成
- **導航**: → `StockViewScreen` (點擊股票)

#### 3.2 StockViewScreen（股票詳情）
- **位置**: 從 StockListScreen 進入
- **架構**: 凍結 Header + 3 個子頁籤
- **子頁籤**:
  1. **文檔清單**
     - ✅ 顯示所有相關文檔
     - ✅ 文檔標題旁顯示發表時間
     - ✅ 顯示情緒觀點
     - 🔄 漲跌幅計算（部分完成）
     - ⏳ 左右滑動顯示 30/90/365 日漲跌幅
  2. **市場敘事**
     - ⏳ AI 彙整論點（Release 01 功能）
  3. **K線圖**
     - ⏳ K 線圖繪製（核心功能）
     - ⏳ 縮放功能
     - ⏳ 左右平移
     - ⏳ 文檔標記顯示
     - ⏳ 點擊標記跳轉文檔
- **完成度**: 🔄 **40%** - 基本架構完成，K 線圖待實現
- **導航**: → `PostDetailScreen` (點擊文檔)

---

### 4. 文檔相關頁面

#### 4.1 PostListScreen（文檔列表）
- **位置**: 從 KOLViewScreen 或 StockViewScreen 進入
- **功能**:
  - ✅ 顯示特定標的的所有文檔
  - ✅ 文檔列表展示
- **完成度**: ✅ **90%** - 基本功能完成
- **導航**: → `PostDetailScreen` (點擊文檔)

#### 4.2 PostDetailScreen（文檔詳情）
- **位置**: 從多處進入（KOLViewScreen, StockViewScreen, PostListScreen）
- **架構**: 凍結 Header + 2 個子頁籤
- **子頁籤**:
  1. **主文內容**
     - ✅ 顯示文檔全文
     - ✅ 書籤功能（UI 完成）
     - ⏳ 回測結果顯示（需先完成回測計算）
  2. **K線圖**
     - ⏳ K 線圖繪製（核心功能）
     - ⏳ 縮放功能
     - ⏳ 左右平移
     - ⏳ 文檔情緒標記顯示
- **完成度**: 🔄 **50%** - 基本架構完成，K 線圖待實現
- **待實現**:
  - ⏳ 左右滑動查看不同細節
  - ⏳ Header 顯示回測結果

---

### 5. 更多功能頁面

#### 5.1 MoreScreen（更多選單）
- **位置**: Tab 4 - 底部導覽第四頁
- **功能**:
  - ✅ 選單列表
  - ✅ 診斷功能入口
  - ✅ 設定選項
  - ✅ 關於對話框
  - ⏳ 書籤管理（Release 01）
- **完成度**: ✅ **80%** - 基本功能完成
- **導航**: → `DiagnosticScreen` (診斷功能)

#### 5.2 DiagnosticScreen（診斷工具）
- **位置**: 從 MoreScreen 進入
- **功能**:
  - ✅ API 連接測試（Gemini, Tiingo）
  - ✅ 即時顯示診斷結果
  - ✅ 錯誤資訊與解決建議
- **完成度**: ✅ **100%** - 完整功能

---

## 📊 整體完成度統計

### 頁面完成度

| 頁面類別 | 頁面數量 | 已完成 | 部分完成 | 待實現 | 完成率 |
|---------|---------|--------|---------|--------|--------|
| **輸入流程** | 5 | 3 | 1 | 1 | 70% |
| **KOL 相關** | 2 | 1 | 1 | 0 | 80% |
| **投資標的** | 2 | 1 | 1 | 0 | 70% |
| **文檔相關** | 2 | 1 | 1 | 0 | 60% |
| **更多功能** | 2 | 2 | 0 | 0 | 100% |
| **總計** | **13** | **8** | **4** | **1** | **73%** |

### 功能完成度（根據 BACKLOG.md）

| 狀態 | 數量 | 百分比 |
|------|------|--------|
| ✅ 已完成 | 18 | 30.5% |
| 🔄 部分完成 | 15 | 25.4% |
| ⏳ 待實現 | 26 | 44.1% |
| **總計** | **59** | **100%** |

**MVP 核心功能完成度**: 約 **55%**  
**Release 01 功能完成度**: 約 **10%**

---

## 🎯 關鍵待實現功能

### 核心功能（MVP 必需）

1. **K 線圖繪製** ⏳
   - 影響頁面: `StockViewScreen`, `PostDetailScreen`
   - 功能: 股價走勢圖、縮放、平移、文檔標記
   - 優先級: 🔴 **高**

2. **回測計算** ⏳
   - 影響頁面: `KOLViewScreen`, `StockViewScreen`, `PostDetailScreen`
   - 功能: 5/30/90/365 日漲跌幅計算、勝率統計
   - 優先級: 🔴 **高**

3. **漲跌幅顯示** 🔄
   - 影響頁面: `KOLViewScreen`, `StockViewScreen`, `PostListScreen`
   - 狀態: 部分完成（情緒已顯示，漲跌幅計算待實作）
   - 優先級: 🔴 **高**

### 增強功能（Release 01）

4. **網址自動抓取** ⏳
   - 影響頁面: `QuickInputScreen`
   - 功能: 自動辨識網址並抓取內容
   - 優先級: 🟡 **中**

5. **AI 比對重複文檔** ⏳
   - 影響頁面: `AnalysisResultScreen`
   - 功能: 避免重複建檔
   - 優先級: 🟡 **中**

6. **市場敘事 AI 彙整** ⏳
   - 影響頁面: `StockViewScreen`
   - 功能: AI 彙整所有文檔論點
   - 優先級: 🟡 **中**

### 優化功能

7. **滑動刪除與多選** ⏳
   - 影響頁面: `DraftListScreen`
   - 優先級: 🟢 **低**

8. **左右滑動查看細節** ⏳
   - 影響頁面: `KOLViewScreen`, `StockViewScreen`, `PostDetailScreen`
   - 優先級: 🟢 **低**

---

## 🏗️ 架構設計特點

### 1. 統一的設計模式

- **列表頁面**: 搜尋欄 + 卡片列表 + FAB（如需要）
- **詳情頁面**: 凍結 Header + 子頁籤（TabBarView）
- **輸入頁面**: 表單驗證 + 自動填入 + 視覺提示

### 2. 狀態管理

- 使用 **Riverpod** 進行狀態管理
- Provider 分層：
  - `repository_providers.dart` - Repository 層
  - `draft_state_provider.dart` - 草稿狀態
  - `kol_posts_provider.dart` - KOL 文檔
  - `stock_posts_provider.dart` - 股票文檔
  - `bookmark_provider.dart` - 書籤管理
  - `stock_price_provider.dart` - 股價資料

### 3. 導航流程

- **輸入流程**: QuickInput → AnalysisResult → DraftEdit → Preview
- **查看流程**: List → View (with Tabs) → Detail
- **狀態保持**: 使用 IndexedStack 和 AutomaticKeepAliveClientMixin

### 4. 視覺設計

- **Material Design 3** 風格
- **脈衝邊框提醒** (`pulsing_border_card.dart`) - 必填欄位未填寫時
- **凍結 Header** - 使用 NestedScrollView + SliverAppBar
- **卡片式設計** - 列表項目統一使用卡片樣式

---

## 📈 開發進度時間線

### 已完成階段

1. ✅ **Phase 1** (2025-12-07): 專案初始化與資料庫架構
2. ✅ **Phase 2** (2025-12-08): 基礎設施建立（Tiingo, Gemini）
3. ✅ **導覽架構重構** (2025-12-10): 4 個 Tab 底部導覽
4. ✅ **AI 增強功能** (2025-12-13): KOL 與時間自動辨識

### 進行中階段

5. 🔄 **Phase 3**: 核心功能 - 輸入流（95% 完成）
   - ✅ UI 輸入頁面
   - ✅ 自動填入邏輯
   - ⏳ Review 與儲存優化

### 待處理階段

6. ⏳ **Phase 4**: 核心功能 - 分析與 UI
   - ⏳ K 線圖與標記繪製
   - ⏳ 回測邏輯（勝率計算）

7. ⏳ **Phase 5**: 優化與完善
   - ⏳ 錯誤處理優化
   - ⏳ UI 優化

---

## 🎨 頁面架構視覺化

```
┌─────────────────────────────────────┐
│      HomeScreen (底部導覽容器)        │
├─────────────────────────────────────┤
│  Tab 1: 快速輸入                     │
│  ├─ QuickInputScreen                │
│  │  ├─ → DraftListScreen            │
│  │  ├─ → AnalysisResultScreen       │
│  │  └─ → DraftEditScreen            │
│  │      └─ → PreviewScreen          │
│                                     │
│  Tab 2: KOL                         │
│  ├─ KOLListScreen                   │
│  │  └─ → KOLViewScreen (3 Tabs)     │
│  │      ├─ Overview                 │
│  │      ├─ 勝率統計                  │
│  │      └─ 簡介                      │
│  │      └─ → PostDetailScreen        │
│                                     │
│  Tab 3: 投資標的                     │
│  ├─ StockListScreen                 │
│  │  └─ → StockViewScreen (3 Tabs)    │
│  │      ├─ 文檔清單                  │
│  │      ├─ 市場敘事                  │
│  │      └─ K線圖                     │
│  │      └─ → PostDetailScreen        │
│                                     │
│  Tab 4: 更多                         │
│  ├─ MoreScreen                      │
│  │  └─ → DiagnosticScreen           │
└─────────────────────────────────────┘
```

---

## 📝 總結

### 優勢

1. ✅ **清晰的架構設計** - 底部導覽 + 子頁籤的統一模式
2. ✅ **完整的輸入流程** - 從快速輸入到預覽確認的完整流程
3. ✅ **AI 增強功能** - 自動辨識 KOL 和時間，提升用戶體驗
4. ✅ **良好的狀態管理** - 使用 Riverpod 進行統一管理

### 待改進

1. ⏳ **核心功能待實現** - K 線圖和回測計算是 MVP 的核心功能
2. ⏳ **勝率統計功能** - 這是 APP 的核心價值，需要優先完成
3. ⏳ **部分 UI 優化** - 滑動刪除、多選等增強功能

### 下一步建議

1. 🔴 **優先級 1**: 實現回測計算功能（勝率統計）
2. 🔴 **優先級 2**: 實現 K 線圖繪製與標記
3. 🟡 **優先級 3**: 完成漲跌幅計算與顯示
4. 🟢 **優先級 4**: UI 優化與增強功能

---

**報告生成時間**: 2025-12-13  
**最後更新**: 根據 README.md 和 BACKLOG.md 最新狀態
