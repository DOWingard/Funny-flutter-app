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
  final double gapMin = 50;
  final double gapMax = 150;

  double auraSpawnTimer = 0.0;
  final double auraSpawnInterval = 1.5;

  // --- Parallax layers ---
  late ParallaxLayer backLayer;
  late ParallaxLayer buildingsLayer;
  late ParallaxLayer frontLayer;

  // --- Callback for game over ---
  VoidCallback? onGameOver;

  @override
  Future<void> onLoad() async {
    super.onLoad();

    // --- Preload all sounds ---
    await FlameAudio.audioCache.loadAll([
      'tap.wav',
      'jump.wav',
      'gg.mp3',
      'soundtrack.mp3',
      'aura.mp3',
    ]);

    // --- Initialize BGM ---
    FlameAudio.bgm.initialize();

    // --- Load parallax layers ---
    final back = await loadSprite('skyline/back.png');
    final buildings = await loadSprite('skyline/buildings.png');
    final front = await loadSprite('skyline/front.png');

    backLayer = ParallaxLayer(sprite: back, speedMultiplier: 0.2);
    buildingsLayer = ParallaxLayer(sprite: buildings, speedMultiplier: 0.5);
    frontLayer = ParallaxLayer(sprite: front, speedMultiplier: 0.8);

    add(backLayer);
    add(buildingsLayer);
    add(frontLayer);

    // --- First platform ---
    Platform startPlatform = Platform(
      position: Vector2(50, 300),
      size: Vector2(200, platformHeight),
    );
    add(startPlatform);
    platforms.add(startPlatform);

    // --- Player ---
    player = Player(
      position: Vector2(startPlatform.position.x + 50, startPlatform.position.y - 50),
      size: Vector2(35, 50),
    );
    add(player);

    // --- Preload additional platforms ---
    double currentX = startPlatform.position.x + startPlatform.size.x;
    while (currentX < size.x * 2) {
      double y = minY + random.nextDouble() * (maxY - minY);
      Platform p = Platform(
        position: Vector2(currentX, y),
        size: Vector2(platformWidth, platformHeight),
      );
      add(p);
      platforms.add(p);
      currentX = p.position.x + p.size.x + gapMin + random.nextDouble() * (gapMax - gapMin);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    // --- Handle BGM based on game state ---
    if (started && !gameOver) {
      if (!FlameAudio.bgm.isPlaying) {
        FlameAudio.bgm.play('soundtrack.mp3', volume: 0.5);
      }
    } else {
      if (FlameAudio.bgm.isPlaying) {
        FlameAudio.bgm.pause();
      }
    }

    if (!started || gameOver) return;

    speedMultiplier += dt * 0.01;

    // --- Update parallax layers ---
    backLayer.updatePosition(platformSpeed * speedMultiplier * dt);
    buildingsLayer.updatePosition(platformSpeed * speedMultiplier * dt);
    frontLayer.updatePosition(platformSpeed * speedMultiplier * dt);

    // --- Move platforms ---
    for (var p in platforms) {
      p.position.x -= platformSpeed * speedMultiplier * dt;
    }

    // --- Remove offscreen platforms ---
    platforms.removeWhere((p) {
      if (p.position.x + p.size.x < 0) {
        remove(p);
        return true;
      }
      return false;
    });

    // --- Generate new platforms ---
    if (platforms.isNotEmpty) {
      double lastX = platforms.last.position.x + platforms.last.size.x;
      while (lastX < size.x + 200) {
        double y = minY + random.nextDouble() * (maxY - minY);
        Platform p = Platform(
          position: Vector2(lastX + gapMin + random.nextDouble() * (gapMax - gapMin), y),
          size: Vector2(platformWidth, platformHeight),
        );
        add(p);
        platforms.add(p);
        lastX = p.position.x + p.size.x;
      }
    }

    // --- Spawn auras ---
    auraSpawnTimer += dt;
    if (auraSpawnTimer >= auraSpawnInterval) {
      auraSpawnTimer = 0.0;
      double x = size.x + 20;
      double y = 50 + random.nextDouble() * (size.y - 100);
      Aura aura = Aura(position: Vector2(x, y));
      add(aura);
      auras.add(aura);
    }

    // --- Move auras ---
    for (var aura in auras) {
      aura.position.x -= platformSpeed * speedMultiplier * dt;
    }

    // --- Remove offscreen auras ---
    auras.removeWhere((a) {
      if (a.position.x + a.size.x < 0) {
        remove(a);
        return true;
      }
      return false;
    });

    // --- PLATFORM COLLISION ---
    bool onPlatform = false;
    Rect playerRectNext = player.toRect().translate(0, player.velocity.y * dt);

    for (var p in platforms) {
      Rect platformRect = p.toRect();
      double overlapWidth =
          (playerRectNext.right).clamp(platformRect.left, platformRect.right) -
              (playerRectNext.left).clamp(platformRect.left, platformRect.right);
      bool sufficientOverlap = overlapWidth >= player.size.x * 0.5;

      if (playerRectNext.bottom <= platformRect.top &&
          playerRectNext.bottom + player.velocity.y * dt >= platformRect.top &&
          sufficientOverlap) {
        player.position.y = platformRect.top - player.size.y;
        player.velocity.y = 0;
        player.jumpsLeft = 2;
        onPlatform = true;
        break;
      }
    }

    if (!onPlatform) player.velocity.y += 800 * dt;
    player.position += player.velocity * dt;

    // --- AURA COLLISION & COUNT ---
    List<Aura> collected = [];
    for (var aura in auras) {
      if (player.toRect().overlaps(aura.toRect())) {
        auraCount++;
        FlameAudio.play('aura.mp3', volume: 0.8);
        collected.add(aura);
        remove(aura);
      }
    }
    for (var c in collected) {
      auras.remove(c);
    }

    // --- GAME OVER CHECK ---
    if (!onPlatform && player.position.y > size.y) {
      if (!gameOver) {
        gameOver = true;
        FlameAudio.play('gg.mp3', volume: 0.5);
        onGameOver?.call();
      }
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    if (!started) {
      canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), Paint()..color = Colors.black);
      _drawText(canvas, 'Tap to Start', 40);
    } else if (gameOver) {
      canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), Paint()..color = Colors.black);
      _drawText(canvas, 'Game Over\n\nAura Farmed: $auraCount\n\nTap to Restart', 30, color: Colors.red);
    } else {
      _drawText(canvas, 'Aura: $auraCount', 20, center: false, offset: const Offset(10, 10));
    }
  }

  void _drawText(Canvas canvas, String text, double fontSize,
      {Color color = Colors.white, Offset? offset, bool center = true}) {
    TextPainter tp = TextPainter(
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
      auraCount = 0;
      speedMultiplier = 1.0;
      platforms.forEach(remove);
      platforms.clear();
      auras.forEach(remove);
      auras.clear();
      started = false;
      gameOver = false;
      FlameAudio.bgm.stop();
      onLoad();
      return;
    }

    if (player.jumpsLeft > 0) {
      player.velocity.y = -400;
      player.jumpsLeft -= 1;
      FlameAudio.play('jump.wav', volume: 0.5);
    }
  }
}

