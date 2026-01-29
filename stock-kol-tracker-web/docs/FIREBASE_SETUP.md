# Firebase App Hosting 設定指南

本指南說明如何建立 Firebase 專案並使用 App Hosting 部署 Next.js 應用程式。

## 前置條件

- Google 帳號
- GitHub 帳號（用於連結自動部署）
- 已完成 Supabase 設定（參考 `supabase/SETUP.md`）

## 1. 建立 Firebase 專案

1. 前往 [Firebase Console](https://console.firebase.google.com/)
2. 點選「建立專案」或「Add project」
3. 填寫專案資訊：
   - **專案名稱**: `stock-kol-tracker-web`
   - **專案 ID**: 自動生成或自訂（例如：`stock-kol-tracker-web`）
4. Google Analytics 設定（選填，可跳過）
5. 點選「建立專案」，等待專案建立完成

## 2. 啟用 App Hosting

1. 在 Firebase Console 中，選擇剛建立的專案
2. 在左側選單中，找到「Build」→「App Hosting」
3. 點選「Get started」開始設定

### 2.1 連結 GitHub Repository

1. 點選「Connect to GitHub」
2. 授權 Firebase 存取您的 GitHub 帳號
3. 選擇 Repository：`alan8983/stock-kol-tracker-web`（或您的 Repository 名稱）
4. 選擇分支：`main`（或 `master`）

### 2.2 設定建置選項

- **Root directory**: `.`（專案根目錄）
- **Live branch**: `main`
- **Automatic rollouts**: 啟用（推送到 main 時自動部署）
- **Preview channels**: 啟用（PR 自動建立預覽環境）

### 2.3 設定區域

選擇最接近用戶的區域：
- **推薦**: `asia-east1`（台灣）或 `asia-northeast1`（東京）

## 3. 設定環境變數（Secrets）

Firebase App Hosting 使用 Google Cloud Secret Manager 管理敏感環境變數。

### 3.1 透過 Firebase CLI 設定

```bash
# 安裝 Firebase CLI（如果尚未安裝）
npm install -g firebase-tools

# 登入 Firebase
firebase login

# 選擇專案
firebase use stock-kol-tracker-web

# 設定 Secrets
firebase apphosting:secrets:set SUPABASE_URL
# 輸入您的 Supabase Project URL

firebase apphosting:secrets:set SUPABASE_ANON_KEY
# 輸入您的 Supabase anon public key

firebase apphosting:secrets:set SUPABASE_SERVICE_ROLE_KEY
# 輸入您的 Supabase service_role key

firebase apphosting:secrets:set GEMINI_API_KEY
# 輸入您的 Gemini API Key

firebase apphosting:secrets:set TIINGO_API_TOKEN
# 輸入您的 Tiingo API Token
```

### 3.2 透過 Google Cloud Console 設定（替代方案）

1. 前往 [Google Cloud Console - Secret Manager](https://console.cloud.google.com/security/secret-manager)
2. 選擇對應的 Firebase 專案
3. 點選「Create Secret」
4. 建立以下 Secrets：
   - `SUPABASE_URL`
   - `SUPABASE_ANON_KEY`
   - `SUPABASE_SERVICE_ROLE_KEY`
   - `GEMINI_API_KEY`
   - `TIINGO_API_TOKEN`

### 3.3 Secret 值對照表

| Secret 名稱 | 來源 | 說明 |
|------------|------|------|
| `SUPABASE_URL` | Supabase Dashboard → Settings → API → Project URL | Supabase 專案 URL |
| `SUPABASE_ANON_KEY` | Supabase Dashboard → Settings → API → anon public | 公開金鑰，可在前端使用 |
| `SUPABASE_SERVICE_ROLE_KEY` | Supabase Dashboard → Settings → API → service_role | 私密金鑰，僅用於後端 |
| `GEMINI_API_KEY` | [Google AI Studio](https://aistudio.google.com/apikey) | Gemini API 金鑰 |
| `TIINGO_API_TOKEN` | [Tiingo](https://www.tiingo.com/) | 股價 API Token |

## 4. 配置文件說明

### 4.1 apphosting.yaml

此文件定義 App Hosting 的運行配置和環境變數映射：

```yaml
runConfig:
  runtime: nodejs20        # Node.js 版本
  concurrency: 80          # 每個實例的並發請求數
  cpu: 1                   # CPU 數量
  memoryMiB: 512           # 記憶體大小（MB）
  minInstances: 0          # 最小實例數（0 = 可縮減至零）
  maxInstances: 10         # 最大實例數

env:
  - variable: NEXT_PUBLIC_SUPABASE_URL
    secret: SUPABASE_URL
  - variable: NEXT_PUBLIC_SUPABASE_ANON_KEY
    secret: SUPABASE_ANON_KEY
  - variable: SUPABASE_SERVICE_ROLE_KEY
    secret: SUPABASE_SERVICE_ROLE_KEY
  - variable: GEMINI_API_KEY
    secret: GEMINI_API_KEY
  - variable: TIINGO_API_TOKEN
    secret: TIINGO_API_TOKEN
```

### 4.2 firebase.json

此文件定義 Firebase 專案的整體配置：

```json
{
  "hosting": {
    "source": ".",
    "ignore": ["firebase.json", "**/.*", "**/node_modules/**"]
  }
}
```

## 5. 部署流程

### 5.1 自動部署（推薦）

設定完成後，每次推送到 `main` 分支都會自動觸發部署：

```bash
git add .
git commit -m "feat: add new feature"
git push origin main
```

部署狀態可在 Firebase Console → App Hosting 中查看。

### 5.2 手動部署

如需手動觸發部署：

```bash
# 安裝 Firebase CLI
npm install -g firebase-tools

# 登入
firebase login

# 部署
firebase apphosting:backends:create --project stock-kol-tracker-web
```

### 5.3 預覽部署（PR Preview）

建立 Pull Request 時，Firebase 會自動建立預覽環境：

1. 在 GitHub 建立 Pull Request
2. Firebase 自動建置並部署到預覽 URL
3. PR 頁面會顯示預覽連結
4. 合併 PR 後，預覽環境自動清理

## 6. 更新 Supabase Redirect URLs

部署完成後，需要更新 Supabase 的 OAuth 重定向 URL：

1. 取得 Firebase App Hosting 的網域（例如：`stock-kol-tracker-web.web.app`）
2. 前往 Supabase Dashboard → Authentication → URL Configuration
3. 在 **Redirect URLs** 中新增：
   ```
   https://stock-kol-tracker-web.web.app/auth/callback
   ```
4. 更新 **Site URL**（生產環境）：
   ```
   https://stock-kol-tracker-web.web.app
   ```

## 7. 驗證部署

### 7.1 檢查部署狀態

1. 前往 Firebase Console → App Hosting
2. 確認最新部署狀態為「Success」
3. 點選部署的 URL 訪問網站

### 7.2 測試功能

1. 訪問首頁，確認載入正常
2. 測試登入/註冊功能
3. 測試 AI 分析功能
4. 確認資料庫連線正常

## 8. 監控與日誌

### 8.1 查看日誌

```bash
# 使用 Firebase CLI 查看日誌
firebase apphosting:backends:logs --project stock-kol-tracker-web
```

或在 Google Cloud Console → Logging 中查看。

### 8.2 監控指標

Firebase Console → App Hosting 提供以下指標：
- 請求數量
- 響應時間
- 錯誤率
- 實例數量

## 9. 成本說明

Firebase App Hosting 計費方式：

| 項目 | 免費額度 | 超出費用 |
|------|----------|----------|
| 建置時間 | 120 分鐘/天 | $0.003/分鐘 |
| 頻寬 | 10 GB/月 | $0.15/GB |
| 儲存 | 10 GB | $0.026/GB |
| 實例時間 | 依 Cloud Run 計費 | 依使用量 |

**成本控制建議**：
- 設定 `minInstances: 0` 允許縮減至零
- 監控每月用量
- 設定預算警報

## 10. 常見問題

### Q1: 部署失敗，顯示 "Build failed"

**解決方案**：
1. 檢查 `package.json` 中的 `build` 腳本
2. 確認本地執行 `npm run build` 成功
3. 檢查環境變數是否正確設定

### Q2: 網站載入但資料庫連線失敗

**解決方案**：
1. 確認 Secrets 已正確設定
2. 檢查 `apphosting.yaml` 中的環境變數映射
3. 確認 Supabase RLS 政策正確

### Q3: OAuth 登入失敗

**解決方案**：
1. 確認 Supabase Redirect URLs 已更新
2. 檢查 Google OAuth 憑證中的授權重新導向 URI
3. 確認 `NEXT_PUBLIC_APP_URL` 環境變數正確

## 11. 相關資源

- [Firebase App Hosting 官方文檔](https://firebase.google.com/docs/app-hosting)
- [Next.js on Firebase](https://firebase.google.com/docs/app-hosting/get-started)
- [Firebase CLI 參考](https://firebase.google.com/docs/cli)
- [Google Cloud Secret Manager](https://cloud.google.com/secret-manager/docs)
