import 'package:flutter/material.dart';
import '../utils/candle_aggregator.dart';

/// 時間範圍類型
enum TimeRange {
  oneMonth,   // 1月
  threeMonths, // 3月
  ytd,        // YTD (Year To Date)
  oneYear,    // 1年
  fiveYears,  // 5年
}

/// K線間隔和時間範圍選擇器
class ChartIntervalSelector extends StatelessWidget {
  final CandleInterval selectedInterval;
  final TimeRange selectedRange;
  final ValueChanged<CandleInterval>? onIntervalChanged;
  final ValueChanged<TimeRange>? onRangeChanged;

  const ChartIntervalSelector({
    super.key,
    required this.selectedInterval,
    required this.selectedRange,
    this.onIntervalChanged,
    this.onRangeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 第一排：K線間隔選擇
        _buildIntervalRow(context),
        const SizedBox(height: 8),
        // 第二排：時間範圍選擇
        _buildRangeRow(context),
      ],
    );
  }

  Widget _buildIntervalRow(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildIntervalButton(context, CandleInterval.daily, '日K'),
          const SizedBox(width: 4),
          _buildIntervalButton(context, CandleInterval.weekly, '周K'),
          const SizedBox(width: 4),
          _buildIntervalButton(context, CandleInterval.monthly, '月K'),
          const SizedBox(width: 4),
          _buildIntervalButton(context, CandleInterval.quarterly, '季K'),
          const SizedBox(width: 4),
          _buildIntervalButton(context, CandleInterval.yearly, '年K'),
        ],
      ),
    );
  }

  Widget _buildRangeRow(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildRangeButton(context, TimeRange.oneMonth, '1月'),
          const SizedBox(width: 4),
          _buildRangeButton(context, TimeRange.threeMonths, '3月'),
          const SizedBox(width: 4),
          _buildRangeButton(context, TimeRange.ytd, 'YTD'),
          const SizedBox(width: 4),
          _buildRangeButton(context, TimeRange.oneYear, '1年'),
          const SizedBox(width: 4),
          _buildRangeButton(context, TimeRange.fiveYears, '5年'),
        ],
      ),
    );
  }

  Widget _buildIntervalButton(
    BuildContext context,
    CandleInterval interval,
    String label,
  ) {
    final isSelected = selectedInterval == interval;
    return _buildButton(
      context: context,
      label: label,
      isSelected: isSelected,
      onTap: () => onIntervalChanged?.call(interval),
    );
  }

  Widget _buildRangeButton(
    BuildContext context,
    TimeRange range,
    String label,
  ) {
    final isSelected = selectedRange == range;
    return _buildButton(
      context: context,
      label: label,
      isSelected: isSelected,
      onTap: () => onRangeChanged?.call(range),
    );
  }

  Widget _buildButton({
    required BuildContext context,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: isSelected
          ? Theme.of(context).colorScheme.primary
          : Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.outline.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected
                  ? Theme.of(context).colorScheme.onPrimary
                  : Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }

  /// 計算時間範圍對應的開始日期
  static DateTime calculateStartDate(TimeRange range) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (range) {
      case TimeRange.oneMonth:
        return today.subtract(const Duration(days: 30));
      case TimeRange.threeMonths:
        return today.subtract(const Duration(days: 90));
      case TimeRange.ytd:
        return DateTime(today.year, 1, 1);
      case TimeRange.oneYear:
        return today.subtract(const Duration(days: 365));
      case TimeRange.fiveYears:
        return today.subtract(const Duration(days: 1825));
    }
  }
}

