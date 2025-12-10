import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/repositories/diagnostic_repository.dart';
import '../../../domain/providers/database_provider.dart';

/// 診斷畫面 - 用於檢查草稿功能和資料庫狀態
class DiagnosticScreen extends ConsumerStatefulWidget {
  const DiagnosticScreen({super.key});

  @override
  ConsumerState<DiagnosticScreen> createState() => _DiagnosticScreenState();
}

class _DiagnosticScreenState extends ConsumerState<DiagnosticScreen> {
  Map<String, dynamic>? _defaultRecordsStatus;
  Map<String, dynamic>? _draftsStatus;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _runDiagnostics();
  }

  Future<void> _runDiagnostics() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final db = ref.read(databaseProvider);
      final diagnosticRepo = DiagnosticRepository(db);

      final defaultRecords = await diagnosticRepo.checkDefaultRecords();
      final drafts = await diagnosticRepo.checkDrafts();

      setState(() {
        _defaultRecordsStatus = defaultRecords;
        _draftsStatus = drafts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _fixDefaultRecords() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final db = ref.read(databaseProvider);
      final diagnosticRepo = DiagnosticRepository(db);

      await diagnosticRepo.ensureDefaultRecords();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('已建立預設記錄'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // 重新執行診斷
      await _runDiagnostics();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('系統診斷'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _runDiagnostics,
            tooltip: '重新檢查',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text('錯誤: $_error'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _runDiagnostics,
                          child: const Text('重試'),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildSection(
                      title: '預設記錄狀態',
                      icon: Icons.storage,
                      children: [
                        _buildInfoRow('總 KOL 數量', '${_defaultRecordsStatus?['totalKols'] ?? 0}'),
                        _buildInfoRow('總 Stock 數量', '${_defaultRecordsStatus?['totalStocks'] ?? 0}'),
                        _buildStatusRow(
                          '預設 KOL (ID=1)',
                          _defaultRecordsStatus?['hasDefaultKol'] == true,
                          _defaultRecordsStatus?['defaultKolName'],
                        ),
                        _buildStatusRow(
                          '預設 Stock (TEMP)',
                          _defaultRecordsStatus?['hasDefaultStock'] == true,
                          _defaultRecordsStatus?['defaultStockName'],
                        ),
                        if (_defaultRecordsStatus?['hasDefaultKol'] == false ||
                            _defaultRecordsStatus?['hasDefaultStock'] == false)
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: ElevatedButton.icon(
                              onPressed: _fixDefaultRecords,
                              icon: const Icon(Icons.build),
                              label: const Text('修復預設記錄'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSection(
                      title: '草稿狀態',
                      icon: Icons.drafts,
                      children: [
                        _buildInfoRow('總貼文數量', '${_draftsStatus?['totalPosts'] ?? 0}'),
                        _buildInfoRow('草稿數量', '${_draftsStatus?['totalDrafts'] ?? 0}'),
                        _buildInfoRow(
                          '所有狀態值',
                          '${(_draftsStatus?['allStatuses'] as List?)?.join(', ') ?? '無'}',
                        ),
                        if (_draftsStatus?['drafts'] != null &&
                            (_draftsStatus!['drafts'] as List).isNotEmpty) ...[
                          const Divider(),
                          const Text(
                            '草稿列表：',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          ...(_draftsStatus!['drafts'] as List).map((draft) {
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'ID: ${draft['id']}',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 4),
                                    Text('內容: ${draft['content']}...'),
                                    Text('狀態: ${draft['status']}'),
                                    Text('KOL ID: ${draft['kolId']}'),
                                    Text('Stock: ${draft['stockTicker']}'),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ],
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSection(
                      title: '診斷結果',
                      icon: Icons.info,
                      children: [
                        if (_defaultRecordsStatus?['hasDefaultKol'] == true &&
                            _defaultRecordsStatus?['hasDefaultStock'] == true &&
                            _draftsStatus?['totalDrafts'] == 0)
                          const Card(
                            color: Colors.blue,
                            child: Padding(
                              padding: EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  Icon(Icons.info, color: Colors.white),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '資料庫設定正確，但目前沒有草稿。\n請嘗試建立一個草稿來測試功能。',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        if (_defaultRecordsStatus?['hasDefaultKol'] == false ||
                            _defaultRecordsStatus?['hasDefaultStock'] == false)
                          const Card(
                            color: Colors.red,
                            child: Padding(
                              padding: EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  Icon(Icons.error, color: Colors.white),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '預設記錄缺失！這會導致草稿功能無法正常運作。\n請點擊上方的「修復預設記錄」按鈕。',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        if (_defaultRecordsStatus?['hasDefaultKol'] == true &&
                            _defaultRecordsStatus?['hasDefaultStock'] == true &&
                            _draftsStatus?['totalDrafts'] != null &&
                            _draftsStatus!['totalDrafts'] > 0)
                          Card(
                            color: Colors.green,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  const Icon(Icons.check_circle, color: Colors.white),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '草稿功能正常！找到 ${_draftsStatus!['totalDrafts']} 個草稿。',
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, bool status, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label)),
          Row(
            children: [
              if (value != null)
                Text(
                  value,
                  style: const TextStyle(color: Colors.grey),
                ),
              const SizedBox(width: 8),
              Icon(
                status ? Icons.check_circle : Icons.cancel,
                color: status ? Colors.green : Colors.red,
                size: 20,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
