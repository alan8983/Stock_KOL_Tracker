import 'dart:async';
import 'package:flutter/material.dart';

/// 自動暫存文字輸入框
/// 使用 Debounce 機制避免頻繁寫入
class AutoSaveTextField extends StatefulWidget {
  final String? initialValue;
  final String? hintText;
  final int maxLines;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onAutoSave;
  final Duration debounceDuration;

  const AutoSaveTextField({
    super.key,
    this.initialValue,
    this.hintText,
    this.maxLines = 5,
    this.onChanged,
    this.onAutoSave,
    this.debounceDuration = const Duration(milliseconds: 500),
  });

  @override
  State<AutoSaveTextField> createState() => _AutoSaveTextFieldState();
}

class _AutoSaveTextFieldState extends State<AutoSaveTextField> {
  late final TextEditingController _controller;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged(String value) {
    widget.onChanged?.call(value);

    // 取消之前的計時器
    _debounceTimer?.cancel();

    // 設定新的計時器
    _debounceTimer = Timer(widget.debounceDuration, () {
      widget.onAutoSave?.call(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      maxLines: widget.maxLines,
      decoration: InputDecoration(
        hintText: widget.hintText ?? '請輸入或貼上內容...',
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.all(16),
      ),
      onChanged: _onTextChanged,
    );
  }
}
