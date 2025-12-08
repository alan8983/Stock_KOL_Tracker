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
  TextColumn get stockTicker => text().references(Stocks, #ticker)();
  TextColumn get content => text()();
  TextColumn get sentiment => text()();
  DateTimeColumn get postedAt => dateTime()();
  DateTimeColumn get createdAt => dateTime()();
  TextColumn get status => text()();
}

// Table 4: StockPrices
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

@DriftDatabase(tables: [KOLs, Stocks, Posts, StockPrices])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      beforeOpen: (details) async {
        // 啟用 Foreign Key 約束
        await customStatement('PRAGMA foreign_keys = ON;');
        
        // 為 StockPrices 添加複合唯一索引 (ticker, date)
        await customStatement('''
          CREATE UNIQUE INDEX IF NOT EXISTS idx_stock_prices_ticker_date 
          ON stock_prices(ticker, date);
        ''');
        
        // 建立預設 KOL（未分類）- 用於快速草稿
        await customStatement('''
          INSERT OR IGNORE INTO kols (id, name, createdAt) 
          VALUES (1, '未分類', datetime('now'));
        ''');
        
        // 建立預設 Stock（臨時）- 用於快速草稿
        await customStatement('''
          INSERT OR IGNORE INTO stocks (ticker, name, lastUpdated) 
          VALUES ('TEMP', '臨時', datetime('now'));
        ''');
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // 未來版本升級時使用
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
