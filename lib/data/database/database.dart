import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';

part 'database.g.dart';

// Table 1: KOLs
class KOLs extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get bio => text().nullable()();
  TextColumn get socialLink => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
}

// Table 2: Stocks
class Stocks extends Table {
  TextColumn get ticker => text()();
  TextColumn get name => text().nullable()();
  TextColumn get exchange => text().nullable()();
  DateTimeColumn get lastUpdated => dateTime()();
  
  @override
  Set<Column> get primaryKey => {ticker};
}

// Table 3: Posts
class Posts extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get kolId => integer().references(KOLs, #id)();
  // 注意：stockTicker 和 sentiment 已移至 PostStocks 表，保留此欄位僅為向後兼容
  @Deprecated('使用 PostStocks 表代替')
  TextColumn get stockTicker => text().references(Stocks, #ticker).nullable()();
  TextColumn get content => text()();
  @Deprecated('使用 PostStocks 表代替')
  TextColumn get sentiment => text().nullable()();
  DateTimeColumn get postedAt => dateTime()();
  DateTimeColumn get createdAt => dateTime()();
  TextColumn get status => text()();
  TextColumn get aiAnalysisJson => text().nullable()(); // AI 分析結果（JSON 格式）
}

// Table 4: PostStocks (Post 與 Stock 的多對多關聯表)
class PostStocks extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get postId => integer().references(Posts, #id)();
  TextColumn get stockTicker => text().references(Stocks, #ticker)();
  TextColumn get sentiment => text()(); // 該標的的情緒 (Bullish/Bearish/Neutral)
  BoolColumn get isPrimary => boolean().withDefault(const Constant(false))(); // 是否為主要標的
  
  @override
  List<Set<Column>> get uniqueKeys => [
    {postId, stockTicker}, // 確保同一 Post 不會有重複的 Stock
  ];
}

// Table 5: StockPrices
class StockPrices extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get ticker => text().references(Stocks, #ticker)();
  DateTimeColumn get date => dateTime()();
  RealColumn get open => real()();
  RealColumn get close => real()();
  RealColumn get high => real()();
  RealColumn get low => real()();
  IntColumn get volume => integer()();
}

@DriftDatabase(tables: [KOLs, Stocks, Posts, PostStocks, StockPrices])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : _skipDefaultData = false, super(_openConnection());
  
  /// 測試用建構子，允許使用自訂 executor
  AppDatabase.customExecutor(QueryExecutor executor, {bool skipDefaultData = false})
      : _skipDefaultData = skipDefaultData,
        super(executor);

  final bool _skipDefaultData;

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
        
        // 跳過預設資料（在測試環境中使用）
        if (_skipDefaultData) return;
        
        // 建立預設 KOL（未分類）- 用於快速草稿
        // 注意：Drift 將 KOLs 類別轉換為 k_o_ls 表名，createdAt 轉換為 created_at
        // 注意：Drift 預設將 DateTime 儲存為 Unix Timestamp (seconds)，所以使用 strftime('%s', 'now')
        await customStatement('''
          INSERT OR IGNORE INTO k_o_ls (id, name, created_at) 
          VALUES (1, '未分類', CAST(strftime('%s', 'now') AS INTEGER));
        ''');
        
        // 建立預設 Stock（臨時）- 用於快速草稿
        await customStatement('''
          INSERT OR IGNORE INTO stocks (ticker, name, last_updated) 
          VALUES ('TEMP', '臨時', CAST(strftime('%s', 'now') AS INTEGER));
        ''');
        
        // 為 StockPrices 添加複合唯一索引 (ticker, date)
        await customStatement('''
          CREATE UNIQUE INDEX IF NOT EXISTS idx_stock_prices_ticker_date 
          ON stock_prices(ticker, date);
        ''');
      },
      beforeOpen: (details) async {
        // 啟用 Foreign Key 約束
        await customStatement('PRAGMA foreign_keys = ON;');
        
        // 為 StockPrices 添加複合唯一索引 (ticker, date)
        await customStatement('''
          CREATE UNIQUE INDEX IF NOT EXISTS idx_stock_prices_ticker_date 
          ON stock_prices(ticker, date);
        ''');
        
        // 跳過預設資料（在測試環境中使用）
        if (_skipDefaultData) return;
        
        // 確保預設數據存在（僅當表已存在時）
        // 如果表不存在，INSERT 會失敗，我們捕獲錯誤即可
        try {
          await customStatement('''
            INSERT OR IGNORE INTO k_o_ls (id, name, created_at) 
            VALUES (1, '未分類', CAST(strftime('%s', 'now') AS INTEGER));
          ''');
        } catch (e) {
          // 如果表不存在，忽略錯誤（將在 onCreate 中處理）
        }
        
        try {
          await customStatement('''
            INSERT OR IGNORE INTO stocks (ticker, name, last_updated) 
            VALUES ('TEMP', '臨時', CAST(strftime('%s', 'now') AS INTEGER));
          ''');
        } catch (e) {
          // 如果表不存在，忽略錯誤（將在 onCreate 中處理）
        }
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // 從版本 1 升級到版本 2：新增 aiAnalysisJson 欄位
        if (from == 1 && to >= 2) {
          await m.addColumn(posts, posts.aiAnalysisJson);
        }
        
        // 從版本 2 升級到版本 3：新增 PostStocks 表並遷移資料
        if (from <= 2 && to >= 3) {
          // 建立 PostStocks 表
          await m.createTable(postStocks);
          
          // 遷移現有資料：將 Posts.stockTicker + sentiment 轉移到 PostStocks 表
          await customStatement('''
            INSERT INTO post_stocks (post_id, stock_ticker, sentiment, is_primary)
            SELECT id, stock_ticker, sentiment, 1
            FROM posts
            WHERE stock_ticker IS NOT NULL AND stock_ticker != ''
          ''');
          
          // 將 stockTicker 和 sentiment 設為可為 null（向後兼容）
          // 注意：SQLite 不支援直接修改欄位，所以我們保留欄位但標記為 deprecated
        }
      },
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    // 確保 SQLite 原生庫已載入
    if (Platform.isAndroid) {
      await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
    }
    
    // 取得應用程式文件目錄
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'stock_kol_tracker.db'));
    
    return NativeDatabase.createInBackground(file);
  });
}
