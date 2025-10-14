import 'package:flutter_test/flutter_test.dart';
import 'package:flame/game.dart';
import 'package:side_run/game.dart'; // adjust to your actual path

void main() {
  testWidgets('SideScrollerGame loads and responds to taps', (WidgetTester tester) async {
    // 1. Create the game instance (no sprite needed)
    final game = SideScrollerGame();

    // 2. Wrap the game in a GameWidget
    await tester.pumpWidget(GameWidget(game: game));

    // 3. Let the game finish loading
    await tester.runAsync(() async {
      await game.onLoad();
    });
    await tester.pump();

    // 4. Verify the GameWidget exists
    expect(find.byType(GameWidget), findsOneWidget);

    // 5. Verify the player exists
    final player = game.player;
    expect(player, isNotNull);

    // 6. Simulate a tap (jump)
    await tester.tap(find.byType(GameWidget));
    await tester.pump();

    // The player's velocity should now be upward
    expect(player.velocity.y, lessThan(0));

    // 7. Advance game by 1 second
    game.update(1.0);

    // Gravity should have reduced upward velocity
    expect(player.velocity.y, greaterThan(-400));

    // 8. Simulate multiple frames to let the player fall
    for (int i = 0; i < 60; i++) {
      game.update(1 / 60); // 1 frame at 60 FPS
    }

    // Player should still be above the bottom of the screen
    expect(player.position.y, lessThan(game.size.y + 100));
  });
}
