'use client';

import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { createClient } from '@/infrastructure/supabase/client';
import { KOLRepository } from '@/infrastructure/repositories';
import type { KOL, KOLInsert, KOLUpdate } from '@/infrastructure/repositories';

export function useKOLs() {
  const supabase = createClient();
  const repository = new KOLRepository(supabase);
  const queryClient = useQueryClient();

  const {
    data: kols = [],
    isLoading,
    error,
  } = useQuery<KOL[]>({
    queryKey: ['kols'],
    queryFn: async () => {
      return await repository.findAll();
    },
  });

  const createMutation = useMutation({
    mutationFn: (kol: KOLInsert) => repository.create(kol),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['kols'] });
    },
  });

  const updateMutation = useMutation({
    mutationFn: ({ id, updates }: { id: string; updates: KOLUpdate }) =>
      repository.update(id, updates),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['kols'] });
    },
  });

  const deleteMutation = useMutation({
    mutationFn: (id: string) => repository.delete(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['kols'] });
    },
  });

  const searchMutation = useMutation({
    mutationFn: (query: string) => repository.search(query),
  });

  return {
    kols,
    isLoading,
    error,
    createKOL: createMutation.mutateAsync,
    updateKOL: updateMutation.mutateAsync,
    deleteKOL: deleteMutation.mutateAsync,
    searchKOLs: searchMutation.mutateAsync,
    isCreating: createMutation.isPending,
    isUpdating: updateMutation.isPending,
    isDeleting: deleteMutation.isPending,
  };
}
