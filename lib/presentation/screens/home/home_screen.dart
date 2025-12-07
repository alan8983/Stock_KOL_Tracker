import 'package:flutter/material.dart';
import '../input/quick_input_screen.dart';
import '../input/draft_list_screen.dart';

/// 主頁面 (Landing Page)
/// Phase 2 Backbone Step 0 - 真正的 HomeScreen
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock KOL Tracker'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.track_changes,
                  size: 100,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 32),
                Text(
                  'Stock KOL Tracker',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '追蹤 KOL 投資觀點，驗證勝率',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 64),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: SizedBox(
                    width: double.infinity,
                    child: Column(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const QuickInputScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.add_circle_outline),
                        label: const Text('新增草稿'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 20,
                          ),
                          minimumSize: const Size(double.infinity, 56),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const DraftListScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.drafts_outlined),
                        label: const Text('檢視草稿'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 20,
                          ),
                          minimumSize: const Size(double.infinity, 56),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
