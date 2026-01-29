'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { Button } from '@/components/ui/button';
import { Textarea } from '@/components/ui/textarea';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { usePosts } from '@/hooks/use-posts';
import type { AnalysisResult } from '@/infrastructure/api/gemini-client';

export function QuickInputPage() {
  const router = useRouter();
  const { createPost, isCreating } = usePosts();
  const [content, setContent] = useState('');
  const [isAnalyzing, setIsAnalyzing] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [analysisResult, setAnalysisResult] = useState<AnalysisResult | null>(null);

  const handleAnalyze = async () => {
    if (!content.trim()) {
      setError('請輸入內容');
      return;
    }

    setIsAnalyzing(true);
    setError(null);
    setAnalysisResult(null);

    try {
      const response = await fetch('/api/ai/analyze', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ content }),
      });

      const result = await response.json();

      if (!response.ok) {
        throw new Error(result.error?.message || '分析失敗');
      }

      setAnalysisResult(result.data);
    } catch (err: any) {
      setError(err.message || '分析時發生錯誤');
    } finally {
      setIsAnalyzing(false);
    }
  };

  const handleSaveAsDraft = async () => {
    if (!content.trim()) {
      setError('請輸入內容');
      return;
    }

    try {
      const post = await createPost({
        content,
        status: 'Draft',
        ai_analysis_json: analysisResult || undefined,
      });

      router.push(`/posts/${post.id}/edit`);
    } catch (err: any) {
      setError(err.message || '儲存失敗');
    }
  };

  return (
    <div className="container mx-auto px-4 py-8 max-w-4xl">
      <h1 className="text-3xl font-bold mb-6">快速輸入</h1>

      <div className="space-y-6">
        <Card>
          <CardHeader>
            <CardTitle>輸入內容</CardTitle>
            <CardDescription>
              貼上 KOL 的發言內容，系統將自動分析投資標的、情緒和 KOL 資訊
            </CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            <Textarea
              placeholder="貼上 KOL 的發言內容..."
              value={content}
              onChange={(e) => setContent(e.target.value)}
              rows={10}
              className="font-mono text-sm"
            />

            {error && (
              <div className="rounded-md bg-red-50 p-3 text-sm text-red-800">
                {error}
              </div>
            )}

            <div className="flex gap-2">
              <Button
                onClick={handleAnalyze}
                disabled={isAnalyzing || !content.trim()}
                className="flex-1"
              >
                {isAnalyzing ? '分析中...' : 'AI 分析'}
              </Button>
              <Button
                variant="outline"
                onClick={handleSaveAsDraft}
                disabled={isCreating || !content.trim()}
              >
                儲存為草稿
              </Button>
            </div>
          </CardContent>
        </Card>

        {analysisResult && (
          <Card>
            <CardHeader>
              <CardTitle>分析結果</CardTitle>
              <CardDescription>AI 分析完成，您可以編輯後儲存</CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="text-sm font-medium text-gray-700">情緒</label>
                  <div className="mt-1">
                    <span
                      className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${
                        analysisResult.sentiment === 'Bullish'
                          ? 'bg-green-100 text-green-800'
                          : analysisResult.sentiment === 'Bearish'
                          ? 'bg-red-100 text-red-800'
                          : 'bg-gray-100 text-gray-800'
                      }`}
                    >
                      {analysisResult.sentiment === 'Bullish'
                        ? '看漲'
                        : analysisResult.sentiment === 'Bearish'
                        ? '看跌'
                        : '中性'}
                    </span>
                  </div>
                </div>

                {analysisResult.kolName && (
                  <div>
                    <label className="text-sm font-medium text-gray-700">KOL</label>
                    <div className="mt-1 text-sm">{analysisResult.kolName}</div>
                  </div>
                )}

                {analysisResult.postedAtText && (
                  <div>
                    <label className="text-sm font-medium text-gray-700">發文時間</label>
                    <div className="mt-1 text-sm">{analysisResult.postedAtText}</div>
                  </div>
                )}

                {analysisResult.tickers && analysisResult.tickers.length > 0 && (
                  <div>
                    <label className="text-sm font-medium text-gray-700">投資標的</label>
                    <div className="mt-1 flex flex-wrap gap-2">
                      {analysisResult.tickers.map((ticker) => (
                        <span
                          key={ticker}
                          className="inline-flex items-center px-2.5 py-0.5 rounded-md text-xs font-medium bg-blue-100 text-blue-800"
                        >
                          {ticker}
                        </span>
                      ))}
                    </div>
                  </div>
                )}
              </div>

              {analysisResult.narrative && (
                <div>
                  <label className="text-sm font-medium text-gray-700">市場敘事</label>
                  <div className="mt-1 text-sm text-gray-600">{analysisResult.narrative}</div>
                </div>
              )}

              <Button
                onClick={handleSaveAsDraft}
                disabled={isCreating}
                className="w-full"
              >
                {isCreating ? '儲存中...' : '儲存為草稿並編輯'}
              </Button>
            </CardContent>
          </Card>
        )}
      </div>
    </div>
  );
}
