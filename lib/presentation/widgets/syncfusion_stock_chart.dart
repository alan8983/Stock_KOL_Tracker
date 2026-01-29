import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';
import '../../data/database/database.dart';
import '../../domain/providers/stock_price_provider.dart';
import '../../domain/providers/stock_posts_provider.dart';
import '../theme/chart_theme_config.dart';
import '../utils/candle_aggregator.dart';
import '../utils/marker_position_calculator.dart';
import '../widgets/chart_interval_selector.dart';
import '../widgets/sentiment_marker.dart';
import 'marker_bubble_overlay.dart';

/// Syncfusion K 線圖組件
/// 使用 syncfusion_flutter_charts 實現 K 線圖和情緒標記
class SyncfusionStockChart extends ConsumerStatefulWidget {
  final String ticker;
  final DateTime? focusDate;
  final ChartThemeConfig theme;

  const SyncfusionStockChart({
    super.key,
    required this.ticker,
    this.focusDate,
    this.theme = ChartThemeConfig.defaultTheme,
  });

  @override
  ConsumerState<SyncfusionStockChart> createState() => _SyncfusionStockChartState();
}

class _SyncfusionStockChartState extends ConsumerState<SyncfusionStockChart> {
  // K線間隔和時間範圍狀態
  CandleInterval _selectedInterval = CandleInterval.daily;
  TimeRange _selectedRange = TimeRange.oneYear;
  
  // 長按氣泡狀態
  OverlayEntry? _bubbleOverlay;
  List<Post>? _currentBubblePosts;
  Offset? _bubblePosition;

  @override
  void dispose() {
    _closeBubble();
    super.dispose();
  }

