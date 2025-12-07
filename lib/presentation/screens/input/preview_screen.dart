import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/providers/draft_state_provider.dart';
import '../../../domain/providers/repository_providers.dart';
import '../../../core/utils/datetime_formatter.dart';
import '../../widgets/confirm_dialog.dart';

/// 預覽頁面 (Step 3.1-3.2)
/// 預覽記錄結果、確認建檔彈窗
class PreviewScreen extends ConsumerWidget {
  const PreviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(draftStateProvider);
    final notifier = ref.read(draftStateProvider.notifier);
    final kolRepo = ref.watch(kolRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('預覽記錄'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // KOL 資訊
            FutureBuilder(
              future: state.kolId != null
                  ? kolRepo.getKOLById(state.kolId!)
                  : null,
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data != null) {
                  final kol = snapshot.data!;
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.person),
                      title: Text(kol.name),
                      subtitle: kol.bio != null ? Text(kol.bio!) : null,
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            const SizedBox(height: 16),

            // 投資標的
            Card(
              child: ListTile(
                leading: const Icon(Icons.trending_up),
                title: const Text('投資標的'),
                trailing: Text(
                  state.ticker ?? '未設定',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 走勢情緒
            Card(
              child: ListTile(
                leading: Icon(
                  state.sentiment == 'Bullish'
                      ? Icons.trending_up
                      : state.sentiment == 'Bearish'
                          ? Icons.trending_down
                          : Icons.remove,
                  color: state.sentiment == 'Bullish'
                      ? Colors.green
                      : state.sentiment == 'Bearish'
                          ? Colors.red
                          : Colors.grey,
                ),
                title: const Text('走勢情緒'),
                trailing: Chip(
                  label: Text(state.sentiment),
                  backgroundColor: state.sentiment == 'Bullish'
                      ? Colors.green.withOpacity(0.2)
                      : state.sentiment == 'Bearish'
                          ? Colors.red.withOpacity(0.2)
                          : Colors.grey.withOpacity(0.2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 發文時間
            Card(
              child: ListTile(
                leading: const Icon(Icons.access_time),
                title: const Text('發文時間'),
                trailing: Text(
                  state.postedAt != null
                      ? DateTimeFormatter.format(state.postedAt!)
                      : '未設定',
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 主文內容
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '主文內容',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(state.content),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // AI 分析結果
            if (state.aiResult != null) ...[
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.auto_awesome, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'AI 分析結果',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      if (state.aiResult!.reasoning != null) ...[
                        const SizedBox(height: 8),
                        Text(state.aiResult!.reasoning!),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // 錯誤訊息
            if (state.errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  state.errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),

            const SizedBox(height: 32),

            // 確認建檔按鈕
            ElevatedButton(
              onPressed: state.isSaving
                  ? null
                  : () async {
                      final confirmed = await ConfirmDialog.show(
                        context,
                        title: '確認建檔',
                        message: '確定要建立此記錄嗎？',
                        confirmText: '確認',
                        cancelText: '取消',
                      );

                      if (confirmed && context.mounted) {
                        try {
                          await notifier.publishPost();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('記錄已建立'),
                                backgroundColor: Colors.green,
                              ),
                            );
                            notifier.reset();
                            Navigator.of(context).popUntil((route) => route.isFirst);
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('建立失敗: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: state.isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('確認建檔'),
            ),
          ],
        ),
      ),
    );
  }
}
