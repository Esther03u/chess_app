import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chess_app/core/strings.dart';
import 'package:chess_app/models/puzzle.dart';
import 'package:chess_app/screens/puzzle_screen.dart';
import 'package:chess_app/services/lichess_api.dart';

class FakeLichessApi implements LichessApi {
  final DailyPuzzle Function() onDailyPuzzle;

  FakeLichessApi(this.onDailyPuzzle);

  @override
  DailyPuzzle? get cachedDailyPuzzle => null;

  @override
  String get endpoint => 'https://fake-lichess.org';

  @override
  Future<DailyPuzzle> dailyPuzzle() async {
    return onDailyPuzzle();
  }
}

void main() {
  group('PuzzleScreen - FR5 Acceptance Tests', () {
    late DailyPuzzle testPuzzle;

    setUpAll(() {
      final file = File('test/fixtures/puzzle_daily.json');
      final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      testPuzzle = DailyPuzzle.fromJson(json);
    });

    testWidgets(
      '1. Loads and displays puzzle rating, tags, and initial board',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(home: PuzzleScreen(initialPuzzle: testPuzzle)),
        );
        await tester.pump();

        // Verify puzzle ID & rating
        expect(find.text('${AppStrings.puzzleRating}: 1763'), findsOneWidget);
        expect(find.text('#Ba42D'), findsOneWidget);

        // Verify prompt
        expect(find.text(AppStrings.yourTurnToMove), findsOneWidget);

        // Verify buttons
        expect(find.text(AppStrings.retryPuzzle), findsOneWidget);
        expect(find.text(AppStrings.showSolution), findsOneWidget);
      },
    );

    testWidgets('2. Executes correct move and auto-plays opponent reply', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: PuzzleScreen(initialPuzzle: testPuzzle)),
      );
      await tester.pump();

      // Tap White knight on c4
      await tester.tap(find.byKey(const Key('square_c4')));
      await tester.pump();

      // Tap destination square a5 (first move in solution is 'c4a5')
      await tester.tap(find.byKey(const Key('square_a5')));
      await tester.pump();

      // Fast forward delay for opponent's reply ('c6b5')
      await tester.pump(const Duration(milliseconds: 500));

      // After opponent move, player's turn resumes
      expect(find.text(AppStrings.yourTurnToMove), findsOneWidget);
    });

    testWidgets('3. Solves entire puzzle to victory', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: PuzzleScreen(initialPuzzle: testPuzzle)),
      );
      await tester.pump();

      // Move 1: c4 -> a5
      await tester.tap(find.byKey(const Key('square_c4')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('square_a5')));
      await tester.pump();
      // Opponent moves c6 -> b5
      await tester.pump(const Duration(milliseconds: 500));

      // Move 2: e6 -> c4
      await tester.tap(find.byKey(const Key('square_e6')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('square_c4')));
      await tester.pump();
      // Opponent moves b5 -> a5
      await tester.pump(const Duration(milliseconds: 500));

      // Move 3: c4 -> a4
      await tester.tap(find.byKey(const Key('square_c4')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('square_a4')));
      await tester.pump();

      // Verify puzzle is solved!
      expect(find.text(AppStrings.puzzleSolved), findsOneWidget);
    });

    testWidgets('4. Detects wrong move and shows error message', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: PuzzleScreen(initialPuzzle: testPuzzle)),
      );
      await tester.pump();

      // Tap pawn on a2
      await tester.tap(find.byKey(const Key('square_a2')));
      await tester.pump();

      // Tap a3 (legal move, but NOT the puzzle solution)
      await tester.tap(find.byKey(const Key('square_a3')));
      await tester.pump();

      // Verify wrong move feedback banner
      expect(find.text(AppStrings.wrongMove), findsOneWidget);
    });

    testWidgets('5. Can reveal solution', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: PuzzleScreen(initialPuzzle: testPuzzle)),
      );
      await tester.pump();

      // Tap show solution button
      await tester.tap(find.text(AppStrings.showSolution));
      await tester.pump();

      // Verify solution moves appear
      expect(find.text(AppStrings.solutionLabel), findsOneWidget);
      expect(find.text('c4a5  c6b5  e6c4  b5a5  c4a4'), findsOneWidget);
    });

    testWidgets('6. Handles API network error gracefully with retry option', (
      tester,
    ) async {
      bool shouldFail = true;
      final api = FakeLichessApi(() {
        if (shouldFail) {
          throw const ApiException(
            'ไม่สามารถเชื่อมต่ออินเทอร์เน็ตได้ กรุณาตรวจสอบการเชื่อมต่อของคุณ',
            isNetworkError: true,
          );
        }
        return testPuzzle;
      });

      await tester.pumpWidget(MaterialApp(home: PuzzleScreen(api: api)));
      // Pump async future completion
      await tester.pump();
      await tester.pump();

      // Verify error message and retry button
      expect(
        find.text(
          'ไม่สามารถเชื่อมต่ออินเทอร์เน็ตได้ กรุณาตรวจสอบการเชื่อมต่อของคุณ',
        ),
        findsOneWidget,
      );
      expect(find.text(AppStrings.retry), findsOneWidget);

      // Now recover network and tap retry
      shouldFail = false;
      await tester.tap(find.text(AppStrings.retry));
      await tester.pump();
      await tester.pump();

      // Verify recovered puzzle
      expect(find.text('${AppStrings.puzzleRating}: 1763'), findsOneWidget);
      expect(find.text(AppStrings.yourTurnToMove), findsOneWidget);
    });
  });
}
