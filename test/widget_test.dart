import 'package:flutter_test/flutter_test.dart';
import 'package:flame/game.dart';
import 'package:side_run/game.dart'; // adjust to your actual path

void main() {
  testWidgets('SideScrollerGame loads and responds to taps', (WidgetTester tester) async {
    // 1. Create the game instance with a character asset
    final game = SideScrollerGame(characterAsset: 'person001.png');
    
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
    expect(player.characterAsset, equals('person001.png'));
    
    // 6. Start the game first (simulate first tap to start)
    await tester.tap(find.byType(GameWidget));
    await tester.pump();
    expect(game.started, isTrue);
    
    // 7. Simulate a tap to jump
    await tester.tap(find.byType(GameWidget));
    await tester.pump();
    
    // The player's velocity should now be upward
    expect(player.velocity.y, lessThan(0));
    expect(player.jumpsLeft, equals(1)); // Should have 1 jump left after first jump
    
    // 8. Advance game by small amount
    game.update(0.1);
    
    // Gravity should have reduced upward velocity
    expect(player.velocity.y, greaterThan(-400));
    
    // 9. Simulate multiple frames to let the player fall
    for (int i = 0; i < 60; i++) {
      game.update(1 / 60); // 1 frame at 60 FPS
    }
    
    // Player should have fallen somewhat
    expect(player.position.y, greaterThan(250)); // Should be lower than starting position
    
    // 10. Test double jump
    player.jumpsLeft = 2; // Reset jumps
    await tester.tap(find.byType(GameWidget));
    await tester.pump();
    expect(player.jumpsLeft, equals(1));
    
    await tester.tap(find.byType(GameWidget));
    await tester.pump();
    expect(player.jumpsLeft, equals(0));
    
    // Third tap should not allow another jump
    final velocityBeforeThirdTap = player.velocity.y;
    await tester.tap(find.byType(GameWidget));
    await tester.pump();
    expect(player.jumpsLeft, equals(0));
    
    // 11. Test platform collision
    expect(game.platforms.length, greaterThan(0));
    
    // 12. Test aura spawning
    game.auraSpawnTimer = game.auraSpawnInterval; // Force aura spawn
    game.update(0.1);
    expect(game.auras.length, greaterThan(0));
    
    // 13. Test speed multiplier increases over time
    final initialSpeed = game.speedMultiplier;
    for (int i = 0; i < 100; i++) {
      game.update(1 / 60);
    }
    expect(game.speedMultiplier, greaterThan(initialSpeed));
  });

  testWidgets('SideScrollerGame handles game over', (WidgetTester tester) async {
    final game = SideScrollerGame(characterAsset: 'person001.png');
    
    await tester.pumpWidget(GameWidget(game: game));
    
    await tester.runAsync(() async {
      await game.onLoad();
    });
    await tester.pump();
    
    // Start the game
    await tester.tap(find.byType(GameWidget));
    await tester.pump();
    
    // Force player to fall off screen
    game.player.position.y = game.size.y + 100;
    game.update(0.1);
    
    expect(game.gameOver, isTrue);
  });

  testWidgets('SideScrollerGame resets correctly', (WidgetTester tester) async {
    final game = SideScrollerGame(characterAsset: 'person002.png');
    
    await tester.pumpWidget(GameWidget(game: game));
    
    await tester.runAsync(() async {
      await game.onLoad();
    });
    await tester.pump();
    
    // Start the game
    await tester.tap(find.byType(GameWidget));
    await tester.pump();
    
    // Collect some auras
    game.auraCount = 5;
    
    // Trigger game over
    game.player.position.y = game.size.y + 100;
    game.update(0.1);
    expect(game.gameOver, isTrue);
    
    // Restart by tapping
    await tester.tap(find.byType(GameWidget));
    await tester.pump();
    
    // Game should be reset
    expect(game.gameOver, isFalse);
    expect(game.started, isFalse);
    expect(game.auraCount, equals(0));
    expect(game.speedMultiplier, equals(1.0));
  });
}