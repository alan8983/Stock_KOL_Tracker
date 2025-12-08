# 🚨 安全警告：API Keys 洩露處理指南

## 問題概述

在專案歷史記錄中發現硬編碼的真實 API Keys 已被提交到版本控制系統。這些憑證可能已被他人存取，需要立即處理。

## 已洩露的 API Keys

1. **Tiingo API Token**: `2037c488ea53d7574e5036107f5c0dd1aa9810f0`
2. **Gemini API Key**: `AIzaSyBcjWsDJuzp78nLtgP4dVOc2oKgW84fcDQ`

## 立即行動步驟

### 1. 立即撤銷已洩露的 API Keys ⚠️

#### Tiingo API Token
1. 前往 [Tiingo Dashboard](https://api.tiingo.com/documentation/general/overview)
2. 登入您的帳戶
3. 找到對應的 API Token
4. **立即撤銷或刪除該 Token**
5. 建立新的 API Token
6. 更新 `.env` 檔案中的 `TIINGO_API_TOKEN`

#### Gemini API Key
1. 前往 [Google AI Studio](https://aistudio.google.com/)
2. 登入您的 Google 帳戶
3. 前往 API Keys 管理頁面
4. **立即刪除或撤銷該 API Key**
5. 建立新的 API Key
6. 更新 `.env` 檔案中的 `GEMINI_API_KEY`

### 2. 清理 Git 歷史記錄（可選但建議）

如果此專案是公開的或與他人共享，建議清理 Git 歷史記錄中的敏感資訊：

#### 方法 A: 使用 git filter-branch（適用於小型專案）
```bash
# 警告：這會重寫整個 Git 歷史，請先備份！
git filter-branch --force --index-filter \
  "git rm --cached --ignore-unmatch BACKLOG.md test/api_connection_test.dart scripts/test_gemini.dart test/gemini_diagnostic_test.dart" \
  --prune-empty --tag-name-filter cat -- --all
```

#### 方法 B: 使用 BFG Repo-Cleaner（推薦，更快速）
```bash
# 1. 安裝 BFG Repo-Cleaner
# 2. 建立替換檔案 replace.txt，內容為：
2037c488ea53d7574e5036107f5c0dd1aa9810f0==REMOVED_TIINGO_TOKEN
AIzaSyBcjWsDJuzp78nLtgP4dVOc2oKgW84fcDQ==REMOVED_GEMINI_KEY

# 3. 執行清理
java -jar bfg.jar --replace-text replace.txt

# 4. 清理並推送
git reflog expire --expire=now --all
git gc --prune=now --aggressive
git push --force --all
```

**⚠️ 重要提醒**：
- 清理 Git 歷史會影響所有協作者
- 請確保所有協作者都了解此操作
- 建議在清理前先備份整個專案

### 3. 驗證修復

已修復的檔案：
- ✅ `BACKLOG.md` - 已移除真實 API Keys，改用佔位符
- ✅ `test/api_connection_test.dart` - 改為從環境變數讀取
- ✅ `scripts/test_gemini.dart` - 改為從環境變數讀取
- ✅ `test/gemini_diagnostic_test.dart` - 改為從環境變數讀取

### 4. 預防措施

#### 已實施的安全措施：
1. ✅ `.env` 檔案已在 `.gitignore` 中
2. ✅ 所有測試檔案改為從環境變數讀取 API Keys
3. ✅ `BACKLOG.md` 中不再包含真實的 API Keys

#### 未來開發建議：
1. **永遠不要**在程式碼中硬編碼 API Keys
2. **永遠不要**將包含真實 API Keys 的檔案提交到版本控制
3. 使用 `.env` 檔案管理敏感資訊
4. 定期檢查 Git 歷史中是否有敏感資訊
5. 使用 Git hooks 或 CI/CD 工具自動檢查敏感資訊
6. 考慮使用密碼管理工具（如 1Password, Bitwarden）管理 API Keys

### 5. 監控異常活動

在撤銷舊的 API Keys 後，請監控：
- Tiingo API 使用量是否異常
- Gemini API 使用量是否異常
- 是否有未授權的 API 呼叫

## 相關資源

- [GitHub 安全最佳實踐](https://docs.github.com/en/code-security/security-advisories)
- [OWASP API Security Top 10](https://owasp.org/www-project-api-security/)
- [Git 清理敏感資料指南](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/removing-sensitive-data-from-a-repository)

---

**最後更新**: 2024-12-XX  
**狀態**: 🔴 需要立即處理
