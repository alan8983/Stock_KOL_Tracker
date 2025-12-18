import 'package:flutter/material.dart';
import '../../domain/providers/kol_win_rate_provider.dart';

/// KOL 統計卡片元件
/// 
/// 顯示 KOL 的勝率統計、文檔數、情緒分布等資訊
class KOLStatsCard extends StatelessWidget {
  final KOLWinRateStats stats;

  const KOLStatsCard({
    super.key,
    required this.stats,
  });

  Color _getWinRateColor(double winRate) {
    if (winRate >= 65) return Colors.green;
    if (winRate >= 50) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 勝率統計
          if (stats.winRateStats.hasAnyData) ...[
          const Row(
            children: [
              Icon(Icons.assessment, size: 16, color: Colors.blue),
              SizedBox(width: 4),
              Text(
                '勝率統計',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
            const SizedBox(height: 6),
            _buildWinRateRows(),
            const SizedBox(height: 12),
          ],

          // 基本統計
          Row(
            children: [
              const Icon(Icons.description, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                '${stats.totalPosts} 篇文檔',
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.show_chart, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                '${stats.stockCount} 檔股票',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // 情緒分布
          Row(
            children: [
              const Icon(Icons.trending_up, size: 14, color: Colors.green),
              const SizedBox(width: 4),
              Text(
                '看多 ${(stats.bullishRatio * 100).toStringAsFixed(0)}%',
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.trending_down, size: 14, color: Colors.red),
              const SizedBox(width: 4),
              Text(
                '看空 ${(stats.bearishRatio * 100).toStringAsFixed(0)}%',
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.trending_flat, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                '中立 ${(stats.neutralRatio * 100).toStringAsFixed(0)}%',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWinRateRows() {
    final periods = [
      (5, stats.winRateStats.stats5d),
      (30, stats.winRateStats.stats30d),
      (90, stats.winRateStats.stats90d),
      (365, stats.winRateStats.stats365d),
    ];

    return Row(
      children: periods.map((entry) {
        final period = entry.$1;
        final periodStats = entry.$2;
        
        if (periodStats == null || periodStats.totalPredictions == 0) {
          return Expanded(
            child: _buildWinRateCell(
              period: period,
              winRate: null,
              correct: 0,
              total: 0,
            ),
          );
        }

        return Expanded(
          child: _buildWinRateCell(
            period: period,
            winRate: periodStats.winRate,
            correct: periodStats.correctPredictions,
            total: periodStats.totalPredictions,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildWinRateCell({
    required int period,
    required double? winRate,
    required int correct,
    required int total,
  }) {
    final hasData = winRate != null && total > 0;
    final color = hasData ? _getWinRateColor(winRate) : Colors.grey;

    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
            Text(
              '$period天',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade700,
              ),
            ),
          const SizedBox(height: 2),
          Text(
            hasData ? '${winRate.toStringAsFixed(0)}%' : 'N/A',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          if (hasData) ...[
            const SizedBox(height: 2),
            Text(
              '($correct/$total)',
              style: TextStyle(
                fontSize: 9,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
