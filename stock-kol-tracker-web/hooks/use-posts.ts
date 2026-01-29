'use client';

import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { createClient } from '@/infrastructure/supabase/client';
import { PostRepository } from '@/infrastructure/repositories';
import type { Post, PostInsert, PostUpdate } from '@/infrastructure/repositories';

export function usePosts() {
  const supabase = createClient();
  const repository = new PostRepository(supabase);
  const queryClient = useQueryClient();

  const {
    data: posts = [],
    isLoading,
    error,
  } = useQuery<Post[]>({
    queryKey: ['posts'],
    queryFn: async () => {
      return await repository.findAll();
    },
  });

  const draftsQuery = useQuery<Post[]>({
    queryKey: ['posts', 'drafts'],
    queryFn: async () => {
      return await repository.findDrafts();
    },
  });

  const publishedQuery = useQuery<Post[]>({
    queryKey: ['posts', 'published'],
    queryFn: async () => {
      return await repository.findPublished();
    },
  });

  const createMutation = useMutation({
    mutationFn: (post: PostInsert) => repository.create(post),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['posts'] });
    },
  });

  const updateMutation = useMutation({
    mutationFn: ({ id, updates }: { id: string; updates: PostUpdate }) =>
      repository.update(id, updates),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['posts'] });
    },
  });

  const deleteMutation = useMutation({
    mutationFn: (id: string) => repository.delete(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['posts'] });
    },
  });

  const publishMutation = useMutation({
    mutationFn: (id: string) => repository.publish(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['posts'] });
    },
  });

  return {
    posts,
    drafts: draftsQuery.data || [],
    published: publishedQuery.data || [],
    isLoading,
    error,
    createPost: createMutation.mutateAsync,
    updatePost: updateMutation.mutateAsync,
    deletePost: deleteMutation.mutateAsync,
    publishPost: publishMutation.mutateAsync,
    isCreating: createMutation.isPending,
    isUpdating: updateMutation.isPending,
    isDeleting: deleteMutation.isPending,
    isPublishing: publishMutation.isPending,
  };
}
