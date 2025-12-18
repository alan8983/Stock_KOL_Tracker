import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/providers/price_change_provider.dart';

/// 漲跌幅顯示元件
/// 
/// 支援左右滑動切換不同時間區間（5、30、90、365 天）
/// 使用綠漲紅跌配色（美股慣例）
class PriceChangeIndicator extends ConsumerStatefulWidget {
  final int postId;
  
  const PriceChangeIndicator({
    super.key,
    required this.postId,
  });

  @override
  ConsumerState<PriceChangeIndicator> createState() => _PriceChangeIndicatorState();
}

class _PriceChangeIndicatorState extends ConsumerState<PriceChangeIndicator> {
  late PageController _pageController;
  int _currentPage = 0;
  
  // 支援的時間區間
  static const List<int> _periods = [5, 30, 90, 365];
  
  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final priceChangeAsync = ref.watch(postPriceChangeProvider(widget.postId));

    return priceChangeAsync.when(
      data: (priceChange) => _buildContent(priceChange.changes),
      loading: () => _buildLoading(),
      error: (error, stack) => _buildError(error),
    );
  }

  Widget _buildContent(Map<int, double?> changes) {
    return SizedBox(
      height: 50,
      child: Column(
        children: [
          // 可滑動的漲跌幅顯示區域
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemCount: _periods.length,
              itemBuilder: (context, index) {
                final period = _periods[index];
                final change = changes[period];
                return _buildPeriodCard(period, change);
              },
            ),
          ),
          const SizedBox(height: 4),
          // 區間指示器（小圓點）
          _buildPageIndicator(),
        ],
      ),
    );
  }

  Widget _buildPeriodCard(int period, double? change) {
    if (change == null) {
      return _buildNoDataCard(period);
    }

    final isPositive = change >= 0;
    final color = isPositive ? Colors.green : Colors.red;
    final icon = isPositive ? Icons.arrow_upward : Icons.arrow_downward;
    final sign = isPositive ? '+' : '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.show_chart, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            _getPeriodLabel(period),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 2),
          Text(
            '$sign${change.toStringAsFixed(2)}%',
            style: TextStyle(
              fontSize: 14,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoDataCard(int period) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.info_outline, size: 14, color: Colors.grey.shade600),
          const SizedBox(width: 4),
          Text(
            _getPeriodLabel(period),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '資料不足',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '計算中...',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(Object error) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 14, color: Colors.red.shade600),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              '載入失敗',
              style: TextStyle(
                fontSize: 12,
                color: Colors.red.shade600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        _periods.length,
        (index) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _currentPage == index
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.shade300,
          ),
        ),
      ),
    );
  }

  String _getPeriodLabel(int period) {
    switch (period) {
      case 5:
        return '5天';
      case 30:
        return '30天';
      case 90:
        return '90天';
      case 365:
        return '365天';
      default:
        return '$period天';
    }
  }
}
