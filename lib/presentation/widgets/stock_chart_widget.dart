import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/providers/stock_price_provider.dart';
import '../../domain/providers/stock_posts_provider.dart';
import '../../data/database/database.dart';
import '../theme/chart_theme_config.dart';
import 'sentiment_marker.dart';
import 'fl_chart_controller.dart';
import 'candles_painter.dart';
import 'volume_painter.dart';
import 'sentiment_markers_painter.dart';

/// 股價圖表組件（K線圖 + 交易量 + 情緒標記）
/// 使用 CustomPainter 完全自定義實現
class StockChartWidget extends ConsumerStatefulWidget {
  final String ticker;
  final ChartThemeConfig theme;

  const StockChartWidget({
    super.key,
    required this.ticker,
    this.theme = ChartThemeConfig.defaultTheme,
  });

  @override
  ConsumerState<StockChartWidget> createState() => _StockChartWidgetState();
}

class _StockChartWidgetState extends ConsumerState<StockChartWidget> {
  late FlChartController _controller;

  @override
  void initState() {
    super.initState();
    _controller = FlChartController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 使用完整範圍的股價數據（2023/01/01 至今）
    final pricesAsync = ref.watch(stockFullRangePricesProvider(widget.ticker));
    final postsAsync = ref.watch(stockPostsProvider(widget.ticker));

    return pricesAsync.when(
      data: (prices) {
        if (prices.isEmpty) {
          return _buildEmptyState();
        }

        return postsAsync.when(
          data: (posts) => _buildChart(context, prices, posts),
          loading: () => _buildChart(context, prices, []),
          error: (e, s) => _buildChart(context, prices, []),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorState(error),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.candlestick_chart, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            '無股價資料',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          SizedBox(height: 8),
          Text(
            '請確認 Tiingo API Token 設定',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text('載入股價失敗: $error'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () =>
                ref.invalidate(stockFullRangePricesProvider(widget.ticker)),
            child: const Text('重試'),
          ),
        ],
      ),
    );
  }

  Widget _buildChart(
      BuildContext context, List<StockPrice> prices, List<Post> posts) {
    // 更新控制器數據
    _controller.updateData(prices, posts);

    return LayoutBuilder(
      builder: (context, constraints) {
        // 計算圖表高度（固定為400像素，確保有足夠的可視空間）
        final chartHeight = 400.0;
        final chartSize = Size(constraints.maxWidth, chartHeight);

        // 更新圖表尺寸
        _controller.updateSize(chartSize);

        return SingleChildScrollView(
          child: Column(
            children: [
            // 圖表說明
            _buildLegend(),
            const SizedBox(height: 8),
            // K線圖區域
            SizedBox(
              height: chartHeight,
              width: constraints.maxWidth,
              child: GestureDetector(
                onScaleStart: _controller.handleScaleStart,
                onScaleUpdate: _controller.handleScaleUpdate,
                onScaleEnd: _controller.handleScaleEnd,
                child: ListenableBuilder(
                  listenable: _controller,
                  builder: (context, _) {
                    return Stack(
                      children: [
                        // 1. K 線圖層（包含網格和座標軸）
                        CustomPaint(
                          size: chartSize,
                          painter: CandlesPainter(
                            controller: _controller,
                            theme: widget.theme,
                          ),
                        ),
                        // 2. 交易量圖層
                        CustomPaint(
                          size: chartSize,
                          painter: VolumePainter(
                            controller: _controller,
                            theme: widget.theme,
                          ),
                        ),
                        // 3. 情緒標記圖層
                        if (posts.isNotEmpty)
                          CustomPaint(
                            size: chartSize,
                            painter: SentimentMarkersPainter(
                              controller: _controller,
                              theme: widget.theme,
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
            // 刷新按鈕
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      ref.invalidate(stockFullRangePricesProvider(widget.ticker));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('更新股價資料中...'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('刷新'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ],
              ),
            ),
            // 保留統計卡片作為輔助信息
            if (posts.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildPostsSummary(posts),
            ],
          ],
        ),
      );
      },
    );
  }

  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 16,
        runSpacing: 0,
        children: [
          _buildLegendItem(
            widget.theme.bullishColor,
            '看多 (L)',
            SentimentMarker.fromSentiment(
              sentiment: 'Bullish',
              theme: widget.theme,
              size: 16,
            ),
          ),
          _buildLegendItem(
            widget.theme.neutralColor,
            '中性 (N)',
            SentimentMarker.fromSentiment(
              sentiment: 'Neutral',
              theme: widget.theme,
              size: 16,
            ),
          ),
          _buildLegendItem(
            widget.theme.bearishColor,
            '看空 (S)',
            SentimentMarker.fromSentiment(
              sentiment: 'Bearish',
              theme: widget.theme,
              size: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label, Widget marker) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        marker,
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  /// 顯示文檔摘要（輔助信息）
  Widget _buildPostsSummary(List<Post> posts) {
    // 按情緒分組統計
    final bullishCount = posts.where((p) => p.sentiment == 'Bullish').length;
    final bearishCount = posts.where((p) => p.sentiment == 'Bearish').length;
    final neutralCount = posts.where((p) => p.sentiment == 'Neutral').length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '情緒分布',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildSentimentCount(
                      '看多', bullishCount, widget.theme.bullishColor),
                  _buildSentimentCount(
                      '中性', neutralCount, widget.theme.neutralColor),
                  _buildSentimentCount(
                      '看空', bearishCount, widget.theme.bearishColor),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '提示：圖表上的書籤標記顯示文檔發布日期和情緒\n使用雙指縮放（5-365天）和單指平移查看不同時間範圍',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSentimentCount(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
              fontSize: 12, color: color, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 20,
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
