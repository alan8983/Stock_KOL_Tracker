import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_chen_kchart/k_chart.dart';
import '../../data/database/database.dart';
import '../utils/kchart_data_converter.dart';

/// K線圖狀態適配器
/// 追蹤圖表的可見範圍和縮放狀態，提供座標轉換功能（用於情緒標記定位）
/// 
/// 注意：此適配器需要與 flutter_chen_kchart 的實際 API 配合使用
/// 如果套件提供 Controller，則封裝套件的 Controller
/// 如果套件不提供狀態訪問，則需要通過手勢事件來維護狀態
class KChartStateAdapter extends ChangeNotifier {
  // K線數據（使用 KLineEntity）
  List<KLineEntity> _candles = [];
  
  // 輔助：保留 KChartData 用於日期匹配（臨時）
  List<KChartData> _kchartData = [];
  
  // 文檔數據（用於情緒標記）
  List<Post> _posts = [];
  
  // 圖表尺寸
  Size _chartSize = Size.zero;
  
  // 可見範圍（基於索引）
  int _startIndex = 0;
  int _endIndex = 0;
  int _visibleCount = 60; // 預設顯示 60 根 K線
  
  // 基礎可見數量（用於根據縮放比例計算實際可見數量）
  // 這個值表示在 scale = 1.0 時顯示的 K 線數量
  static const int _baseVisibleCount = 60;
  
  // 價格範圍（基於可見數據）
  double _minPrice = 0;
  double _maxPrice = 0;
  
  // 交易量範圍
  double _maxVolume = 0;
  
  // 縮放比例
  double _scale = 1.0;
  
  // 偏移量（用於平移）
  double _offset = 0.0;

  // 交互狀態和 Marker 可見性控制
  bool _isInteracting = false;
  bool _markersVisible = true;
  Timer? _debounceTimer;
  bool _isAtBoundary = true; // 是否在邊界位置

  // Getters
  List<KLineEntity> get candles => _candles;
  List<KChartData> get kchartData => _kchartData; // 用於日期匹配
  List<Post> get posts => _posts;
  Size get chartSize => _chartSize;
  int get startIndex => _startIndex;
  int get endIndex => _endIndex;
  int get visibleCount => _visibleCount;
  double get minPrice => _minPrice;
  double get maxPrice => _maxPrice;
  double get maxVolume => _maxVolume;
  double get scale => _scale;
  double get offset => _offset;
  bool get markersVisible => _markersVisible;
  bool get isAtBoundary => _isAtBoundary;

  /// 更新數據
  void updateData(List<StockPrice> prices, List<Post> posts) {
    _candles = KChartDataConverter.convertToKLineEntities(prices);
    _kchartData = KChartDataConverter.convertToKChartData(prices); // 用於日期匹配
    _posts = posts;

    if (_candles.isEmpty) {
      _startIndex = 0;
      _endIndex = 0;
      _visibleCount = 60;
      _updatePriceRange();
      return;
    }

    // 初始化可見範圍（顯示最新的數據）
    // 確保下界不大於上界：如果數據量少於5，則使用全部數據
    final minVisible = _candles.length < 5 ? _candles.length : 5;
    _visibleCount = _visibleCount.clamp(minVisible, _candles.length);
    _endIndex = _candles.length - 1;
    _startIndex = (_endIndex - _visibleCount + 1).clamp(0, _candles.length - 1);

    _updatePriceRange();
    notifyListeners();
  }

  /// 更新圖表尺寸
  void updateSize(Size size) {
    if (_chartSize != size) {
      _chartSize = size;
      notifyListeners();
    }
  }

  /// 設置可見範圍
  void setVisibleRange(int startIndex, int endIndex) {
    if (startIndex < 0 || endIndex >= _candles.length || startIndex > endIndex) {
      return;
    }
    
    _startIndex = startIndex;
    _endIndex = endIndex;
    _visibleCount = endIndex - startIndex + 1;
    
    _updatePriceRange();
    notifyListeners();
  }

  /// 精確設置可見範圍（通過索引）
  void setVisibleRangeByIndex(int startIndex, int endIndex) {
    if (_candles.isEmpty) return;
    
    // 確保索引在有效範圍內
    final clampedStart = startIndex.clamp(0, _candles.length - 1);
    final clampedEnd = endIndex.clamp(clampedStart, _candles.length - 1);
    
    // 確保範圍至少包含一根K線
    if (clampedEnd < clampedStart) return;
    
    _startIndex = clampedStart;
    _endIndex = clampedEnd;
    _visibleCount = clampedEnd - clampedStart + 1;
    
    _updatePriceRange();
    notifyListeners();
  }

