'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import * as z from 'zod';
import { usePosts } from '@/hooks/use-posts';
import { useKOLs } from '@/hooks/use-kols';
import { useStocks } from '@/hooks/use-stocks';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Textarea } from '@/components/ui/textarea';
import { Label } from '@/components/ui/label';
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from '@/components/ui/card';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import { Calendar } from '@/components/ui/calendar';
import { Popover, PopoverContent, PopoverTrigger } from '@/components/ui/popover';
import { format } from 'date-fns';
import { CalendarIcon } from 'lucide-react';
import { cn } from '@/lib/utils';

const postSchema = z.object({
  content: z.string().min(1, '內容不能為空'),
  kolId: z.string().optional(),
  stockTicker: z.string().optional(),
  sentiment: z.enum(['Bullish', 'Bearish', 'Neutral']).optional(),
  postedAt: z.date().optional(),
});

type PostFormData = z.infer<typeof postSchema>;

export function DraftEditPage({ postId }: { postId: string }) {
  const router = useRouter();
  const { posts, updatePost, publishPost, isLoading } = usePosts();
  const { kols } = useKOLs();
  const { stocks } = useStocks();
  const [isSaving, setIsSaving] = useState(false);
  const [isPublishing, setIsPublishing] = useState(false);

  const post = posts.find((p) => p.id === postId);

  const {
    register,
    handleSubmit,
    setValue,
    watch,
    formState: { errors },
  } = useForm<PostFormData>({
    resolver: zodResolver(postSchema),
    defaultValues: post
      ? {
          content: post.content,
          kolId: post.kol_id || undefined,
          stockTicker: post.stock_ticker || undefined,
          sentiment: (post.sentiment as any) || undefined,
          postedAt: post.posted_at ? new Date(post.posted_at) : undefined,
        }
      : undefined,
  });

  const postedAt = watch('postedAt');

  useEffect(() => {
    if (post) {
      setValue('content', post.content);
      setValue('kolId', post.kol_id || undefined);
      setValue('stockTicker', post.stock_ticker || undefined);
      setValue('sentiment', (post.sentiment as any) || undefined);
      if (post.posted_at) {
        setValue('postedAt', new Date(post.posted_at));
      }
    }
  }, [post, setValue]);

  if (isLoading || !post) {
    return (
      <div className="container mx-auto px-4 py-8">
        <div className="text-center">載入中...</div>
      </div>
    );
  }

  const onSubmit = async (data: PostFormData) => {
    setIsSaving(true);
    try {
      await updatePost({
        id: postId,
        updates: {
          content: data.content,
          kol_id: data.kolId || null,
          stock_ticker: data.stockTicker || null,
          sentiment: data.sentiment || null,
          posted_at: data.postedAt ? data.postedAt.toISOString() : null,
        },
      });
      router.push('/posts');
    } catch (error) {
      alert('儲存失敗');
    } finally {
      setIsSaving(false);
    }
  };

  const handlePublish = async () => {
    if (!watch('kolId') || !watch('stockTicker')) {
      alert('發布前必須選擇 KOL 和投資標的');
      return;
    }

    setIsPublishing(true);
    try {
      await publishPost(postId);
      router.push('/posts');
    } catch (error: any) {
      alert(error.message || '發布失敗');
    } finally {
      setIsPublishing(false);
    }
  };

  return (
    <div className="container mx-auto px-4 py-8 max-w-4xl">
      <div className="flex justify-between items-center mb-6">
        <h1 className="text-3xl font-bold">編輯文檔</h1>
        <div className="flex gap-2">
          <Button variant="outline" onClick={() => router.back()}>
            取消
          </Button>
          <Button onClick={handleSubmit(onSubmit)} disabled={isSaving}>
            {isSaving ? '儲存中...' : '儲存'}
          </Button>
          {post.status === 'Draft' && (
            <Button onClick={handlePublish} disabled={isPublishing}>
              {isPublishing ? '發布中...' : '發布'}
            </Button>
          )}
        </div>
      </div>

      <form onSubmit={handleSubmit(onSubmit)} className="space-y-6">
        <Card>
          <CardHeader>
            <CardTitle>內容</CardTitle>
            <CardDescription>文檔的主要內容</CardDescription>
          </CardHeader>
          <CardContent>
            <Textarea
              {...register('content')}
              rows={10}
              className="font-mono text-sm"
            />
            {errors.content && (
              <p className="text-sm text-red-600 mt-1">{errors.content.message}</p>
            )}
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>關聯資訊</CardTitle>
            <CardDescription>選擇 KOL、投資標的和情緒</CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="space-y-2">
              <Label htmlFor="kolId">KOL</Label>
              <Select
                value={watch('kolId') || ''}
                onValueChange={(value) => setValue('kolId', value)}
              >
                <SelectTrigger>
                  <SelectValue placeholder="選擇 KOL" />
                </SelectTrigger>
                <SelectContent>
                  {kols.map((kol) => (
                    <SelectItem key={kol.id} value={kol.id}>
                      {kol.name}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>

            <div className="space-y-2">
              <Label htmlFor="stockTicker">投資標的</Label>
              <Select
                value={watch('stockTicker') || ''}
                onValueChange={(value) => setValue('stockTicker', value)}
              >
                <SelectTrigger>
                  <SelectValue placeholder="選擇投資標的" />
                </SelectTrigger>
                <SelectContent>
                  {stocks.map((stock) => (
                    <SelectItem key={stock.ticker} value={stock.ticker}>
                      {stock.ticker} {stock.name ? `- ${stock.name}` : ''}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>

            <div className="space-y-2">
              <Label htmlFor="sentiment">情緒</Label>
              <Select
                value={watch('sentiment') || ''}
                onValueChange={(value: any) => setValue('sentiment', value)}
              >
                <SelectTrigger>
                  <SelectValue placeholder="選擇情緒" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="Bullish">看漲</SelectItem>
                  <SelectItem value="Bearish">看跌</SelectItem>
                  <SelectItem value="Neutral">中性</SelectItem>
                </SelectContent>
              </Select>
            </div>

            <div className="space-y-2">
              <Label>發文時間</Label>
              <Popover>
                <PopoverTrigger asChild>
                  <Button
                    variant="outline"
                    className={cn(
                      'w-full justify-start text-left font-normal',
                      !postedAt && 'text-muted-foreground'
                    )}
                  >
                    <CalendarIcon className="mr-2 h-4 w-4" />
                    {postedAt ? (
                      format(postedAt, 'yyyy-MM-dd')
                    ) : (
                      <span>選擇日期</span>
                    )}
                  </Button>
                </PopoverTrigger>
                <PopoverContent className="w-auto p-0">
                  <Calendar
                    mode="single"
                    selected={postedAt}
                    onSelect={(date) => setValue('postedAt', date || undefined)}
                    initialFocus
                  />
                </PopoverContent>
              </Popover>
            </div>
          </CardContent>
        </Card>
      </form>
    </div>
  );
}
