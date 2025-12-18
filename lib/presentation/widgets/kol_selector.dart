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
  static const int _newKolId = -1; // 特殊 ID 代表新增 KOL

  @override
  Widget build(BuildContext context) {
    final kolRepo = ref.watch(kolRepositoryProvider);
    final kolsAsync = ref.watch(kolListProvider);

    return kolsAsync.when(
      data: (kols) {
        // 確保選定的 ID 存在於列表中，否則使用 null
        final validSelectedId = widget.selectedKolId != null &&
                kols.any((kol) => kol.id == widget.selectedKolId)
            ? widget.selectedKolId
            : null;

        return DropdownButtonFormField<int?>(
          value: validSelectedId,
          decoration: const InputDecoration(
            hintText: '選擇 KOL',
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
            const DropdownMenuItem<int?>(
              value: _newKolId,
              child: Row(
                children: [
                  Icon(Icons.add, size: 18, color: Color(0xFF6366F1)),
                  SizedBox(width: 8),
                  Text(
                    '新 KOL',
                    style: TextStyle(
                      color: Color(0xFF6366F1),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
          onChanged: (value) {
            if (value == _newKolId) {
              _showCreateKOLDialog(context, kolRepo);
            } else {
              widget.onChanged?.call(value);
            }
          },
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
      // 強制重新載入 KOL 列表並等待完成
      await ref.refresh(kolListProvider.future);
      
      // 確保列表刷新完成後，再自動選擇新建立的 KOL
      if (mounted) {
        widget.onChanged?.call(result.id);
      }
    }
  }
}

/// KOL 列表 Provider
final kolListProvider = FutureProvider<List<KOL>>((ref) async {
  final kolRepo = ref.watch(kolRepositoryProvider);
  return await kolRepo.getAllKOLs();
});
