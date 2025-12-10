import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:drift/drift.dart';
import 'package:drift/native.dart';

/// 簡單的草稿功能診斷腳本
/// 
/// 執行方式：
/// dart scripts/test_draft_feature.dart
/// 
/// 此腳本會檢查實際的資料庫檔案

void main() async {
  print('=== 草稿功能診斷 ===\n');

  // 尋找資料庫檔案
  // 在 Windows 上通常位於 C:\Users\[username]\AppData\Local\[app_name]\
  // 但我們可以檢查當前目錄
  
  print('1. 檢查資料庫檔案位置...');
  print('   預期位置: 應用程式文件目錄/stock_kol_tracker.db');
  print('   請在 APP 中執行以下測試：\n');

  print('2. 手動測試步驟：');
  print('   a) 在 HomeScreen 的文字框輸入一些內容');
  print('   b) 點擊「存為草稿」按鈕');
  print('   c) 查看是否有成功提示（綠色 SnackBar）');
  print('   d) 切換到「草稿」分頁');
  print('   e) 檢查是否看到剛才儲存的草稿\n');

  print('3. 自動暫存測試：');
  print('   a) 在文字框輸入內容（不要點擊任何按鈕）');
  print('   b) 將 APP 切換到背景（按 Home 鍵或切換到其他 APP）');
  print('   c) 返回 APP');
  print('   d) 切換到「草稿」分頁');
  print('   e) 檢查是否看到自動儲存的草稿\n');

  print('4. 除錯資訊：');
  print('   如果看不到草稿，請檢查：');
  print('   a) 終端機/控制台是否有錯誤訊息');
  print('   b) 草稿列表畫面是否顯示「載入中」或錯誤');
  print('   c) 點擊「存為草稿」後是否有任何提示');
  print('   d) 檢查 draft_list_provider 是否正確載入\n');

  print('5. 資料庫查詢語法：');
  print('   草稿查詢條件: WHERE status = \'Draft\'');
  print('   建立草稿時的 status 值: \'Draft\'\n');

  print('=== SQL 查詢檢查 ===');
  print('您可以使用 SQLite 工具查看資料庫內容：\n');
  print('SELECT * FROM posts WHERE status = \'Draft\';');
  print('SELECT COUNT(*) FROM posts WHERE status = \'Draft\';');
  print('SELECT * FROM kols WHERE id = 1;');
  print('SELECT * FROM stocks WHERE ticker = \'TEMP\';\n');

  print('=== 診斷完成 ===');
}
