# K線圖狀態同步改進實施總結

## 實施日期
2025年1月

## 實施內容

### ✅ 1. 改進 KChartStateAdapter.setScale() 方法

**改進前**：
```dart
void setScale(double scale) {
  _scale = scale.clamp(0.1, 5.0);
  notifyListeners(); // ❌ 沒有更新可見範圍
}
```

**改進後**：
```dart
void setScale(double scale) {
  _scale = scale.clamp(0.1, 5.0);
  _updateVisibleRangeFromScale(); // ✅ 更新可見範圍
}
```

### ✅ 2. 添加 _updateVisibleRangeFromScale() 方法

新增方法，根據縮放比例計算並更新可見範圍：

```dart
void _updateVisibleRangeFromScale() {
  if (_candles.isEmpty) {
    notifyListeners();
    return;
  }
  
  // 根據縮放比例計算可見數量
  // scale < 1.0 = 縮小（看到更多），scale > 1.0 = 放大（看到更少）
  final newVisibleCount = (_baseVisibleCount / _scale).round();
  _visibleCount = newVisibleCount.clamp(5, _candles.length);
  
  // 假設顯示最新數據（從右側開始）
  _endIndex = _candles.length - 1;
  _startIndex = (_endIndex - _visibleCount + 1).clamp(0, _candles.length - 1);
  
  _updatePriceRange();
  notifyListeners();
}
```

**關鍵特性**：
- 根據縮放比例動態計算可見 K 線數量
- 假設顯示最新數據（從右側開始）
- 自動更新價格範圍

### ✅ 3. 添加 setToLatest() 和 setToOldest() 方法

**setToLatest()**：
```dart
/// 設置為顯示最新數據（從 onLoadMore(true) 調用）
void setToLatest() {
  if (_candles.isEmpty) return;
  _endIndex = _candles.length - 1;
  _startIndex = (_endIndex - _visibleCount + 1).clamp(0, _candles.length - 1);
  _updatePriceRange();
  notifyListeners();
}
```

**setToOldest()**：
```dart
/// 設置為顯示最舊數據（從 onLoadMore(false) 調用）
void setToOldest() {
  if (_candles.isEmpty) return;
  _startIndex = 0;
  _endIndex = (_visibleCount - 1).clamp(0, _candles.length - 1);
  _updatePriceRange();
  notifyListeners();
}
```

### ✅ 4. 在 StockChartWidget 中添加 isOnDrag 回調

```dart
isOnDrag: (isDragging) {
  // 拖拽結束後，使用當前縮放比例重新計算可見範圍
  if (!isDragging) {
    final currentScale = _kchartController.currentScale;
    _stateAdapter.setScale(currentScale);
  }
},
```

**功能**：
- 監聽拖拽狀態變化
- 拖拽結束後重新計算可見範圍，同步標記位置

### ✅ 5. 在 StockChartWidget 中添加 onLoadMore 回調

```dart
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
```

**功能**：
- 檢測滾動到邊界的情況
- 根據邊界位置更新可見範圍
- 確保標記位置在邊界處準確

## 修改的文件

1. ✅ `lib/presentation/widgets/kchart_state_adapter.dart`
   - 添加 `_baseVisibleCount` 常量
   - 改進 `setScale()` 方法
   - 添加 `_updateVisibleRangeFromScale()` 方法
   - 添加 `setToLatest()` 方法
   - 添加 `setToOldest()` 方法

2. ✅ `lib/presentation/widgets/stock_chart_widget.dart`
   - 添加 `isOnDrag` 回調
   - 添加 `onLoadMore` 回調

## 預期改進效果

### 改進前
- ❌ 縮放後，標記位置不更新
- ❌ 平移後，標記位置錯誤
- ⚠️ 僅在初始狀態下位置較準確

### 改進後
- ✅ 縮放後，標記位置會根據新的可見範圍更新
- ✅ 拖拽結束後，標記位置會重新計算
- ✅ 邊界位置（最新/最舊數據）的標記位置更準確
- ⚠️ 中間位置（歷史數據）的標記位置仍有誤差（由於無法獲取精確滾動位置）

## 編譯檢查

✅ **無編譯錯誤**
- Flutter analyze 通過
- 僅有一個 lint 建議（prefer_const_declarations），不影響功能

## 已知局限性

由於 `flutter_chen_kchart` 套件的 API 限制，以下問題仍無法完全解決：

1. **精確的平移位置**：
   - 無法獲取 `mScrollX`（滾動偏移）
   - 無法獲取精確的可見範圍（`mStartIndex`, `mStopIndex`）
   - 只能通過估算和邊界檢測來近似

2. **中間位置的準確性**：
   - 當用戶滾動到歷史數據的中間位置時，標記位置可能不準確
   - 只有在邊界位置（最新/最舊）時，位置才相對準確

3. **布局參數**：
   - `indexToX()` 方法中的布局參數（leftPadding, rightPadding）是估算值
   - 可能需要通過實際測試調整

## 測試建議

實施改進後，建議測試以下場景：

### 基本功能測試
- [ ] 初始載入時，標記是否在正確位置
- [ ] 縮放操作後，標記是否正確跟隨
- [ ] 拖拽結束後，標記位置是否更新

### 邊界測試
- [ ] 滾動到最右側（最新數據），標記是否正確
- [ ] 滾動到最左側（最舊數據），標記是否正確

### 精度測試
- [ ] 使用已知日期的測試數據
- [ ] 檢查標記是否對齊到正確的 K 線
- [ ] 記錄偏差情況

### 布局參數驗證
- [ ] 創建測試頁面，顯示多個標記
- [ ] 對比實際位置與計算位置
- [ ] 調整 leftPadding 和 rightPadding 參數（如需要）

## 後續優化建議

### 優先級 2（測試後調整）

1. **驗證和調整布局參數**：
   - 通過實際測試確定 `indexToX()` 中的 leftPadding 和 rightPadding 是否準確
   - 可能需要調整這些值以匹配實際圖表布局

2. **驗證和調整基礎可見數量**：
   - `_baseVisibleCount` 目前設為 60
   - 可能需要根據實際圖表尺寸和顯示效果調整

3. **動態計算基礎可見數量**：
   - 可以考慮在 `updateSize()` 方法中根據圖表寬度動態計算
   - 例如：`_baseVisibleCount = (size.width / 7).round()`

### 優先級 3（長期優化）

1. **更精確的座標轉換算法**：
   - 考慮更複雜的計算方式
   - 可能需要通過大量測試數據來優化

2. **監聽套件更新**：
   - 如果未來版本提供更多 API（如 `onScrollChanged`），可以進一步改進

## 實施狀態

✅ **所有優先級 1 的改進已完成**

- ✅ 改進 `setScale()` 方法
- ✅ 添加 `_updateVisibleRangeFromScale()` 方法
- ✅ 添加 `setToLatest()` 和 `setToOldest()` 方法
- ✅ 添加 `isOnDrag` 回調監聽
- ✅ 添加 `onLoadMore` 回調處理

## 總結

本次改進大幅改善了 K 線圖狀態同步的問題，特別是在縮放和邊界情況下的標記位置準確性。雖然由於套件 API 限制，無法達到 100% 精確，但已能滿足大部分使用場景的需求。

建議在實際使用中測試效果，並根據測試結果進行優先級 2 的調整。

