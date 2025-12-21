import 'package:flutter/material.dart';
import 'kchart_state_adapter.dart';

/// K線圖手勢包裝器
/// 攔截滑動手勢，轉換為以Candlestick為單位的移動
class ChartGestureWrapper extends StatefulWidget {
  final Widget child;
  final KChartStateAdapter stateAdapter;

  const ChartGestureWrapper({
    super.key,
    required this.child,
    required this.stateAdapter,
  });

  @override
  State<ChartGestureWrapper> createState() => _ChartGestureWrapperState();
}

class _ChartGestureWrapperState extends State<ChartGestureWrapper> {
  // 累積的滑動距離（像素）
  double _accumulatedPanDelta = 0.0;
  
  // 上次更新時的索引位置
  int? _lastStartIndex;
  int? _lastEndIndex;

  @override
  void initState() {
    super.initState();
    widget.stateAdapter.addListener(_onStateChanged);
  }

  @override
  void dispose() {
    widget.stateAdapter.removeListener(_onStateChanged);
    super.dispose();
  }

  void _onStateChanged() {
    // 當狀態適配器更新時，同步記錄當前索引位置
    _lastStartIndex = widget.stateAdapter.startIndex;
    _lastEndIndex = widget.stateAdapter.endIndex;
  }

  /// 將像素滑動距離轉換為Candlestick數量
  int _pixelsToCandles(double pixelDelta, double chartWidth, int visibleCount) {
    if (chartWidth == 0 || visibleCount == 0) return 0;
    
    final unitWidth = chartWidth / visibleCount;
    // 使用round()確保以整根Candlestick為單位移動
    return (pixelDelta / unitWidth).round();
  }

  /// 處理滑動手勢更新
  void _handlePanUpdate(DragUpdateDetails details) {
    final chartSize = widget.stateAdapter.chartSize;
    if (chartSize.width == 0) return;

    final visibleCount = widget.stateAdapter.visibleCount;
    if (visibleCount == 0) return;

    // 累積滑動距離（向右滑動為正，向左滑動為負）
    _accumulatedPanDelta += details.delta.dx;

    // 計算每個Candlestick的寬度（像素）
    final unitWidth = chartSize.width / visibleCount;
    
    // 計算需要移動的Candlestick數量（向右滑動顯示更舊數據，索引減小）
    final candleDelta = (_accumulatedPanDelta / unitWidth).round();

    // 如果移動了至少一根Candlestick，執行移動
    if (candleDelta.abs() >= 1) {
      // 獲取當前索引位置
      final currentStartIndex = widget.stateAdapter.startIndex;
      final currentEndIndex = widget.stateAdapter.endIndex;

      // 計算新的索引位置
      // 向右滑動（正delta）→ 顯示更舊的數據（索引減小）
      // 向左滑動（負delta）→ 顯示更新的數據（索引增加）
      final newStartIndex = currentStartIndex - candleDelta;
      final newEndIndex = currentEndIndex - candleDelta;

      // 更新可見範圍（會自動處理邊界）
      widget.stateAdapter.panByCandles(-candleDelta);

      // 重置累積距離（保留餘數，用於下次累積）
      _accumulatedPanDelta = _accumulatedPanDelta - (candleDelta * unitWidth);
    }
  }

  /// 處理滑動手勢結束
  void _handlePanEnd(DragEndDetails details) {
    // 滑動結束時，處理剩餘的未完成移動
    final chartSize = widget.stateAdapter.chartSize;
    if (chartSize.width == 0) {
      _accumulatedPanDelta = 0.0;
      return;
    }

    final visibleCount = widget.stateAdapter.visibleCount;
    if (visibleCount == 0) {
      _accumulatedPanDelta = 0.0;
      return;
    }

    // 如果還有未完成的移動，嘗試完成它
    final remainingCandleDelta = _pixelsToCandles(
      _accumulatedPanDelta,
      chartSize.width,
      visibleCount,
    );

    if (remainingCandleDelta.abs() >= 1) {
      final currentStartIndex = widget.stateAdapter.startIndex;
      final currentEndIndex = widget.stateAdapter.endIndex;

      widget.stateAdapter.setVisibleRangeByIndex(
        (currentStartIndex - remainingCandleDelta).clamp(0, widget.stateAdapter.candles.length - 1),
        (currentEndIndex - remainingCandleDelta).clamp(0, widget.stateAdapter.candles.length - 1),
      );
    }

    // 重置累積距離
    _accumulatedPanDelta = 0.0;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // 攔截水平滑動手勢
      onHorizontalDragUpdate: _handlePanUpdate,
      onHorizontalDragEnd: _handlePanEnd,
      // 允許子組件處理其他手勢（如縮放）
      behavior: HitTestBehavior.translucent,
      child: widget.child,
    );
  }
}

