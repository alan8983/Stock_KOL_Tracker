import { SupabaseClient } from '@supabase/supabase-js';
import { Database } from '@/domain/models/database.types';
import { BaseRepository } from './base-repository';

export type Post = Database['public']['Tables']['posts']['Row'];
export type PostInsert = Database['public']['Tables']['posts']['Insert'];
export type PostUpdate = Database['public']['Tables']['posts']['Update'];

export class PostRepository extends BaseRepository {
  constructor(supabase: SupabaseClient<Database>) {
    super(supabase);
  }

  async findAll(): Promise<Post[]> {
    const userId = await this.getUserIdAsync();
    const { data, error } = await this.supabase
      .from('posts')
      .select('*')
      .eq('user_id', userId)
      .order('created_at', { ascending: false });

    if (error) {
      throw new Error(`Failed to fetch posts: ${error.message}`);
    }

    return data || [];
  }

  async findById(id: string): Promise<Post | null> {
    const userId = await this.getUserIdAsync();
    const { data, error } = await this.supabase
      .from('posts')
      .select('*')
      .eq('id', id)
      .eq('user_id', userId)
      .single();

    if (error) {
      if (error.code === 'PGRST116') {
        return null;
      }
      throw new Error(`Failed to fetch post: ${error.message}`);
    }

    return data;
  }

  async findByKOLId(kolId: string): Promise<Post[]> {
    const userId = await this.getUserIdAsync();
    const { data, error } = await this.supabase
      .from('posts')
      .select('*')
      .eq('kol_id', kolId)
      .eq('user_id', userId)
      .order('created_at', { ascending: false });

    if (error) {
      throw new Error(`Failed to fetch posts by KOL: ${error.message}`);
    }

    return data || [];
  }

  async findByStockTicker(ticker: string): Promise<Post[]> {
    const userId = await this.getUserIdAsync();
    const { data, error } = await this.supabase
      .from('posts')
      .select('*')
      .eq('stock_ticker', ticker)
      .eq('user_id', userId)
      .order('created_at', { ascending: false });

    if (error) {
      throw new Error(`Failed to fetch posts by stock: ${error.message}`);
    }

    return data || [];
  }

  async findDrafts(): Promise<Post[]> {
    const userId = await this.getUserIdAsync();
    const { data, error } = await this.supabase
      .from('posts')
      .select('*')
      .eq('user_id', userId)
      .eq('status', 'Draft')
      .order('created_at', { ascending: false });

    if (error) {
      throw new Error(`Failed to fetch drafts: ${error.message}`);
    }

    return data || [];
  }

  async findPublished(): Promise<Post[]> {
    const userId = await this.getUserIdAsync();
    const { data, error } = await this.supabase
      .from('posts')
      .select('*')
      .eq('user_id', userId)
      .eq('status', 'Published')
      .order('created_at', { ascending: false });

    if (error) {
      throw new Error(`Failed to fetch published posts: ${error.message}`);
    }

    return data || [];
  }

  async create(post: PostInsert): Promise<Post> {
    const userId = await this.getUserIdAsync();
    const { data, error } = await this.supabase
      .from('posts')
      .insert({
        ...post,
        user_id: userId,
      } as any)
      .select()
      .single();

    if (error) {
      throw new Error(`Failed to create post: ${error.message}`);
    }

    return data;
  }

  async update(id: string, updates: PostUpdate): Promise<Post> {
    const userId = await this.getUserIdAsync();
    // @ts-ignore - Supabase type inference issue
    const { data, error } = await this.supabase
      .from('posts')
      .update(updates)
      .eq('id', id)
      .eq('user_id', userId)
      .select()
      .single();

    if (error) {
      throw new Error(`Failed to update post: ${error.message}`);
    }

    return data;
  }

  async delete(id: string): Promise<void> {
    const userId = await this.getUserIdAsync();
    const { error } = await this.supabase
      .from('posts')
      .delete()
      .eq('id', id)
      .eq('user_id', userId);

    if (error) {
      throw new Error(`Failed to delete post: ${error.message}`);
    }
  }

  async publish(id: string): Promise<Post> {
    const userId = await this.getUserIdAsync();
    const post = await this.findById(id);
    
    if (!post) {
      throw new Error('Post not found');
    }

    if (post.status === 'Published') {
      throw new Error('Post is already published');
    }

    if (!post.kol_id || !post.stock_ticker) {
      throw new Error('Published post must have kol_id and stock_ticker');
    }

    return this.update(id, { status: 'Published' });
  }
}
