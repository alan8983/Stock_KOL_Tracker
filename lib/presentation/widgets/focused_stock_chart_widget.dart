import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/providers/stock_price_provider.dart';
import '../../domain/providers/stock_posts_provider.dart';
import '../../data/database/database.dart';
import '../theme/chart_theme_config.dart';
import 'fl_chart_controller.dart';
import 'candles_painter.dart';
import 'volume_painter.dart';
import 'sentiment_markers_painter.dart';
import 'sentiment_marker.dart';

/// 支持聚焦特定日期的股價圖表組件
class FocusedStockChartWidget extends ConsumerStatefulWidget {
  final String ticker;
  final DateTime? focusDate; // 聚焦日期
  final ChartThemeConfig theme;

  const FocusedStockChartWidget({
    super.key,
    required this.ticker,
    this.focusDate,
    this.theme = ChartThemeConfig.defaultTheme,
  });

  @override
  ConsumerState<FocusedStockChartWidget> createState() =>
      _FocusedStockChartWidgetState();
}

class _FocusedStockChartWidgetState
    extends ConsumerState<FocusedStockChartWidget> {
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
          Text('無股價資料', style: TextStyle(fontSize: 18, color: Colors.grey)),
          SizedBox(height: 8),
          Text('請確認 Tiingo API Token 設定',
              style: TextStyle(fontSize: 14, color: Colors.grey)),
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
    // 使用帶聚焦功能的更新方法
    _controller.updateDataWithFocus(prices, posts, focusDate: widget.focusDate);

    return LayoutBuilder(
      builder: (context, constraints) {
        final chartHeight = 400.0;
        final chartSize = Size(constraints.maxWidth, chartHeight);
        _controller.updateSize(chartSize);

        return SingleChildScrollView(
          child: Column(
            children: [
              // 圖表說明
              _buildLegend(),
              const SizedBox(height: 8),

              // 聚焦日期提示（如果有）
              if (widget.focusDate != null) _buildFocusHint(),

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
                          // 1. K 線圖層
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        ref.invalidate(
                            stockFullRangePricesProvider(widget.ticker));
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
                        padding:
                            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFocusHint() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.center_focus_strong,
              size: 16, color: Colors.blue.shade700),
          const SizedBox(width: 6),
          Text(
            '圖表已聚焦於文檔發布日',
            style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
          ),
        ],
      ),
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
}

