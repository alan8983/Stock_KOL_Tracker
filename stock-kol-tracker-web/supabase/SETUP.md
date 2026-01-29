# Supabase 設定指南

## 1. 建立 Supabase 專案

1. 前往 [Supabase](https://supabase.com/)
2. 登入或註冊帳號
3. 點選 "New Project"
4. 填寫專案資訊：
   - **Name**: stock-kol-tracker-web
   - **Database Password**: 設定強密碼（請妥善保存）
   - **Region**: 選擇最接近的區域（建議選擇 `ap-southeast-1` 或 `ap-northeast-1`）
5. 等待專案建立完成（約 2 分鐘）

## 2. 執行資料庫遷移

### 方法一：使用 Supabase Dashboard

1. 在 Supabase Dashboard 中，前往 **SQL Editor**
2. 開啟 `supabase/migrations/20250130000000_initial_schema.sql`
3. 複製所有 SQL 內容
4. 在 SQL Editor 中貼上並執行

### 方法二：使用 Supabase CLI

```bash
# 安裝 Supabase CLI
npm install -g supabase

# 登入 Supabase
npx supabase login

# 連結專案
npx supabase link --project-ref <your-project-ref>

# 推送遷移
npx supabase db push
```

## 3. 設定 Authentication

### Email/Password 認證

1. 在 Supabase Dashboard 中，前往 **Authentication > Providers**
2. 確認 **Email** 提供者已啟用
3. 設定 **Email Templates**（可選）

### Google OAuth 認證

1. 在 Supabase Dashboard 中，前往 **Authentication > Providers**
2. 啟用 **Google** 提供者
3. 設定 OAuth 憑證：
   - 前往 [Google Cloud Console](https://console.cloud.google.com/)
   - 建立新專案或選擇現有專案
   - 啟用 **Google+ API**
   - 建立 **OAuth 2.0 Client ID**
   - 設定授權重新導向 URI：
     ```
     https://<your-project-ref>.supabase.co/auth/v1/callback
     ```
   - 複製 **Client ID** 和 **Client Secret**
   - 在 Supabase Dashboard 中填入這些值

### 設定 Redirect URLs

在 Supabase Dashboard 中，前往 **Authentication > URL Configuration**：

- **Site URL**: `http://localhost:3000` (開發環境) 或 `https://your-domain.com` (生產環境)
- **Redirect URLs**: 新增以下 URL：
  ```
  http://localhost:3000/auth/callback
  https://your-domain.com/auth/callback
  ```

## 4. 取得 API Keys

1. 在 Supabase Dashboard 中，前往 **Settings > API**
2. 複製以下值到 `.env` 檔案：
   - **Project URL** → `NEXT_PUBLIC_SUPABASE_URL`
   - **anon public** key → `NEXT_PUBLIC_SUPABASE_ANON_KEY`
   - **service_role** key → `SUPABASE_SERVICE_ROLE_KEY`（僅用於後端，不要暴露在前端）

## 5. 驗證設定

執行以下 SQL 查詢驗證 RLS 政策：

```sql
-- 檢查 RLS 是否啟用
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public';

-- 檢查政策
SELECT schemaname, tablename, policyname 
FROM pg_policies 
WHERE schemaname = 'public';
```

## 6. 測試認證流程

1. 啟動開發伺服器：`npm run dev`
2. 訪問 `http://localhost:3000/auth/login`
3. 測試 Email/Password 註冊和登入
4. 測試 Google OAuth（如果已設定）

## 注意事項

- **RLS 政策**：所有資料表都已啟用 RLS，確保用戶只能存取自己的資料
- **Service Role Key**：絕對不要在前端程式碼中使用，僅用於後端 API Routes
- **環境變數**：確保 `.env` 檔案已加入 `.gitignore`，不會被提交到 Git
