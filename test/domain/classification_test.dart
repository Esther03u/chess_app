import 'package:flutter_test/flutter_test.dart';
import 'package:chess_app/domain/classification.dart';

void main() {
  group('MoveClassifier & Classification Math (FR6 & §3.9)', () {
    test(
      'winPct conversion: 0 centipawns equals exactly 50% winning chance',
      () {
        final pct = MoveClassifier.winPct(0);
        expect(pct, closeTo(50.0, 0.001));
      },
    );

    test('winPct is symmetrical: winPct(cp) + winPct(-cp) equals 100%', () {
      const centipawns = [50, 100, 250, 500, 1000];
      for (final cp in centipawns) {
        final pos = MoveClassifier.winPct(cp);
        final neg = MoveClassifier.winPct(-cp);
        expect(pos + neg, closeTo(100.0, 0.001));
      }
    });

    test('winLoss calculation: monotonic and non-negative', () {
      expect(MoveClassifier.winLoss(100, 100), equals(0.0));
      // Making a move that improved or equaled position gives 0 loss
      expect(MoveClassifier.winLoss(0, 100), equals(0.0));
      // Blunder loses win percentage
      final loss = MoveClassifier.winLoss(200, -200);
      expect(loss, greaterThan(30.0));
    });

    test('Move classification thresholds (§3.9)', () {
      // Best moves (engine top or loss < 2)
      expect(
        MoveClassifier.classify(5.0, isEngineTop: true),
        equals(MoveClassification.best),
      );
      expect(
        MoveClassifier.classify(1.5, isEngineTop: false),
        equals(MoveClassification.best),
      );

      // Good moves (loss < 10)
      expect(
        MoveClassifier.classify(5.0, isEngineTop: false),
        equals(MoveClassification.good),
      );
      expect(
        MoveClassifier.classify(9.9, isEngineTop: false),
        equals(MoveClassification.good),
      );

      // Inaccuracies (loss < 20)
      expect(
        MoveClassifier.classify(10.1, isEngineTop: false),
        equals(MoveClassification.inaccuracy),
      );
      expect(
        MoveClassifier.classify(19.9, isEngineTop: false),
        equals(MoveClassification.inaccuracy),
      );

      // Mistakes (loss < 30)
      expect(
        MoveClassifier.classify(20.1, isEngineTop: false),
        equals(MoveClassification.mistake),
      );
      expect(
        MoveClassifier.classify(29.9, isEngineTop: false),
        equals(MoveClassification.mistake),
      );

      // Blunders (loss >= 30)
      expect(
        MoveClassifier.classify(30.0, isEngineTop: false),
        equals(MoveClassification.blunder),
      );
      expect(
        MoveClassifier.classify(50.0, isEngineTop: false),
        equals(MoveClassification.blunder),
      );
    });

    test('moveAccuracy calculation is clamped between 0 and 100', () {
      final perfect = MoveClassifier.moveAccuracy(0.0);
      expect(perfect, closeTo(100.0, 0.5));

      final hugeLoss = MoveClassifier.moveAccuracy(150.0);
      expect(hugeLoss, equals(0.0));

      final moderate = MoveClassifier.moveAccuracy(15.0);
      expect(moderate, greaterThan(40.0));
      expect(moderate, lessThan(60.0));
    });

    test('Mate to centipawns conversion', () {
      expect(MoveClassifier.mateToCentipawns(1), equals(9999));
      expect(MoveClassifier.mateToCentipawns(3), equals(9997));
      expect(MoveClassifier.mateToCentipawns(-1), equals(-9999));
      expect(MoveClassifier.mateToCentipawns(-5), equals(-9995));
      expect(MoveClassifier.mateToCentipawns(0), equals(0));
    });

    test('Average accuracy calculation', () {
      expect(MoveClassifier.averageAccuracy([]), equals(100.0));
      expect(
        MoveClassifier.averageAccuracy([100.0, 80.0, 60.0]),
        closeTo(80.0, 0.001),
      );
    });
  });
}
