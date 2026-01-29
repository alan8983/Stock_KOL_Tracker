'use client';

import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { createClient } from '@/infrastructure/supabase/client';
import { StockRepository } from '@/infrastructure/repositories';
import type { Stock, StockInsert, StockUpdate } from '@/infrastructure/repositories';

export function useStocks() {
  const supabase = createClient();
  const repository = new StockRepository(supabase);
  const queryClient = useQueryClient();

  const {
    data: stocks = [],
    isLoading,
    error,
  } = useQuery<Stock[]>({
    queryKey: ['stocks'],
    queryFn: async () => {
      return await repository.findAll();
    },
  });

  const createMutation = useMutation({
    mutationFn: (stock: StockInsert) => repository.create(stock),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['stocks'] });
    },
  });

  const updateMutation = useMutation({
    mutationFn: ({ ticker, updates }: { ticker: string; updates: StockUpdate }) =>
      repository.update(ticker, updates),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['stocks'] });
    },
  });

  const deleteMutation = useMutation({
    mutationFn: (ticker: string) => repository.delete(ticker),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['stocks'] });
    },
  });

  const searchMutation = useMutation({
    mutationFn: (query: string) => repository.search(query),
  });

  return {
    stocks,
    isLoading,
    error,
    createStock: createMutation.mutateAsync,
    updateStock: updateMutation.mutateAsync,
    deleteStock: deleteMutation.mutateAsync,
    searchStocks: searchMutation.mutateAsync,
    isCreating: createMutation.isPending,
    isUpdating: updateMutation.isPending,
    isDeleting: deleteMutation.isPending,
  };
}
