import { DraftEditPage } from '@/components/pages/draft-edit-page';

export default function DraftEditPageRoute({
  params,
}: {
  params: { id: string };
}) {
  return <DraftEditPage postId={params.id} />;
}
