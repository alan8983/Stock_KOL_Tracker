// 此檔案將由 Supabase CLI 自動生成
// 執行: npx supabase gen types typescript --project-id <project-id> > domain/models/database.types.ts

// 暫時使用手動定義的類型
export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[];

export interface Database {
  public: {
    Tables: {
      profiles: {
        Row: {
          id: string;
          display_name: string | null;
          plan: 'free' | 'pro';
          ai_usage_count: number;
          created_at: string;
        };
        Insert: {
          id: string;
          display_name?: string | null;
          plan?: 'free' | 'pro';
          ai_usage_count?: number;
          created_at?: string;
        };
        Update: {
          id?: string;
          display_name?: string | null;
          plan?: 'free' | 'pro';
          ai_usage_count?: number;
          created_at?: string;
        };
      };
      kols: {
        Row: {
          id: string;
          user_id: string;
          name: string;
          bio: string | null;
          social_link: string | null;
          created_at: string;
        };
        Insert: {
          id?: string;
          user_id: string;
          name: string;
          bio?: string | null;
          social_link?: string | null;
          created_at?: string;
        };
        Update: {
          id?: string;
          user_id?: string;
          name?: string;
          bio?: string | null;
          social_link?: string | null;
          created_at?: string;
        };
      };
      stocks: {
        Row: {
          ticker: string;
          user_id: string;
          name: string | null;
          exchange: string | null;
          last_updated: string;
        };
        Insert: {
          ticker: string;
          user_id: string;
          name?: string | null;
          exchange?: string | null;
          last_updated?: string;
        };
        Update: {
          ticker?: string;
          user_id?: string;
          name?: string | null;
          exchange?: string | null;
          last_updated?: string;
        };
      };
      posts: {
        Row: {
          id: string;
          user_id: string;
          kol_id: string | null;
          stock_ticker: string | null;
          content: string;
          sentiment: 'Bullish' | 'Bearish' | 'Neutral' | null;
          posted_at: string | null;
          created_at: string;
          status: 'Draft' | 'Published';
          ai_analysis_json: Json | null;
        };
        Insert: {
          id?: string;
          user_id: string;
          kol_id?: string | null;
          stock_ticker?: string | null;
          content: string;
          sentiment?: 'Bullish' | 'Bearish' | 'Neutral' | null;
          posted_at?: string | null;
          created_at?: string;
          status?: 'Draft' | 'Published';
          ai_analysis_json?: Json | null;
        };
        Update: {
          id?: string;
          user_id?: string;
          kol_id?: string | null;
          stock_ticker?: string | null;
          content?: string;
          sentiment?: 'Bullish' | 'Bearish' | 'Neutral' | null;
          posted_at?: string | null;
          created_at?: string;
          status?: 'Draft' | 'Published';
          ai_analysis_json?: Json | null;
        };
      };
      stock_prices: {
        Row: {
          id: number;
          ticker: string;
          date: string;
          open: number | null;
          close: number | null;
          high: number | null;
          low: number | null;
          volume: number | null;
        };
        Insert: {
          id?: number;
          ticker: string;
          date: string;
          open?: number | null;
          close?: number | null;
          high?: number | null;
          low?: number | null;
          volume?: number | null;
        };
        Update: {
          id?: number;
          ticker?: string;
          date?: string;
          open?: number | null;
          close?: number | null;
          high?: number | null;
          low?: number | null;
          volume?: number | null;
        };
      };
    };
  };
}
