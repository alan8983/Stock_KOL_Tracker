'use client';

import { useEffect, useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { createClient } from '@/infrastructure/supabase/client';
import { ProfileRepository } from '@/infrastructure/repositories';
import type { Profile } from '@/infrastructure/repositories';

export function useProfile() {
  const supabase = createClient();
  const repository = new ProfileRepository(supabase);

  const {
    data: profile,
    isLoading,
    error,
    refetch,
  } = useQuery<Profile | null>({
    queryKey: ['profile'],
    queryFn: async () => {
      return await repository.getCurrentProfile();
    },
  });

  return {
    profile,
    isLoading,
    error,
    refetch,
  };
}
