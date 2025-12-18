import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../data/database/database.dart';
import 'chart_layout_config.dart';

/// K 線圖狀態管理器
/// 負責管理可見範圍、縮放、平移和座標轉換
class FlChartController extends ChangeNotifier {
  // 數據
  List<StockPrice> _prices = [];
  List<Post> _posts = [];

  // 聚焦日期（可選）
  DateTime? _focusDate;
  bool _isFocused = false; // 標記是否已執行過聚焦

  // 可見範圍
  int _startIndex = 0;
  int _endIndex = 0;
  int _visibleCount = ChartLayoutConfig.defaultVisibleCandles;

  // 縮放和平移狀態
  double _baseScale = 1.0;
  double _currentScale = 1.0;

  // 圖表尺寸
  Size _chartSize = Size.zero;

  // 價格範圍（基於可見數據）
  double _minPrice = 0;
  double _maxPrice = 0;

  // 交易量範圍
  int _maxVolume = 0;

  // Getters
  List<StockPrice> get prices => _prices;
  List<Post> get posts => _posts;
  int get startIndex => _startIndex;
  int get endIndex => _endIndex;
  int get visibleCount => _visibleCount;
  Size get chartSize => _chartSize;
  double get minPrice => _minPrice;
  double get maxPrice => _maxPrice;
  int get maxVolume => _maxVolume;

  /// 計算 K 線寬度
  double get candleWidth {
    if (_chartSize.width == 0 || _visibleCount == 0) return 0;
    final drawableWidth = _chartSize.width -
        ChartLayoutConfig.leftPadding -
        ChartLayoutConfig.rightPadding;
    return drawableWidth / _visibleCount * ChartLayoutConfig.candleWidthRatio;
  }

  /// 更新數據
  void updateData(List<StockPrice> prices, List<Post> posts) {
    _prices = prices;
    _posts = posts;

    if (_prices.isEmpty) {
      _startIndex = 0;
      _endIndex = 0;
      _visibleCount = ChartLayoutConfig.defaultVisibleCandles;
      return;
    }

    // 初始化可見範圍（顯示最新的數據）
    _visibleCount = math.min(_visibleCount, _prices.length);
    _endIndex = _prices.length - 1;
    _startIndex = math.max(0, _endIndex - _visibleCount + 1);

    _updateVisibleRange();
    notifyListeners();
  }

  /// 更新數據並聚焦到特定日期
  void updateDataWithFocus(
    List<StockPrice> prices,
    List<Post> posts, {
    DateTime? focusDate,
  }) {
    _prices = prices;
    _posts = posts;
    _focusDate = focusDate;
    _isFocused = false; // 重置聚焦狀態

    if (_prices.isEmpty) {
      _startIndex = 0;
      _endIndex = 0;
      _visibleCount = ChartLayoutConfig.defaultVisibleCandles;
      return;
    }

    // 初始化可見範圍
    _visibleCount = math.min(_visibleCount, _prices.length);

    // 如果有聚焦日期，置中該日期
    if (_focusDate != null && !_isFocused) {
      final focusIndex = _findFocusIndex(_focusDate!);
      if (focusIndex != null) {
        _centerOnIndex(focusIndex);
        _isFocused = true; // 標記已聚焦，避免重複執行
      } else {
        // 沒找到聚焦日期，顯示最新數據
        _endIndex = _prices.length - 1;
        _startIndex = math.max(0, _endIndex - _visibleCount + 1);
        _updateVisibleRange();
      }
    } else {
      // 沒有聚焦日期，顯示最新數據
      _endIndex = _prices.length - 1;
      _startIndex = math.max(0, _endIndex - _visibleCount + 1);
      _updateVisibleRange();
    }

    notifyListeners();
  }

  /// 更新圖表尺寸
  void updateSize(Size size) {
    if (_chartSize != size) {
      _chartSize = size;
      notifyListeners();
    }
  }

  /// 更新可見範圍並重新計算價格範圍
  void _updateVisibleRange() {
    if (_prices.isEmpty) return;

    // 確保索引在有效範圍內
    _startIndex = _startIndex.clamp(0, _prices.length - 1);
    _endIndex = (_startIndex + _visibleCount - 1).clamp(_startIndex, _prices.length - 1);

    // 如果 endIndex 到達末尾，調整 startIndex
    if (_endIndex >= _prices.length - 1) {
      _endIndex = _prices.length - 1;
      _startIndex = math.max(0, _endIndex - _visibleCount + 1);
    }

    // 計算可見範圍內的價格範圍
    _calculatePriceRange();
    _calculateVolumeRange();
  }

  /// 計算價格範圍（基於可見數據）
  void _calculatePriceRange() {
    if (_prices.isEmpty || _startIndex >= _prices.length) {
      _minPrice = 0;
      _maxPrice = 0;
      return;
    }

    double min = double.infinity;
    double max = double.negativeInfinity;

    for (int i = _startIndex; i <= _endIndex && i < _prices.length; i++) {
      final price = _prices[i];
      min = math.min(min, price.low);
      max = math.max(max, price.high);
    }

    // 添加 5% 的上下邊距
    final padding = (max - min) * 0.05;
    _minPrice = min - padding;
    _maxPrice = max + padding;

    // 防止除以零
    if (_minPrice == _maxPrice) {
      _minPrice = _minPrice * 0.95;
      _maxPrice = _maxPrice * 1.05;
    }
  }

