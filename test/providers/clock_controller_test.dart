import 'package:flutter_test/flutter_test.dart';
import 'package:chess_app/domain/game_logic.dart';
import 'package:chess_app/providers/clock_controller.dart';

void main() {
  group(
    'ClockController - FR3 Chess Clock with Increment and Flag Detection',
    () {
      late FakeClockTicker fakeTicker;

      setUp(() {
        fakeTicker = FakeClockTicker();
      });

      test('Initializes with chosen TimeControl and initial duration', () {
        final clock = ClockController(
          timeControl: TimeControl.blitz3p2,
          ticker: fakeTicker,
        );

        expect(clock.whiteTime, equals(const Duration(minutes: 3)));
        expect(clock.blackTime, equals(const Duration(minutes: 3)));
        expect(clock.timeControl.incrementSeconds, equals(2));
        expect(clock.isRunning, isFalse);
        expect(clock.isFlagged, isFalse);
        expect(clock.flaggedSide, isNull);
      });

      test('Clock ticks down for active side when started', () {
        final clock = ClockController(
          timeControl: TimeControl.blitz5p0,
          ticker: fakeTicker,
        );

        clock.start(PlayerColor.white);
        expect(clock.isRunning, isTrue);
        expect(clock.activeSide, equals(PlayerColor.white));

        // Advance 10 seconds
        fakeTicker.advance(const Duration(seconds: 10));

        expect(
          clock.whiteTime,
          equals(const Duration(minutes: 4, seconds: 50)),
        );
        expect(
          clock.blackTime,
          equals(const Duration(minutes: 5)),
        ); // Black unchanged
      });

      test('FR3: Increment is added after move and active side switches', () {
        final clock = ClockController(
          timeControl: TimeControl.blitz3p2, // 3 min + 2s increment
          ticker: fakeTicker,
        );

        clock.start(PlayerColor.white);

        // White thinks for 5 seconds
        fakeTicker.advance(const Duration(seconds: 5));
        expect(
          clock.whiteTime,
          equals(const Duration(minutes: 2, seconds: 55)),
        );

        // White completes move -> switch to Black: White gets +2s increment
        clock.switchTurn(PlayerColor.black);

        expect(
          clock.whiteTime,
          equals(const Duration(minutes: 2, seconds: 57)),
        ); // 2:55 + 2s
        expect(clock.activeSide, equals(PlayerColor.black));

        // Black thinks for 3 seconds
        fakeTicker.advance(const Duration(seconds: 3));
        expect(
          clock.blackTime,
          equals(const Duration(minutes: 2, seconds: 57)),
        );

        // Black completes move -> switch to White: Black gets +2s increment
        clock.switchTurn(PlayerColor.white);

        expect(
          clock.blackTime,
          equals(const Duration(minutes: 2, seconds: 59)),
        ); // 2:57 + 2s
        expect(clock.activeSide, equals(PlayerColor.white));
      });

      test('FR3: Flag detection when time expires triggers onTimeout', () {
        PlayerColor? timedOut;
        final clock = ClockController(
          timeControl: const TimeControl(
            label: 'Test',
            initialMinutes: 1,
            incrementSeconds: 0,
          ),
          ticker: fakeTicker,
          onTimeout: (color) => timedOut = color,
        );

        clock.start(PlayerColor.white);

        // Advance 59 seconds (1 second remaining)
        fakeTicker.advance(const Duration(seconds: 59));
        expect(clock.whiteTime, equals(const Duration(seconds: 1)));
        expect(clock.isFlagged, isFalse);
        expect(timedOut, isNull);

        // Advance another 2 seconds -> triggers flag
        fakeTicker.advance(const Duration(seconds: 2));

        expect(clock.whiteTime, equals(Duration.zero));
        expect(clock.isFlagged, isTrue);
        expect(clock.flaggedSide, equals(PlayerColor.white));
        expect(clock.isRunning, isFalse);
        expect(timedOut, equals(PlayerColor.white));
      });

      test('FR3: Clock pauses and stops ticking when paused', () {
        final clock = ClockController(
          timeControl: TimeControl.blitz5p0,
          ticker: fakeTicker,
        );

        clock.start(PlayerColor.white);
        fakeTicker.advance(const Duration(seconds: 10));
        expect(
          clock.whiteTime,
          equals(const Duration(minutes: 4, seconds: 50)),
        );

        clock.pause();
        expect(clock.isRunning, isFalse);

        // Advance while paused
        fakeTicker.advance(const Duration(seconds: 10));
        // Time should not change while paused
        expect(
          clock.whiteTime,
          equals(const Duration(minutes: 4, seconds: 50)),
        );

        // Resume
        clock.resume();
        expect(clock.isRunning, isTrue);
        fakeTicker.advance(const Duration(seconds: 5));
        expect(
          clock.whiteTime,
          equals(const Duration(minutes: 4, seconds: 45)),
        );
      });

      test('Unlimited mode does not tick or flag', () {
        final clock = ClockController(
          timeControl: TimeControl.unlimited,
          ticker: fakeTicker,
        );

        clock.start(PlayerColor.white);
        expect(clock.isRunning, isFalse);
        expect(clock.isUnlimited, isTrue);

        fakeTicker.advance(const Duration(minutes: 30));
        expect(clock.isFlagged, isFalse);
        expect(clock.formatTime(PlayerColor.white), equals('∞'));
      });

      test('formatTime displays mm:ss or tenths under 10 seconds', () {
        final clock = ClockController(
          timeControl: const TimeControl(
            label: 'Test',
            initialMinutes: 1,
            incrementSeconds: 0,
          ),
          ticker: fakeTicker,
        );

        clock.start(PlayerColor.white);
        expect(clock.formatTime(PlayerColor.white), equals('01:00'));

        // Advance to 8.5 seconds remaining
        fakeTicker.advance(const Duration(milliseconds: 51500));
        expect(clock.formatTime(PlayerColor.white), equals('0:08.5'));
      });
    },
  );
}
