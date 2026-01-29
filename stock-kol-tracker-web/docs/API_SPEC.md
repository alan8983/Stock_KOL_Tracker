# API 規格 (API Specification)

本文檔定義所有 API 端點的契約，前後端開發必須共同遵守。

## 外部 API

### Gemini API

- **用途**：AI 文本分析
- **端點**：`/api/ai/analyze` (Next.js API Route 代理)
- **方法**：POST
- **請求體**：
  ```typescript
  {
    content: string;
  }
  ```
- **回應**：
  ```typescript
  {
    sentiment: 'Bullish' | 'Bearish' | 'Neutral';
    kolName?: string;
    postedAtText?: string;
    stockTicker?: string;
    analysis: Record<string, unknown>;
  }
  ```

### Tiingo API

- **用途**：股價資料獲取
- **端點**：`/api/stocks/[ticker]` (Next.js API Route 代理)
- **方法**：GET
- **查詢參數**：
  - `ticker`: string (股票代碼)
  - `startDate?`: string (ISO 日期)
  - `endDate?`: string (ISO 日期)
- **回應**：
  ```typescript
  {
    ticker: string;
    prices: StockPrice[];
  }
  ```

## Supabase API

### Auth API

- **用途**：用戶認證
- **端點**：Supabase Auth (透過 `@supabase/ssr`)
- **功能**：
  - Email/Password 登入
  - Google OAuth
  - Session 管理

### Database API

- **用途**：資料儲存
- **端點**：Supabase PostgreSQL (透過 `@supabase/supabase-js`)
- **表**：
  - `profiles`
  - `kols`
  - `stocks`
  - `posts`
  - `stock_prices`

## 內部 API Routes

### `/api/ai/analyze`

- **方法**：POST
- **認證**：需要（檢查用戶配額）
- **請求體**：`{ content: string }`
- **回應**：`AnalysisResult`

### `/api/stocks/[ticker]`

- **方法**：GET
- **認證**：可選（公開股價資料）
- **查詢參數**：`startDate?`, `endDate?`
- **回應**：`StockPrice[]`

### `/api/webhooks/*`

- **用途**：處理外部 Webhook
- **認證**：根據 Webhook 類型決定

## 錯誤處理

所有 API 回應應遵循以下格式：

```typescript
// 成功
{
  data: T;
}

// 錯誤
{
  error: {
    code: string;
    message: string;
    details?: unknown;
  }
}
```

## 認證

- **Session 管理**：使用 Supabase Auth Session
- **API Routes**：透過 `createServerClient` 獲取用戶身份
- **RLS**：所有資料庫操作透過 Supabase RLS 強制執行
