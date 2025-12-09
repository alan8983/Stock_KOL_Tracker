# Stock KOL Tracker

一個 Flutter 開發的財經 KOL 投資建議回測系統，幫助投資者追蹤和分析 KOL 的投資觀點，驗證其準確性與時效性。

## 📋 專案概述

Stock KOL Tracker 是一個本地部署的移動應用程式，專為忙碌的散戶投資者設計。透過 AI 分析 KOL 發言內容，自動識別投資標的、情緒分析，並提供回測功能來評估 KOL 的預測準確度。

## 🚀 快速開始

### 環境需求
- Flutter SDK (最新穩定版)
- Dart SDK
- Android Studio / Xcode (用於移動端開發)

### 安裝步驟

1. **克隆專案**
```bash
git clone https://github.com/alan8983/Stock_KOL_Tracker.git
cd Stock_KOL_Tracker
```

2. **安裝依賴**
```bash
flutter pub get
```

3. **設定環境變數**
```bash
cp env.example .env
# 編輯 .env 檔案，填入您的 API Keys
# GEMINI_API_KEY=your_gemini_api_key
# TIINGO_API_TOKEN=your_tiingo_token
```

4. **執行應用程式**
```bash
flutter run
```

## 📊 Git 推送進展記錄

### 🎯 最新進展 (2025-12-10)

#### Commit: `00a95b8` - 更新 README 文件
**日期**: 2025-12-10  
**主要變更**:
- ✅ 添加新的文件連結（`IMPLEMENTATION_REPORT.md`、`NAVIGATION_TEST_SUMMARY.md`）
- ✅ 更新已實現功能列表（導覽架構、KOL 管理、股票管理、文檔管理）
- ✅ 更新專案結構文件，包含詳細的目錄樹
- ✅ 更新專案進度統計，標記導覽架構重構完成

---

#### Commit: `5b5390c` - 重構導覽架構並添加新畫面
**日期**: 2025-12-10  
**主要變更**:
- ✅ 實現 4 個底部 Tab 導覽架構（快速輸入、KOL、投資標的、更多）
- ✅ 新增 `KOLListScreen` 與搜尋功能
- ✅ 新增 `StockListScreen` 與搜尋功能
- ✅ 新增 `MoreScreen` 選單頁面
- ✅ 新增 `PostDetailScreen` 與 2 個子頁籤
- ✅ 增強 `KOLViewScreen` 和 `StockViewScreen`，各包含 3 個子頁籤
- ✅ 新增 `kol_list_provider` 和 `stock_list_provider` 進行狀態管理
- ✅ 改善草稿列表流程，使用 Navigator 返回值傳遞資料
- ✅ 更新 Repository 層，新增搜尋和 `getById` 方法
- ✅ 新增實施報告文件（`IMPLEMENTATION_REPORT.md`、`NAVIGATION_TEST_SUMMARY.md`）

**架構改進**:
- 完整的底部導覽架構，支援 4 個主要功能區塊
- 統一的列表頁面設計模式（搜尋 + 卡片列表）
- 統一的詳情頁面設計模式（凍結 Header + 子頁籤）
- 完善的狀態管理架構（Provider 模式）

---

### 📅 近期進展 (2025-12-09)

#### Commit: `294de96` - 測試腳本、安全通知與 Commit Log
**日期**: 2025-12-09  
**主要變更**:
- ✅ 新增測試腳本 (`test_api.sh`, `test/api_connection_test.dart`, `test/gemini_diagnostic_test.dart`)
- ✅ 建立安全通知文件 (`SECURITY_NOTICE.md`) - 處理 API Keys 洩露問題
- ✅ 新增 Commit Log 文件 (`COMMIT_LOG.md`) - 詳細記錄開發進度
- ✅ 移除硬編碼的 API Keys，改為從環境變數讀取
- ✅ 更新依賴套件，改善程式碼結構
- ✅ 將 Sample 檔案轉換為 .txt 格式

**技術改進**:
- 改善環境變數載入與錯誤處理機制
- 更新 Gemini 模型為 `gemini-flash-latest`
- 升級 `google_generative_ai` 套件至 `0.4.7`

---

