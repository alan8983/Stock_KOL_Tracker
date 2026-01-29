import { RegisterForm } from '@/components/forms/register-form';
import { createServerSupabaseClient } from '@/infrastructure/supabase/client';
import { redirect } from 'next/navigation';

export default async function RegisterPage() {
  const supabase = await createServerSupabaseClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  // 如果已登入，重定向
  if (user) {
    redirect('/dashboard');
  }

  return (
    <div className="flex min-h-screen items-center justify-center bg-gray-50 px-4 py-12 sm:px-6 lg:px-8">
      <div className="w-full max-w-md space-y-8">
        <div>
          <h2 className="mt-6 text-center text-3xl font-bold tracking-tight text-gray-900">
            建立新帳號
          </h2>
          <p className="mt-2 text-center text-sm text-gray-600">
            或{' '}
            <a
              href="/auth/login"
              className="font-medium text-blue-600 hover:text-blue-500"
            >
              登入現有帳號
            </a>
          </p>
        </div>
        <RegisterForm />
      </div>
    </div>
  );
}
