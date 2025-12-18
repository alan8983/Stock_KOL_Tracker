import '../../data/database/database.dart';

/// KOL 模糊匹配工具
/// 用於從 AI 辨識的名稱找出最相似的 KOL
class KOLMatcher {
  /// 相似度閾值（0-1），超過此值才視為匹配成功
  static const double similarityThreshold = 0.7;

  /// 從 KOL 列表中找出與給定名稱最相似的 KOL
  /// 返回 KOL ID，若沒有找到相似的則返回 null
  static int? findBestMatch(String? aiKolName, List<KOL> allKols) {
    if (aiKolName == null || aiKolName.trim().isEmpty) {
      print('⚠️ KOLMatcher: AI 未辨識到 KOL 名稱');
      return null;
    }

    if (allKols.isEmpty) {
      print('⚠️ KOLMatcher: 資料庫中沒有 KOL 記錄');
      return null;
    }

    final cleanedAiName = aiKolName.trim();
    print('🔍 KOLMatcher: 開始匹配 "$cleanedAiName"');

    KOL? bestMatch;
    double bestSimilarity = 0.0;

    for (final kol in allKols) {
      final similarity = calculateSimilarity(cleanedAiName, kol.name);
      print('   - ${kol.name}: 相似度 ${(similarity * 100).toStringAsFixed(1)}%');

      if (similarity > bestSimilarity) {
        bestSimilarity = similarity;
        bestMatch = kol;
      }
    }

    if (bestSimilarity >= similarityThreshold && bestMatch != null) {
      print('✅ KOLMatcher: 找到匹配 "${bestMatch.name}" (相似度: ${(bestSimilarity * 100).toStringAsFixed(1)}%)');
      return bestMatch.id;
    } else {
      print('⚠️ KOLMatcher: 沒有找到相似度 >= ${(similarityThreshold * 100).toInt()}% 的 KOL');
      return null;
    }
  }

  /// 計算兩個字串的相似度（0-1）
  /// 使用多種策略：完全匹配、包含關係、編輯距離
  static double calculateSimilarity(String name1, String name2) {
    final s1 = name1.toLowerCase().trim();
    final s2 = name2.toLowerCase().trim();

    // 策略 1: 完全匹配
    if (s1 == s2) {
      return 1.0;
    }

    // 策略 2: 包含關係（較短的字串在較長的字串中）
    if (s1.contains(s2)) {
      // s1 包含 s2
      return 0.85 + (s2.length / s1.length * 0.15);
    }
    
    if (s2.contains(s1)) {
      // s2 包含 s1
      return 0.85 + (s1.length / s2.length * 0.15);
    }

    // 策略 3: 移除空格後再比較
    final s1NoSpace = s1.replaceAll(' ', '');
    final s2NoSpace = s2.replaceAll(' ', '');
    
    if (s1NoSpace == s2NoSpace) {
      return 0.95;
    }

    if (s1NoSpace.contains(s2NoSpace)) {
      return 0.80 + (s2NoSpace.length / s1NoSpace.length * 0.15);
    }
    
    if (s2NoSpace.contains(s1NoSpace)) {
      return 0.80 + (s1NoSpace.length / s2NoSpace.length * 0.15);
    }

    // 策略 4: Levenshtein Distance（編輯距離）
    final distance = _levenshteinDistance(s1, s2);
    final maxLength = s1.length > s2.length ? s1.length : s2.length;
    
    if (maxLength == 0) return 0.0;
    
    final similarity = 1.0 - (distance / maxLength);
    return similarity > 0 ? similarity : 0.0;
  }

  /// 計算 Levenshtein Distance（編輯距離）
  /// 返回將 s1 轉換為 s2 所需的最少編輯次數
  static int _levenshteinDistance(String s1, String s2) {
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;

    final matrix = List.generate(
      s1.length + 1,
      (i) => List.filled(s2.length + 1, 0),
    );

    // 初始化第一列和第一行
    for (var i = 0; i <= s1.length; i++) {
      matrix[i][0] = i;
    }
    for (var j = 0; j <= s2.length; j++) {
      matrix[0][j] = j;
    }

    // 計算編輯距離
    for (var i = 1; i <= s1.length; i++) {
      for (var j = 1; j <= s2.length; j++) {
        final cost = s1[i - 1] == s2[j - 1] ? 0 : 1;
        matrix[i][j] = [
          matrix[i - 1][j] + 1, // 刪除
          matrix[i][j - 1] + 1, // 插入
          matrix[i - 1][j - 1] + cost, // 替換
        ].reduce((a, b) => a < b ? a : b);
      }
    }

    return matrix[s1.length][s2.length];
  }
}

