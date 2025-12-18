import 'package:flutter_test/flutter_test.dart';
import 'package:stock_kol_tracker/core/utils/win_rate_calculator.dart';

void main() {
  late WinRateCalculator calculator;

  setUp(() {
    calculator = WinRateCalculator();
  });

  group('WinRateCalculator', () {
    group('evaluatePrediction', () {
      test('Bullish + 漲幅 > 2% = 正確', () {
        final result = calculator.evaluatePrediction(
          sentiment: 'Bullish',
          priceChange: 5.0, // +5%
        );

        expect(result.outcome, PredictionOutcome.correct);
        expect(result.sentiment, 'Bullish');
        expect(result.priceChange, 5.0);
      });

      test('Bearish + 跌幅 < -2% = 正確', () {
        final result = calculator.evaluatePrediction(
          sentiment: 'Bearish',
          priceChange: -3.5, // -3.5%
        );

        expect(result.outcome, PredictionOutcome.correct);
        expect(result.sentiment, 'Bearish');
        expect(result.priceChange, -3.5);
      });

      test('Bullish + 跌幅 < -2% = 錯誤', () {
        final result = calculator.evaluatePrediction(
          sentiment: 'Bullish',
          priceChange: -4.0, // -4%
        );

        expect(result.outcome, PredictionOutcome.incorrect);
      });

      test('Bearish + 漲幅 > 2% = 錯誤', () {
        final result = calculator.evaluatePrediction(
          sentiment: 'Bearish',
          priceChange: 3.0, // +3%
        );

        expect(result.outcome, PredictionOutcome.incorrect);
      });

      test('Bullish + 漲幅 = +1.5% (震盪區間) = 不計入', () {
        final result = calculator.evaluatePrediction(
          sentiment: 'Bullish',
          priceChange: 1.5,
        );

        expect(result.outcome, PredictionOutcome.neutral);
        expect(result.countsTowardWinRate, false);
      });

      test('Bullish + 漲幅 = -1.0% (震盪區間) = 不計入', () {
        final result = calculator.evaluatePrediction(
          sentiment: 'Bullish',
          priceChange: -1.0,
        );

        expect(result.outcome, PredictionOutcome.neutral);
        expect(result.countsTowardWinRate, false);
      });

      test('門檻邊界：漲幅剛好 +2.0%', () {
        final result = calculator.evaluatePrediction(
          sentiment: 'Bullish',
          priceChange: 2.0,
        );

        // 邊界值視為震盪區間（不計入）
        expect(result.outcome, PredictionOutcome.neutral);
      });

      test('門檻邊界：跌幅剛好 -2.0%', () {
        final result = calculator.evaluatePrediction(
          sentiment: 'Bearish',
          priceChange: -2.0,
        );

        // 邊界值視為震盪區間（不計入）
        expect(result.outcome, PredictionOutcome.neutral);
      });

      test('門檻邊界：漲幅 +2.1% (超過門檻)', () {
        final result = calculator.evaluatePrediction(
          sentiment: 'Bullish',
          priceChange: 2.1,
        );

        expect(result.outcome, PredictionOutcome.correct);
      });

      test('Neutral 情緒 = 不計入勝率', () {
        final result = calculator.evaluatePrediction(
          sentiment: 'Neutral',
          priceChange: 5.0,
        );

        expect(result.outcome, PredictionOutcome.notApplicable);
        expect(result.countsTowardWinRate, false);
      });

      test('沒有價格資料 = 不計入', () {
        final result = calculator.evaluatePrediction(
          sentiment: 'Bullish',
          priceChange: null,
        );

        expect(result.outcome, PredictionOutcome.notApplicable);
        expect(result.countsTowardWinRate, false);
      });

      test('countsTowardWinRate 只對 correct 和 incorrect 為 true', () {
        final correct = calculator.evaluatePrediction(
          sentiment: 'Bullish',
          priceChange: 5.0,
        );
        expect(correct.countsTowardWinRate, true);

        final incorrect = calculator.evaluatePrediction(
          sentiment: 'Bullish',
          priceChange: -5.0,
        );
        expect(incorrect.countsTowardWinRate, true);

        final neutral = calculator.evaluatePrediction(
          sentiment: 'Bullish',
          priceChange: 1.0,
        );
        expect(neutral.countsTowardWinRate, false);

        final notApplicable = calculator.evaluatePrediction(
          sentiment: 'Neutral',
          priceChange: 5.0,
        );
        expect(notApplicable.countsTowardWinRate, false);
      });
    });

    group('門檻值測試', () {
      test('門檻值應為 2.0', () {
        expect(WinRateCalculator.threshold, 2.0);
      });

      test('測試邊界值 -2.0 到 +2.0 都視為震盪', () {
        for (double change = -2.0; change <= 2.0; change += 0.1) {
          final result = calculator.evaluatePrediction(
            sentiment: 'Bullish',
            priceChange: change,
          );
          expect(
            result.outcome,
            PredictionOutcome.neutral,
            reason: 'Change $change should be neutral',
          );
        }
      });

      test('測試超過門檻的值', () {
        // 漲幅超過 2%
        final bullishCorrect = calculator.evaluatePrediction(
          sentiment: 'Bullish',
          priceChange: 2.01,
        );
        expect(bullishCorrect.outcome, PredictionOutcome.correct);

        // 跌幅超過 -2%
        final bearishCorrect = calculator.evaluatePrediction(
          sentiment: 'Bearish',
          priceChange: -2.01,
        );
        expect(bearishCorrect.outcome, PredictionOutcome.correct);
      });
    });
  });
}