// --- Parallax Layer ---
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
    for (int i = -1; i <= 1; i++) {
      sprite.render(
        canvas,
        position: Vector2(offsetX + i * sizeOnScreen.x, 0),
        size: sizeOnScreen,
        overridePaint: Paint(),
      );
    }
  }
}

// --- Player ---
class Player extends PositionComponent {
  Vector2 velocity = Vector2.zero();
  int jumpsLeft = 2;

  Player({required Vector2 position, Vector2? size})
      : super(position: position, size: size ?? Vector2(35, 50), anchor: Anchor.topLeft);

  @override
  void render(Canvas canvas) {
    canvas.drawRect(toRect(), Paint()..color = Colors.blue);
  }
}

// --- Platform using tiles ---
class Platform extends PositionComponent {
  late Sprite leftTile;
  late Sprite centerTile;
  late Sprite rightTile;
  late Sprite middleTile;

  Platform({required Vector2 position, required Vector2 size})
      : super(position: position, size: size);

  @override
  Future<void> onLoad() async {
    super.onLoad();
    leftTile = await Sprite.load('platform/pl.png');
    middleTile = await Sprite.load('platform/pm.png');
    centerTile = await Sprite.load('platform/pc.png');
    rightTile = await Sprite.load('platform/pr.png');
  }

  @override
  void render(Canvas canvas) {
    final tileHeight = size.y;

    // Scale each tile's width according to height
    final scaleLeft = tileHeight / leftTile.srcSize.y;
    final scaleMiddle = tileHeight / middleTile.srcSize.y;
    final scaleCenter = tileHeight / centerTile.srcSize.y;
    final scaleRight = tileHeight / rightTile.srcSize.y;

    final widthLeft = leftTile.srcSize.x * scaleLeft;
    final widthMiddle = middleTile.srcSize.x * scaleMiddle;
    final widthCenter = centerTile.srcSize.x * scaleCenter;
    final widthRight = rightTile.srcSize.x * scaleRight;

    double xPos = position.x;

    // Left tile
    leftTile.render(
      canvas,
      position: Vector2(xPos, position.y),
      size: Vector2(widthLeft, tileHeight),
    );
    xPos += widthLeft;

    // Middle tiles (repeat to fill space between left+right)
    while (xPos + widthCenter + widthRight < position.x + size.x) {
      middleTile.render(
        canvas,
        position: Vector2(xPos, position.y),
        size: Vector2(widthMiddle, tileHeight),
      );
      xPos += widthMiddle;
    }

    // Center tile (optional, can be skipped if not needed)
    centerTile.render(
      canvas,
      position: Vector2(xPos, position.y),
      size: Vector2(widthCenter, tileHeight),
    );
    xPos += widthCenter;

    // Right tile
    rightTile.render(
      canvas,
      position: Vector2(position.x + size.x - widthRight, position.y),
      size: Vector2(widthRight, tileHeight),
    );
  }
}


// --- Aura ---
class Aura extends PositionComponent {
  Aura({required Vector2 position}) : super(position: position, size: Vector2(20, 20));

  @override
  void render(Canvas canvas) {
    canvas.drawCircle(
        Offset(position.x + size.x / 2, position.y + size.y / 2),
        size.x / 2,
        Paint()..color = Colors.purple);
  }
}