  /// 以Candlestick為單位平移
  /// delta > 0: 向右移動（顯示更新的數據）
  /// delta < 0: 向左移動（顯示更舊的數據）
  void panByCandles(int delta) {
    if (_candles.isEmpty || delta == 0) return;
    
    final newStartIndex = _startIndex + delta;
    final newEndIndex = _endIndex + delta;
    
    // 檢查邊界
    if (newStartIndex < 0) {
      // 到達左側邊界，移動到最開始
      setVisibleRangeByIndex(0, _visibleCount - 1);
      return;
    }
    
    if (newEndIndex >= _candles.length) {
      // 到達右側邊界，移動到最新
      final clampedEnd = _candles.length - 1;
      final clampedStart = (clampedEnd - _visibleCount + 1).clamp(0, clampedEnd);
      setVisibleRangeByIndex(clampedStart, clampedEnd);
      return;
    }
    
    // 正常移動
    setVisibleRangeByIndex(newStartIndex, newEndIndex);
  }

  // 縮放相關的節流控制
  DateTime? _lastScaleUpdateTime;
  static const _scaleUpdateThrottleMs = 16; // 約60fps

  /// 設置縮放比例
  /// 同時根據縮放比例更新可見範圍
  /// 使用節流機制避免過於頻繁的更新
  void setScale(double scale) {
    final now = DateTime.now();
    
    // 節流：限制更新頻率
    if (_lastScaleUpdateTime != null) {
      final elapsed = now.difference(_lastScaleUpdateTime!);
      if (elapsed.inMilliseconds < _scaleUpdateThrottleMs) {
        // 跳過此次更新，但記錄最新的scale值
        _scale = scale.clamp(0.1, 5.0);
        return;
      }
    }
    
    _lastScaleUpdateTime = now;
    _scale = scale.clamp(0.1, 5.0);
    _updateVisibleRangeFromScale();
  }
  
  /// 根據縮放比例更新可見範圍
  /// scale < 1.0 表示縮小（看到更多 K 線），scale > 1.0 表示放大（看到更少 K 線）
  void _updateVisibleRangeFromScale() {
    if (_candles.isEmpty) {
      notifyListeners();
      return;
    }
    
    // 根據縮放比例計算可見數量
    // 當 scale = 1.0 時，可見數量 = _baseVisibleCount
    // 當 scale < 1.0（縮小）時，可見數量增加
    // 當 scale > 1.0（放大）時，可見數量減少
    final newVisibleCount = (_baseVisibleCount / _scale).round();
    // 確保下界不大於上界：如果數據量少於5，則使用全部數據
    final minVisible = _candles.length < 5 ? _candles.length : 5;
    final clampedVisibleCount = newVisibleCount.clamp(minVisible, _candles.length);
    
    // 如果可見數量沒有變化，不需要更新
    if (clampedVisibleCount == _visibleCount) {
      return;
    }
    
    // 保持當前可見範圍的中心點不變（如果可能）
    final currentCenterIndex = (_startIndex + _endIndex) ~/ 2;
    final halfVisible = clampedVisibleCount ~/ 2;
    
    _visibleCount = clampedVisibleCount;
    
    // 計算新的起始和結束索引，盡量保持中心點
    var newStartIndex = (currentCenterIndex - halfVisible).clamp(0, _candles.length - clampedVisibleCount);
    var newEndIndex = newStartIndex + clampedVisibleCount - 1;
    
    // 如果到達邊界，調整到邊界
    if (newEndIndex >= _candles.length) {
      newEndIndex = _candles.length - 1;
      newStartIndex = (newEndIndex - clampedVisibleCount + 1).clamp(0, newEndIndex);
    }
    
    _startIndex = newStartIndex;
    _endIndex = newEndIndex;
    
    _updatePriceRange();
    notifyListeners();
  }

  /// 設置偏移量
  void setOffset(double offset) {
    _offset = offset;
    notifyListeners();
  }

  /// 更新價格範圍（基於可見數據）
  void _updatePriceRange() {
    if (_candles.isEmpty || _startIndex >= _candles.length) {
      _minPrice = 0;
      _maxPrice = 0;
      _maxVolume = 0;
      return;
    }

    double min = double.infinity;
    double max = double.negativeInfinity;
    double maxVol = 0;

    final endIdx = (_endIndex + 1).clamp(0, _candles.length);
    for (int i = _startIndex; i < endIdx; i++) {
      final candle = _candles[i];
      min = min < candle.low ? min : candle.low;
      max = max > candle.high ? max : candle.high;
      maxVol = maxVol > candle.vol ? maxVol : candle.vol;
    }

    // 添加 5% 的上下邊距
    final padding = (max - min) * 0.05;
    _minPrice = min - padding;
    _maxPrice = max + padding;
    _maxVolume = maxVol;

    // 防止除以零
    if (_minPrice == _maxPrice) {
      _minPrice = _minPrice * 0.95;
      _maxPrice = _maxPrice * 1.05;
    }
  }

