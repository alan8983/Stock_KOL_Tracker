import 'package:flutter/material.dart';
import '../../core/utils/datetime_formatter.dart';

/// 絕對時間選擇器
/// 格式：yyyy/MM/dd HH:mm
class DateTimePickerField extends StatefulWidget {
  final DateTime? initialDateTime;
  final ValueChanged<DateTime>? onChanged;

  const DateTimePickerField({
    super.key,
    this.initialDateTime,
    this.onChanged,
  });

  @override
  State<DateTimePickerField> createState() => _DateTimePickerFieldState();
}

class _DateTimePickerFieldState extends State<DateTimePickerField> {
  DateTime? _selectedDateTime;

  @override
  void initState() {
    super.initState();
    _selectedDateTime = widget.initialDateTime ?? DateTime.now();
  }

  Future<void> _selectDateTime() async {
    // 先選擇日期
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      locale: const Locale('zh', 'TW'),
    );

    if (pickedDate == null) return;

    // 再選擇時間
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime ?? DateTime.now()),
    );

    if (pickedTime == null) return;

    final combinedDateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    setState(() {
      _selectedDateTime = combinedDateTime;
    });

    widget.onChanged?.call(combinedDateTime);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '發文時間 (絕對時間)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _selectDateTime,
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: '選擇日期時間',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.calendar_today),
              suffixIcon: Icon(Icons.access_time),
            ),
            child: Text(
              _selectedDateTime != null
                  ? DateTimeFormatter.format(_selectedDateTime!)
                  : '請選擇日期時間',
              style: TextStyle(
                fontSize: 16,
                color: _selectedDateTime != null
                    ? Colors.black
                    : Colors.grey.shade600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
