# K線圖狀態同步檢查總結

## 檢查完成時間
2025年1月

## 檢查項目

### ✅ 1. API 整合確認
**狀態**: ✅ 已完成  
**文檔**: `docs/KCHART_API_VERIFICATION.md`

所有使用的 API 都與源碼定義一致，無需修改。

### ⚠️ 2. 狀態同步問題分析
**狀態**: ⚠️ 發現問題，需要改進  
**文檔**: `docs/KCHART_STATE_SYNC_ANALYSIS.md`, `docs/KCHART_STATE_SYNC_IMPROVEMENTS.md`

## 發現的問題

### 問題 1：可見範圍不同步 ⚠️

**現狀**：
- `KChartStateAdapter.setScale()` 只更新了縮放比例，**沒有更新可見範圍**
- `_startIndex` 和 `_endIndex` 在初始化後不再更新
- 當用戶縮放/平移圖表時，這些值與實際圖表狀態不一致

**影響**：
- `indexToX()` 方法依賴這些值計算 X 座標
- 情緒標記的位置會錯誤

### 問題 2：缺少平移狀態監聽 ⚠️

**現狀**：
- 沒有使用 `isOnDrag` 回調
- 沒有使用 `onLoadMore` 回調
- 無法知道圖表何時被平移

**影響**：
- 平移後，標記位置不會更新
- 無法檢測邊界情況

### 問題 3：座標轉換參數可能不準確 ⚠️

**現狀**：
- `indexToX()` 中硬編碼了布局參數（leftPadding=50px, rightPadding=10px）
- 這些值可能與實際圖表布局不一致

**影響**：
- 標記的 X 座標可能會有偏差

## 改進方案

### 立即改進（高優先級）

#### 1. 改進 `setScale()` 方法

**當前實現**：
```dart
void setScale(double scale) {
  _scale = scale.clamp(0.1, 5.0);
  notifyListeners(); // ❌ 沒有更新可見範圍
}
```

**改進後**：
```dart
// 基礎可見數量（需要根據實際調整，約 60-80）
static const int _baseVisibleCount = 60;

void setScale(double scale) {
  _scale = scale.clamp(0.1, 5.0);
  _updateVisibleRangeFromScale(); // ✅ 更新可見範圍
}

void _updateVisibleRangeFromScale() {
  if (_candles.isEmpty) return;
  
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

#### 2. 添加回調監聽

在 `StockChartWidget` 中添加：

```dart
KChartWidget(
  // ... 現有參數
  onScaleChanged: (scale) {
    _stateAdapter.setScale(scale); // ✅ 已存在
  },
  isOnDrag: (isDragging) {
    if (!isDragging) {
      // ✅ 拖拽結束後，重新計算可見範圍
      final currentScale = _kchartController.currentScale;
      _stateAdapter.setScale(currentScale);
    }
  },
  onLoadMore: (isRightEdge) {
    // ✅ 檢測邊界情況
    if (isRightEdge) {
      _stateAdapter.setToLatest();
    } else {
      _stateAdapter.setToOldest();
    }
  },
)
```

#### 3. 添加輔助方法到 KChartStateAdapter

```dart
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
```

### 後續改進（中優先級）

#### 1. 驗證布局參數

通過實際測試確定 `indexToX()` 中的布局參數是否準確：
- leftPadding 和 rightPadding 的實際值
- 可能需要調整這些值以匹配實際圖表布局

#### 2. 動態調整基礎可見數量

`_baseVisibleCount` 可能需要根據圖表尺寸動態計算：
```dart
void updateSize(Size size) {
  _chartSize = size;
  // 根據圖表寬度計算基礎可見數量
  // 例如：假設每個 K 線寬度約為 6-8px
  _baseVisibleCount = (size.width / 7).round();
  notifyListeners();
}
```

## 實施優先級

### 優先級 1（立即實施）✅
1. 改進 `setScale()` 方法，根據縮放比例更新可見範圍
2. 添加 `isOnDrag` 回調監聽
3. 添加 `onLoadMore` 回調處理邊界情況
4. 添加 `setToLatest()` 和 `setToOldest()` 方法

### 優先級 2（測試後調整）
1. 驗證和調整布局參數（leftPadding, rightPadding）
2. 驗證和調整基礎可見數量（_baseVisibleCount）

### 優先級 3（長期優化）
1. 考慮更精確的座標轉換算法
2. 如果套件未來提供更多 API，進一步改進

## 預期效果

### 改進前
- ❌ 縮放後，標記位置不更新
- ❌ 平移後，標記位置錯誤
- ⚠️ 僅在初始狀態下位置較準確

### 改進後
- ✅ 縮放後，標記位置會根據新的可見範圍更新
- ✅ 拖拽結束後，標記位置會重新計算
- ✅ 邊界位置（最新/最舊數據）的標記位置更準確
- ⚠️ 中間位置（歷史數據）的標記位置仍有誤差（由於無法獲取精確滾動位置）

## 已知局限性

由於 `flutter_chen_kchart` 的限制，以下問題無法完全解決：

1. **精確的平移位置**：
   - 無法獲取 `mScrollX`（滾動偏移）
   - 無法獲取精確的可見範圍（`mStartIndex`, `mStopIndex`）
   - 只能通過估算和邊界檢測來近似

2. **中間位置的準確性**：
   - 當用戶滾動到歷史數據的中間位置時，標記位置可能不準確
   - 只有在邊界位置（最新/最舊）時，位置才相對準確

3. **布局參數**：
   - 布局參數（padding）是估算值，可能需要通過測試調整

## 測試建議

實施改進後，需要測試：

1. ✅ 初始載入時標記位置是否正確
2. ✅ 縮放操作後標記是否正確跟隨
3. ✅ 拖拽結束後標記位置是否更新
4. ✅ 滾動到最新數據時標記是否正確
5. ✅ 滾動到最舊數據時標記是否正確
6. ⚠️ 滾動到中間位置時標記的偏差程度

## 結論

**當前狀態**：
- ⚠️ 狀態同步不完整，存在已知問題
- ✅ 可以通過改進方案大幅改善
- ⚠️ 但仍存在局限性，無法達到 100% 準確

**建議**：
1. 立即實施優先級 1 的改進
2. 通過實際測試驗證效果
3. 根據測試結果調整參數（優先級 2）
4. 在文檔中說明已知局限性

**如果改進後仍無法滿足需求**：
- 考慮聯繫套件開發者請求更多 API
- 或考慮回到自定義實現方案（FlChartController）

