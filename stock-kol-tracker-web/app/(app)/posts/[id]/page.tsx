import { PostDetailPage } from '@/components/pages/post-detail-page';

export default function PostDetailPageRoute({
  params,
}: {
  params: { id: string };
}) {
  return <PostDetailPage postId={params.id} />;
}
