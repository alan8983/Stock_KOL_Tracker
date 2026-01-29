# Stock KOL Tracker Web

Stock KOL Tracker 的 Web 版本，使用 Next.js 14 + Supabase + Firebase App Hosting 架構。

## 🚀 快速開始

### 環境需求

- Node.js 20+
- npm 或 yarn
- Supabase 專案（免費方案即可）

### 安裝步驟

1. **克隆專案**
   ```bash
   git clone <repository-url>
   cd stock-kol-tracker-web
   ```

2. **安裝依賴**
   ```bash
   npm install
   ```

3. **設定環境變數**
   ```bash
   cp .env.example .env
   # 編輯 .env 檔案，填入您的 Supabase 和 API Keys
   ```

4. **執行開發伺服器**
   ```bash
   npm run dev
   ```

5. **開啟瀏覽器**
   訪問 [http://localhost:3000](http://localhost:3000)

## 📁 專案結構

```
stock-kol-tracker-web/
├── app/                    # Next.js App Router
│   ├── (marketing)/        # 行銷頁面
│   ├── (auth)/             # 認證頁面
│   ├── (app)/              # 主要功能頁面
│   └── api/                # API Routes
├── components/             # UI 元件
├── domain/                 # 領域層（業務邏輯）
├── infrastructure/         # 基礎設施層
├── hooks/                  # React Hooks
├── stores/                 # Zustand Stores
├── lib/                    # 工具函數
├── supabase/               # Supabase 設定
│   └── migrations/         # 資料庫遷移
└── docs/                   # 規格文件
```

## 🔧 開發

### 資料庫遷移

1. **連接到 Supabase**
   ```bash
   npx supabase link --project-ref <project-ref>
   ```

2. **執行遷移**
   ```bash
   npx supabase db push
   ```

### 類型生成

從 Supabase 生成 TypeScript 類型：

```bash
npx supabase gen types typescript --project-id <project-id> > domain/models/database.types.ts
```

## 📚 規格文件

所有規格文件位於 `docs/` 目錄：

- [DOMAIN_MODELS.md](./docs/DOMAIN_MODELS.md) - 領域模型定義
- [API_SPEC.md](./docs/API_SPEC.md) - API 規格
- [INVARIANTS.md](./docs/INVARIANTS.md) - 不變量規則
- [ARCHITECTURE.md](./docs/ARCHITECTURE.md) - 架構決策記錄

## 🚢 部署

### Firebase App Hosting 部署

詳細設定請參考 [FIREBASE_SETUP.md](./docs/FIREBASE_SETUP.md)

#### 快速步驟

1. **建立 Firebase 專案**
   - 前往 [Firebase Console](https://console.firebase.google.com/)
   - 建立新專案：`stock-kol-tracker-web`

2. **啟用 App Hosting 並連結 GitHub**
   - Firebase Console → Build → App Hosting
   - 連結 GitHub Repository
   - 選擇 `main` 分支

3. **設定環境變數（Secrets）**
   ```bash
   # 安裝 Firebase CLI
   npm install -g firebase-tools
   
   # 登入並設定 Secrets
   firebase login
   firebase use stock-kol-tracker-web
   firebase apphosting:secrets:set SUPABASE_URL
   firebase apphosting:secrets:set SUPABASE_ANON_KEY
   firebase apphosting:secrets:set SUPABASE_SERVICE_ROLE_KEY
   firebase apphosting:secrets:set GEMINI_API_KEY
   firebase apphosting:secrets:set TIINGO_API_TOKEN
   ```

4. **自動部署**
   - 推送到 `main` 分支會自動觸發部署
   - 建立 Pull Request 會自動建立預覽環境

### 環境變數說明

| 變數名稱 | 說明 | 來源 |
|---------|------|------|
| `NEXT_PUBLIC_SUPABASE_URL` | Supabase 專案 URL | Supabase Dashboard |
| `NEXT_PUBLIC_SUPABASE_ANON_KEY` | Supabase 公開金鑰 | Supabase Dashboard |
| `SUPABASE_SERVICE_ROLE_KEY` | Supabase 私密金鑰 | Supabase Dashboard |
| `GEMINI_API_KEY` | Gemini API 金鑰 | Google AI Studio |
| `TIINGO_API_TOKEN` | Tiingo API Token | Tiingo |

## 📝 授權

本專案為個人開發專案。