  /// 將價格轉換為 Y 座標
  /// 假設 K線區域佔圖表高度的 70%，交易量區域佔 20%
  double priceToY(double price) {
    if (_chartSize.height == 0 || _maxPrice == _minPrice) {
      return _chartSize.height / 2;
    }

    // K線區域配置（與 ChartLayoutConfig 保持一致）
    const topPadding = 20.0;
    const candleAreaRatio = 0.70;
    final candleTop = topPadding;
    final candleHeight = _chartSize.height * candleAreaRatio;

    final normalized = (price - _minPrice) / (_maxPrice - _minPrice);
    return candleTop + candleHeight * (1 - normalized); // Y軸反轉
  }

  /// 將索引轉換為 X 座標
  /// 假設左側留 50px，右側留 10px
  double indexToX(int index) {
    if (_chartSize.width == 0 || _visibleCount == 0) return 0;

    const leftPadding = 50.0;
    const rightPadding = 10.0;
    final drawableWidth = _chartSize.width - leftPadding - rightPadding;
    final unitWidth = drawableWidth / _visibleCount;
    final relativeIndex = index - _startIndex;

    return leftPadding + relativeIndex * unitWidth + unitWidth / 2;
  }

  /// 將 X 座標轉換為索引
  int? xToIndex(double x) {
    if (_chartSize.width == 0 || _visibleCount == 0) return null;

    const leftPadding = 50.0;
    const rightPadding = 10.0;
    final drawableWidth = _chartSize.width - leftPadding - rightPadding;
    final unitWidth = drawableWidth / _visibleCount;

    final relativeX = x - leftPadding;
    final relativeIndex = (relativeX / unitWidth).floor();
    final index = _startIndex + relativeIndex;

    if (index < 0 || index >= _candles.length) return null;
    return index;
  }

  /// 找到與指定日期對應的 K線索引
  int? findCandleIndexByDate(DateTime targetDate) {
    return KChartDataConverter.findCandleIndexByDate(targetDate, _kchartData);
  }

  /// 聚焦到指定日期
  /// 將該日期置中顯示
  void focusOnDate(DateTime focusDate) {
    final index = findCandleIndexByDate(focusDate);
    if (index == null) return;

    final halfVisible = _visibleCount ~/ 2;
    final newStartIndex = (index - halfVisible).clamp(0, (_candles.length - _visibleCount).clamp(0, _candles.length));
    
    setVisibleRange(newStartIndex, newStartIndex + _visibleCount - 1);
  }

  /// 設置為顯示最新數據（從 onLoadMore(true) 調用）
  /// 當用戶滾動到右側邊界時，表示正在查看最新數據
  void setToLatest() {
    if (_candles.isEmpty) return;
    _endIndex = _candles.length - 1;
    _startIndex = (_endIndex - _visibleCount + 1).clamp(0, _candles.length - 1);
    _updatePriceRange();
    notifyListeners();
  }

  /// 設置為顯示最舊數據（從 onLoadMore(false) 調用）
  /// 當用戶滾動到左側邊界時，表示正在查看最舊數據
  void setToOldest() {
    if (_candles.isEmpty) return;
    _startIndex = 0;
    _endIndex = (_visibleCount - 1).clamp(0, _candles.length - 1);
    _updatePriceRange();
    notifyListeners();
  }

  /// 設置交互狀態（從 isOnDrag/onScaleChanged 調用）
  /// 當用戶開始交互時隱藏 Marker，結束交互後 500ms 重新顯示
  void setInteracting(bool interacting) {
    _isInteracting = interacting;
    if (interacting) {
      // 開始交互：隱藏 Marker
      _markersVisible = false;
      _debounceTimer?.cancel();
      notifyListeners();
    } else {
      // 結束交互：啟動防抖 Timer
      _debounceTimer?.cancel();
      _debounceTimer = Timer(Duration(milliseconds: 500), () {
        _markersVisible = true;
        notifyListeners();
      });
    }
  }

  /// 設置邊界狀態（從 onLoadMore 調用）
  /// 當滾動到邊界時，更新可見範圍並標記為邊界位置
  void setBoundaryState(bool isRightEdge) {
    _isAtBoundary = true;
    if (isRightEdge) {
      setToLatest();
    } else {
      setToOldest();
    }
  }

  /// 離開邊界（滾動到中間位置）
  /// 當開始拖拽時調用，表示可能不在邊界位置
  void leaveBoundary() {
    _isAtBoundary = false;
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _candles = [];
    _posts = [];
    super.dispose();
  }
}

