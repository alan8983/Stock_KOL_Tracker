'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { useStocks } from '@/hooks/use-stocks';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Card, CardContent } from '@/components/ui/card';
import { Search, TrendingUp } from 'lucide-react';

export function StockListPage() {
  const router = useRouter();
  const { stocks, isLoading, searchStocks } = useStocks();
  const [searchQuery, setSearchQuery] = useState('');
  const [isSearching, setIsSearching] = useState(false);
  const [searchResults, setSearchResults] = useState<any[]>([]);

  const handleSearch = async (query: string) => {
    setSearchQuery(query);
    if (query.trim()) {
      setIsSearching(true);
      try {
        const results = await searchStocks(query);
        setSearchResults(results);
      } catch (error) {
        console.error('搜尋失敗:', error);
      }
    } else {
      setIsSearching(false);
      setSearchResults([]);
    }
  };

  const displayStocks = isSearching ? searchResults : stocks;

  return (
    <div className="container mx-auto px-4 py-8 max-w-6xl">
      <div className="flex justify-between items-center mb-6">
        <h1 className="text-3xl font-bold">投資標的管理</h1>
      </div>

      <div className="mb-6">
        <div className="relative">
          <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-gray-400" />
          <Input
            placeholder="搜尋股票代碼或名稱..."
            value={searchQuery}
            onChange={(e) => handleSearch(e.target.value)}
            className="pl-10"
          />
        </div>
      </div>

      {isLoading ? (
        <div className="text-center py-12">載入中...</div>
      ) : displayStocks.length === 0 ? (
        <Card>
          <CardContent className="py-12 text-center">
            <TrendingUp className="h-16 w-16 mx-auto text-gray-400 mb-4" />
            <p className="text-gray-500">
              {isSearching ? '找不到符合的股票' : '目前沒有投資標的'}
            </p>
          </CardContent>
        </Card>
      ) : (
        <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
          {displayStocks.map((stock) => (
            <Card
              key={stock.ticker}
              className="cursor-pointer hover:shadow-lg transition-shadow"
              onClick={() => router.push(`/stocks/${stock.ticker}`)}
            >
              <CardContent className="p-6">
                <div className="flex items-center justify-between">
                  <div>
                    <h3 className="font-bold text-xl">{stock.ticker}</h3>
                    {stock.name && (
                      <p className="text-sm text-gray-600 mt-1">{stock.name}</p>
                    )}
                    {stock.exchange && (
                      <p className="text-xs text-gray-500 mt-1">{stock.exchange}</p>
                    )}
                  </div>
                  <TrendingUp className="h-8 w-8 text-blue-500" />
                </div>
                <div className="mt-4 text-xs text-gray-500">
                  最後更新：{new Date(stock.last_updated).toLocaleDateString('zh-TW')}
                </div>
              </CardContent>
            </Card>
          ))}
        </div>
      )}
    </div>
  );
}
