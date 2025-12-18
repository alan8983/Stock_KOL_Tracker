import 'package:drift/drift.dart';
import 'package:stock_kol_tracker/data/database/database.dart';

/// 測試資料常數
/// 從 Sample_001.txt ~ Sample_004.txt 提取的測試資料

class TestData {
  // ==================== KOL 測試資料 ====================
  
  static final kol1 = KOLsCompanion.insert(
    id: const Value(101),
    name: '蕭上農',
    bio: const Value('科技股分析專家'),
    socialLink: const Value('https://example.com/shiau'),
    createdAt: DateTime(2024, 1, 1),
  );

  static final kol2 = KOLsCompanion.insert(
    id: const Value(102),
    name: 'IEObserve 國際經濟觀察',
    bio: const Value('國際經濟與市場分析'),
    socialLink: const Value('https://example.com/ieobserve'),
    createdAt: DateTime(2024, 1, 2),
  );

  static final kol3 = KOLsCompanion.insert(
    id: const Value(103),
    name: '大叔美股筆記',
    bio: const Value('美股投資筆記'),
    socialLink: const Value('https://example.com/uncle'),
    createdAt: DateTime(2024, 1, 3),
  );

  // ==================== Stock 測試資料 ====================
  
  static final stockGOOGL = StocksCompanion.insert(
    ticker: 'GOOGL',
    name: const Value('Alphabet Inc.'),
    exchange: const Value('NASDAQ'),
    lastUpdated: DateTime(2025, 12, 13),
  );

  static final stockORCL = StocksCompanion.insert(
    ticker: 'ORCL',
    name: const Value('Oracle Corporation'),
    exchange: const Value('NYSE'),
    lastUpdated: DateTime(2025, 12, 11),
  );

  static final stockTSLA = StocksCompanion.insert(
    ticker: 'TSLA',
    name: const Value('Tesla Inc.'),
    exchange: const Value('NASDAQ'),
    lastUpdated: DateTime(2025, 12, 10),
  );

  static final stockONDS = StocksCompanion.insert(
    ticker: 'ONDS',
    name: const Value('Ondas Holdings Inc.'),
    exchange: const Value('NASDAQ'),
    lastUpdated: DateTime(2025, 12, 13),
  );

  // ==================== Post 測試資料 ====================
  
  /// Sample_001: 蕭上農 - GOOGL - Bullish
  static final post1 = PostsCompanion.insert(
    id: const Value(1001),
    kolId: 101,
    stockTicker: 'GOOGL',
    content: sample001Content,
    sentiment: 'Bullish',
    postedAt: DateTime(2025, 12, 13, 12, 0),
    createdAt: DateTime(2025, 12, 13, 12, 0),
    status: 'Published',
  );

  /// Sample_002: IEObserve 國際經濟觀察 - ORCL - Bearish
  static final post2 = PostsCompanion.insert(
    id: const Value(1002),
    kolId: 102,
    stockTicker: 'ORCL',
    content: sample002Content,
    sentiment: 'Bearish',
    postedAt: DateTime(2025, 12, 11, 14, 2),
    createdAt: DateTime(2025, 12, 11, 14, 2),
    status: 'Published',
  );

  /// Sample_003: IEObserve 國際經濟觀察 - TSLA - Bullish
  static final post3 = PostsCompanion.insert(
    id: const Value(1003),
    kolId: 102,
    stockTicker: 'TSLA',
    content: sample003Content,
    sentiment: 'Bullish',
    postedAt: DateTime(2025, 12, 10, 11, 25),
    createdAt: DateTime(2025, 12, 10, 11, 25),
    status: 'Published',
  );

  /// Sample_004: 大叔美股筆記 - ONDS - Bullish
  static final post4 = PostsCompanion.insert(
    id: const Value(1004),
    kolId: 103,
    stockTicker: 'ONDS',
    content: sample004Content,
    sentiment: 'Bullish',
    postedAt: DateTime(2025, 12, 13, 8, 0),
    createdAt: DateTime(2025, 12, 13, 8, 0),
    status: 'Published',
  );

  // ==================== Sample 文件內容 ====================
  
