import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_chen_kchart/k_chart.dart';
import '../../domain/providers/stock_price_provider.dart';
import '../../domain/providers/stock_posts_provider.dart';
import '../../data/database/database.dart';
import '../theme/chart_theme_config.dart';
import 'sentiment_marker.dart';
import 'kchart_state_adapter.dart';
import 'kchart_sentiment_markers_painter.dart';
import '../utils/candle_aggregator.dart';
import 'chart_interval_selector.dart';


/// 股價圖表組件（K線圖 + 交易量 + 情緒標記）
/// 使用 flutter_chen_kchart 套件實現
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
  late KChartController _kchartController;
  late KChartStateAdapter _stateAdapter;
  
  // K線間隔和時間範圍狀態
  CandleInterval _selectedInterval = CandleInterval.daily;
  TimeRange _selectedRange = TimeRange.oneYear;

  @override
  void initState() {
    super.initState();
    _kchartController = KChartController();
    _stateAdapter = KChartStateAdapter();
  }

  @override
  void dispose() {
    _stateAdapter.dispose();
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
    // 1. 根據時間範圍過濾數據
    final startDate = ChartIntervalSelector.calculateStartDate(_selectedRange);
    final filteredPrices = prices.where((price) {
      final priceDate = DateTime(price.date.year, price.date.month, price.date.day);
      return priceDate.isAfter(startDate) || priceDate.isAtSameMomentAs(startDate);
    }).toList();

    // 2. 根據K線間隔聚合數據
    final aggregatedPrices = CandleAggregator.aggregate(filteredPrices, _selectedInterval);

    // 3. 更新狀態適配器數據
    _stateAdapter.updateData(aggregatedPrices, posts);
    
    // 4. 獲取 KLineEntity 列表
    final kchartData = _stateAdapter.candles;

    return LayoutBuilder(
      builder: (context, constraints) {
        // 計算圖表高度（固定為400像素，確保有足夠的可視空間）
        const chartHeight = 400.0;
        final chartSize = Size(constraints.maxWidth, chartHeight);

        // 更新圖表尺寸
        _stateAdapter.updateSize(chartSize);

        return SingleChildScrollView(
          child: Column(
            children: [
            // K線間隔和時間範圍選擇器
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: ChartIntervalSelector(
                selectedInterval: _selectedInterval,
                selectedRange: _selectedRange,
                onIntervalChanged: (interval) {
                  setState(() {
                    _selectedInterval = interval;
                  });
                },
                onRangeChanged: (range) {
                  setState(() {
                    _selectedRange = range;
                  });
                },
              ),
            ),
            const SizedBox(height: 8),
            // 圖表說明
            _buildLegend(),
            const SizedBox(height: 8),
            // K線圖區域
            SizedBox(
              height: chartHeight,
              width: constraints.maxWidth,
              child: ListenableBuilder(
                listenable: _stateAdapter,
                builder: (context, _) {
                  return Stack(
                    children: [
                      // 1. K線圖（使用 flutter_chen_kchart 套件）
                      // K線圖已經內建了手勢處理（縮放、平移），不需要額外包裝
                      KChartWidget(
                        kchartData,
                        controller: _kchartController,
                        mainState: MainState.MA,
                        isLine: false, // 使用 K線圖而非線圖
                        volHidden: false, // 顯示交易量
                        secondaryState: SecondaryState.NONE, // 不顯示副圖指標
                        isTrendLine: false, // 不使用趨勢線模式
                        enableTheme: true,
                        minScale: 0.1,
                        maxScale: 5.0,
                        scaleSensitivity: 2.5,
                        enablePinchZoom: true,
                        enableScrollZoom: true,
                        onScaleChanged: (scale) {
                          // 縮放變化時，更新狀態適配器
                          _stateAdapter.setScale(scale);
                        },
                        isOnDrag: (isDragging) {
                          // 拖拽結束後，使用當前縮放比例重新計算可見範圍
                          // 這有助於在拖拽後同步標記位置
                          if (!isDragging) {
                            final currentScale = _kchartController.currentScale;
                            _stateAdapter.setScale(currentScale);
                          }
                        },
                        onLoadMore: (isRightEdge) {
                          // 檢測邊界情況，更新可見範圍
                          // isRightEdge = true 表示滾動到右側邊界（最新數據）
                          // isRightEdge = false 表示滾動到左側邊界（最舊數據）
                          if (isRightEdge) {
                            _stateAdapter.setToLatest();
                          } else {
                            _stateAdapter.setToOldest();
                          }
                        },
                      ),
                      // 2. 情緒標記圖層（使用 IgnorePointer 確保不攔截手勢）
                      if (posts.isNotEmpty)
                        IgnorePointer(
                          child: CustomPaint(
                            size: chartSize,
                            painter: KChartSentimentMarkersPainter(
                              stateAdapter: _stateAdapter,
                              theme: widget.theme,
                            ),
                          ),
                        ),
                    ],
                  );
                },
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
