# flutter_chen_kchart 狀態同步問題分析

## 問題概述

`KChartStateAdapter` 需要與 `KChartWidget` 的內部狀態同步，以確保情緒標記能正確定位。目前存在以下問題：

1. **縮放狀態同步**：僅通過 `onScaleChanged` 回調更新縮放比例
2. **平移狀態同步**：沒有回調來獲取平移狀態
3. **可見範圍同步**：`KChartStateAdapter` 維護的可見範圍不與實際圖表狀態同步

## 當前實現狀況

### 1. 可用的回調 API

根據源碼分析（`lib/k_chart_widget.dart`），`KChartWidget` 提供以下回調：

| 回調 | 類型 | 說明 | 狀態 |
|------|------|------|------|
| `onScaleChanged` | `Function(double)?` | 縮放變化時觸發，提供當前縮放比例 | ✅ 已使用 |
| `isOnDrag` | `Function(bool)?` | 拖拽狀態變化（開始/結束），不提供位置信息 | ⚠️ 未使用 |
| `onLoadMore` | `Function(bool)?` | 滾動到邊界時觸發（true=右側，false=左側） | ⚠️ 未使用 |
| `onCrossLineTap` | `Function(double price)?` | 點擊十字線標籤時觸發 | ❌ 不使用 |

### 2. KChartController 提供的狀態訪問

根據源碼（`lib/k_chart_widget.dart:29-106`），`KChartController` 提供：

```dart
class KChartController {
  // 獲取當前縮放比例
  double get currentScale => _state?.currentScale ?? 1.0;
  
  // 檢查是否達到最小/最大縮放
  bool get isAtMinScale => _state?._isAtMinScale ?? false;
  bool get isAtMaxScale => _state?._isAtMaxScale ?? false;
  
  // 操作：縮放到指定比例、放大、縮小、重置
  Future<void> scaleTo(double targetScale, ...);
  Future<void> zoomIn({double factor = 1.2});
  Future<void> zoomOut({double factor = 1.2});
  Future<void> resetScale();
}
```

**關鍵發現**：
- ✅ 可以獲取 `currentScale`
- ❌ **無法獲取** `mScrollX`（滾動偏移）
- ❌ **無法獲取** 可見範圍（`mStartIndex`, `mStopIndex`）

### 3. KChartWidget 內部狀態（私有）

內部使用以下狀態管理：
- `mScaleX` - 縮放比例
- `mScrollX` - 滾動偏移（像素）
- `mStartIndex` - 可見範圍起始索引（計算得出）
- `mStopIndex` - 可見範圍結束索引（計算得出）

這些都是私有狀態，無法直接訪問。

## 問題分析

### 問題 1：可見範圍無法同步

**現狀**：
- `KChartStateAdapter` 維護 `_startIndex`、`_endIndex`、`_visibleCount`
- 這些值在初始化時設置，但之後不再更新
- `KChartWidget` 內部有自己的可見範圍計算邏輯

**影響**：
- `indexToX()` 方法依賴 `_startIndex` 和 `_visibleCount`
- 如果這些值不準確，情緒標記的 X 座標會錯誤

### 問題 2：僅有縮放回調，缺少平移回調

**現狀**：
- `onScaleChanged` 僅提供縮放比例
- 沒有提供平移偏移的回調
- `isOnDrag` 只提供布爾值，不提供位置信息

**影響**：
- 無法知道圖表滾動到哪裡
- 無法更新 `_startIndex` 和 `_endIndex`

### 問題 3：座標轉換的假設

**當前實現**（`KChartStateAdapter.indexToX`）：
```dart
double indexToX(int index) {
  const leftPadding = 50.0;
  const rightPadding = 10.0;
  final drawableWidth = _chartSize.width - leftPadding - rightPadding;
  final unitWidth = drawableWidth / _visibleCount;
  final relativeIndex = index - _startIndex;
  return leftPadding + relativeIndex * unitWidth + unitWidth / 2;
}
```

**假設**：
1. 左側留白 50px，右側留白 10px
2. K線均勻分布
3. `_startIndex` 和 `_visibleCount` 準確

**風險**：
- 如果 `KChartWidget` 的實際布局不同，計算會錯誤
- 如果可見範圍不準確，所有標記位置都會錯誤

## 解決方案分析

### 方案 A：使用 KChartController.currentScale 估算（推薦）

**思路**：
- 使用 `currentScale` 和基礎可見數量來估算 `visibleCount`
- 假設縮放時可見數量 = 基礎數量 / scale
- 假設初始狀態顯示最新數據（從右到左）

