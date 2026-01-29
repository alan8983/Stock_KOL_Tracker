'use client';

import { useRouter } from 'next/navigation';
import { usePosts } from '@/hooks/use-posts';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Plus, FileText, Calendar } from 'lucide-react';

export function DraftListPage() {
  const router = useRouter();
  const { drafts, published, isLoading, deletePost } = usePosts();

  const handleDelete = async (id: string) => {
    if (confirm('確定要刪除此文檔嗎？')) {
      try {
        await deletePost(id);
      } catch (error) {
        alert('刪除失敗');
      }
    }
  };

  if (isLoading) {
    return (
      <div className="container mx-auto px-4 py-8">
        <div className="text-center">載入中...</div>
      </div>
    );
  }

  return (
    <div className="container mx-auto px-4 py-8 max-w-6xl">
      <div className="flex justify-between items-center mb-6">
        <h1 className="text-3xl font-bold">文檔管理</h1>
        <Button onClick={() => router.push('/input')}>
          <Plus className="mr-2 h-4 w-4" />
          快速輸入
        </Button>
      </div>

      <div className="grid gap-6 md:grid-cols-2">
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <FileText className="h-5 w-5" />
              草稿 ({drafts.length})
            </CardTitle>
            <CardDescription>尚未發布的文檔</CardDescription>
          </CardHeader>
          <CardContent>
            {drafts.length === 0 ? (
              <div className="text-center py-8 text-gray-500">
                尚無草稿
              </div>
            ) : (
              <div className="space-y-2">
                {drafts.map((draft) => (
                  <div
                    key={draft.id}
                    className="flex items-center justify-between p-3 border rounded-lg hover:bg-gray-50"
                  >
                    <div
                      className="flex-1 cursor-pointer"
                      onClick={() => router.push(`/posts/${draft.id}/edit`)}
                    >
                      <div className="text-sm font-medium truncate">
                        {draft.content.substring(0, 50)}
                        {draft.content.length > 50 ? '...' : ''}
                      </div>
                      <div className="text-xs text-gray-500 mt-1">
                        <Calendar className="inline h-3 w-3 mr-1" />
                        {new Date(draft.created_at).toLocaleString('zh-TW')}
                      </div>
                    </div>
                    <div className="flex gap-2">
                      <Button
                        variant="ghost"
                        size="sm"
                        onClick={() => router.push(`/posts/${draft.id}/edit`)}
                      >
                        編輯
                      </Button>
                      <Button
                        variant="ghost"
                        size="sm"
                        onClick={() => handleDelete(draft.id)}
                      >
                        刪除
                      </Button>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <FileText className="h-5 w-5" />
              已發布 ({published.length})
            </CardTitle>
            <CardDescription>已發布的文檔</CardDescription>
          </CardHeader>
          <CardContent>
            {published.length === 0 ? (
              <div className="text-center py-8 text-gray-500">
                尚無已發布文檔
              </div>
            ) : (
              <div className="space-y-2">
                {published.map((post) => (
                  <div
                    key={post.id}
                    className="flex items-center justify-between p-3 border rounded-lg hover:bg-gray-50"
                  >
                    <div
                      className="flex-1 cursor-pointer"
                      onClick={() => router.push(`/posts/${post.id}`)}
                    >
                      <div className="text-sm font-medium truncate">
                        {post.content.substring(0, 50)}
                        {post.content.length > 50 ? '...' : ''}
                      </div>
                      <div className="text-xs text-gray-500 mt-1">
                        <Calendar className="inline h-3 w-3 mr-1" />
                        {new Date(post.created_at).toLocaleString('zh-TW')}
                      </div>
                    </div>
                    <Button
                      variant="ghost"
                      size="sm"
                      onClick={() => router.push(`/posts/${post.id}`)}
                    >
                      查看
                    </Button>
                  </div>
                ))}
              </div>
            )}
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
