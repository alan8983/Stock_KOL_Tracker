'use client';

import { useRouter } from 'next/navigation';
import { usePosts } from '@/hooks/use-posts';
import { useKOLs } from '@/hooks/use-kols';
import { useStocks } from '@/hooks/use-stocks';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { ArrowLeft, Edit } from 'lucide-react';

export function PostDetailPage({ postId }: { postId: string }) {
  const router = useRouter();
  const { posts, isLoading } = usePosts();
  const { kols } = useKOLs();
  const { stocks } = useStocks();

  const post = posts.find((p) => p.id === postId);
  const kol = post?.kol_id ? kols.find((k) => k.id === post.kol_id) : null;
  const stock = post?.stock_ticker
    ? stocks.find((s) => s.ticker === post.stock_ticker)
    : null;

  if (isLoading || !post) {
    return (
      <div className="container mx-auto px-4 py-8">
        <div className="text-center">載入中...</div>
      </div>
    );
  }

  return (
    <div className="container mx-auto px-4 py-8 max-w-4xl">
      <div className="flex items-center gap-4 mb-6">
        <Button variant="ghost" size="icon" onClick={() => router.back()}>
          <ArrowLeft className="h-4 w-4" />
        </Button>
        <h1 className="text-3xl font-bold">文檔詳情</h1>
        {post.status === 'Draft' && (
          <Button
            variant="outline"
            onClick={() => router.push(`/posts/${post.id}/edit`)}
          >
            <Edit className="mr-2 h-4 w-4" />
            編輯
          </Button>
        )}
      </div>

      <div className="space-y-6">
        <Card>
          <CardHeader>
            <CardTitle>內容</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="whitespace-pre-wrap font-mono text-sm">
              {post.content}
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>關聯資訊</CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div>
              <label className="text-sm font-medium text-gray-700">狀態</label>
              <div className="mt-1">
                <span
                  className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${
                    post.status === 'Published'
                      ? 'bg-green-100 text-green-800'
                      : 'bg-gray-100 text-gray-800'
                  }`}
                >
                  {post.status === 'Published' ? '已發布' : '草稿'}
                </span>
              </div>
            </div>

            {kol && (
              <div>
                <label className="text-sm font-medium text-gray-700">KOL</label>
                <div className="mt-1 text-sm">{kol.name}</div>
                {kol.bio && (
                  <div className="mt-1 text-xs text-gray-500">{kol.bio}</div>
                )}
              </div>
            )}

            {stock && (
              <div>
                <label className="text-sm font-medium text-gray-700">投資標的</label>
                <div className="mt-1 text-sm">
                  {stock.ticker} {stock.name ? `- ${stock.name}` : ''}
                </div>
              </div>
            )}

            {post.sentiment && (
              <div>
                <label className="text-sm font-medium text-gray-700">情緒</label>
                <div className="mt-1">
                  <span
                    className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${
                      post.sentiment === 'Bullish'
                        ? 'bg-green-100 text-green-800'
                        : post.sentiment === 'Bearish'
                        ? 'bg-red-100 text-red-800'
                        : 'bg-gray-100 text-gray-800'
                    }`}
                  >
                    {post.sentiment === 'Bullish'
                      ? '看漲'
                      : post.sentiment === 'Bearish'
                      ? '看跌'
                      : '中性'}
                  </span>
                </div>
              </div>
            )}

            {post.posted_at && (
              <div>
                <label className="text-sm font-medium text-gray-700">發文時間</label>
                <div className="mt-1 text-sm">
                  {new Date(post.posted_at).toLocaleString('zh-TW')}
                </div>
              </div>
            )}

            <div>
              <label className="text-sm font-medium text-gray-700">建立時間</label>
              <div className="mt-1 text-sm">
                {new Date(post.created_at).toLocaleString('zh-TW')}
              </div>
            </div>
          </CardContent>
        </Card>

        {post.ai_analysis_json && (
          <Card>
            <CardHeader>
              <CardTitle>AI 分析結果</CardTitle>
              <CardDescription>原始分析資料</CardDescription>
            </CardHeader>
            <CardContent>
              <pre className="text-xs bg-gray-50 p-4 rounded overflow-auto">
                {JSON.stringify(post.ai_analysis_json, null, 2)}
              </pre>
            </CardContent>
          </Card>
        )}
      </div>
    </div>
  );
}
