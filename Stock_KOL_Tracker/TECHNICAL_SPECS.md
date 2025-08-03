# 技術規格詳細說明

## 技術棧詳細配置

### 前端 (React Native)
- **版本**: React Native 0.72+
- **UI庫**: React Native Elements 或 NativeBase
- **導航**: React Navigation 6 (支援Navigation Event)
- **狀態管理**: Redux Toolkit 或 Zustand (跨頁面資料同步)
- **圖表**: React Native Chart Kit (Base64圖表支援)
- **深色主題**: 自定義深色主題配置
- **圖片處理**: react-native-image-picker (Base64轉換)
- **檔案處理**: react-native-fs (本地檔案操作)

### 後端 (Python)
- **版本**: Python 3.9+
- **框架**: FastAPI 或 Flask (JSON API支援)
- **NLP**: OpenAI GPT API (結構化分析)
- **數據處理**: pandas, numpy (資料分析)
- **API客戶端**: requests, aiohttp (外部API整合)
- **數據庫**: SQLite3 (本地存儲)
- **圖片處理**: Pillow, pytesseract (OCR功能)
- **快取**: 自定義DataCache類 (本地快取)
- **加密**: cryptography (資料加密)
- **日誌**: logging (結構化日誌)

### 開發工具
- **包管理**: npm/yarn (前端), pip (後端)
- **代碼格式化**: Prettier, Black (JSON格式支援)
- **Linting**: ESLint, Pylint (資料結構檢查)
- **版本控制**: Git (語義化提交)
- **API測試**: Postman (JSON API測試)
- **資料庫工具**: SQLite Browser (本地資料庫管理)
- **圖片處理**: ImageMagick (圖表生成)
- **效能監控**: React Native Debugger (前端除錯)

## API配置

### Alpha Vantage API
- **基礎URL**: https://www.alphavantage.co/query
- **免費限制**: 每月500次請求
- **數據格式**: JSON
- **更新頻率**: 5分鐘 (股票價格)
- **快取策略**: 1小時本地快取
- **主要端點**:
  - 日線數據: `TIME_SERIES_DAILY` (價格歷史)
  - 公司概況: `OVERVIEW` (基本資訊)
  - 搜索: `SYMBOL_SEARCH` (股票代碼查詢)
  - 即時價格: `GLOBAL_QUOTE` (當前價格)

### OpenAI GPT API
- **模型**: gpt-3.5-turbo 或 gpt-4
- **主要用途**: 投資標的識別、情緒分析、敘事生成、時間識別
- **提示詞設計**: 結構化JSON格式輸出，包含信心度評估
- **溫度設定**: 0.3 (確保分析結果一致性)
- **錯誤處理**: 重試機制和備用分析策略

## 數據庫設計詳細

