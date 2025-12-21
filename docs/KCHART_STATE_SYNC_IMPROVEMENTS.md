# K線圖狀態同步改進方案

## 問題總結

經過深入分析 `flutter_chen_kchart` 源碼，發現以下關鍵問題：

### 1. 無法訪問的內部狀態

`KChartWidget` 內部使用以下私有狀態：
- `mScaleX` - 縮放比例
- `mScrollX` - 滾動偏移（像素）
- `mStartIndex` / `mStopIndex` - 可見範圍（動態計算）
- `mTranslateX` - 平移偏移
- `mPointWidth` - K 線寬度（根據 scaleX 計算）

這些都是私有狀態，無法直接訪問。

### 2. 可用的 API 限制

| API | 可用性 | 限制 |
|-----|--------|------|
| `KChartController.currentScale` | ✅ | 只能獲取縮放比例，無法獲取滾動位置 |
| `onScaleChanged` 回調 | ✅ | 僅提供縮放比例 |
| `isOnDrag` 回調 | ⚠️ | 僅提供拖拽狀態（true/false），無位置信息 |
| `onLoadMore` 回調 | ⚠️ | 僅在滾動到邊界時觸發 |

### 3. 當前實現的問題

1. **可見範圍不準確**：
   - `KChartStateAdapter` 的 `_startIndex` 和 `_endIndex` 在初始化後不再更新
   - 實際圖表的可見範圍會隨縮放/平移而變化

2. **座標轉換假設不準確**：
   - `indexToX()` 方法基於假設的布局參數（leftPadding=50px）
   - 實際圖表的布局參數可能不同

3. **縮放/平移不同步**：
   - 只有縮放比例通過回調更新
   - 平移狀態無法獲取

## 改進方案

### 方案 1：基於縮放比例的估算（當前可行方案）

**策略**：使用 `onScaleChanged` 回調來估算可見範圍

**實現邏輯**：
```dart
void setScale(double scale) {
  _scale = scale.clamp(0.1, 5.0);
  
  // 根據縮放比例計算可見數量
  // scale < 1.0 = 縮小（看到更多），scale > 1.0 = 放大（看到更少）
  final baseVisibleCount = 60; // 基礎可見數量（需要根據實際調整）
  final newVisibleCount = (baseVisibleCount / scale).round();
  _visibleCount = newVisibleCount.clamp(5, _candles.length);
  
  // 假設顯示最新數據（從右側開始）
  if (_candles.isNotEmpty) {
    _endIndex = _candles.length - 1;
    _startIndex = (_endIndex - _visibleCount + 1).clamp(0, _candles.length - 1);
    _updatePriceRange();
    notifyListeners();
  }
}
```

**優點**：
- 簡單易實現
- 利用現有 API

**缺點**：
- 無法處理平移情況
- 如果用戶滾動到歷史數據，標記位置會錯誤

### 方案 2：添加 isOnDrag 監聽（增強方案）

**策略**：使用 `isOnDrag` 回調來檢測拖拽狀態，拖拽結束後重新計算

**實現**：
```dart
// 在 StockChartWidget 中
KChartWidget(
  // ... 其他參數
  isOnDrag: (isDragging) {
    if (!isDragging) {
      // 拖拽結束後，使用當前縮放比例重新計算可見範圍
      final currentScale = _kchartController.currentScale;
      _stateAdapter.setScale(currentScale);
    }
  },
)
```

**優點**：
- 可以檢測拖拽結束事件
- 拖拽後可以重新計算

**缺點**：
- 仍然無法獲取精確的滾動位置
- 只能基於縮放比例估算

### 方案 3：使用 onLoadMore 檢測邊界（輔助方案）

**策略**：使用 `onLoadMore` 回調來檢測是否滾動到邊界

**實現**：
```dart
// 在 StockChartWidget 中
KChartWidget(
  // ... 其他參數
  onLoadMore: (isRightEdge) {
    if (isRightEdge) {
      // 滾動到右側邊界（最新數據）
      _stateAdapter.setToLatest();
    }
    // isRightEdge = false 表示左側邊界（最舊數據）
    // 這種情況下，我們可以設置 _startIndex = 0
  },
)
```

**在 KChartStateAdapter 中添加**：
```dart
/// 設置為顯示最新數據
void setToLatest() {
  if (_candles.isEmpty) return;
  _endIndex = _candles.length - 1;
  _startIndex = (_endIndex - _visibleCount + 1).clamp(0, _candles.length - 1);
  _updatePriceRange();
  notifyListeners();
}
```

### 方案 4：改進座標轉換（需要測試）

**問題**：當前假設 leftPadding = 50px，但實際值可能不同

**解決**：通過實際測試確定正確的布局參數，或使用更靈活的計算方式

**建議**：
1. 創建測試頁面，顯示多個已知位置的標記
2. 對比實際位置與計算位置
3. 調整布局參數

