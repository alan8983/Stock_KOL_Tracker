import 'package:flutter/material.dart';
import '../../data/models/relative_time_input.dart';
import '../../core/utils/datetime_formatter.dart';

/// 相對時間選擇器
/// 支援輸入 "X小時前"、"X天前" 等格式
class RelativeTimePicker extends StatefulWidget {
  final DateTime? initialDateTime;
  final ValueChanged<DateTime>? onChanged;

  const RelativeTimePicker({
    super.key,
    this.initialDateTime,
    this.onChanged,
  });

  @override
  State<RelativeTimePicker> createState() => _RelativeTimePickerState();
}

class _RelativeTimePickerState extends State<RelativeTimePicker> {
  final _valueController = TextEditingController();
  TimeUnit _selectedUnit = TimeUnit.hour;
  DateTime? _calculatedTime;

  @override
  void initState() {
    super.initState();
    _valueController.addListener(_calculateTime);
  }

  @override
  void dispose() {
    _valueController.dispose();
    super.dispose();
  }

  void _calculateTime() {
    final value = int.tryParse(_valueController.text);
    if (value != null && value > 0) {
      final relativeTime = RelativeTimeInput(
        value: value,
        unit: _selectedUnit,
      );
      setState(() {
        _calculatedTime = relativeTime.toAbsoluteTime();
      });
      widget.onChanged?.call(_calculatedTime!);
    } else {
      setState(() {
        _calculatedTime = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '發文時間 (相對時間)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextField(
                controller: _valueController,
                decoration: const InputDecoration(
                  labelText: '數字',
                  border: OutlineInputBorder(),
                  hintText: '例如: 3',
                ),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 3,
              child: DropdownButtonFormField<TimeUnit>(
                value: _selectedUnit,
                decoration: const InputDecoration(
                  labelText: '單位',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: TimeUnit.hour, child: Text('小時前')),
                  DropdownMenuItem(value: TimeUnit.day, child: Text('天前')),
                  DropdownMenuItem(value: TimeUnit.week, child: Text('週前')),
                  DropdownMenuItem(value: TimeUnit.month, child: Text('月前')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedUnit = value);
                    _calculateTime();
                  }
                },
              ),
            ),
          ],
        ),
        if (_calculatedTime != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.access_time, size: 20),
                const SizedBox(width: 8),
                Text(
                  '計算結果: ${DateTimeFormatter.format(_calculatedTime!)}',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
