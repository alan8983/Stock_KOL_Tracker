import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:stock_kol_tracker/data/services/Gemini/gemini_service.dart';

void main() {
  group('_extractJson via markdown fence + brace scan', () {
    final service = GeminiService(apiKey: 'dummy-key');

    test('extracts fenced code block (```json ... ```)', () {
      const text = '''
Here is your result:
```json
{
  "sentiment": "Bullish",
  "tickers": ["AAPL"]
}
```
Thanks!
''';

      final extracted = service.debugExtractJson(text);
      final decoded = jsonDecode(extracted) as Map<String, dynamic>;

      expect(decoded['sentiment'], 'Bullish');
      expect(decoded['tickers'], ['AAPL']);
    });

    test('handles malformed fence ending with ```json', () {
      const text = '''
```json
{
  "sentiment": "Neutral",
  "tickers": []
}
```json
''';

      final extracted = service.debugExtractJson(text);
      final decoded = jsonDecode(extracted) as Map<String, dynamic>;

      expect(decoded['sentiment'], 'Neutral');
      expect(decoded['tickers'], isEmpty);
    });

    test('falls back to brace scan when no fence', () {
      const text = '''
AI analysis result:
{ "sentiment": "Bearish", "tickers": ["TSLA"] }
Thank you.
''';

      final extracted = service.debugExtractJson(text);
      final decoded = jsonDecode(extracted) as Map<String, dynamic>;

      expect(decoded['sentiment'], 'Bearish');
      expect(decoded['tickers'], ['TSLA']);
    });

    test('returns trimmed text if no braces present', () {
      const text = 'No JSON present';
      final extracted = service.debugExtractJson(text);
      expect(extracted, 'No JSON present');
    });
  });
}
