import 'package:flutter/material.dart';
import 'package:drift/drift.dart' as drift;
import '../../data/database/database.dart';
import '../../data/repositories/kol_repository.dart';

/// 快速新增 KOL 對話框
class CreateKOLDialog extends StatefulWidget {
  final KOLRepository kolRepository;

  const CreateKOLDialog({
    super.key,
    required this.kolRepository,
  });

  @override
  State<CreateKOLDialog> createState() => _CreateKOLDialogState();
}

class _CreateKOLDialogState extends State<CreateKOLDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _socialLinkController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _socialLinkController.dispose();
    super.dispose();
  }

  Future<void> _saveKOL() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final kolId = await widget.kolRepository.createKOL(
        KOLsCompanion.insert(
          name: _nameController.text,
          bio: drift.Value(_bioController.text.isEmpty
              ? null
              : _bioController.text),
          socialLink: drift.Value(_socialLinkController.text.isEmpty
              ? null
              : _socialLinkController.text),
          createdAt: DateTime.now(),
        ),
      );

      final kol = await widget.kolRepository.getKOLById(kolId);
      if (kol != null && mounted) {
        Navigator.of(context).pop(kol);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('建立失敗: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('新增 KOL'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: '名稱 *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '請輸入 KOL 名稱';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bioController,
                decoration: const InputDecoration(
                  labelText: '簡介',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _socialLinkController,
                decoration: const InputDecoration(
                  labelText: '社群連結',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.link),
                ),
                keyboardType: TextInputType.url,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _saveKOL,
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('建立'),
        ),
      ],
    );
  }
}