## 推薦的綜合改進方案

結合方案 1、2、3，實現以下改進：

### 1. 改進 KChartStateAdapter

```dart
class KChartStateAdapter extends ChangeNotifier {
  // 基礎可見數量（需要根據實際圖表尺寸調整）
  static const int _baseVisibleCount = 60;
  
  /// 設置縮放比例（從 onScaleChanged 調用）
  void setScale(double scale) {
    _scale = scale.clamp(0.1, 5.0);
    _updateVisibleRangeFromScale();
  }
  
  /// 根據縮放比例更新可見範圍
  void _updateVisibleRangeFromScale() {
    if (_candles.isEmpty) return;
    
    // 計算新的可見數量
    final newVisibleCount = (_baseVisibleCount / _scale).round();
    _visibleCount = newVisibleCount.clamp(5, _candles.length);
    
    // 假設顯示最新數據（這個假設在用戶滾動到歷史數據時會不準確）
    _endIndex = _candles.length - 1;
    _startIndex = (_endIndex - _visibleCount + 1).clamp(0, _candles.length - 1);
    
    _updatePriceRange();
    notifyListeners();
  }
  
  /// 設置為顯示最新數據（從 onLoadMore(true) 調用）
  void setToLatest() {
    if (_candles.isEmpty) return;
    _endIndex = _candles.length - 1;
    _startIndex = (_endIndex - _visibleCount + 1).clamp(0, _candles.length - 1);
    _updatePriceRange();
    notifyListeners();
  }
  
  /// 設置為顯示最舊數據（從 onLoadMore(false) 調用）
  void setToOldest() {
    if (_candles.isEmpty) return;
    _startIndex = 0;
    _endIndex = (_visibleCount - 1).clamp(0, _candles.length - 1);
    _updatePriceRange();
    notifyListeners();
  }
}
```

### 2. 改進 StockChartWidget

```dart
KChartWidget(
  kchartData,
  controller: _kchartController,
  // ... 其他參數
  onScaleChanged: (scale) {
    _stateAdapter.setScale(scale);
  },
  isOnDrag: (isDragging) {
    if (!isDragging) {
      // 拖拽結束後，使用當前縮放比例重新計算
      final currentScale = _kchartController.currentScale;
      _stateAdapter.setScale(currentScale);
    }
  },
  onLoadMore: (isRightEdge) {
    if (isRightEdge) {
      // 滾動到右側邊界（最新數據）
      _stateAdapter.setToLatest();
    } else {
      // 滾動到左側邊界（最舊數據）
      _stateAdapter.setToOldest();
    }
  },
)
```

## 局限性說明

### 已知限制

1. **平移精度**：
   - 無法獲取精確的滾動位置
   - 當用戶滾動到歷史數據中間位置時，標記位置可能不準確
   - 只有在邊界位置（最新/最舊）時，位置才相對準確

2. **初始可見範圍**：
   - 基礎可見數量（`_baseVisibleCount`）需要根據實際圖表尺寸調整
   - 可能需要通過測試確定最佳值

3. **布局參數假設**：
   - `indexToX()` 方法中的布局參數（leftPadding, rightPadding）是假設值
   - 實際值可能不同，需要通過測試驗證

### 可接受的誤差範圍

- **最新數據區域**（用戶最常查看）：誤差較小
- **歷史數據區域**：誤差可能較大，但標記仍然會在大致正確的位置

## 測試計劃

### 1. 基本功能測試

- [ ] 初始載入時，標記是否在正確位置
- [ ] 縮放後，標記是否正確跟隨
- [ ] 拖拽結束後，標記位置是否更新

### 2. 邊界測試

- [ ] 滾動到最右側（最新數據），標記是否正確
- [ ] 滾動到最左側（最舊數據），標記是否正確

### 3. 精度測試

- [ ] 使用已知日期的測試數據
- [ ] 檢查標記是否對齊到正確的 K 線
- [ ] 記錄偏差情況

### 4. 布局參數驗證

- [ ] 創建測試頁面，顯示多個標記
- [ ] 對比實際位置與計算位置
- [ ] 調整 leftPadding 和 rightPadding 參數

## 實施步驟

1. ✅ 分析問題（當前文檔）
2. ⏳ 實施改進方案（修改 KChartStateAdapter 和 StockChartWidget）
3. ⏳ 運行測試驗證效果
4. ⏳ 根據測試結果調整參數
5. ⏳ 更新文檔說明局限性

## 長期解決方案

如果當前方案無法滿足需求，可以考慮：

1. **聯繫套件開發者**：請求添加更多回調 API（如 `onScrollChanged`）
2. **使用自定義實現**：回到之前的 `FlChartController` 自定義實現方案
3. **等待套件更新**：如果未來版本提供更好的 API

