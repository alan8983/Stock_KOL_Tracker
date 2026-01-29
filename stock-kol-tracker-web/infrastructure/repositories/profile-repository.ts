import { SupabaseClient } from '@supabase/supabase-js';
import { Database } from '@/domain/models/database.types';
import { BaseRepository } from './base-repository';

export type Profile = Database['public']['Tables']['profiles']['Row'];
export type ProfileUpdate = Database['public']['Tables']['profiles']['Update'];

export class ProfileRepository extends BaseRepository {
  constructor(supabase: SupabaseClient<Database>) {
    super(supabase);
  }

  async findById(id: string): Promise<Profile | null> {
    const { data, error } = await this.supabase
      .from('profiles')
      .select('*')
      .eq('id', id)
      .single();

    if (error) {
      if (error.code === 'PGRST116') {
        return null;
      }
      throw new Error(`Failed to fetch profile: ${error.message}`);
    }

    return data;
  }

  async getCurrentProfile(): Promise<Profile | null> {
    const userId = await this.getUserIdAsync();
    return this.findById(userId);
  }

  async update(id: string, updates: ProfileUpdate): Promise<Profile> {
    // @ts-ignore - Supabase type inference issue
    const { data, error } = await this.supabase
      .from('profiles')
      .update(updates)
      .eq('id', id)
      .select()
      .single();

    if (error) {
      throw new Error(`Failed to update profile: ${error.message}`);
    }

    return data;
  }

  async updateCurrentProfile(updates: ProfileUpdate): Promise<Profile> {
    const userId = await this.getUserIdAsync();
    return this.update(userId, updates);
  }

  async incrementAIUsage(): Promise<Profile> {
    const userId = await this.getUserIdAsync();
    const profile = await this.findById(userId);
    
    if (!profile) {
      throw new Error('Profile not found');
    }

    return this.update(userId, {
      ai_usage_count: profile.ai_usage_count + 1,
    });
  }

  async canUseAI(): Promise<boolean> {
    const profile = await this.getCurrentProfile();
    if (!profile) {
      return false;
    }

    // 付費用戶無限制
    if (profile.plan === 'pro') {
      return true;
    }

    // 免費用戶限制 10 次/月
    // 這裡簡化處理，實際應該檢查當月使用次數
    return profile.ai_usage_count < 10;
  }
}
