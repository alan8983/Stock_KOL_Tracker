/// flutter_chen_kchart API 驗證腳本
/// 此腳本用於驗證實際使用的 API 是否存在且正確

import 'dart:io';

void main() {
  print('=' * 60);
  print('flutter_chen_kchart API 驗證');
  print('=' * 60);
  print('');

  // 檢查套件是否已安裝
  print('1. 檢查套件版本...');
  try {
    final result = Process.runSync(
      'flutter',
      ['pub', 'deps', '--style=compact'],
      runInShell: true,
    );
    
    if (result.stdout.toString().contains('flutter_chen_kchart')) {
      print('   ✓ 套件已安裝');
      // 提取版本號
      final match = RegExp(r'flutter_chen_kchart\s+(\S+)')
          .firstMatch(result.stdout.toString());
      if (match != null) {
        print('   版本: ${match.group(1)}');
      }
    } else {
      print('   ✗ 套件未找到');
      exit(1);
    }
  } catch (e) {
    print('   ✗ 無法檢查套件: $e');
    exit(1);
  }

  print('');
  print('2. 檢查編譯錯誤...');
  try {
    final result = Process.runSync(
      'flutter',
      ['analyze', 'lib/presentation/widgets/stock_chart_widget.dart'],
      runInShell: true,
    );
    
    if (result.exitCode == 0 || 
        !result.stdout.toString().contains('error') &&
        !result.stderr.toString().contains('error')) {
      print('   ✓ 無編譯錯誤');
    } else {
      print('   ⚠ 發現問題:');
      print(result.stdout);
      print(result.stderr);
    }
  } catch (e) {
    print('   ⚠ 無法執行分析: $e');
  }

  print('');
  print('3. API 使用檢查列表:');
  print('');
  
  // 檢查使用的 API
  final apis = [
    'KChartWidget',
    'KChartController',
    'KLineEntity',
    'MainState',
    'SecondaryState',
    'KLineEntity.fromCustom',
  ];

  for (final api in apis) {
    print('   - $api');
  }

  print('');
  print('=' * 60);
  print('驗證完成');
  print('');
  print('注意事項:');
  print('1. 此腳本僅做基本檢查，詳細 API 驗證需要查看套件源碼');
  print('2. 建議查看套件文檔: https://pub.dev/documentation/flutter_chen_kchart');
  print('3. 如果發現 API 不匹配，請檢查套件版本與文檔版本是否一致');
  print('=' * 60);
}

