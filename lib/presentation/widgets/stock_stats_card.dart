import 'package:flutter/material.dart';
import '../../data/models/stock_stats.dart';

/// 股票統計卡片元件
/// 
/// 顯示股票的討論統計、市場共識、近期表現等資訊
class StockStatsCard extends StatelessWidget {
  final StockStats stats;

  const StockStatsCard({
    super.key,
    required this.stats,
  });

  Color _getConsensusColor() {
    switch (stats.consensusColor) {
      case 'darkGreen':
        return Colors.green.shade700;
      case 'lightGreen':
        return Colors.green.shade400;
      case 'darkRed':
        return Colors.red.shade700;
      case 'lightRed':
        return Colors.red.shade400;
      default:
        return Colors.grey.shade600;
    }
  }

  Color _getPriceChangeColor(double? change) {
    if (change == null) return Colors.grey;
    if (change > 0) return Colors.green;
    if (change < 0) return Colors.red;
    return Colors.grey;
  }

  String _formatPriceChange(double? change) {
    if (change == null) return 'N/A';
    final sign = change >= 0 ? '+' : '';
    return '$sign${change.toStringAsFixed(1)}%';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 討論統計
          Row(
            children: [
              const Icon(Icons.chat_bubble_outline, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                '${stats.kolCount} 個 KOL 討論，共 ${stats.totalPosts} 篇文檔',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 市場共識
          Row(
            children: [
              const Icon(Icons.emoji_objects, size: 16, color: Colors.amber),
              const SizedBox(width: 4),
              const Text(
                '市場共識：',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                stats.consensusLabel,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: _getConsensusColor(),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '(${stats.consensusStrength.toStringAsFixed(0)}%)',
                style: TextStyle(
                  fontSize: 12,
                  color: _getConsensusColor(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // 情緒分布條
          Row(
            children: [
                Expanded(
                  flex: (stats.bullishConsensus * 100).toInt(),
                  child: Container(
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.horizontal(left: Radius.circular(3)),
                    ),
                  ),
                ),
              Expanded(
                flex: (stats.bearishConsensus * 100).toInt(),
                child: Container(
                  height: 6,
                  color: Colors.red,
                ),
              ),
              Expanded(
                flex: (stats.neutralRatio * 100).toInt(),
                child: Container(
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Colors.grey,
                    borderRadius: BorderRadius.horizontal(right: Radius.circular(3)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // 情緒百分比文字
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '📈 ${stats.bullishConsensus.toStringAsFixed(0)}%',
                style: const TextStyle(fontSize: 11, color: Colors.green),
              ),
              Text(
                '📉 ${stats.bearishConsensus.toStringAsFixed(0)}%',
                style: const TextStyle(fontSize: 11, color: Colors.red),
              ),
              Text(
                '➖ ${stats.neutralRatio.toStringAsFixed(0)}%',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // 近期表現
          const Row(
            children: [
              Icon(Icons.trending_up, size: 14, color: Colors.grey),
              SizedBox(width: 4),
              Text(
                '近期表現：',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // 漲跌幅網格
          Row(
            children: [
              Expanded(
                child: _buildPriceChangeCell('5天', stats.avg5d),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: _buildPriceChangeCell('30天', stats.avg30d),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: _buildPriceChangeCell('90天', stats.avg90d),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: _buildPriceChangeCell('365天', stats.avg365d),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceChangeCell(String label, double? change) {
    final color = _getPriceChangeColor(change);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _formatPriceChange(change),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
