import { SupabaseClient } from '@supabase/supabase-js';
import { Database } from '@/domain/models/database.types';
import { BaseRepository } from './base-repository';

export type KOL = Database['public']['Tables']['kols']['Row'];
export type KOLInsert = Database['public']['Tables']['kols']['Insert'];
export type KOLUpdate = Database['public']['Tables']['kols']['Update'];

export class KOLRepository extends BaseRepository {
  constructor(supabase: SupabaseClient<Database>) {
    super(supabase);
  }

  async findAll(): Promise<KOL[]> {
    const userId = await this.getUserIdAsync();
    const { data, error } = await this.supabase
      .from('kols')
      .select('*')
      .eq('user_id', userId)
      .order('created_at', { ascending: false });

    if (error) {
      throw new Error(`Failed to fetch KOLs: ${error.message}`);
    }

    return data || [];
  }

  async findById(id: string): Promise<KOL | null> {
    const userId = await this.getUserIdAsync();
    const { data, error } = await this.supabase
      .from('kols')
      .select('*')
      .eq('id', id)
      .eq('user_id', userId)
      .single();

    if (error) {
      if (error.code === 'PGRST116') {
        return null;
      }
      throw new Error(`Failed to fetch KOL: ${error.message}`);
    }

    return data;
  }

  async findByName(name: string): Promise<KOL | null> {
    const userId = await this.getUserIdAsync();
    const { data, error } = await this.supabase
      .from('kols')
      .select('*')
      .eq('name', name)
      .eq('user_id', userId)
      .single();

    if (error) {
      if (error.code === 'PGRST116') {
        return null;
      }
      throw new Error(`Failed to fetch KOL: ${error.message}`);
    }

    return data;
  }

  async create(kol: KOLInsert): Promise<KOL> {
    const userId = await this.getUserIdAsync();
    const { data, error } = await this.supabase
      .from('kols')
      .insert({
        ...kol,
        user_id: userId,
      } as any)
      .select()
      .single();

    if (error) {
      throw new Error(`Failed to create KOL: ${error.message}`);
    }

    return data;
  }

  async update(id: string, updates: KOLUpdate): Promise<KOL> {
    const userId = await this.getUserIdAsync();
    // @ts-ignore - Supabase type inference issue
    const { data, error } = await this.supabase
      .from('kols')
      .update(updates)
      .eq('id', id)
      .eq('user_id', userId)
      .select()
      .single();

    if (error) {
      throw new Error(`Failed to update KOL: ${error.message}`);
    }

    return data;
  }

  async delete(id: string): Promise<void> {
    const userId = await this.getUserIdAsync();
    const { error } = await this.supabase
      .from('kols')
      .delete()
      .eq('id', id)
      .eq('user_id', userId);

    if (error) {
      throw new Error(`Failed to delete KOL: ${error.message}`);
    }
  }

  async search(query: string): Promise<KOL[]> {
    const userId = await this.getUserIdAsync();
    const { data, error } = await this.supabase
      .from('kols')
      .select('*')
      .eq('user_id', userId)
      .ilike('name', `%${query}%`)
      .order('created_at', { ascending: false });

    if (error) {
      throw new Error(`Failed to search KOLs: ${error.message}`);
    }

    return data || [];
  }
}
