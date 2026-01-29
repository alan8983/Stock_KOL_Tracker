# 不變量規則 (Invariants)

本文檔定義系統中必須始終保持的不變量規則，所有實作都必須遵守這些規則。

## 資料不變量

### Post 不變量

#### I1: 發布的Post必須關聯有效的KOL和Stock

```typescript
function publishedPostMustHaveValidReferences(post: Post): boolean {
  if (post.status === 'Published') {
    return post.kolId !== null && post.stockTicker !== null;
  }
  return true;
}
```

**驗證時機**：Post 狀態變更為 `Published` 時

#### I2: sentiment只能是三種值之一

```typescript
function sentimentMustBeValid(sentiment: string): boolean {
  return ['Bullish', 'Bearish', 'Neutral'].includes(sentiment);
}
```

**驗證時機**：Post 建立或更新時

#### I3: postedAt不能晚於createdAt

```typescript
function postedAtMustBeBeforeCreatedAt(post: Post): boolean {
  if (!post.postedAt) return true;
  return new Date(post.postedAt) <= new Date(post.createdAt);
}
```

**驗證時機**：Post 建立或更新時

#### I4: 每個用戶的KOL名稱必須唯一

```typescript
async function kolNameMustBeUniquePerUser(
  userId: string,
  kolName: string
): Promise<boolean> {
  // 查詢資料庫驗證
}
```

**驗證時機**：KOL 建立或更新時

## 業務規則不變量

### B1: Draft可轉Published，但不可逆

- **規則**：Post 狀態只能從 `Draft` 轉為 `Published`
- **驗證時機**：Post 狀態變更時
- **實作層級**：DB Trigger 或 Service Layer

### B2: 股價快取7天內有效

- **規則**：查詢股價時，優先使用快取，超過 7 天則重新獲取
- **驗證時機**：查詢股價時
- **實作層級**：API Route

### B3: AI分析結果必須包含sentiment

- **規則**：AI 分析完成後，結果必須包含有效的 `sentiment` 值
- **驗證時機**：AI 分析完成後
- **實作層級**：Service Layer

### B4: 用戶只能存取自己的資料

- **規則**：所有 CRUD 操作都必須透過 Supabase RLS 驗證用戶身份
- **驗證時機**：所有資料庫操作
- **實作層級**：Supabase RLS

### B5: 免費用戶AI分析 ≤ 10次/月

- **規則**：免費用戶每月 AI 分析次數不得超過 10 次
- **驗證時機**：AI API 調用時
- **實作層級**：API Route

### B6: 免費用戶KOL追蹤 ≤ 5位

- **規則**：免費用戶追蹤的 KOL 數量不得超過 5 位
- **驗證時機**：KOL 建立時
- **實作層級**：DB Trigger 或 Service Layer

## 勝率計算不變量

### I5: 勝率門檻為±2%

```typescript
const WIN_RATE_THRESHOLD = 0.02; // ±2%
```

### I6: Neutral情緒不計入勝率

```typescript
function neutralExcludedFromWinRate(sentiment: string): boolean {
  return sentiment !== 'Neutral';
}
```

### I7: 漲幅>+2%視為看漲，跌幅<-2%視為看跌

```typescript
function evaluatePrediction(
  sentiment: string,
  priceChange: number
): boolean | null {
  if (priceChange > 0.02) return sentiment === 'Bullish';
  if (priceChange < -0.02) return sentiment === 'Bearish';
  return null; // 震盪區間，不計入
}
```

## 實作要求

所有不變量必須在以下層級進行驗證：

1. **TypeScript 類型系統**：使用 Zod 進行運行時驗證
2. **Service Layer**：業務邏輯驗證
3. **Database Layer**：透過 Constraints 和 Triggers 強制執行
4. **API Layer**：請求驗證和錯誤處理
