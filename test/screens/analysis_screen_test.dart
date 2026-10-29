import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chess_app/core/strings.dart';
import 'package:chess_app/domain/classification.dart';
import 'package:chess_app/models/analysis_result.dart';
import 'package:chess_app/models/game_record.dart';
import 'package:chess_app/screens/analysis_screen.dart';
import 'package:chess_app/widgets/eval_graph.dart';

void main() {
  group('AnalysisScreen - FR6 Widget & User Experience', () {
    late GameRecord sampleRecordWithCachedAnalysis;

    setUp(() {
      const move1 = AnalyzedMove(
        ply: 0,
        moveNumber: 1,
        isWhite: true,
        san: 'e4',
        uci: 'e2e4',
        fen: 'rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1',
        evalWhiteCp: 35,
        evalBefore: 30,
        evalAfter: 35,
        winLoss: 0.0,
        accuracy: 98.5,
        classification: MoveClassification.best,
        bestMove: 'e2e4',
      );

      const move2 = AnalyzedMove(
        ply: 1,
        moveNumber: 1,
        isWhite: false,
        san: 'e5',
        uci: 'e7e5',
        fen: 'rnbqkbnr/pppp1ppp/8/4p3/4P3/8/PPPP1PPP/RNBQKBNR w KQkq e6 0 2',
        evalWhiteCp: 30,
        evalBefore: -35,
        evalAfter: -30,
        winLoss: 0.0,
        accuracy: 97.2,
        classification: MoveClassification.best,
        bestMove: 'e7e5',
      );

      const move3 = AnalyzedMove(
        ply: 2,
        moveNumber: 2,
        isWhite: true,
        san: 'Qh5',
        uci: 'd1h5',
        fen: 'rnbqkbnr/pppp1ppp/8/4p2Q/4P3/8/PPPP1PPP/RNB1KBNR b KQkq - 1 2',
        evalWhiteCp: 10,
        evalBefore: 30,
        evalAfter: 10,
        winLoss: 2.5,
        accuracy: 88.0,
        classification: MoveClassification.good,
        bestMove: 'g1f3',
      );

      final analysis = GameAnalysis(
        moves: [move1, move2, move3],
        whiteAccuracy: 93.3,
        blackAccuracy: 97.2,
        whiteSummary: {
          MoveClassification.best: 1,
          MoveClassification.good: 1,
          MoveClassification.inaccuracy: 0,
          MoveClassification.mistake: 0,
          MoveClassification.blunder: 0,
        },
        blackSummary: {
          MoveClassification.best: 1,
          MoveClassification.good: 0,
          MoveClassification.inaccuracy: 0,
          MoveClassification.mistake: 0,
          MoveClassification.blunder: 0,
        },
      );

      sampleRecordWithCachedAnalysis = GameRecord(
        id: 1,
        pgn: '1. e4 e5 2. Qh5 *',
        white: 'Grandmaster White',
        black: 'Grandmaster Black',
        result: '*',
        timeControl: '10 + 0',
        playedAt: 1730200000000,
        analysisJson: jsonEncode(analysis.toJson()),
      );
    });

    testWidgets(
      '1. Loads cached analysis immediately and displays accuracy scores',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: AnalysisScreen(record: sampleRecordWithCachedAnalysis),
          ),
        );
        await tester.pump();

        // Verify Screen title
        expect(find.text(AppStrings.gameAnalysis), findsOneWidget);

        // Verify Player names & Accuracies
        expect(find.text('Grandmaster White'), findsOneWidget);
        expect(find.text('93.3%'), findsOneWidget);

        expect(find.text('Grandmaster Black'), findsOneWidget);
        expect(find.text('97.2%'), findsOneWidget);

        // Verify EvalGraph is rendered
        expect(find.byType(EvalGraph), findsOneWidget);

        // Verify current move banner (defaults to last move: 2. Qh5)
        expect(find.text('2. Qh5'), findsOneWidget);
        expect(find.text('Eval: +0.10'), findsOneWidget);
      },
    );

    testWidgets('2. Navigates between moves using chevron buttons', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: AnalysisScreen(record: sampleRecordWithCachedAnalysis),
        ),
      );
      await tester.pump();

      // Current move is 3 / 3
      expect(find.text('3 / 3'), findsOneWidget);

      // Tap previous move chevron
      await tester.tap(find.byIcon(Icons.chevron_left));
      await tester.pump();

      // Should now be at move 2 / 3 (1... e5)
      expect(find.text('2 / 3'), findsOneWidget);
      expect(find.text('1... e5'), findsOneWidget);

      // Tap first page button
      await tester.tap(find.byIcon(Icons.first_page));
      await tester.pump();

      // Should now be at move 1 / 3 (1. e4)
      expect(find.text('1 / 3'), findsOneWidget);
      expect(find.text('1. e4'), findsOneWidget);
    });
  });
}
