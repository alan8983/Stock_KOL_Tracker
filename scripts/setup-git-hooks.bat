@echo off
REM 設置 Git Hooks 腳本 (Windows 版本)
REM 此腳本會為專案設置必要的 Git hooks，包括 pre-commit hook

echo 🔧 開始設置 Git hooks...

REM 檢查是否在 Git 專案根目錄
if not exist ".git" (
    echo ❌ 錯誤: 請在 Git 專案根目錄執行此腳本
    exit /b 1
)

REM 檢查 hooks 目錄是否存在
if not exist ".git\hooks" (
    echo 📁 建立 .git\hooks 目錄...
    mkdir .git\hooks
)

REM Windows 上不需要設置執行權限，但可以驗證檔案存在
if exist ".git\hooks\pre-commit" (
    echo ✅ Pre-commit hook 已就緒
) else (
    echo ⚠️  警告: 找不到 pre-commit hook 檔案
    echo    請確保已正確 clone 專案
)

echo.
echo ════════════════════════════════════════════════════
echo   Git Hooks 設置完成！
echo ════════════════════════════════════════════════════
echo.
echo 已啟用的保護措施：
echo   ✓ Pre-commit hook - 防止 API keys 洩露
echo.
echo 這些 hooks 會在您提交程式碼前自動檢查：
echo   • .env 檔案是否被意外加入
echo   • 程式碼中是否包含 API keys
echo.
echo 如需繞過檢查（僅在確定安全時）：
echo   git commit --no-verify
echo.

