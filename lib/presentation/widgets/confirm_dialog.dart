import 'package:flutter/material.dart';

/// 確認建檔對話框
class ConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

  const ConfirmDialog({
    super.key,
    this.title = '確認',
    required this.message,
    this.confirmText = '確認',
    this.cancelText = '取消',
    this.onConfirm,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () {
            onCancel?.call();
            Navigator.of(context).pop(false);
          },
          child: Text(cancelText),
        ),
        ElevatedButton(
          onPressed: () {
            onConfirm?.call();
            Navigator.of(context).pop(true);
          },
          child: Text(confirmText),
        ),
      ],
    );
  }

  /// 顯示確認對話框
  static Future<bool> show(
    BuildContext context, {
    String title = '確認',
    required String message,
    String confirmText = '確認',
    String cancelText = '取消',
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => ConfirmDialog(
        title: title,
        message: message,
        confirmText: confirmText,
        cancelText: cancelText,
      ),
    );
    return result ?? false;
  }
}
