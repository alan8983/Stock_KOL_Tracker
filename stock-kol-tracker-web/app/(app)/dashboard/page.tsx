import { createServerSupabaseClient } from '@/infrastructure/supabase/client';
import { redirect } from 'next/navigation';

export default async function DashboardPage() {
  const supabase = await createServerSupabaseClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    redirect('/auth/login');
  }

  return (
    <div className="container mx-auto px-4 py-8">
      <h1 className="text-3xl font-bold mb-4">儀表板</h1>
      <p className="text-gray-600">歡迎回來，{user.email}！</p>
    </div>
  );
}
