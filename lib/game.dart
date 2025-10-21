import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/material.dart';

class SideScrollerGame extends FlameGame with TapDetector {
  late Player player;
  final Random random = Random();

  double platformSpeed = 200;
  double speedMultiplier = 1.0;
  bool started = false;
  bool gameOver = false;

  List<Platform> platforms = [];
  List<Aura> auras = [];
  int auraCount = 0;

  final double minY = 200;
  final double maxY = 400;
  final double platformWidth = 120;
  final double platformHeight = 20;

  // Reduced gaps to double spawn density
  final double gapMin = 25;
  final double gapMax = 75;

  double auraSpawnTimer = 0.0;
  final double auraSpawnInterval = 1.5;

  late ParallaxLayer backLayer;
  late ParallaxLayer buildingsLayer;
  late ParallaxLayer frontLayer;

  VoidCallback? onGameOver;

  final String characterAsset;

  SideScrollerGame({required this.characterAsset}) {
    player = Player(position: Vector2.zero(), characterAsset: characterAsset);
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();

    await FlameAudio.audioCache.loadAll([
      'tap.wav',
      'jump.wav',
      'gg.mp3',
      'soundtrack.mp3',
      'aura.mp3',
    ]);

    FlameAudio.bgm.initialize();

    final back = await loadSprite('skyline/back.png');
    final buildings = await loadSprite('skyline/buildings.png');
    final front = await loadSprite('skyline/front.png');

    backLayer = ParallaxLayer(sprite: back, speedMultiplier: 0.2);
    buildingsLayer = ParallaxLayer(sprite: buildings, speedMultiplier: 0.5);
    frontLayer = ParallaxLayer(sprite: front, speedMultiplier: 0.8);

    add(backLayer);
    add(buildingsLayer);
    add(frontLayer);

    _resetGame();
  }

  void _resetGame() {
    for (var p in platforms) {
      remove(p);
    }
    for (var a in auras) {
      remove(a);
    }
    if (player.isMounted) remove(player);

    platforms.clear();
    auras.clear();
    auraCount = 0;
    speedMultiplier = 1.0;
    started = false;
    gameOver = false;

    final startPlatform = Platform(position: Vector2(50, 300), size: Vector2(200, platformHeight));
    add(startPlatform);
    platforms.add(startPlatform);

    player = Player(
      position: Vector2(startPlatform.position.x + 50, startPlatform.position.y - 50),
      characterAsset: characterAsset,
    );
    add(player);

    double currentX = startPlatform.position.x + startPlatform.size.x;
    while (currentX < size.x * 2) { // double horizontal width
      final y = minY + random.nextDouble() * (2 * (maxY - minY)); // double vertical range
      final overlap = platformWidth * 0.5;
      final p = Platform(
        position: Vector2(currentX - overlap, y),
        size: Vector2(platformWidth, platformHeight),
      );
      add(p);
      platforms.add(p);

      // Update currentX with smaller gap to double spawn density
      currentX = p.position.x + p.size.x + gapMin + random.nextDouble() * (gapMax - gapMin);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (!started || gameOver) return;

    speedMultiplier += dt * 0.01;

    backLayer.updatePosition(platformSpeed * dt * speedMultiplier);
    buildingsLayer.updatePosition(platformSpeed * dt * speedMultiplier);
    frontLayer.updatePosition(platformSpeed * dt * speedMultiplier);

    for (var p in platforms) {
      p.position.x -= platformSpeed * dt * speedMultiplier;
    }

    platforms.removeWhere((p) {
      if (p.position.x + p.size.x < 0) {
        remove(p);
        return true;
      }
      return false;
    });

    if (platforms.isNotEmpty) {
      double lastX = platforms.last.position.x + platforms.last.size.x;
      while (lastX < size.x * 2) { // double horizontal width
        final y = minY + random.nextDouble() * (2 * (maxY - minY)); // double vertical range
        final overlap = platformWidth * 0.5;
        final p = Platform(
          position: Vector2(lastX + gapMin + random.nextDouble() * (gapMax - gapMin) - overlap, y),
          size: Vector2(platformWidth, platformHeight),
        );
        add(p);
        platforms.add(p);
        lastX = p.position.x + p.size.x;
      }
    }

    auraSpawnTimer += dt;
    if (auraSpawnTimer >= auraSpawnInterval) {
      auraSpawnTimer = 0;
      final x = size.x + 20;
      final y = 50 + random.nextDouble() * (size.y - 100);
      final aura = Aura(position: Vector2(x, y));
      add(aura);
      auras.add(aura);
    }

    for (var aura in auras) {
      aura.position.x -= platformSpeed * dt * speedMultiplier;
    }

    auras.removeWhere((a) {
      if (a.position.x + a.size.x < 0) {
        remove(a);
        return true;
      }
      return false;
    });

    bool onPlatform = false;
    final playerNext = player.toRect().translate(0, player.velocity.y * dt);
    for (var p in platforms) {
      final platRect = p.toRect();
      final overlapWidth = (playerNext.right).clamp(platRect.left, platRect.right) -
          (playerNext.left).clamp(platRect.left, platRect.right);
      if (playerNext.bottom <= platRect.top &&
          playerNext.bottom + player.velocity.y * dt >= platRect.top &&
          overlapWidth >= player.size.x * 0.5) {
        player.position.y = platRect.top - player.size.y;
        player.velocity.y = 0;
        player.jumpsLeft = 2;
        onPlatform = true;
        break;
      }
    }

    if (!onPlatform) player.velocity.y += 800 * dt;
    player.position += player.velocity * dt;

    List<Aura> collected = [];
    for (var aura in auras) {
      if (player.toRect().overlaps(aura.toRect())) {
        auraCount++;
        FlameAudio.play('aura.mp3', volume: 0.8);
        collected.add(aura);
        remove(aura);
      }
    }
    collected.forEach(auras.remove);

    if (!onPlatform && player.position.y > size.y && !gameOver) {
      gameOver = true;
      FlameAudio.play('gg.mp3', volume: 0.5);
      onGameOver?.call();
    }
  }

  String _getAuraRank(int count) {
    if (count >= 100) return 'RIZZ MASTER';
    if (count >= 75) return 'Fanum Tax Collector';
    if (count >= 50) return 'Ohio Gyatt Goblin';
    if (count >= 35) return 'W Rizzler';
    if (count >= 20) return 'Skibidi gamer';
    if (count >= 10) return 'Mid Sigma';
    if (count >= 3) return 'The Huzzless';
    return 'Chat, check this Negative Aura';
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    if (!started) {
      canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), Paint()..color = Colors.black.withOpacity(0.7));
      _drawText(canvas, 'Tap to Start', 40);
    } else if (gameOver) {
      canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), Paint()..color = Colors.black.withOpacity(0.7));
      _drawText(canvas, 'You Crashed Out', 30, color: Colors.green);
      _drawText(canvas, '\n\n\nAura Farmed: $auraCount', 30, color: Colors.green);
      _drawText(canvas, '\n\n\n\n${_getAuraRank(auraCount)}', 45, color: Colors.orange);
      _drawText(canvas, '\n\n\n\n\n\n\n\n\n\nTap to Restart', 30, color: Colors.green);
    } else {
      _drawText(canvas, 'Aura: $auraCount', 20, center: false, offset: const Offset(10, 10));
    }
  }

  void _drawText(Canvas canvas, String text, double fontSize,
      {Color color = Colors.white, Offset? offset, bool center = true}) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: fontSize, fontWeight: FontWeight.bold),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.x);

    final position = center
        ? Offset(size.x / 2 - tp.width / 2, size.y / 2 - tp.height / 2)
        : (offset ?? const Offset(0, 0));

    tp.paint(canvas, position);
  }

  @override
  void onTap() {
    if (!started) {
      started = true;
      overlays.remove('GameOver');
      FlameAudio.bgm.stop();
      FlameAudio.bgm.play('soundtrack.mp3', volume: 0.9);
      return;
    }

    if (gameOver) {
      _resetGame();
      return;
    }

    if (player.jumpsLeft > 0) {
      player.velocity.y = -400;
      player.jumpsLeft -= 1;
      FlameAudio.play('jump.wav', volume: 0.5);
    }
  }
}

