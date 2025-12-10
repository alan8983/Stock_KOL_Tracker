#!/bin/bash
#
# 設置 Git Hooks 腳本
# 此腳本會為專案設置必要的 Git hooks，包括 pre-commit hook
#

echo "🔧 開始設置 Git hooks..."

# 檢查是否在 Git 專案根目錄
if [ ! -d ".git" ]; then
    echo "❌ 錯誤: 請在 Git 專案根目錄執行此腳本"
    exit 1
fi

# 檢查 hooks 目錄是否存在
if [ ! -d ".git/hooks" ]; then
    echo "📁 建立 .git/hooks 目錄..."
    mkdir -p .git/hooks
fi

# 設置 pre-commit hook 的執行權限
if [ -f ".git/hooks/pre-commit" ]; then
    echo "✅ 設置 pre-commit hook 執行權限..."
    chmod +x .git/hooks/pre-commit
    echo "✅ Pre-commit hook 已設置完成"
else
    echo "⚠️  警告: 找不到 pre-commit hook 檔案"
    echo "   請確保已正確 clone 專案"
fi

echo ""
echo "════════════════════════════════════════════════════"
echo "  Git Hooks 設置完成！"
echo "════════════════════════════════════════════════════"
echo ""
echo "已啟用的保護措施："
echo "  ✓ Pre-commit hook - 防止 API keys 洩露"
echo ""
echo "這些 hooks 會在您提交程式碼前自動檢查："
echo "  • .env 檔案是否被意外加入"
echo "  • 程式碼中是否包含 API keys"
echo ""
echo "如需繞過檢查（僅在確定安全時）："
echo "  git commit --no-verify"
echo ""

