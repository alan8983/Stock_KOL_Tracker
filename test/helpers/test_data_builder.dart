import 'package:drift/drift.dart';
import 'package:stock_kol_tracker/data/database/database.dart';

/// 測試資料建構器
/// 提供 Builder Pattern 來建立測試用的資料物件
class TestDataBuilder {
  // ==================== KOL Builder ====================

  /// KOL 建構器
  static KOLBuilder kol() => KOLBuilder();

  // ==================== Stock Builder ====================

  /// Stock 建構器
  static StockBuilder stock() => StockBuilder();

  // ==================== Post Builder ====================

  /// Post 建構器
  static PostBuilder post() => PostBuilder();
}

/// KOL 資料建構器
class KOLBuilder {
  int? _id;
  String _name = 'Test KOL';
  String? _bio;
  String? _socialLink;
  DateTime _createdAt = DateTime.now();

  KOLBuilder id(int id) {
    _id = id;
    return this;
  }

  KOLBuilder name(String name) {
    _name = name;
    return this;
  }

  KOLBuilder bio(String? bio) {
    _bio = bio;
    return this;
  }

  KOLBuilder socialLink(String? link) {
    _socialLink = link;
    return this;
  }

  KOLBuilder createdAt(DateTime date) {
    _createdAt = date;
    return this;
  }

  /// 建立 KOLsCompanion（用於插入資料庫）
  KOLsCompanion build() {
    return KOLsCompanion.insert(
      id: _id != null ? Value(_id!) : const Value.absent(),
      name: _name,
      bio: Value(_bio),
      socialLink: Value(_socialLink),
      createdAt: _createdAt,
    );
  }

  /// 建立 KOL 物件（用於測試驗證）
  KOL buildEntity() {
    return KOL(
      id: _id ?? 1,
      name: _name,
      bio: _bio,
      socialLink: _socialLink,
      createdAt: _createdAt,
    );
  }
}

/// Stock 資料建構器
class StockBuilder {
  String _ticker = 'TEST';
  String? _name;
  String? _exchange;
  DateTime _lastUpdated = DateTime.now();

  StockBuilder ticker(String ticker) {
    _ticker = ticker;
    return this;
  }

  StockBuilder name(String? name) {
    _name = name;
    return this;
  }

  StockBuilder exchange(String? exchange) {
    _exchange = exchange;
    return this;
  }

  StockBuilder lastUpdated(DateTime date) {
    _lastUpdated = date;
    return this;
  }

  /// 建立 StocksCompanion（用於插入資料庫）
  StocksCompanion build() {
    return StocksCompanion.insert(
      ticker: _ticker,
      name: Value(_name),
      exchange: Value(_exchange),
      lastUpdated: _lastUpdated,
    );
  }

  /// 建立 Stock 物件（用於測試驗證）
  Stock buildEntity() {
    return Stock(
      ticker: _ticker,
      name: _name,
      exchange: _exchange,
      lastUpdated: _lastUpdated,
    );
  }
}

/// Post 資料建構器
class PostBuilder {
  int? _id;
  int _kolId = 1;
  String _stockTicker = 'TEMP';
  String _content = 'Test content';
  String _sentiment = 'Neutral';
  DateTime _postedAt = DateTime.now();
  DateTime _createdAt = DateTime.now();
  String _status = 'Published';

  PostBuilder id(int id) {
    _id = id;
    return this;
  }

  PostBuilder kolId(int kolId) {
    _kolId = kolId;
    return this;
  }

  PostBuilder stockTicker(String ticker) {
    _stockTicker = ticker;
    return this;
  }

  PostBuilder content(String content) {
    _content = content;
    return this;
  }

  PostBuilder sentiment(String sentiment) {
    _sentiment = sentiment;
    return this;
  }

  PostBuilder postedAt(DateTime date) {
    _postedAt = date;
    return this;
  }

  PostBuilder createdAt(DateTime date) {
    _createdAt = date;
    return this;
  }

  PostBuilder status(String status) {
    _status = status;
    return this;
  }

  /// 便利方法：設定為草稿
  PostBuilder draft() {
    _status = 'Draft';
    return this;
  }

  /// 便利方法：設定為已發布
  PostBuilder published() {
    _status = 'Published';
    return this;
  }

  /// 便利方法：設定情緒為 Bullish
  PostBuilder bullish() {
    _sentiment = 'Bullish';
    return this;
  }

  /// 便利方法：設定情緒為 Bearish
  PostBuilder bearish() {
    _sentiment = 'Bearish';
    return this;
  }

  /// 便利方法：設定情緒為 Neutral
  PostBuilder neutral() {
    _sentiment = 'Neutral';
    return this;
  }

  /// 建立 PostsCompanion（用於插入資料庫）
  PostsCompanion build() {
    return PostsCompanion.insert(
      id: _id != null ? Value(_id!) : const Value.absent(),
      kolId: _kolId,
      stockTicker: _stockTicker,
      content: _content,
      sentiment: _sentiment,
      postedAt: _postedAt,
      createdAt: _createdAt,
      status: _status,
    );
  }

  /// 建立 Post 物件（用於測試驗證）
  Post buildEntity() {
    return Post(
      id: _id ?? 1,
      kolId: _kolId,
      stockTicker: _stockTicker,
      content: _content,
      sentiment: _sentiment,
      postedAt: _postedAt,
      createdAt: _createdAt,
      status: _status,
    );
  }
}

/// 使用範例：
/// 
/// ```dart
/// // 建立 KOL
/// final kol = TestDataBuilder.kol()
///   .id(100)
///   .name('測試 KOL')
///   .bio('測試簡介')
///   .build();
/// 
/// // 建立 Stock
/// final stock = TestDataBuilder.stock()
///   .ticker('AAPL')
///   .name('Apple Inc.')
///   .exchange('NASDAQ')
///   .build();
/// 
/// // 建立 Post
/// final post = TestDataBuilder.post()
///   .id(1000)
///   .kolId(100)
///   .stockTicker('AAPL')
///   .content('看好蘋果')
///   .bullish()
///   .published()
///   .build();
/// ```

