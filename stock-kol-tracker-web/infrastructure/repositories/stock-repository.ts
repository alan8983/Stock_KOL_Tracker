import { SupabaseClient } from '@supabase/supabase-js';
import { Database } from '@/domain/models/database.types';
import { BaseRepository } from './base-repository';

export type Stock = Database['public']['Tables']['stocks']['Row'];
export type StockInsert = Database['public']['Tables']['stocks']['Insert'];
export type StockUpdate = Database['public']['Tables']['stocks']['Update'];

export class StockRepository extends BaseRepository {
  constructor(supabase: SupabaseClient<Database>) {
    super(supabase);
  }

  async findAll(): Promise<Stock[]> {
    const userId = await this.getUserIdAsync();
    const { data, error } = await this.supabase
      .from('stocks')
      .select('*')
      .eq('user_id', userId)
      .order('last_updated', { ascending: false });

    if (error) {
      throw new Error(`Failed to fetch stocks: ${error.message}`);
    }

    return data || [];
  }

  async findByTicker(ticker: string): Promise<Stock | null> {
    const userId = await this.getUserIdAsync();
    const { data, error } = await this.supabase
      .from('stocks')
      .select('*')
      .eq('ticker', ticker)
      .eq('user_id', userId)
      .single();

    if (error) {
      if (error.code === 'PGRST116') {
        return null;
      }
      throw new Error(`Failed to fetch stock: ${error.message}`);
    }

    return data;
  }

  async create(stock: StockInsert): Promise<Stock> {
    const userId = await this.getUserIdAsync();
    const { data, error } = await this.supabase
      .from('stocks')
      .insert({
        ...stock,
        user_id: userId,
      } as any)
      .select()
      .single();

    if (error) {
      throw new Error(`Failed to create stock: ${error.message}`);
    }

    return data;
  }

  async update(ticker: string, updates: StockUpdate): Promise<Stock> {
    const userId = await this.getUserIdAsync();
    // @ts-ignore - Supabase type inference issue
    const { data, error } = await this.supabase
      .from('stocks')
      .update(updates)
      .eq('ticker', ticker)
      .eq('user_id', userId)
      .select()
      .single();

    if (error) {
      throw new Error(`Failed to update stock: ${error.message}`);
    }

    return data;
  }

  async delete(ticker: string): Promise<void> {
    const userId = await this.getUserIdAsync();
    const { error } = await this.supabase
      .from('stocks')
      .delete()
      .eq('ticker', ticker)
      .eq('user_id', userId);

    if (error) {
      throw new Error(`Failed to delete stock: ${error.message}`);
    }
  }

  async search(query: string): Promise<Stock[]> {
    const userId = await this.getUserIdAsync();
    const { data, error } = await this.supabase
      .from('stocks')
      .select('*')
      .eq('user_id', userId)
      .or(`ticker.ilike.%${query}%,name.ilike.%${query}%`)
      .order('last_updated', { ascending: false });

    if (error) {
      throw new Error(`Failed to search stocks: ${error.message}`);
    }

    return data || [];
  }
}
