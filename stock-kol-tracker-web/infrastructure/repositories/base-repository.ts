import { SupabaseClient } from '@supabase/supabase-js';
import { Database } from '@/domain/models/database.types';

export abstract class BaseRepository {
  constructor(protected supabase: SupabaseClient<Database>) {}

  // 注意：此方法已棄用，請使用 getUserIdAsync()
  // 保留此方法僅為了向後兼容，但實際上應該使用 async 版本

  protected async getUserIdAsync(): Promise<string> {
    const {
      data: { user },
      error,
    } = await this.supabase.auth.getUser();
    if (error || !user) {
      throw new Error('User not authenticated');
    }
    return user.id;
  }
}
