import { KOLDetailPage } from '@/components/pages/kol-detail-page';

export default function KOLDetailPageRoute({
  params,
}: {
  params: { id: string };
}) {
  return <KOLDetailPage kolId={params.id} />;
}
