'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { useKOLs } from '@/hooks/use-kols';
import { usePosts } from '@/hooks/use-posts';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Button } from '@/components/ui/button';
import { ArrowLeft } from 'lucide-react';

export function KOLDetailPage({ kolId }: { kolId: string }) {
  const router = useRouter();
  const { kols, isLoading: kolsLoading } = useKOLs();
  const { posts, isLoading: postsLoading } = usePosts();

  const kol = kols.find((k) => k.id === kolId);
  const kolPosts = posts.filter((p) => p.kol_id === kolId && p.status === 'Published');

  // 依股票分組
  const postsByStock = kolPosts.reduce((acc, post) => {
    if (!post.stock_ticker) return acc;
    if (!acc[post.stock_ticker]) {
      acc[post.stock_ticker] = [];
    }
    acc[post.stock_ticker].push(post);
    return acc;
  }, {} as Record<string, typeof kolPosts>);

  if (kolsLoading || postsLoading || !kol) {
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
          <h1 className="text-3xl font-bold">{kol.name}</h1>
          {kol.bio && <p className="text-gray-600 mt-1">{kol.bio}</p>}
        </div>
      </div>

      <Tabs defaultValue="overview" className="space-y-4">
        <TabsList>
          <TabsTrigger value="overview">概覽</TabsTrigger>
          <TabsTrigger value="stats">勝率統計</TabsTrigger>
          <TabsTrigger value="about">簡介</TabsTrigger>
        </TabsList>

        <TabsContent value="overview" className="space-y-4">
          {Object.keys(postsByStock).length === 0 ? (
            <Card>
              <CardContent className="py-12 text-center text-gray-500">
                尚無文檔
              </CardContent>
            </Card>
          ) : (
            Object.entries(postsByStock).map(([ticker, tickerPosts]) => (
              <Card key={ticker}>
                <CardHeader>
                  <CardTitle className="flex items-center justify-between">
                    <span>{ticker}</span>
                    <Button
                      variant="ghost"
                      size="sm"
                      onClick={() => router.push(`/stocks/${ticker}`)}
                    >
                      查看詳情 →
                    </Button>
                  </CardTitle>
                  <CardDescription>{tickerPosts.length} 篇文檔</CardDescription>
                </CardHeader>
                <CardContent>
                  <div className="space-y-2">
                    {tickerPosts
                      .sort(
                        (a, b) =>
                          new Date(b.created_at).getTime() -
                          new Date(a.created_at).getTime()
                      )
                      .slice(0, 3)
                      .map((post) => (
                        <div
                          key={post.id}
                          className="flex items-center justify-between p-3 border rounded-lg hover:bg-gray-50 cursor-pointer"
                          onClick={() => router.push(`/posts/${post.id}`)}
                        >
                          <div className="flex-1">
                            <div className="text-sm font-medium truncate">
                              {post.content.substring(0, 50)}
                              {post.content.length > 50 ? '...' : ''}
                            </div>
                            <div className="flex items-center gap-2 mt-1">
                              <span className="text-xs text-gray-500">
                                {new Date(post.created_at).toLocaleDateString('zh-TW')}
                              </span>
                              {post.sentiment && (
                                <span
                                  className={`inline-flex items-center px-2 py-0.5 rounded text-xs font-medium ${
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
                            </div>
                          </div>
                        </div>
                      ))}
                  </div>
                  {tickerPosts.length > 3 && (
                    <Button
                      variant="ghost"
                      size="sm"
                      className="w-full mt-2"
                      onClick={() => router.push(`/stocks/${ticker}`)}
                    >
                      查看全部 {tickerPosts.length} 篇 →
                    </Button>
                  )}
                </CardContent>
              </Card>
            ))
          )}
        </TabsContent>

        <TabsContent value="stats">
          <Card>
            <CardHeader>
              <CardTitle>勝率統計</CardTitle>
              <CardDescription>計算中...</CardDescription>
            </CardHeader>
            <CardContent>
              <p className="text-gray-500">勝率統計功能將在 Phase 5 實作</p>
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="about">
          <Card>
            <CardHeader>
              <CardTitle>KOL 簡介</CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              {kol.bio && (
                <div>
                  <label className="text-sm font-medium text-gray-700">簡介</label>
                  <p className="mt-1 text-sm">{kol.bio}</p>
                </div>
              )}
              {kol.social_link && (
                <div>
                  <label className="text-sm font-medium text-gray-700">社群連結</label>
                  <a
                    href={kol.social_link}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="mt-1 text-sm text-blue-600 hover:underline block"
                  >
                    {kol.social_link}
                  </a>
                </div>
              )}
              <div>
                <label className="text-sm font-medium text-gray-700">建立時間</label>
                <p className="mt-1 text-sm text-gray-600">
                  {new Date(kol.created_at).toLocaleString('zh-TW')}
                </p>
              </div>
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>
    </div>
  );
}