  static const sample001Content = '''蕭上農
3小時前

為什麼投資 Google 等於投資 SpaceX？被財報掩蓋的這 25% 隱藏資產
1973 年，華爾街正經歷一場慘烈的股災。當時年僅 43 歲的華倫・巴菲特卻在這個時候，大舉買入一家名為「華盛頓郵報」的股票。當時市場對這家公司的看法很簡單：它是做報紙的，而報紙正在被電視取代，這是一個夕陽產業。
但巴菲特看到了一些不一樣的東西。他翻開財報，發現雖然報紙業務面臨挑戰，但這家公司旗下擁有的電視台和房地產價值，已經遠遠超過了當時的股票市值。這意味著，如果你買入這檔股票，等於是免費獲得了報紙業務，還附贈了一堆增值潛力巨大的資產。後來的結果大家都知道了，這筆投資成為巴菲特生涯中最經典的戰役之一，回報率超過百倍。
五十年後的今天，我們在科技股市場可能看到一個驚人相似的劇本，但劇情的走勢更為戲劇化。
主角換成了 Alphabet (Google)。2025 年對 Google 來說是驚心動魄的一年。
上半年，市場還在為「Search 是否會被 AI 取代」而焦慮；下半年，隨著 Gemini 3 的強勢發布與橫掃市場，Google 用實力證明了它是 AI 戰場的真正王者，股價也隨之創下新高。
同時，困擾已久的反壟斷官司也迎來關鍵轉折：法官雖然判定非法壟斷，但拒絕了司法部「拆分 Google」的極端要求。這意味著 Google 挺過了最大的危機。
但這也是最有趣的地方：即便 Google 王者歸來、股價大漲，它的本益比 (P/E Ratio) 依然只有 31 倍左右，相較於微軟的 35 倍，仍存在明顯的「折價」。市場雖然不再擔心它會死，但對於它未來的「反壟斷緊箍咒」（如開放數據、禁止預裝合約）仍心存芥蒂。
正因為投資人的目光都聚焦在 AI 的勝利與反壟斷的餘波，他們反而忽視 Google 資產負債表裡，那枚隱藏的核彈級資產。
Google 不只是一家 AI 公司，它還是地球上唯一一家能飛去火星的公司的第二大股東。這筆被財報會計準則「隱藏」起來的資產，可能價值超過 1,000 億美元，相當於你每買一股 Google，就免費獲贈了一張 SpaceX 的船票。''';

  static const sample002Content = '''IEObserve 國際經濟觀察
 
12月11日下午2:02
 ·
Oracle昨晚公布財報後股價暴跌超過11%，這家老牌科技巨頭正在經歷一場前所未有的財務豪賭。161億美元的營收雖然年增14%，但略低於市場預期的162億美元，公司將2026財年資本支出從350億美元暴增至500億美元，本季自由現金流為-100億美元，遠低於市場預期的-52億美元。
但Oracle的剩餘履約義務（RPO）單季激增680億美元，達到5,233億美元，年增率高達438%。Meta、NVIDIA和OpenAI等客戶已經承諾的未來訂單創下歷史紀錄。OpenAI一家就承諾五年投入超過3,000億美元，這是AI產業史上最大規模的單一客戶合約。
這場豪賭的核心矛盾在於時間差：Oracle正在燒錢建設資料中心，但營收轉化需要時間。公司總債務已超過1,060億美元，CDS信用違約掉期利差上升至1.246個百分點，接近金融危機以來高點。債券市場用真金白銀表達了對Oracle信用風險的擔憂。''';

  static const sample003Content = '''IEObserve 國際經濟觀察
 
12月10日上午11:25
 ·
老馬這次的時間點壓得非常近了，三週拔掉Austin的Robotaxi安全員
基本上只要能拔掉安全員，就是大規模鋪開的開始。而且奧斯丁會是一個很好的小樣本，如果特斯拉的自動駕駛車隊真的有壓倒性的成本優勢，那就會在奧斯丁消滅Waymo、Uber、人類計程車的生存空間。如果在奧斯丁消滅不了其他競爭的替代選項，也沒什麼理由能說在其他地方會消滅其他廠商。''';

  static const sample004Content = '''大叔美股筆記 Uncle Investment Note
16 小時
Facebook

這張圖表來自 Fintel.io，展示了 #ONDS (Ondas Holdings Inc.) 的機構持股 與其股價之間的歷史走勢對比。
Dec, 2025，機構持股量出現了史詩級的垂直暴增。持股股數從原本的低位（約 20,000 x1000 股以下）瞬間飆升至超過 110,000 (x1000) 股，也就是超過 1.1 億股。
這代表聰明錢—— 如對沖基金、共同基金、ETF 等大型機構，在極短的時間內達成了強烈的共識，瘋狂搶籌買入這檔股票。
隨著機構持股在 2025 年底的暴增，股價（黑色線）也隨之劇烈反彈，從底部直衝向上，目前看起來已經回到了 \$8-\$10 甚至更高的區間。這顯示股價的上漲是由真金白銀的機構買盤推動的，而非單純的散戶炒作。
籌碼鎖定： 隨著超過 1 億股被機構鎖定，市場上的流通會變少。''';

  // ==================== 便利方法 ====================
  
  /// 取得所有測試用的 KOL
  static List<KOLsCompanion> get allKOLs => [kol1, kol2, kol3];

  /// 取得所有測試用的 Stock
  static List<StocksCompanion> get allStocks => [
        stockGOOGL,
        stockORCL,
        stockTSLA,
        stockONDS,
      ];

  /// 取得所有測試用的 Post
  static List<PostsCompanion> get allPosts => [post1, post2, post3, post4];

  /// 取得特定 KOL 的 Posts
  static List<PostsCompanion> getPostsByKOL(int kolId) {
    return allPosts.where((post) => post.kolId.value == kolId).toList();
  }

  /// 取得特定 Stock 的 Posts
  static List<PostsCompanion> getPostsByStock(String ticker) {
    return allPosts
        .where((post) => post.stockTicker.value == ticker)
        .toList();
  }
}