#### Commit: `541d2f9` - 增強快速輸入與草稿編輯
**日期**: 2025-12-09  
**主要變更**:
- ✅ 改善快速輸入頁面的內容處理邏輯
- ✅ 更新 `_onAnalyze` 方法，新增輸入驗證
- ✅ 改善內容同步機制（從快速輸入到草稿編輯頁面）
- ✅ 修復導航狀態檢查問題

**功能改進**:
- 輸入驗證：修剪空白字符，避免空白內容觸發分析
- 狀態同步：確保內容正確傳遞到編輯頁面
- 錯誤處理：改善導航失敗時的錯誤提示

---

#### Commit: `2f8b5ae` - 重構 HomeScreen
**日期**: 2025-12-09  
**主要變更**:
- ✅ 將 HomeScreen 改為 `ConsumerStatefulWidget`，使用 Riverpod 狀態管理
- ✅ 實作文字輸入欄位與分析功能
- ✅ 新增導航到 DraftEditScreen 的功能
- ✅ 使用 `IndexedStack` 實現分頁導航（輸入頁面與草稿列表）

**架構改進**:
- 採用 Riverpod 進行狀態管理
- 使用 IndexedStack 保持 Tab 狀態
- 改善輸入處理與導航流程

---

#### Commit: `6139484` - Flutter 專案結構與核心功能
**日期**: 2025-12-08  
**主要變更**:
- ✅ 建立完整的 Flutter 專案結構
- ✅ 實作核心資料層（Database, Repositories, Services）
- ✅ 整合 Tiingo API 服務（股價資料）
- ✅ 整合 Gemini AI 服務（內容分析）
- ✅ 建立基本 UI 框架

**核心功能**:
- **資料庫**: 使用 Drift (SQLite) 進行本地資料儲存
- **API 整合**: TiingoService (股價資料) + GeminiService (AI 分析)
- **狀態管理**: Riverpod Provider 架構
- **UI 框架**: Material Design 3

---

#### Commit: `9860d5c` - 初始 Commit: Flutter MVP
**日期**: 2025-12-07  
**主要變更**:
- ✅ 初始化 Flutter 專案
- ✅ 建立專案基本結構
- ✅ 設定開發環境與依賴管理

**里程碑**:
- 從 Web 原型轉換為 Flutter 移動應用
- 確立技術架構與開發方向

---

### 📅 早期原型階段 (2025-08)

#### Commit: `1f41773` - 專案結構重組
**日期**: 2025-08-08  
- 將原型檔案移至 `Web_Prototype` 資料夾
- 重新組織專案結構

#### Commit: `27bc9b6` - Web 原型版本
**日期**: 2025-08-08  
- 建立 Github Pages 版本的互動式原型
- 實作基本的前端功能與 UI

#### Commit: `65e6cf9` - 初始專案建立
**日期**: 2025-08-04  
- 建立專案初始結構
- 新增 README 與用戶故事文件

---

## 📈 專案進度統計

### Agent Plans 狀態

根據 `.cursor/plans/stock_kol_tracker_mvp_plan_e9a29f9c.plan.md`：

| 狀態 | 數量 | 百分比 |
|------|------|--------|
| ✅ 已完成 | 4 | 36.4% |
| 🔄 進行中 | 1 | 9.1% |
| ⏳ 待處理 | 6 | 54.5% |
| **總計** | **11** | **100%** |

### 已完成階段

1. ✅ **Phase 1**: 專案初始化與資料庫架構
   - Flutter 專案初始化
   - Drift Database 設定
   - 資料庫 Schema 設計

2. ✅ **Phase 2**: 基礎設施建立
   - TiingoService 實作（股價資料獲取與快取）
   - GeminiService 實作（AI 內容分析）

3. ✅ **導覽架構重構** (2024-12-08)
   - 實現 4 個底部 Tab 導覽架構
   - 完成所有主要頁面（快速輸入、KOL、投資標的、更多）
   - 實現 KOL 列表、股票列表、文檔列表功能
   - 完成導航流程測試與驗證

### 進行中階段

4. 🔄 **Phase 3**: 核心功能 - 輸入流
   - UI 輸入頁面：✅ 已完成
   - **自動填入邏輯：進行中** ⬅️ 當前焦點
   - Review 與儲存：待處理

### 待處理階段

5. ⏳ **Phase 4**: 核心功能 - 分析與 UI
   - K 線圖與標記繪製
   - 回測邏輯（勝率計算）