class Player extends PositionComponent {
  Vector2 velocity = Vector2.zero();
  int jumpsLeft = 2;
  late Sprite sprite;
  final String? characterAsset;

  Player({required Vector2 position, this.characterAsset})
      : super(position: position, size: Vector2(35, 50), anchor: Anchor.topLeft);

  @override
  Future<void> onLoad() async {
    super.onLoad();
    sprite = await Sprite.load(characterAsset ?? 'assets/images/person001.png');
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    sprite.render(canvas, size: size);
  }
}

class Platform extends PositionComponent {
  late Sprite tile;

  Platform({required Vector2 position, required Vector2 size})
      : super(position: position, size: size, anchor: Anchor.topLeft);

  @override
  Future<void> onLoad() async {
    super.onLoad();
    tile = await Sprite.load('platform/pc.png');
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    tile.render(canvas, size: size);
  }
}

class Aura extends PositionComponent {
  Aura({required Vector2 position}) : super(position: position, size: Vector2(20, 20), anchor: Anchor.topLeft);

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), size.x / 2, Paint()..color = Colors.green);
  }
}

class ParallaxLayer extends Component with HasGameRef<FlameGame> {
  final Sprite sprite;
  final double speedMultiplier;
  double offsetX = 0;
  late Vector2 sizeOnScreen;

  ParallaxLayer({required this.sprite, required this.speedMultiplier});

  @override
  Future<void> onLoad() async {
    super.onLoad();
    double scale = gameRef.size.y / sprite.srcSize.y;
    sizeOnScreen = Vector2(sprite.srcSize.x * scale, gameRef.size.y);
  }

  void updatePosition(double deltaX) {
    offsetX -= deltaX * speedMultiplier;
    if (offsetX <= -sizeOnScreen.x) offsetX += sizeOnScreen.x;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    for (int i = -1; i <= 1; i++) {
      sprite.render(canvas, position: Vector2(offsetX + i * sizeOnScreen.x, 0), size: sizeOnScreen);
    }
  }
}
