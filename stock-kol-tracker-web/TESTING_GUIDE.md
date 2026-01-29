# 測試指南

## 📋 目前狀態

✅ **前端已建立完成**（Phase 1-4）
- 認證系統（登入/註冊）
- 快速輸入與 AI 分析
- 草稿管理
- KOL 管理
- Stock 管理
- 文檔管理

⚠️ **需要設定後端才能測試**
- Supabase 專案設定
- 環境變數設定
- 資料庫遷移

## 🚀 快速測試步驟

### 1. 建立 Supabase 專案

1. 前往 [Supabase](https://supabase.com/)
2. 登入或註冊帳號
3. 點選 "New Project"
4. 填寫專案資訊並建立

### 2. 執行資料庫遷移

1. 在 Supabase Dashboard 中，前往 **SQL Editor**
2. 開啟 `supabase/migrations/20250130000000_initial_schema.sql`
3. 複製所有 SQL 內容
4. 在 SQL Editor 中貼上並執行

### 3. 設定環境變數

1. 複製環境變數範例：
   ```bash
   cp .env.example .env
   ```

2. 編輯 `.env` 檔案，填入以下資訊：
   ```env
   # 從 Supabase Dashboard > Settings > API 取得
   NEXT_PUBLIC_SUPABASE_URL=https://your-project.supabase.co
   NEXT_PUBLIC_SUPABASE_ANON_KEY=your-anon-key
   SUPABASE_SERVICE_ROLE_KEY=your-service-role-key

   # 從 Google AI Studio 取得
   GEMINI_API_KEY=your-gemini-api-key

   # 從 Tiingo 取得（可選，Phase 5 才需要）
   TIINGO_API_TOKEN=your-tiingo-token

   # 本地開發
   NEXT_PUBLIC_APP_URL=http://localhost:3000
   ```

### 4. 安裝依賴並啟動

```bash
cd stock-kol-tracker-web
npm install
npm run dev
```

### 5. 開啟瀏覽器測試

訪問 [http://localhost:3000](http://localhost:3000)

## 🧪 測試流程

### 基本功能測試

1. **註冊/登入**
   - 訪問 `/auth/register` 註冊新帳號
   - 或訪問 `/auth/login` 登入

2. **快速輸入**
   - 訪問 `/input` 或 `/app/input`
   - 貼上 KOL 發言內容
   - 點擊「AI 分析」
   - 查看分析結果

3. **草稿管理**
   - 訪問 `/posts` 或 `/app/posts`
   - 查看草稿列表
   - 點擊「編輯」修改草稿
   - 點擊「發布」發布文檔

4. **KOL 管理**
   - 訪問 `/kols` 或 `/app/kols`
   - 點擊「新增 KOL」建立新 KOL
   - 點擊 KOL 卡片查看詳情

5. **Stock 管理**
   - 訪問 `/stocks` 或 `/app/stocks`
   - 查看股票列表
   - 點擊股票卡片查看詳情

## ⚠️ 注意事項

### 目前無法測試的功能

- **AI 分析**：需要有效的 Gemini API Key
- **K線圖**：將在 Phase 5 實作
- **勝率統計**：將在 Phase 5 實作
- **股價資料**：需要 Tiingo API Token（Phase 5）

### 可以測試的功能

- ✅ 認證流程（登入/註冊）
- ✅ 基本 CRUD 操作（KOL、Stock、Post）
- ✅ 搜尋功能
- ✅ 頁面導航
- ✅ UI 互動

## 🚢 部署到 Vercel（生產環境測試）

### 1. 推送到 GitHub

```bash
git init
git add .
git commit -m "Initial commit"
git remote add origin <your-repo-url>
git push -u origin main
```

### 2. 在 Vercel 中匯入專案

1. 前往 [Vercel](https://vercel.com/)
2. 點選 "Add New Project"
3. 選擇 GitHub Repository
4. 設定環境變數（與 `.env` 相同）
5. 部署

### 3. 設定 Supabase Redirect URLs

在 Supabase Dashboard > Authentication > URL Configuration：
- 新增 Vercel 部署 URL 到 Redirect URLs

## 📝 測試檢查清單

- [ ] Supabase 專案建立
- [ ] 資料庫遷移執行
- [ ] 環境變數設定
- [ ] 本地開發伺服器啟動
- [ ] 註冊/登入功能
- [ ] 快速輸入功能
- [ ] 草稿管理功能
- [ ] KOL 管理功能
- [ ] Stock 管理功能
- [ ] 搜尋功能
- [ ] 頁面導航

## 🐛 常見問題

### 問題：無法連接到 Supabase

**解決方案**：
- 檢查 `NEXT_PUBLIC_SUPABASE_URL` 是否正確
- 檢查 `NEXT_PUBLIC_SUPABASE_ANON_KEY` 是否正確
- 確認 Supabase 專案狀態為 Active

### 問題：認證失敗

**解決方案**：
- 檢查 Supabase Auth 設定
- 確認 Redirect URLs 設定正確
- 檢查瀏覽器 Console 錯誤訊息

### 問題：AI 分析失敗

**解決方案**：
- 檢查 `GEMINI_API_KEY` 是否正確
- 確認 API Key 有足夠配額
- 檢查 API Route 日誌

## 📚 相關文件

- [Supabase 設定指南](./supabase/SETUP.md)
- [Phase 1 完成總結](./docs/PHASE1_COMPLETION.md)
- [Phase 2 完成總結](./docs/PHASE2_COMPLETION.md)
- [Phase 3 完成總結](./docs/PHASE3_COMPLETION.md)
- [Phase 4 完成總結](./docs/PHASE4_COMPLETION.md)
