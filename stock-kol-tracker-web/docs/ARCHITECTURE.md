# 架構決策記錄 (Architecture Decision Records)

本文檔記錄所有重要的架構決策和技術選型。

## 系統架構

### 整體架構

```
[前端 Next.js on Firebase App Hosting]
    ↓
[Firebase Platform]
    ├── App Hosting (SSR/SSG)
    ├── API Routes
    └── CDN
    ↓
[Supabase Platform]
    ├── Auth
    ├── PostgreSQL (with RLS)
    └── Edge Functions
    ↓
[外部服務]
    ├── Gemini API
    └── Tiingo API
```

## 技術選型

### 前端框架

- **選擇**：Next.js 14+ (App Router)
- **理由**：
  - SSG/SSR 混合支援，適合 SEO
  - App Router 提供更好的路由和資料獲取體驗
  - 與 Vercel 整合良好

### 部署平台

- **選擇**：Firebase App Hosting
- **理由**：
  - Google 生態系整合（GCP、Secret Manager）
  - 原生支援 Next.js App Router 和 SSR
  - GitHub 自動部署（推送即部署）
  - Pull Request 預覽環境
  - 亞洲區域部署（低延遲）

### 資料庫

- **選擇**：Supabase (PostgreSQL)
- **理由**：
  - 成本可控（免費方案）
  - 內建 RLS (Row Level Security)
  - 即時訂閱支援
  - 與 Auth 整合

### 認證

- **選擇**：Supabase Auth
- **理由**：
  - 與資料庫整合
  - 支援 Email + OAuth
  - 免費方案足夠

### 狀態管理

- **選擇**：Zustand + TanStack Query
- **理由**：
  - 輕量級
  - TanStack Query 提供優秀的快取管理
  - 支援樂觀更新

### K線圖套件

- **選擇**：TradingView Lightweight Charts
- **理由**：
  - 輕量、高效能
  - API 友好
  - 免費、開源
  - 專業的金融圖表功能

### 樣式方案

- **選擇**：Tailwind CSS + shadcn/ui
- **理由**：
  - 快速開發
  - 一致性設計
  - 可客製化
  - 組件豐富

### 表單處理

- **選擇**：React Hook Form + Zod
- **理由**：
  - 類型安全
  - 驗證整合
  - 效能優異

### 付款整合

- **選擇**：LemonSqueezy 或 Stripe
- **理由**：
  - 處理訂閱
  - 發票管理
  - 退款處理

## 目錄結構

採用 Next.js App Router 標準結構，不使用 `src/` 目錄：

```
app/                    # Next.js App Router
├── (marketing)/        # 行銷頁面（SSG, SEO優化）
├── (auth)/             # 認證相關頁面
├── (app)/              # 主要功能頁面（需登入）
└── api/                # API Routes

components/             # UI元件
├── ui/                 # 基礎元件 (shadcn/ui)
├── charts/             # 圖表元件
├── forms/              # 表單元件
└── layout/             # 佈局元件

domain/                 # 領域層（核心業務邏輯）
├── models/             # 領域模型 TypeScript Types
├── services/           # 業務邏輯服務
├── validators/         # 驗證規則 + Invariants
└── calculators/        # 計算邏輯（勝率、漲跌幅）

infrastructure/         # 基礎設施層
├── supabase/           # Supabase Client 設定
├── api/                # 外部 API 客戶端
└── repositories/       # 資料存取層

hooks/                  # React Hooks
stores/                 # Zustand Stores
lib/                    # 工具函數

supabase/               # Supabase 設定
├── migrations/         # 資料庫遷移腳本
└── functions/          # Edge Functions

docs/                   # 規格文件（Agent 約束）
```

## 成本控制策略

1. **Gemini API**：免費用戶限制 10 次/月，超出後提示升級
2. **Tiingo API**：股價快取 7 天，減少 API 調用
3. **勝率計算**：每日凌晨批次計算，而非即時
4. **監控**：設定 Supabase 用量告警

## 安全策略

1. **RLS (Row Level Security)**：所有資料表啟用 RLS，強制用戶資料隔離
2. **API Key 保護**：所有外部 API Key 存放在環境變數中
3. **Session 管理**：使用 Supabase Auth Session，自動處理過期
4. **輸入驗證**：使用 Zod 進行所有輸入驗證

## 效能優化

1. **SSG**：行銷頁面使用靜態生成
2. **ISR**：股價資料使用增量靜態再生
3. **CDN**：Firebase CDN 快取靜態資源
4. **資料分頁**：列表頁面使用分頁載入
