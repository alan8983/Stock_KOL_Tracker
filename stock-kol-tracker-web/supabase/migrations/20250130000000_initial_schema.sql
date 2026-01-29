-- Stock KOL Tracker Web - Initial Schema
-- Created: 2025-01-30

-- 用戶 Profile（擴展資料）
CREATE TABLE IF NOT EXISTS profiles (
  id UUID REFERENCES auth.users PRIMARY KEY,
  display_name TEXT,
  plan TEXT DEFAULT 'free' CHECK (plan IN ('free', 'pro')),
  ai_usage_count INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- KOL 表
CREATE TABLE IF NOT EXISTS kols (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users NOT NULL,
  name TEXT NOT NULL,
  bio TEXT,
  social_link TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, name)
);

-- Stock 表
CREATE TABLE IF NOT EXISTS stocks (
  ticker TEXT PRIMARY KEY,
  user_id UUID REFERENCES auth.users NOT NULL,
  name TEXT,
  exchange TEXT,
  last_updated TIMESTAMPTZ DEFAULT NOW()
);

-- Post 表
CREATE TABLE IF NOT EXISTS posts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users NOT NULL,
  kol_id UUID REFERENCES kols,
  stock_ticker TEXT REFERENCES stocks,
  content TEXT NOT NULL,
  sentiment TEXT CHECK (sentiment IN ('Bullish', 'Bearish', 'Neutral')),
  posted_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  status TEXT DEFAULT 'Draft' CHECK (status IN ('Draft', 'Published')),
  ai_analysis_json JSONB
);

-- 股價快取表（全域共享，不分用戶）
CREATE TABLE IF NOT EXISTS stock_prices (
  id SERIAL PRIMARY KEY,
  ticker TEXT NOT NULL,
  date DATE NOT NULL,
  open DECIMAL,
  close DECIMAL,
  high DECIMAL,
  low DECIMAL,
  volume BIGINT,
  UNIQUE(ticker, date)
);

-- 建立索引以提升查詢效能
CREATE INDEX IF NOT EXISTS idx_kols_user_id ON kols(user_id);
CREATE INDEX IF NOT EXISTS idx_stocks_user_id ON stocks(user_id);
CREATE INDEX IF NOT EXISTS idx_posts_user_id ON posts(user_id);
CREATE INDEX IF NOT EXISTS idx_posts_kol_id ON posts(kol_id);
CREATE INDEX IF NOT EXISTS idx_posts_stock_ticker ON posts(stock_ticker);
CREATE INDEX IF NOT EXISTS idx_posts_status ON posts(status);
CREATE INDEX IF NOT EXISTS idx_stock_prices_ticker_date ON stock_prices(ticker, date);

-- RLS (Row Level Security) 政策
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE kols ENABLE ROW LEVEL SECURITY;
ALTER TABLE stocks ENABLE ROW LEVEL SECURITY;
ALTER TABLE posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE stock_prices ENABLE ROW LEVEL SECURITY;

-- 用戶只能存取自己的 Profile
CREATE POLICY "Users can view own profile" ON profiles
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON profiles
  FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" ON profiles
  FOR INSERT WITH CHECK (auth.uid() = id);

-- 用戶只能存取自己的 KOL
CREATE POLICY "Users can only access own kols" ON kols
  FOR ALL USING (auth.uid() = user_id);

-- 用戶只能存取自己的 Stock
CREATE POLICY "Users can only access own stocks" ON stocks
  FOR ALL USING (auth.uid() = user_id);

-- 用戶只能存取自己的 Post
CREATE POLICY "Users can only access own posts" ON posts
  FOR ALL USING (auth.uid() = user_id);

-- 股價資料全部人可讀
CREATE POLICY "Stock prices are public" ON stock_prices
  FOR SELECT USING (true);

-- 觸發器：自動建立 Profile
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, display_name, plan)
  VALUES (NEW.id, NEW.raw_user_meta_data->>'display_name', 'free');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 觸發器：確保 Post 狀態轉換規則（Draft -> Published，不可逆）
CREATE OR REPLACE FUNCTION public.enforce_post_status_transition()
RETURNS TRIGGER AS $$
BEGIN
  -- 如果舊狀態是 Published，不允許變更
  IF OLD.status = 'Published' AND NEW.status != 'Published' THEN
    RAISE EXCEPTION 'Cannot change status from Published to %', NEW.status;
  END IF;
  
  -- 如果新狀態是 Published，必須有關聯的 KOL 和 Stock
  IF NEW.status = 'Published' THEN
    IF NEW.kol_id IS NULL OR NEW.stock_ticker IS NULL THEN
      RAISE EXCEPTION 'Published post must have kol_id and stock_ticker';
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER enforce_post_status_transition_trigger
  BEFORE UPDATE ON posts
  FOR EACH ROW
  WHEN (OLD.status IS DISTINCT FROM NEW.status)
  EXECUTE FUNCTION public.enforce_post_status_transition();

-- 觸發器：限制免費用戶 KOL 數量（≤ 5）
CREATE OR REPLACE FUNCTION public.check_free_user_kol_limit()
RETURNS TRIGGER AS $$
DECLARE
  user_plan TEXT;
  kol_count INT;
BEGIN
  -- 獲取用戶方案
  SELECT plan INTO user_plan FROM profiles WHERE id = NEW.user_id;
  
  -- 如果是免費用戶，檢查 KOL 數量
  IF user_plan = 'free' THEN
    SELECT COUNT(*) INTO kol_count FROM kols WHERE user_id = NEW.user_id;
    
    IF kol_count >= 5 THEN
      RAISE EXCEPTION 'Free users can only track up to 5 KOLs';
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER check_free_user_kol_limit_trigger
  BEFORE INSERT ON kols
  FOR EACH ROW
  EXECUTE FUNCTION public.check_free_user_kol_limit();
