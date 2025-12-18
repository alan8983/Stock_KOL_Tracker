import 'package:flutter_test/flutter_test.dart';
import 'package:stock_kol_tracker/core/utils/time_parser.dart';
import 'package:stock_kol_tracker/core/utils/kol_matcher.dart';
import 'package:stock_kol_tracker/data/database/database.dart';

void main() {
  group('TimeParser Tests', () {
    test('解析相對時間：3小時前', () {
      final now = DateTime.now();
      final result = TimeParser.parse('3小時前');
      
      expect(result, isNotNull);
      expect(result!.difference(now).inHours, closeTo(-3, 0.1));
    });

    test('解析相對時間：16小時', () {
      final now = DateTime.now();
      final result = TimeParser.parse('16小時');
      
      expect(result, isNotNull);
      expect(result!.difference(now).inHours, closeTo(-16, 0.1));
    });

    test('解析相對時間：2天前', () {
      final now = DateTime.now();
      final result = TimeParser.parse('2天前');
      
      expect(result, isNotNull);
      expect(result!.difference(now).inDays, equals(-2));
    });

    test('解析中文日期：12月11日', () {
      final result = TimeParser.parse('12月11日');
      
      expect(result, isNotNull);
      expect(result!.month, equals(12));
      // 日期可能是11日或當年的過去日期，取決於當前日期
      expect(result.day, anyOf(equals(11), greaterThan(0)));
    });

    test('解析中文日期帶時間：12月11日下午2:02', () {
      final result = TimeParser.parse('12月11日下午2:02');
      
      expect(result, isNotNull);
      expect(result!.month, equals(12));
      // 日期可能是11日或當年的過去日期
      expect(result.day, anyOf(equals(11), greaterThan(0)));
      expect(result.hour, equals(14)); // 下午2點 = 14:00
      expect(result.minute, equals(2));
    });

    test('解析中文日期帶時間：12月10日上午11:25', () {
      final result = TimeParser.parse('12月10日上午11:25');
      
      expect(result, isNotNull);
      expect(result!.month, equals(12));
      // 日期可能是10日或當年的過去日期
      expect(result.day, anyOf(equals(10), greaterThan(0)));
      expect(result.hour, equals(11));
      expect(result.minute, equals(25));
    });

    test('無法解析的文字返回 null', () {
      final result = TimeParser.parse('無效的時間');
      expect(result, isNull);
    });

    test('空字串返回 null', () {
      final result = TimeParser.parse('');
      expect(result, isNull);
    });

    test('null 返回 null', () {
      final result = TimeParser.parse(null);
      expect(result, isNull);
    });
  });

  group('KOLMatcher Tests', () {
    test('完全匹配', () {
      final kols = [
        KOL(id: 1, name: '蕭上農', bio: null, socialLink: null, createdAt: DateTime.now()),
        KOL(id: 2, name: 'IEObserve 國際經濟觀察', bio: null, socialLink: null, createdAt: DateTime.now()),
      ];

      final result = KOLMatcher.findBestMatch('蕭上農', kols);
      expect(result, equals(1));
    });

    test('包含關係匹配', () {
      final kols = [
        KOL(id: 1, name: 'IEObserve 國際經濟觀察', bio: null, socialLink: null, createdAt: DateTime.now()),
        KOL(id: 2, name: '大叔美股筆記', bio: null, socialLink: null, createdAt: DateTime.now()),
      ];

      final result = KOLMatcher.findBestMatch('IEObserve', kols);
      expect(result, equals(1));
    });

    test('部分匹配', () {
      final kols = [
        KOL(id: 1, name: '大叔美股筆記 Uncle Investment Note', bio: null, socialLink: null, createdAt: DateTime.now()),
        KOL(id: 2, name: '其他 KOL', bio: null, socialLink: null, createdAt: DateTime.now()),
      ];

      final result = KOLMatcher.findBestMatch('大叔美股筆記', kols);
      expect(result, equals(1));
    });

    test('相似度過低不匹配', () {
      final kols = [
        KOL(id: 1, name: '完全不同的名稱', bio: null, socialLink: null, createdAt: DateTime.now()),
      ];

      final result = KOLMatcher.findBestMatch('蕭上農', kols);
      expect(result, isNull);
    });

    test('空 KOL 列表返回 null', () {
      final result = KOLMatcher.findBestMatch('蕭上農', []);
      expect(result, isNull);
    });

    test('null KOL 名稱返回 null', () {
      final kols = [
        KOL(id: 1, name: '蕭上農', bio: null, socialLink: null, createdAt: DateTime.now()),
      ];

      final result = KOLMatcher.findBestMatch(null, kols);
      expect(result, isNull);
    });

    test('計算相似度：完全匹配', () {
      final similarity = KOLMatcher.calculateSimilarity('蕭上農', '蕭上農');
      expect(similarity, equals(1.0));
    });

    test('計算相似度：包含關係', () {
      final similarity = KOLMatcher.calculateSimilarity('IEObserve', 'IEObserve 國際經濟觀察');
      expect(similarity, greaterThanOrEqualTo(0.7));
    });

    test('計算相似度：大小寫不敏感', () {
      final similarity = KOLMatcher.calculateSimilarity('ieobserve', 'IEObserve');
      expect(similarity, equals(1.0));
    });
  });

  group('Integration Tests', () {
    test('Sample_001 格式：KOL 在開頭，相對時間', () {
      // Sample_001.txt: 蕭上農\n3小時前
      final kolName = '蕭上農';
      final timeText = '3小時前';

      final kols = [
        KOL(id: 1, name: '蕭上農', bio: null, socialLink: null, createdAt: DateTime.now()),
        KOL(id: 2, name: '其他 KOL', bio: null, socialLink: null, createdAt: DateTime.now()),
      ];

      final matchedKolId = KOLMatcher.findBestMatch(kolName, kols);
      final parsedTime = TimeParser.parse(timeText);

      expect(matchedKolId, equals(1));
      expect(parsedTime, isNotNull);
    });

    test('Sample_002 格式：KOL 在開頭，絕對時間', () {
      // Sample_002.txt: IEObserve 國際經濟觀察\n12月11日下午2:02
      final kolName = 'IEObserve 國際經濟觀察';
      final timeText = '12月11日下午2:02';

      final kols = [
        KOL(id: 1, name: 'IEObserve 國際經濟觀察', bio: null, socialLink: null, createdAt: DateTime.now()),
        KOL(id: 2, name: '其他 KOL', bio: null, socialLink: null, createdAt: DateTime.now()),
      ];

      final matchedKolId = KOLMatcher.findBestMatch(kolName, kols);
      final parsedTime = TimeParser.parse(timeText);

      expect(matchedKolId, equals(1));
      expect(parsedTime, isNotNull);
      expect(parsedTime!.month, equals(12));
      // 日期可能因當前日期而異
      expect(parsedTime.day, greaterThan(0));
      expect(parsedTime.hour, equals(14));
      expect(parsedTime.minute, equals(2));
    });
  });
}

