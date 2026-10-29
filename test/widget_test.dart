import 'package:flutter_test/flutter_test.dart';
import 'package:chess_app/core/strings.dart';
import 'package:chess_app/main.dart';
import 'package:chess_app/widgets/board_view.dart';

void main() {
  testWidgets('ChessApp smoke test - board and UI renders', (
    WidgetTester tester,
  ) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ChessApp());

    // Verify app title or top bar is displayed
    expect(find.text(AppStrings.humanVsHuman), findsOneWidget);

    // Verify initial turn indicator
    expect(find.text(AppStrings.whiteTurn), findsOneWidget);

    // Verify BoardView is present
    expect(find.byType(BoardView), findsOneWidget);

    // Verify action buttons
    expect(find.text(AppStrings.undo), findsOneWidget);
    expect(find.text(AppStrings.resign), findsOneWidget);
  });
}