### 表結構SQL (基於資料傳輸架構)
```sql
-- 用戶表
CREATE TABLE users (
    id TEXT PRIMARY KEY,
    nickname TEXT NOT NULL,
    investment_experience TEXT, -- '1-3年', '3-5年', '5年以上'
    risk_tolerance TEXT, -- 'low', 'medium', 'medium_high', 'high'
    monthly_investment REAL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- KOL表
CREATE TABLE kols (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    category TEXT, -- '科技分析師', '投資專家', '分析師'
    accuracy_rate REAL DEFAULT 0.0,
    average_return REAL DEFAULT 0.0,
    total_posts INTEGER DEFAULT 0,
    followers INTEGER DEFAULT 0,
    expertise TEXT, -- JSON格式存儲專長領域
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 投資標的表
CREATE TABLE symbols (
    id TEXT PRIMARY KEY,
    symbol TEXT NOT NULL UNIQUE,
    name TEXT NOT NULL,
    market_type TEXT NOT NULL, -- 'US', 'TW', 'CRYPTO'
    current_price REAL,
    change_percent REAL,
    last_price_update TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- KOL發言記錄表
CREATE TABLE posts (
    id TEXT PRIMARY KEY,
    kol_id TEXT NOT NULL,
    investment_target TEXT NOT NULL,
    narrative TEXT NOT NULL,
    sentiment TEXT NOT NULL, -- 'strong_bullish', 'bullish', 'neutral', 'bearish', 'strong_bearish'
    timestamp TIMESTAMP NOT NULL,
    source_type TEXT, -- 'text', 'image', 'mixed'
    user_id TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (kol_id) REFERENCES kols(id),
    FOREIGN KEY (investment_target) REFERENCES symbols(symbol),
    FOREIGN KEY (user_id) REFERENCES users(id)
);

-- 投資組合表
CREATE TABLE investments (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    symbol TEXT NOT NULL,
    buy_price REAL NOT NULL,
    current_price REAL,
    return_percent REAL,
    holding_days INTEGER,
    investment_amount REAL NOT NULL,
    current_value REAL,
    status TEXT NOT NULL, -- 'active', 'sold'
    kol_posts_count INTEGER DEFAULT 0,
    latest_narrative TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (symbol) REFERENCES symbols(symbol)
);

-- 交易記錄表
CREATE TABLE trades (
    id TEXT PRIMARY KEY,
    investment_id TEXT NOT NULL,
    type TEXT NOT NULL, -- 'buy', 'sell', 'add', 'reduce'
    amount REAL NOT NULL,
    price REAL NOT NULL,
    timestamp TIMESTAMP NOT NULL,
    reason TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (investment_id) REFERENCES investments(id)
);

-- 用戶設定表
CREATE TABLE user_settings (
    user_id TEXT PRIMARY KEY,
    notification_settings TEXT, -- JSON格式存儲通知設定
    analysis_settings TEXT, -- JSON格式存儲分析設定
    data_management TEXT, -- JSON格式存儲數據管理設定
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id)
);

-- AI分析結果表
CREATE TABLE analysis_results (
    id TEXT PRIMARY KEY,
    post_id TEXT NOT NULL,
    investment_target TEXT, -- JSON格式存儲投資標的分析
    narrative TEXT, -- JSON格式存儲敘事分析
    sentiment TEXT, -- JSON格式存儲情緒分析
    timestamp TEXT, -- JSON格式存儲時間分析
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (post_id) REFERENCES posts(id)
);

-- 價格歷史數據表
CREATE TABLE price_history (
    id TEXT PRIMARY KEY,
    symbol TEXT NOT NULL,
    date DATE NOT NULL,
    open_price REAL,
    close_price REAL,
    high_price REAL,
    low_price REAL,
    volume INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (symbol) REFERENCES symbols(symbol),
    UNIQUE(symbol, date)
);

-- 投資筆記表
CREATE TABLE investment_notes (
    id TEXT PRIMARY KEY,
    investment_id TEXT NOT NULL,
    content TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (investment_id) REFERENCES investments(id)
);
```

## 核心算法設計

### NLP分析流程 (基於資料傳輸架構)
1. **文本預處理**: 清理、標準化，支援Base64圖片OCR
2. **投資標的識別**: GPT模型提取股票代碼和名稱，包含信心度評估
3. **投資敘事生成**: 結構化分析投資邏輯，提取關鍵主題
4. **情緒分析**: 五級分類 (強烈看多/看多/中性/看空/強烈看空)，含信心度
5. **時間識別**: 從內容推測發布時間，ISO 8601格式

### AI分析結果結構
```json
{
  "investment_target": {
    "symbol": "AAPL",
    "name": "蘋果公司",
    "confidence": 0.95,
    "extracted_from": "text"
  },
  "narrative": {
    "content": "看好蘋果公司在AI領域的創新能力...",
    "confidence": 0.88,
    "key_themes": ["AI創新", "產品生態系統", "長期競爭優勢"]
  },
  "sentiment": {
    "overall": "bullish",
    "confidence": 0.82,
    "intensity": "strong"
  },
  "timestamp": {
    "detected": "2025-07-15T14:30:00Z",
    "confidence": 0.90
  }
}
```

