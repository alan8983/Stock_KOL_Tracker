import 'package:flutter/material.dart';
import '../../data/database/database.dart';
import '../../core/utils/datetime_formatter.dart';

/// 草稿卡片元件
/// 支援 Dismissible 滑動刪除
class DraftCard extends StatelessWidget {
  final Post draft;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final bool isSelected;
  final ValueChanged<bool>? onSelectionChanged;

  const DraftCard({
    super.key,
    required this.draft,
    this.onTap,
    this.onDelete,
    this.isSelected = false,
    this.onSelectionChanged,
  });

  @override
  Widget build(BuildContext context) {
    final contentPreview = draft.content.length > 100
        ? '${draft.content.substring(0, 100)}...'
        : draft.content;

    return Dismissible(
      key: Key('draft_${draft.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => onDelete?.call(),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                if (onSelectionChanged != null)
                  Checkbox(
                    value: isSelected,
                    onChanged: (value) =>
                        onSelectionChanged?.call(value ?? false),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Chip(
                            label: Text(
                              draft.sentiment,
                              style: const TextStyle(fontSize: 12),
                            ),
                            backgroundColor: _getSentimentColor(draft.sentiment)
                                .withOpacity(0.2),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            draft.stockTicker,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        contentPreview,
                        style: const TextStyle(fontSize: 14),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        DateTimeFormatter.formatRelative(draft.postedAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getSentimentColor(String sentiment) {
    switch (sentiment) {
      case 'Bullish':
        return Colors.green;
      case 'Bearish':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
