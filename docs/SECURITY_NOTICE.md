# 🚨 安全警告：API Keys 洩露處理指南

## 問題概述

在專案歷史記錄中發現硬編碼的真實 API Keys 已被提交到版本控制系統。這些憑證可能已被他人存取，需要立即處理。

## 已洩露的 API Keys（已處理）

1. **Tiingo API Token**: `2037c4...` ✅ **已更換**（已撤銷）
2. **Gemini API Key**: `[已撤銷的舊 Key]` ✅ **已撤銷並更換**（已撤銷）

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
# 注意：實際的 API Keys 已從此文件中移除，僅保留部分識別字元
# 2037c4...==REMOVED_TIINGO_TOKEN
# [已撤銷的 Gemini API Key]==REMOVED_GEMINI_KEY

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
4. ✅ **已建立 Git pre-commit hook** - 自動檢測並阻止 API Keys 被提交
5. ✅ 已更換所有洩露的 API Keys

#### Git Pre-commit Hook 使用說明：

專案已自動設置 pre-commit hook（位於 `.git/hooks/pre-commit`），會在每次提交前檢查：

- 是否意外將 `.env` 檔案加入提交
- 程式碼中是否包含 Gemini API Key 格式（以 `AIza` 開頭）
- 程式碼中是否包含其他 API Key 模式

**如果檢測到敏感資訊，提交會被自動阻止。**

若需要繞過檢查（僅在確定安全的情況下）：
```bash
git commit --no-verify
```

**⚠️ 警告**：除非您非常確定沒有敏感資訊，否則不建議使用 `--no-verify`。

#### 如何在其他開發者的電腦上啟用 hook：

當其他開發者 clone 此專案後，請執行：
```bash
chmod +x .git/hooks/pre-commit
```

或者將 hook 複製到正確位置（如果 hook 檔案存在於專案中）。

#### 未來開發建議：
1. **永遠不要**在程式碼中硬編碼 API Keys
2. **永遠不要**將包含真實 API Keys 的檔案提交到版本控制
3. 使用 `.env` 檔案管理敏感資訊
4. 定期檢查 Git 歷史中是否有敏感資訊
5. 信任 pre-commit hook 的檢查，不要輕易使用 `--no-verify`
6. 考慮使用密碼管理工具（如 1Password, Bitwarden）管理 API Keys
7. 定期更換 API Keys（建議每 3-6 個月）

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

**最後更新**: 2024-12-10  
**狀態**: 🟢 已處理並實施防護措施

### 更新紀錄：
- 2024-12-10: 已撤銷並更換洩露的 API Keys
- 2024-12-10: 已建立 Git pre-commit hook 防止未來洩露
- 2024-12-10: 驗證新 API Keys 正常運作
