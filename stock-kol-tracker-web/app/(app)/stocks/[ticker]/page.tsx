import { StockDetailPage } from '@/components/pages/stock-detail-page';

export default function StockDetailPageRoute({
  params,
}: {
  params: { ticker: string };
}) {
  return <StockDetailPage ticker={params.ticker} />;
}
