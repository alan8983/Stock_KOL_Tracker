'use client';

import { useState } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import * as z from 'zod';
import { useKOLs } from '@/hooks/use-kols';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Textarea } from '@/components/ui/textarea';

const kolSchema = z.object({
  name: z.string().min(1, '名稱不能為空'),
  bio: z.string().optional(),
  socialLink: z.string().url('請輸入有效的 URL').optional().or(z.literal('')),
});

type KOLFormData = z.infer<typeof kolSchema>;

export function CreateKOLDialog({
  open,
  onOpenChange,
}: {
  open: boolean;
  onOpenChange: (open: boolean) => void;
}) {
  const { createKOL, isCreating } = useKOLs();
  const [error, setError] = useState<string | null>(null);

  const {
    register,
    handleSubmit,
    reset,
    formState: { errors },
  } = useForm<KOLFormData>({
    resolver: zodResolver(kolSchema),
  });

  const onSubmit = async (data: KOLFormData) => {
    setError(null);
    try {
      await createKOL({
        name: data.name,
        bio: data.bio || null,
        social_link: data.socialLink || null,
      });
      reset();
      onOpenChange(false);
    } catch (err: any) {
      setError(err.message || '建立失敗');
    }
  };

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>新增 KOL</DialogTitle>
          <DialogDescription>建立新的 KOL 記錄</DialogDescription>
        </DialogHeader>
        <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
          {error && (
            <div className="rounded-md bg-red-50 p-3 text-sm text-red-800">
              {error}
            </div>
          )}

          <div className="space-y-2">
            <Label htmlFor="name">名稱 *</Label>
            <Input
              id="name"
              {...register('name')}
              placeholder="KOL 名稱"
            />
            {errors.name && (
              <p className="text-sm text-red-600">{errors.name.message}</p>
            )}
          </div>

          <div className="space-y-2">
            <Label htmlFor="bio">簡介</Label>
            <Textarea
              id="bio"
              {...register('bio')}
              placeholder="KOL 簡介（選填）"
              rows={3}
            />
            {errors.bio && (
              <p className="text-sm text-red-600">{errors.bio.message}</p>
            )}
          </div>

          <div className="space-y-2">
            <Label htmlFor="socialLink">社群連結</Label>
            <Input
              id="socialLink"
              type="url"
              {...register('socialLink')}
              placeholder="https://..."
            />
            {errors.socialLink && (
              <p className="text-sm text-red-600">{errors.socialLink.message}</p>
            )}
          </div>

          <DialogFooter>
            <Button
              type="button"
              variant="outline"
              onClick={() => onOpenChange(false)}
            >
              取消
            </Button>
            <Button type="submit" disabled={isCreating}>
              {isCreating ? '建立中...' : '建立'}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}
