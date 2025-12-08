#!/bin/bash

# API 連線測試腳本
# 用途：快速測試 Tiingo 與 Gemini API 的連線狀態

echo "================================"
echo "Stock KOL Tracker - API 連線測試"
echo "================================"
echo ""

# 確認專案依賴
echo "📦 檢查 Flutter 依賴..."
flutter pub get

echo ""
echo "🧪 開始執行 API 連線測試..."
echo ""

# 執行測試
flutter test test/api_connection_test.dart --reporter=expanded

echo ""
echo "================================"
echo "測試完成"
echo "================================"
