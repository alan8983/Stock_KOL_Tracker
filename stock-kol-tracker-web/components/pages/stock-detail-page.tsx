'use client';

import { useRouter } from 'next/navigation';
import { useStocks } from '@/hooks/use-stocks';
import { usePosts } from '@/hooks/use-posts';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Button } from '@/components/ui/button';
import { ArrowLeft } from 'lucide-react';

export function StockDetailPage({ ticker }: { ticker: string }) {
  const router = useRouter();
  const { stocks, isLoading: stocksLoading } = useStocks();
  const { posts, isLoading: postsLoading } = usePosts();

  const stock = stocks.find((s) => s.ticker === ticker);
  const stockPosts = posts.filter(
    (p) => p.stock_ticker === ticker && p.status === 'Published'
  );

  if (stocksLoading || postsLoading || !stock) {
    return (
      <div className="container mx-auto px-4 py-8">
        <div className="text-center">載入中...</div>
      </div>
    );
  }

  return (
    <div className="container mx-auto px-4 py-8 max-w-6xl">
      <div className="flex items-center gap-4 mb-6">
        <Button variant="ghost" size="icon" onClick={() => router.back()}>
          <ArrowLeft className="h-4 w-4" />
        </Button>
        <div>
          <h1 className="text-3xl font-bold">{stock.ticker}</h1>
          {stock.name && <p className="text-gray-600 mt-1">{stock.name}</p>}
          {stock.exchange && (
            <p className="text-sm text-gray-500 mt-1">{stock.exchange}</p>
          )}
        </div>
      </div>

      <Tabs defaultValue="posts" className="space-y-4">
        <TabsList>
          <TabsTrigger value="posts">文檔清單</TabsTrigger>
          <TabsTrigger value="narrative">市場敘事</TabsTrigger>
          <TabsTrigger value="chart">K線圖</TabsTrigger>
        </TabsList>

        <TabsContent value="posts" className="space-y-4">
          {stockPosts.length === 0 ? (
            <Card>
              <CardContent className="py-12 text-center text-gray-500">
                尚無文檔
              </CardContent>
            </Card>
          ) : (
            <div className="space-y-4">
              {stockPosts
                .sort(
                  (a, b) =>
                    new Date(b.created_at).getTime() -
                    new Date(a.created_at).getTime()
                )
                .map((post) => (
                  <Card
                    key={post.id}
                    className="cursor-pointer hover:shadow-lg transition-shadow"
                    onClick={() => router.push(`/posts/${post.id}`)}
                  >
                    <CardHeader>
                      <CardTitle className="text-lg">
                        {post.content.substring(0, 100)}
                        {post.content.length > 100 ? '...' : ''}
                      </CardTitle>
                      <CardDescription>
                        {new Date(post.created_at).toLocaleString('zh-TW')}
                      </CardDescription>
                    </CardHeader>
                    <CardContent>
                      <div className="flex items-center gap-2">
                        {post.sentiment && (
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
                        )}
                        {post.kol_id && (
                          <Button
                            variant="ghost"
                            size="sm"
                            onClick={(e) => {
                              e.stopPropagation();
                              router.push(`/kols/${post.kol_id}`);
                            }}
                          >
                            查看 KOL →
                          </Button>
                        )}
                      </div>
                    </CardContent>
                  </Card>
                ))}
            </div>
          )}
        </TabsContent>

        <TabsContent value="narrative">
          <Card>
            <CardHeader>
              <CardTitle>市場敘事</CardTitle>
              <CardDescription>相關文檔的市場觀點</CardDescription>
            </CardHeader>
            <CardContent>
              <p className="text-gray-500">市場敘事功能將在後續版本實作</p>
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="chart">
          <Card>
            <CardHeader>
              <CardTitle>K線圖</CardTitle>
              <CardDescription>股價走勢圖</CardDescription>
            </CardHeader>
            <CardContent>
              <p className="text-gray-500">K線圖功能將在 Phase 5 實作</p>
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>
    </div>
  );
}