### 資料快取策略
1. **股票價格快取**: 1小時過期，5分鐘更新頻率
2. **圖表快取**: 6小時過期，Base64格式存儲
3. **AI分析快取**: 24小時過期，避免重複分析
4. **用戶設定快取**: 即時更新，本地優先

### 績效評估算法
1. **KOL準確率**: 基於歷史發言的預測準確性
2. **平均回報**: 跟單建議的平均相對回報
3. **一致性評估**: 回報率的標準差和穩定性
4. **風險調整回報**: 考慮波動率的風險調整績效

## 開發環境設置

### 必要軟體
- Node.js 18+
- Python 3.9+
- Android Studio (Android開發)
- Git

### 環境變數
```env
# Alpha Vantage API
ALPHA_VANTAGE_API_KEY=your_api_key
ALPHA_VANTAGE_BASE_URL=https://www.alphavantage.co/query

# OpenAI API
OPENAI_API_KEY=your_api_key
OPENAI_MODEL=gpt-3.5-turbo
OPENAI_TEMPERATURE=0.3

# 應用配置
APP_ENV=development
DEBUG=true
LOG_LEVEL=INFO

# 快取配置
CACHE_EXPIRY_STOCK_PRICE=3600  # 1小時
CACHE_EXPIRY_CHART=21600       # 6小時
CACHE_EXPIRY_ANALYSIS=86400    # 24小時

# 資料庫配置
DATABASE_URL=sqlite:///stock_kol_tracker.db
BACKUP_DIR=./backups

# 安全配置
ENCRYPTION_KEY=your_encryption_key
MAX_FILE_SIZE=10485760  # 10MB
ALLOWED_IMAGE_TYPES=jpg,jpeg,png,gif
```

## 性能考量

### API請求優化
- **請求緩存機制**: 基於DataCache類的本地快取
- **批量請求處理**: 多股票價格同時獲取
- **錯誤重試機制**: 指數退避重試策略
- **請求頻率限制**: 5分鐘更新頻率，避免API限制

### 資料傳輸優化
- **JSON格式標準化**: 統一的資料交換格式
- **Base64圖片處理**: 高效的圖片傳輸和存儲
- **增量更新**: 只更新變化的資料
- **壓縮傳輸**: 減少網路傳輸量

### 數據存儲優化
- **索引優化**: 針對常用查詢建立索引
- **數據分區**: 按時間分區存儲歷史數據
- **定期清理**: 自動清理過期快取和舊數據
- **備份策略**: 本地備份 + 可選雲端同步

### 前端性能優化
- **虛擬滾動**: 大量數據的高效渲染
- **圖片懶加載**: 按需加載圖表縮圖
- **狀態管理**: Redux/Zustand優化狀態更新
- **組件記憶化**: React.memo減少不必要的重渲染

## 安全考量

### 數據安全
- **本地存儲加密**: 敏感資料加密存儲
- **API密鑰安全存儲**: 環境變數管理，避免硬編碼
- **用戶數據隱私保護**: 本地優先，可選雲端同步
- **Base64圖片安全**: 驗證圖片格式和大小

### 資料傳輸安全
- **JSON資料驗證**: 輸入資料格式和內容驗證
- **API請求簽名**: 防止請求篡改
- **HTTPS傳輸**: 所有外部API使用HTTPS
- **錯誤資訊過濾**: 避免敏感資訊洩露

### 應用安全
- **輸入驗證**: 前端和後端雙重驗證
- **SQL注入防護**: 參數化查詢
- **錯誤處理**: 全局錯誤邊界和用戶友好提示
- **日誌記錄**: 結構化日誌，避免敏感資訊記錄
- **資料備份安全**: 加密備份檔案

---

*最後更新：2025.07.28*  
*文件版本：v1.1* 