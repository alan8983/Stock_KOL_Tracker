import 'package:flutter/material.dart';

/// 情緒選擇器
/// 三個 Chip：Bullish (看多), Bearish (看空), Neutral (中立)
class SentimentSelector extends StatelessWidget {
  final String selectedSentiment;
  final ValueChanged<String> onChanged;

  const SentimentSelector({
    super.key,
    required this.selectedSentiment,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _SentimentChip(
          label: '看多',
          value: 'Bullish',
          icon: Icons.trending_up,
          color: Colors.green,
          isSelected: selectedSentiment == 'Bullish',
          onTap: () => onChanged('Bullish'),
        ),
        const SizedBox(width: 8),
        _SentimentChip(
          label: '看空',
          value: 'Bearish',
          icon: Icons.trending_down,
          color: Colors.red,
          isSelected: selectedSentiment == 'Bearish',
          onTap: () => onChanged('Bearish'),
        ),
        const SizedBox(width: 8),
        _SentimentChip(
          label: '中立',
          value: 'Neutral',
          icon: Icons.remove,
          color: Colors.grey,
          isSelected: selectedSentiment == 'Neutral',
          onTap: () => onChanged('Neutral'),
        ),
      ],
    );
  }
}

class _SentimentChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _SentimentChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : Colors.transparent,
          border: Border.all(
            color: isSelected ? color : Colors.grey,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isSelected ? color : Colors.grey, size: 20),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : Colors.grey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
