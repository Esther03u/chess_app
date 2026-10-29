import 'package:chess_app/core/strings.dart';
import 'package:chess_app/main.dart';
import 'package:chess_app/widgets/board_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ChessApp smoke test - MainHub and GameScreen navigation', (
    WidgetTester tester,
  ) async {
    // Set a phone-like viewport size
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    // Build app
    await tester.pumpWidget(const ChessApp());
    await tester.pumpAndSettle();

    // Verify Main Hub renders brand header and modes
    expect(find.text(AppStrings.appTitle), findsOneWidget);
    expect(find.text(AppStrings.quickVsBot), findsOneWidget);
    expect(find.text(AppStrings.humanVsHuman), findsOneWidget);
    expect(find.text(AppStrings.quickDailyPuzzle), findsOneWidget);

    // Switch to Game tab via BottomNavigationBar
    await tester.tap(find.byIcon(Icons.grid_4x4_outlined));
    await tester.pumpAndSettle();

    // Verify BoardView is present in Game tab
    expect(find.byType(BoardView), findsOneWidget);
    expect(find.text(AppStrings.whiteTurn), findsOneWidget);
    expect(find.text(AppStrings.undo), findsOneWidget);
    expect(find.text(AppStrings.resign), findsOneWidget);
  });
}
