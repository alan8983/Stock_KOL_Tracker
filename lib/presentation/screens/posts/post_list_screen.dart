import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/providers/post_list_provider.dart';
import '../../widgets/post_card.dart';
import 'post_detail_screen.dart';

/// 文檔清單頁面
/// 顯示所有已發布的文檔
class PostListScreen extends ConsumerStatefulWidget {
  const PostListScreen({super.key});

  @override
  ConsumerState<PostListScreen> createState() => _PostListScreenState();
}

class _PostListScreenState extends ConsumerState<PostListScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final postsAsync = ref.watch(postListProvider);
    final isAscending = ref.read(postListProvider.notifier).isAscending;

    return Scaffold(
      appBar: AppBar(
        title: const Text('文檔清單'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(isAscending ? Icons.arrow_upward : Icons.arrow_downward),
            onPressed: () {
              ref.read(postListProvider.notifier).toggleSortOrder();
            },
            tooltip: isAscending ? '最舊優先' : '最新優先',
          ),
        ],
      ),
      body: postsAsync.when(
        data: (postsWithKOL) {
          if (postsWithKOL.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.article_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    '目前沒有已發布的文檔',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '草稿發布後會顯示在此處',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: postsWithKOL.length,
            itemBuilder: (context, index) {
              final postWithKOL = postsWithKOL[index];
              return PostCard(
                postWithKOL: postWithKOL,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => PostDetailScreen(
                        postId: postWithKOL.post.id,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('載入失敗: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(postListProvider);
                },
                child: const Text('重試'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