6. ⏳ **Phase 5**: 優化與完善
   - 錯誤處理
   - UI 優化

---

## 🎯 核心功能

### 已實現功能

- ✅ **快速輸入**: 支援文字輸入與自動暫存
- ✅ **草稿管理**: 自動暫存、手動儲存、草稿列表
- ✅ **AI 分析**: 整合 Gemini AI 進行內容分析
- ✅ **資料庫**: 本地 SQLite 資料儲存
- ✅ **API 整合**: Tiingo (股價) + Gemini (AI 分析)
- ✅ **狀態管理**: Riverpod 狀態管理架構
- ✅ **導覽架構**: 4 個底部 Tab 導覽（快速輸入、KOL、投資標的、更多）
- ✅ **KOL 管理**: KOL 列表、詳情頁面、搜尋功能
- ✅ **投資標的管理**: 股票列表、詳情頁面、搜尋功能
- ✅ **文檔管理**: 文檔列表與詳情頁面

### 開發中功能

- 🔄 **自動填入**: AI 分析結果自動填入表單
- 🔄 **預覽功能**: 文檔發布前預覽

### 計劃功能

- ⏳ **K 線圖**: 整合股價走勢圖與文檔標記
- ⏳ **回測功能**: 計算 KOL 預測準確率
- ⏳ **勝率統計**: 5/30/90 日後漲跌幅分析

---

## 🛠️ 技術架構

### 技術棧

- **Framework**: Flutter (跨平台移動應用)
- **狀態管理**: Riverpod
- **本地資料庫**: Drift (基於 SQLite)
- **網路請求**: Dio
- **AI 服務**: Google Gemini API
- **股價資料**: Tiingo API

### 專案結構

```
lib/
├── core/              # 核心工具類
│   └── utils/         # 工具函數（日期時間格式化、相對時間解析）
├── data/              # 資料層
│   ├── database/      # 資料庫定義（Drift）
│   ├── models/        # 資料模型
│   ├── repositories/  # 資料存取層（KOL, Post, Stock）
│   └── services/      # 外部服務整合（Tiingo, Gemini）
├── domain/            # 業務邏輯層
│   └── providers/     # Riverpod Providers（狀態管理）
└── presentation/      # UI 層
    ├── screens/        # 頁面
    │   ├── home/      # 主頁（底部導覽容器）
    │   ├── input/     # 輸入相關（快速輸入、草稿列表、編輯、預覽）
    │   ├── kol/       # KOL 相關（列表、詳情）
    │   ├── stocks/    # 股票相關（列表、詳情）
    │   ├── posts/     # 文檔相關（列表、詳情）
    │   └── more/      # 更多功能
    └── widgets/        # 可重用組件
```

---

## 📝 相關文件

- [COMMIT_LOG.md](./COMMIT_LOG.md) - 詳細的 Commit 記錄與功能說明
- [SECURITY_NOTICE.md](./SECURITY_NOTICE.md) - 安全注意事項與 API Keys 管理
- [BACKLOG.md](./BACKLOG.md) - 產品待辦清單與用戶故事
- [PROJECT_MASTER_PLAN.md](./PROJECT_MASTER_PLAN.md) - 專案主計劃文件
- [IMPLEMENTATION_REPORT.md](./IMPLEMENTATION_REPORT.md) - APP 導覽架構重構實施報告
- [NAVIGATION_TEST_SUMMARY.md](./NAVIGATION_TEST_SUMMARY.md) - 導航架構測試總結
- [.cursor/plans/](./.cursor/plans/) - Agent 執行計劃

---

## 🔐 安全注意事項

⚠️ **重要**: 請勿在程式碼中硬編碼 API Keys！

- 所有 API Keys 應存放在 `.env` 檔案中
- `.env` 檔案已加入 `.gitignore`
- 請參考 `SECURITY_NOTICE.md` 了解詳細的安全指南

---

## 📄 授權

本專案為個人開發專案。

---

## 👤 作者

- **GitHub**: [@alan8983](https://github.com/alan8983)

---

## 🙏 致謝

- Google Gemini API - AI 內容分析
- Tiingo - 股價資料服務
- Flutter 社群 - 優秀的開源框架與工具