**實現步驟**：
1. 監聽 `onScaleChanged`，更新 `_scale`
2. 根據 `scale` 計算 `_visibleCount`（需要知道基礎數量）
3. 假設 `_endIndex` 始終是最新數據（或使用 `onLoadMore` 回調）
4. 計算 `_startIndex = _endIndex - _visibleCount + 1`

**優點**：
- 可以利用現有 API
- 實現相對簡單

**缺點**：
- 仍然無法獲取精確的可見範圍
- 平移時無法更新 `_startIndex`

### 方案 B：使用 isOnDrag 回調 + 定時檢查（不推薦）

**思路**：
- 使用 `isOnDrag` 知道何時在拖拽
- 拖拽結束後，使用 `KChartController.currentScale` 重新計算

**缺點**：
- 無法知道拖拽的具體位置
- 需要猜測可見範圍

### 方案 C：嘗試訪問內部狀態（不推薦，可能不可行）

**思路**：
- 嘗試通過反射或其他方式訪問私有狀態

**缺點**：
- Flutter 不推薦使用反射
- 代碼脆弱，容易在套件更新時失效
- 可能違反套件的設計意圖

### 方案 D：使用輪詢方式檢查 Controller（不推薦）

**思路**：
- 使用 `Timer` 定期檢查 `KChartController.currentScale`
- 根據變化推斷狀態

**缺點**：
- 性能開銷
- 仍然無法獲取精確位置

## 推薦解決方案

### 混合方案：改進的估算方法

結合以下策略：

1. **使用 `onScaleChanged` 更新縮放比例** ✅ 已實現
2. **使用 `isOnDrag` 監聽拖拽狀態**
3. **基於縮放比例估算可見範圍**
4. **使用 `onLoadMore` 檢測邊界情況**
5. **定期使用 `currentScale` 驗證狀態**

### 實現建議

```dart
class KChartStateAdapter extends ChangeNotifier {
  // 基礎可見數量（初始狀態）
  static const int _baseVisibleCount = 60;
  
  // 數據總數
  int get totalCount => _candles.length;
  
  /// 根據縮放比例計算可見數量
  void _updateVisibleCountFromScale(double scale) {
    // scale < 1.0 表示縮小（看到更多），scale > 1.0 表示放大（看到更少）
    final newVisibleCount = (_baseVisibleCount / scale).round();
    _visibleCount = newVisibleCount.clamp(5, totalCount);
    
    // 更新可見範圍（假設顯示最新數據）
    if (totalCount > 0) {
      _endIndex = totalCount - 1;
      _startIndex = (_endIndex - _visibleCount + 1).clamp(0, totalCount - 1);
      _updatePriceRange();
      notifyListeners();
    }
  }
  
  /// 設置縮放比例（從 onScaleChanged 回調調用）
  void setScale(double scale) {
    _scale = scale.clamp(0.1, 5.0);
    _updateVisibleCountFromScale(scale);
  }
  
  /// 設置拖拽狀態（從 isOnDrag 回調調用）
  void setDragging(bool isDragging) {
    // 可以記錄拖拽狀態，但無法獲取具體位置
    // 拖拽結束後可能需要重新計算（如果可行的話）
  }
}
```

### 局限性說明

**無法完全解決的問題**：
1. **精確的可見範圍**：由於無法訪問內部狀態，只能估算
2. **平移位置**：無法知道圖表滾動到歷史數據的哪個位置
3. **標記位置精度**：標記位置可能會有輕微偏差

**可接受的誤差**：
- 如果用戶主要在查看最新數據（右側），誤差較小
- 如果用戶滾動到歷史數據，標記位置可能不准確
- 但標記仍然會出現在大致正確的位置附近

## 測試建議

### 測試場景

1. **初始狀態**：驗證標記是否顯示在正確位置
2. **縮放測試**：縮放後標記是否仍然正確
3. **平移測試**：平移後標記是否跟隨
4. **邊界測試**：滾動到最左側/最右側時標記是否正確

### 驗證方法

1. 使用已知的測試數據（有明確日期標記的 K線數據）
2. 檢查標記是否對齊到正確的 K線
3. 記錄偏差情況

## 結論

**當前狀態**：
- ⚠️ 狀態同步不完整，存在局限性
- ⚠️ 無法獲取精確的可見範圍和平移位置
- ✅ 可以通過估算方法實現近似同步

**建議**：
1. 實現改進的估算方法（方案 A + 混合策略）
2. 添加 `isOnDrag` 回調監聽
3. 在文檔中說明局限性
4. 通過實際測試驗證效果

**長期解決方案**：
- 如果套件未來版本提供更多回調 API，可以改進
- 或者考慮使用完全自定義的 K線圖實現（如之前的 `FlChartController` 方案）