  void _closeBubble() {
    _bubbleOverlay?.remove();
    _bubbleOverlay = null;
    _currentBubblePosts = null;
    _bubblePosition = null;
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

    // 3. 計算 Marker 位置
    final markerPositions = MarkerPositionCalculator.calculatePositions(
      aggregatedPrices,
      posts,
      _selectedInterval,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        const chartHeight = 400.0;

        return SingleChildScrollView(
          child: Column(
            children: [
              // 聚焦日期提示（如果有）- 移到圖表上方
              if (widget.focusDate != null) ...[
                _buildFocusHint(),
                const SizedBox(height: 8),
              ],
              // K線圖區域（保持固定高度和寬度，確保座標系統不變）
              SizedBox(
                height: chartHeight,
                width: constraints.maxWidth,
                child: _buildSyncfusionChart(aggregatedPrices, markerPositions),
              ),
              // K線間隔和時間範圍選擇器（移到圖表下方）
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
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
              // 圖表說明（移到選擇器下方）
              _buildLegend(),
              const SizedBox(height: 8),
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

  Widget _buildSyncfusionChart(
    List<StockPrice> prices,
    Map<DateTime, List<Post>> markerPositions,
  ) {
    return SfCartesianChart(
      primaryXAxis: DateTimeAxis(
        dateFormat: DateFormat('MM/dd'),
        // intervalType 已移除，讓圖表自動計算間隔
        labelStyle: TextStyle(fontSize: 10, color: widget.theme.textColor),
        majorGridLines: MajorGridLines(
          color: widget.theme.gridLineColor,
          width: 0.5,
        ),
      ),
      primaryYAxis: NumericAxis(
        labelStyle: TextStyle(fontSize: 10, color: widget.theme.textColor),
        majorGridLines: MajorGridLines(
          color: widget.theme.gridLineColor,
          width: 0.5,
        ),
      ),
      plotAreaBackgroundColor: widget.theme.backgroundColor,
      series: <CartesianSeries>[
        // K 線圖
        CandleSeries<StockPrice, DateTime>(
          dataSource: prices,
          xValueMapper: (data, _) => data.date,
          lowValueMapper: (data, _) => data.low,
          highValueMapper: (data, _) => data.high,
          openValueMapper: (data, _) => data.open,
          closeValueMapper: (data, _) => data.close,
          bullColor: widget.theme.increasingColor,
          bearColor: widget.theme.decreasingColor,
          name: 'K線',
          // 動畫設置：加快動畫速度（從默認 1500ms 縮短到 600ms）
          animationDuration: 600,
        ),
        // 交易量（使用次要 Y 軸）
        ColumnSeries<StockPrice, DateTime>(
          dataSource: prices,
          xValueMapper: (data, _) => data.date,
          yValueMapper: (data, _) => data.volume.toDouble(),
          yAxisName: 'volumeAxis',
          color: widget.theme.volumeIncreasingColor.withOpacity(0.3),
          name: '交易量',
          // 動畫設置：加快動畫速度（從默認 1500ms 縮短到 600ms）
          animationDuration: 600,
        ),
      ],
      // 次要 Y 軸（交易量）
      axes: <ChartAxis>[
        NumericAxis(
          name: 'volumeAxis',
          opposedPosition: true,
          isVisible: false,
        ),
      ],
      // 情緒標記 Annotation
      annotations: _buildAnnotations(prices, markerPositions),
      // 縮放平移
      zoomPanBehavior: ZoomPanBehavior(
        enablePinching: true,
        enablePanning: true,
        zoomMode: ZoomMode.x,
      ),
      // Trackball（顯示詳細信息）
      trackballBehavior: TrackballBehavior(
        enable: true,
        activationMode: ActivationMode.longPress,
        tooltipSettings: InteractiveTooltip(
          enable: true,
          color: widget.theme.backgroundColor,
          borderColor: widget.theme.gridLineColor,
          borderWidth: 1,
        ),
      ),
    );
  }

  List<CartesianChartAnnotation> _buildAnnotations(
    List<StockPrice> prices,
    Map<DateTime, List<Post>> markerPositions,
  ) {
    final List<CartesianChartAnnotation> annotations = [];

    if (prices.isEmpty || markerPositions.isEmpty) {
      return annotations;
    }

    // 計算價格範圍（用於計算偏移量）
    double minPrice = prices.first.low;
    double maxPrice = prices.first.high;
    for (final price in prices) {
      if (price.low < minPrice) minPrice = price.low;
      if (price.high > maxPrice) maxPrice = price.high;
    }

    // 計算1/8圖表高度對應的價格偏移量
    // 圖表高度400.0，1/8 = 50像素
    const chartHeight = 400.0;
    const offsetInPixels = chartHeight / 8.0; // 約50像素
    const plotAreaRatio = 0.75; // K線圖區域約佔75%（預留空間給交易量等）
    final plotAreaHeight = chartHeight * plotAreaRatio;
    
    // 將像素偏移轉換為價格偏移
    // 假設價格範圍均勻分布在plotAreaHeight中
    final priceRange = maxPrice - minPrice;
    final priceOffset = (priceRange / plotAreaHeight) * offsetInPixels;

    for (final entry in markerPositions.entries) {
      final candleDate = entry.key;
      final posts = entry.value;
      
      // 找到對應的 K 線數據
      final candle = prices.firstWhere(
        (c) {
          final cDate = DateTime(c.date.year, c.date.month, c.date.day);
          return cDate.isAtSameMomentAs(candleDate);
        },
        orElse: () => prices.first,
      );

      final sentiment = posts.first.sentiment;
      
      // 創建 Marker Widget（支援長按）
      final markerWidget = GestureDetector(
        onLongPress: () {
          _showBubble(context, posts, candleDate);
        },
        child: SentimentMarker.fromSentiment(
          sentiment: sentiment,
          theme: widget.theme,
          size: 20.0,
        ),
      );

      // 計算Marker的Y座標，距離K線約1/8圖表高度
      double markerY;
      if (sentiment == 'Bearish') {
        // 看空：在上方（high + 偏移）
        markerY = candle.high + priceOffset;
        // 確保不超出圖表最大價格範圍（加上一些padding）
        final maxAllowedPrice = maxPrice + priceRange * 0.1; // 允許10%的padding
        if (markerY > maxAllowedPrice) {
          markerY = maxAllowedPrice;
        }
      } else {
        // 看多/中性：在下方（low - 偏移）
        markerY = candle.low - priceOffset;
        // 確保不低於圖表最小價格範圍（減去一些padding）
        final minAllowedPrice = minPrice - priceRange * 0.1; // 允許10%的padding
        if (markerY < minAllowedPrice) {
          markerY = minAllowedPrice;
        }
      }

      annotations.add(
        CartesianChartAnnotation(
          widget: markerWidget,
          coordinateUnit: CoordinateUnit.point,
          x: candleDate,
          y: markerY,
        ),
      );
    }

    return annotations;
  }

  void _showBubble(BuildContext context, List<Post> posts, DateTime candleDate) {
    _closeBubble();

    // 計算氣泡位置（在 Marker 附近）
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final size = renderBox.size;
    final position = Offset(size.width * 0.5, size.height * 0.3);

    _currentBubblePosts = posts;
    _bubblePosition = position;

    _bubbleOverlay = OverlayEntry(
      builder: (context) => MarkerBubbleOverlay(
        posts: posts,
        position: position,
        onDismiss: _closeBubble,
      ),
    );

    Overlay.of(context).insert(_bubbleOverlay!);
  }

  // _getIntervalType() 方法已移除，因為 DateIntervalType 不再需要
  // DateTimeAxis 會根據數據自動計算合適的間隔

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

  Widget _buildPostsSummary(List<Post> posts) {
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
                '提示：圖表上的書籤標記顯示文檔發布日期和情緒\n長按標記查看文檔清單，使用雙指縮放和平移查看不同時間範圍',
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
}

