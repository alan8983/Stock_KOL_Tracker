import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/providers/draft_list_provider.dart';
import '../../../data/models/draft_form_state.dart';
import '../../../data/database/database.dart';
import '../../widgets/draft_card.dart';

/// 草稿列表頁面 (Step 2)
/// 草稿一覽、滑動刪除、長按多選刪除
/// 點擊草稿會返回QuickInputScreen並填入內容
class DraftListScreen extends ConsumerStatefulWidget {
  const DraftListScreen({super.key});

  @override
  ConsumerState<DraftListScreen> createState() => _DraftListScreenState();
}

class _DraftListScreenState extends ConsumerState<DraftListScreen> {
  final Set<int> _selectedDraftIds = {};
  bool _isSelectionMode = false;

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedDraftIds.clear();
      }
    });
  }

  void _toggleSelection(int draftId, bool selected) {
    setState(() {
      if (selected) {
        _selectedDraftIds.add(draftId);
      } else {
        _selectedDraftIds.remove(draftId);
      }
    });
  }

  /// 將Post轉換為DraftFormState並返回
  void _selectDraft(Post draft) {
    final draftFormState = DraftFormState(
      content: draft.content,
      ticker: draft.stockTicker,
      sentiment: draft.sentiment,
      kolId: draft.kolId,
      postedAt: draft.postedAt,
    );
    Navigator.of(context).pop(draftFormState);
  }

  Future<void> _deleteSelected() async {
    if (_selectedDraftIds.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('確認刪除'),
        content: Text('確定要刪除 ${_selectedDraftIds.length} 個草稿嗎？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('刪除'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await ref
            .read(draftListProvider.notifier)
            .deleteDrafts(_selectedDraftIds.toList());
        setState(() {
          _selectedDraftIds.clear();
          _isSelectionMode = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('已刪除選取的草稿')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('刪除失敗: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final draftsAsync = ref.watch(draftListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('草稿列表'),
        actions: [
          if (_isSelectionMode)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed:
                  _selectedDraftIds.isEmpty ? null : _deleteSelected,
              tooltip: '刪除選取',
            ),
          IconButton(
            icon: Icon(_isSelectionMode ? Icons.close : Icons.checklist),
            onPressed: _toggleSelectionMode,
            tooltip: _isSelectionMode ? '取消選擇' : '多選模式',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(draftListProvider.notifier).loadDrafts();
        },
        child: draftsAsync.when(
          data: (drafts) {
            if (drafts.isEmpty) {
              return const SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: 400,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.drafts, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          '目前沒有草稿',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            return ListView.builder(
              itemCount: drafts.length,
              itemBuilder: (context, index) {
                final draft = drafts[index];
                return DraftCard(
                  draft: draft,
                  isSelected: _selectedDraftIds.contains(draft.id),
                  onSelectionChanged: _isSelectionMode
                      ? (selected) => _toggleSelection(draft.id, selected)
                      : null,
                  onTap: _isSelectionMode
                      ? () => _toggleSelection(
                          draft.id, !_selectedDraftIds.contains(draft.id))
                      : () => _selectDraft(draft), // 選擇草稿並返回
                  onDelete: () async {
                    try {
                      await ref
                          .read(draftListProvider.notifier)
                          .deleteDraft(draft.id);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('已刪除草稿')),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('刪除失敗: $e')),
                        );
                      }
                    }
                  },
                );
              },
            );
          },
          loading: () => const SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            child: SizedBox(
              height: 400,
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
          error: (error, stack) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: SizedBox(
              height: 400,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('載入失敗: $error'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        ref.invalidate(draftListProvider);
                      },
                      child: const Text('重試'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