  /// 計算交易量範圍（基於可見數據）
  void _calculateVolumeRange() {
    if (_prices.isEmpty || _startIndex >= _prices.length) {
      _maxVolume = 0;
      return;
    }

    int max = 0;
    for (int i = _startIndex; i <= _endIndex && i < _prices.length; i++) {
      max = math.max(max, _prices[i].volume);
    }

    _maxVolume = max;
  }

  /// 將價格轉換為 Y 座標
  double priceToY(double price) {
    if (_chartSize.height == 0 || _maxPrice == _minPrice) {
      return _chartSize.height / 2;
    }

    final candleTop = ChartLayoutConfig.topPadding;
    final candleHeight =
        _chartSize.height * ChartLayoutConfig.candleAreaRatio;

    final normalized = (price - _minPrice) / (_maxPrice - _minPrice);
    return candleTop + candleHeight * (1 - normalized);
  }

  /// 將索引轉換為 X 座標
  double indexToX(int index) {
    if (_chartSize.width == 0 || _visibleCount == 0) return 0;

    final drawableWidth = _chartSize.width -
        ChartLayoutConfig.leftPadding -
        ChartLayoutConfig.rightPadding;
    final unitWidth = drawableWidth / _visibleCount;
    final relativeIndex = index - _startIndex;

    return ChartLayoutConfig.leftPadding +
        relativeIndex * unitWidth +
        unitWidth / 2;
  }

  /// 將 X 座標轉換為索引
  int? xToIndex(double x) {
    if (_chartSize.width == 0 || _visibleCount == 0) return null;

    final drawableWidth = _chartSize.width -
        ChartLayoutConfig.leftPadding -
        ChartLayoutConfig.rightPadding;
    final unitWidth = drawableWidth / _visibleCount;

    final relativeX = x - ChartLayoutConfig.leftPadding;
    final relativeIndex = (relativeX / unitWidth).floor();
    final index = _startIndex + relativeIndex;

    if (index < 0 || index >= _prices.length) return null;
    return index;
  }

  // 手勢處理
  void handleScaleStart(ScaleStartDetails details) {
    _baseScale = _currentScale;
  }

  void handleScaleUpdate(ScaleUpdateDetails details) {
    if (details.scale != 1.0) {
      // 縮放：調整可見 K 線數量
      _currentScale = _baseScale / details.scale;
      final newVisibleCount = (_visibleCount * details.scale)
          .round()
          .clamp(ChartLayoutConfig.minVisibleCandles,
              ChartLayoutConfig.maxVisibleCandles);

      if (newVisibleCount != _visibleCount) {
        // 計算縮放中心點，保持焦點位置不變
        final focusX = details.localFocalPoint.dx;
        final focusIndex = xToIndex(focusX);

        _visibleCount = newVisibleCount;

        // 調整起始索引，使焦點處的 K 線保持在相同位置
        if (focusIndex != null) {
          final focusRatio = (focusIndex - _startIndex) / (_endIndex - _startIndex);
          _startIndex = (focusIndex - _visibleCount * focusRatio).round();
        }

        _updateVisibleRange();
        notifyListeners();
      }
    } else if (details.focalPointDelta.dx != 0) {
      // 平移：調整起始索引
      final drawableWidth = _chartSize.width -
          ChartLayoutConfig.leftPadding -
          ChartLayoutConfig.rightPadding;
      final unitWidth = drawableWidth / _visibleCount;
      final indexDelta = -(details.focalPointDelta.dx / unitWidth).round();

      final newStartIndex = (_startIndex + indexDelta)
          .clamp(0, math.max(0, _prices.length - _visibleCount))
          .toInt();

      if (newStartIndex != _startIndex) {
        _startIndex = newStartIndex;
        _updateVisibleRange();
        notifyListeners();
      }
    }
  }

  void handleScaleEnd(ScaleEndDetails details) {
    _baseScale = _currentScale;
  }

  /// 找到聚焦日期對應的 K 線索引
  int? _findFocusIndex(DateTime focusDate) {
    final normalizedTarget = DateTime(
      focusDate.year,
      focusDate.month,
      focusDate.day,
    );

    for (int i = 0; i < _prices.length; i++) {
      final priceDate = DateTime(
        _prices[i].date.year,
        _prices[i].date.month,
        _prices[i].date.day,
      );

      if (priceDate.isAtSameMomentAs(normalizedTarget)) {
        return i; // 精確匹配
      }

      if (priceDate.isAfter(normalizedTarget)) {
        // 找到下一個交易日
        if (priceDate.difference(normalizedTarget).inDays <= 7) {
          return i;
        }
        break;
      }
    }

    return null;
  }

  /// 將指定索引置中
  void _centerOnIndex(int focusIndex) {
    final halfVisible = _visibleCount ~/ 2;
    _startIndex =
        (focusIndex - halfVisible).clamp(0, math.max(0, _prices.length - _visibleCount));
    _updateVisibleRange();
  }

  @override
  void dispose() {
    _prices = [];
    _posts = [];
    super.dispose();
  }
}
