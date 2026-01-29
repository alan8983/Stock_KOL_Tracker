import Link from 'next/link';
import { Button } from '@/components/ui/button';

export default function Home() {
  return (
    <div className="flex min-h-screen flex-col items-center justify-center bg-gray-50 px-4 py-12">
      <div className="w-full max-w-2xl space-y-8 text-center">
        <div>
          <h1 className="text-4xl font-bold tracking-tight text-gray-900 sm:text-6xl">
            Stock KOL Tracker
          </h1>
          <p className="mt-6 text-lg leading-8 text-gray-600">
            追蹤和分析 KOL 的投資觀點，驗證其準確性與時效性
          </p>
        </div>

        <div className="flex flex-col gap-4 sm:flex-row sm:justify-center">
          <Button asChild size="lg">
            <Link href="/auth/register">開始使用</Link>
          </Button>
          <Button asChild variant="outline" size="lg">
            <Link href="/auth/login">登入</Link>
          </Button>
        </div>

        <div className="mt-12 grid grid-cols-1 gap-6 sm:grid-cols-3">
          <div className="rounded-lg bg-white p-6 shadow">
            <h3 className="text-lg font-semibold">快速輸入</h3>
            <p className="mt-2 text-sm text-gray-600">
              AI 自動分析 KOL 發言，識別投資標的和情緒
            </p>
          </div>
          <div className="rounded-lg bg-white p-6 shadow">
            <h3 className="text-lg font-semibold">勝率統計</h3>
            <p className="mt-2 text-sm text-gray-600">
              追蹤 KOL 預測準確度，評估投資建議品質
            </p>
          </div>
          <div className="rounded-lg bg-white p-6 shadow">
            <h3 className="text-lg font-semibold">K線圖分析</h3>
            <p className="mt-2 text-sm text-gray-600">
              視覺化股價走勢，結合文檔標記分析
            </p>
          </div>
        </div>
      </div>
    </div>
  );
}
