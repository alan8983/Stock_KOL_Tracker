'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { useKOLs } from '@/hooks/use-kols';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Card, CardContent } from '@/components/ui/card';
import { Plus, Search, User } from 'lucide-react';
import { CreateKOLDialog } from '@/components/dialogs/create-kol-dialog';

export function KOLListPage() {
  const router = useRouter();
  const { kols, isLoading, searchKOLs } = useKOLs();
  const [searchQuery, setSearchQuery] = useState('');
  const [isSearching, setIsSearching] = useState(false);
  const [showCreateDialog, setShowCreateDialog] = useState(false);
  const [searchResults, setSearchResults] = useState<any[]>([]);

  const handleSearch = async (query: string) => {
    setSearchQuery(query);
    if (query.trim()) {
      setIsSearching(true);
      try {
        const results = await searchKOLs(query);
        setSearchResults(results);
      } catch (error) {
        console.error('搜尋失敗:', error);
      }
    } else {
      setIsSearching(false);
      setSearchResults([]);
    }
  };

  const displayKOLs = isSearching ? searchResults : kols;

  return (
    <div className="container mx-auto px-4 py-8 max-w-6xl">
      <div className="flex justify-between items-center mb-6">
        <h1 className="text-3xl font-bold">KOL 管理</h1>
        <Button onClick={() => setShowCreateDialog(true)}>
          <Plus className="mr-2 h-4 w-4" />
          新增 KOL
        </Button>
      </div>

      <div className="mb-6">
        <div className="relative">
          <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-gray-400" />
          <Input
            placeholder="搜尋 KOL..."
            value={searchQuery}
            onChange={(e) => handleSearch(e.target.value)}
            className="pl-10"
          />
        </div>
      </div>

      {isLoading ? (
        <div className="text-center py-12">載入中...</div>
      ) : displayKOLs.length === 0 ? (
        <Card>
          <CardContent className="py-12 text-center">
            <User className="h-16 w-16 mx-auto text-gray-400 mb-4" />
            <p className="text-gray-500">
              {isSearching ? '找不到符合的 KOL' : '目前沒有 KOL，點擊上方按鈕新增'}
            </p>
          </CardContent>
        </Card>
      ) : (
        <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
          {displayKOLs.map((kol) => (
            <Card
              key={kol.id}
              className="cursor-pointer hover:shadow-lg transition-shadow"
              onClick={() => router.push(`/kols/${kol.id}`)}
            >
              <CardContent className="p-6">
                <div className="flex items-start gap-4">
                  <div className="flex-shrink-0">
                    <div className="h-12 w-12 rounded-full bg-blue-100 flex items-center justify-center">
                      <span className="text-xl font-bold text-blue-600">
                        {kol.name.charAt(0).toUpperCase()}
                      </span>
                    </div>
                  </div>
                  <div className="flex-1 min-w-0">
                    <h3 className="font-semibold text-lg truncate">{kol.name}</h3>
                    {kol.bio && (
                      <p className="text-sm text-gray-600 mt-1 line-clamp-2">
                        {kol.bio}
                      </p>
                    )}
                    {kol.social_link && (
                      <a
                        href={kol.social_link}
                        target="_blank"
                        rel="noopener noreferrer"
                        className="text-xs text-blue-600 hover:underline mt-2 block"
                        onClick={(e) => e.stopPropagation()}
                      >
                        查看連結 →
                      </a>
                    )}
                  </div>
                </div>
              </CardContent>
            </Card>
          ))}
        </div>
      )}

      <CreateKOLDialog
        open={showCreateDialog}
        onOpenChange={setShowCreateDialog}
      />
    </div>
  );
}
