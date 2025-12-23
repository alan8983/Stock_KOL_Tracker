import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/providers/draft_list_provider.dart';
import '../../../data/models/draft_form_state.dart';
import '../../../data/database/database.dart';
import '../../widgets/draft_card.dart';

/// 草稿列表頁面 (Email Inbox 樣式)
/// 草稿一覽、滑動刪除
/// 點擊草稿會返回QuickInputScreen並填入內容
class DraftListScreen extends ConsumerWidget {
  const DraftListScreen({super.key});

  /// 將Post轉換為DraftFormState並返回
  void _selectDraft(BuildContext context, Post draft) {
    final draftFormState = DraftFormState(
      content: draft.content,
      ticker: draft.stockTicker,
      sentiment: draft.sentiment,
      kolId: draft.kolId,
      postedAt: draft.postedAt,
    );
    Navigator.of(context).pop(draftFormState);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draftsAsync = ref.watch(draftListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('草稿列表'),
        elevation: 0,
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
                        Icon(Icons.drafts_outlined, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          '目前沒有草稿',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '向左滑動可刪除草稿',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
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
                  onTap: () => _selectDraft(context, draft),
                  onDelete: () async {
                    try {
                      await ref
                          .read(draftListProvider.notifier)
                          .deleteDraft(draft.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('已刪除草稿')),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
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
