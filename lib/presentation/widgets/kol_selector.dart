import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database/database.dart';
import '../../data/repositories/kol_repository.dart';
import '../../domain/providers/repository_providers.dart';
import 'create_kol_dialog.dart';

/// KOL 選擇器
/// 下拉選單顯示所有 KOL，並提供新增功能
class KOLSelector extends ConsumerStatefulWidget {
  final int? selectedKolId;
  final ValueChanged<int?>? onChanged;

  const KOLSelector({
    super.key,
    this.selectedKolId,
    this.onChanged,
  });

  @override
  ConsumerState<KOLSelector> createState() => _KOLSelectorState();
}

class _KOLSelectorState extends ConsumerState<KOLSelector> {
  @override
  Widget build(BuildContext context) {
    final kolRepo = ref.watch(kolRepositoryProvider);
    final kolsAsync = ref.watch(kolListProvider);

    return kolsAsync.when(
      data: (kols) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'KOL',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _showCreateKOLDialog(context, kolRepo),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('新增 KOL'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<int?>(
              value: widget.selectedKolId,
              decoration: const InputDecoration(
                labelText: '選擇 KOL',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('請選擇 KOL'),
                ),
                ...kols.map((kol) => DropdownMenuItem<int?>(
                      value: kol.id,
                      child: Text(kol.name),
                    )),
              ],
              onChanged: (value) {
                widget.onChanged?.call(value);
              },
            ),
          ],
        );
      },
      loading: () => const CircularProgressIndicator(),
      error: (error, stack) => Text('錯誤: $error'),
    );
  }

  Future<void> _showCreateKOLDialog(
      BuildContext context, KOLRepository kolRepo) async {
    final result = await showDialog<KOL>(
      context: context,
      builder: (context) => CreateKOLDialog(kolRepository: kolRepo),
    );

    if (result != null && mounted) {
      // 重新載入 KOL 列表
      ref.invalidate(kolListProvider);
      // 自動選擇新建立的 KOL
      widget.onChanged?.call(result.id);
    }
  }
}

/// KOL 列表 Provider
final kolListProvider = FutureProvider<List<KOL>>((ref) async {
  final kolRepo = ref.watch(kolRepositoryProvider);
  return await kolRepo.getAllKOLs();
});
