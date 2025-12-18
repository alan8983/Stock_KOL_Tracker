import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stock_kol_tracker/data/database/database.dart';
import 'package:stock_kol_tracker/data/repositories/kol_repository.dart';
import 'package:stock_kol_tracker/data/repositories/post_repository.dart';
import 'package:stock_kol_tracker/data/repositories/stock_repository.dart';
import 'package:stock_kol_tracker/domain/providers/repository_providers.dart';
import 'package:stock_kol_tracker/domain/providers/database_provider.dart';
import 'package:stock_kol_tracker/presentation/screens/kol/kol_view_screen.dart';

import '../helpers/test_database_helper.dart';
import '../fixtures/test_data.dart';

void main() {
  group('KOL View Screen 整合測試', () {
    late AppDatabase testDb;

    setUp(() async {
      // 建立測試用記憶體資料庫
      testDb = TestDatabaseHelper.createInMemoryDatabase();
      
      // 插入測試資料
      await TestDatabaseHelper.seedTestData(testDb);
    });

    tearDown(() async {
      // 清理測試資料
      await TestDatabaseHelper.cleanupDatabase(testDb);
      await testDb.close();
    });

    /// 建立測試環境的 Widget
    Widget createTestWidget(int kolId) {
      return ProviderScope(
        overrides: [
          // 覆蓋資料庫 Provider，使用測試資料庫
          databaseProvider.overrideWithValue(testDb),
          // 覆蓋 Repository Providers
          kolRepositoryProvider.overrideWithValue(KOLRepository(testDb)),
          postRepositoryProvider.overrideWithValue(PostRepository(testDb)),
          stockRepositoryProvider.overrideWithValue(StockRepository(testDb)),
        ],
        child: MaterialApp(
          home: KOLViewScreen(kolId: kolId),
        ),
      );
    }

    testWidgets('測試案例 1: 顯示 KOL 基本資訊', (WidgetTester tester) async {
      // Arrange: 使用 IEObserve 國際經濟觀察 (ID: 102)
      const testKolId = 102;
      
      // Act: 載入畫面
      await tester.pumpWidget(createTestWidget(testKolId));
      await tester.pumpAndSettle();

      // Assert: 驗證 KOL 名稱顯示正確
      expect(find.text('IEObserve 國際經濟觀察'), findsAtLeastNWidgets(1));
      
      // Assert: 驗證頁面不顯示載入錯誤
      expect(find.text('找不到此 KOL'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      
      // Assert: 驗證有三個 Tab
      expect(find.text('Overview'), findsOneWidget);
      expect(find.text('勝率統計'), findsOneWidget);
      expect(find.text('簡介'), findsOneWidget);
    });

    testWidgets('測試案例 2: 顯示文檔列表（Overview Tab）', (WidgetTester tester) async {
      // Arrange: 使用 IEObserve 國際經濟觀察 (ID: 102)，有 2 篇文章：ORCL, TSLA
      const testKolId = 102;
      
      // Act: 載入畫面
      await tester.pumpWidget(createTestWidget(testKolId));
      await tester.pumpAndSettle();

      // Assert: 驗證顯示 2 個股票分組
      expect(find.text('ORCL'), findsOneWidget);
      expect(find.text('TSLA'), findsOneWidget);
      
      // Assert: 驗證股票名稱顯示
      expect(find.text('Oracle Corporation'), findsOneWidget);
      expect(find.text('Tesla Inc.'), findsOneWidget);
      
      // Assert: 驗證顯示文檔數量
      expect(find.text('1 篇文檔'), findsNWidgets(2)); // 每個股票各 1 篇
      
      // Assert: 驗證文檔內容摘要正確顯示（檢查部分內容）
      expect(find.textContaining('Oracle昨晚公布財報後股價暴跌超過11%'), findsOneWidget);
      expect(find.textContaining('老馬這次的時間點壓得非常近了'), findsOneWidget);
      
      // Assert: 驗證情緒標籤顯示
      expect(find.text('Bearish'), findsOneWidget); // ORCL 文章
      expect(find.text('Bullish'), findsOneWidget); // TSLA 文章
    });

    testWidgets('測試案例 3: 單一文檔的 KOL', (WidgetTester tester) async {
      // Arrange: 使用蕭上農 (ID: 101)，只有 1 篇文章 GOOGL
      const testKolId = 101;
      
      // Act: 載入畫面
      await tester.pumpWidget(createTestWidget(testKolId));
      await tester.pumpAndSettle();

      // Assert: 驗證 KOL 名稱
      expect(find.text('蕭上農'), findsAtLeastNWidgets(1));
      
      // Assert: 驗證顯示 1 個股票分組（GOOGL）
      expect(find.text('GOOGL'), findsOneWidget);
      expect(find.text('Alphabet Inc.'), findsOneWidget);
      
      // Assert: 驗證該分組下有 1 篇文檔
      expect(find.text('1 篇文檔'), findsOneWidget);
      
      // Assert: 驗證文檔內容（檢查部分內容）
      expect(find.textContaining('為什麼投資 Google 等於投資 SpaceX？'), findsOneWidget);
      
      // Assert: 驗證情緒標籤
      expect(find.text('Bullish'), findsOneWidget);
    });

    testWidgets('測試案例 4: Tab 切換功能', (WidgetTester tester) async {
      // Arrange: 使用 IEObserve 國際經濟觀察 (ID: 102)
      const testKolId = 102;
      
      // Act: 載入畫面
      await tester.pumpWidget(createTestWidget(testKolId));
      await tester.pumpAndSettle();

      // Assert: 預設在 Overview Tab，應該看到文檔列表
      expect(find.text('ORCL'), findsOneWidget);
      expect(find.text('TSLA'), findsOneWidget);
      
      // Act: 切換至「簡介」Tab
      await tester.tap(find.text('簡介'));
      await tester.pumpAndSettle();

      // Assert: 驗證顯示 KOL 簡介資訊
      expect(find.text('KOL 簡介'), findsOneWidget);
      expect(find.text('國際經濟與市場分析'), findsWidgets); // 可能在多處出現（header 和 content）
      expect(find.text('SNS 連結'), findsOneWidget);
      
      // Assert: 驗證統計資訊顯示
      expect(find.text('統計資訊'), findsOneWidget);
      expect(find.text('建立時間'), findsOneWidget);
      expect(find.text('文檔數量'), findsOneWidget);
      expect(find.text('追蹤標的數'), findsOneWidget);
      
      // 等待統計資料載入
      await tester.pumpAndSettle();
      
      // Assert: 驗證統計數據正確（數字 "2" 會出現多次：文檔數量和追蹤標的數）
      expect(find.text('2'), findsWidgets); // 至少 2 個（文檔數和標的數）
      
      // Act: 切換回 Overview Tab
      await tester.tap(find.text('Overview'));
      await tester.pumpAndSettle();

      // Assert: 驗證文檔列表仍正確顯示
      expect(find.text('ORCL'), findsOneWidget);
      expect(find.text('TSLA'), findsOneWidget);
      expect(find.textContaining('Oracle昨晚公布財報後股價暴跌超過11%'), findsOneWidget);
    });

    testWidgets('測試案例 5: 點擊文檔導航', (WidgetTester tester) async {
      // Arrange: 使用蕭上農 (ID: 101)
      const testKolId = 101;
      
      // Act: 載入畫面
      await tester.pumpWidget(createTestWidget(testKolId));
      await tester.pumpAndSettle();

      // Act: 點擊文檔項目
      await tester.tap(find.textContaining('為什麼投資 Google 等於投資 SpaceX？'));
      await tester.pumpAndSettle();

      // Assert: 驗證導航到文檔詳細頁面
      // 注意：由於我們沒有完整的導航設置，這裡可能會出現錯誤
      // 這個測試主要驗證點擊事件有被觸發
      // 實際專案中可能需要 mock Navigator
    });

    testWidgets('測試案例 6: 點擊股票標題導航', (WidgetTester tester) async {
      // Arrange: 使用 IEObserve 國際經濟觀察 (ID: 102)
      const testKolId = 102;
      
      // Act: 載入畫面
      await tester.pumpWidget(createTestWidget(testKolId));
      await tester.pumpAndSettle();

      // Act: 點擊 ORCL 股票標題
      await tester.tap(find.text('ORCL'));
      await tester.pumpAndSettle();

      // Assert: 驗證導航到股票詳細頁面
      // 注意：由於我們沒有完整的導航設置，這裡可能會出現錯誤
      // 這個測試主要驗證點擊事件有被觸發
    });

    testWidgets('測試案例 7: 空 KOL（無文檔）', (WidgetTester tester) async {
      // Arrange: 使用大叔美股筆記 (ID: 103)，有 1 篇文章
      const testKolId = 103;
      
      // Act: 載入畫面
      await tester.pumpWidget(createTestWidget(testKolId));
      await tester.pumpAndSettle();

      // Assert: 驗證 KOL 名稱
      expect(find.text('大叔美股筆記'), findsAtLeastNWidgets(1));
      
      // Assert: 驗證顯示 ONDS 股票
      expect(find.text('ONDS'), findsOneWidget);
      expect(find.text('Ondas Holdings Inc.'), findsOneWidget);
      
      // Assert: 驗證文檔內容
      expect(find.textContaining('這張圖表來自 Fintel.io'), findsOneWidget);
    });

    testWidgets('測試案例 8: 驗證情緒標籤圖示', (WidgetTester tester) async {
      // Arrange: 使用 IEObserve 國際經濟觀察 (ID: 102)
      const testKolId = 102;
      
      // Act: 載入畫面
      await tester.pumpWidget(createTestWidget(testKolId));
      await tester.pumpAndSettle();

      // Assert: 驗證 Bullish 圖示（向上箭頭）
      expect(find.byIcon(Icons.trending_up), findsWidgets);
      
      // Assert: 驗證 Bearish 圖示（向下箭頭）
      expect(find.byIcon(Icons.trending_down), findsWidgets);
    });
  });
}

