import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flame/events.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

enum ReviveState { none, waitingForAdTap, tapToContinue }

class SideScrollerGame extends FlameGame with TapDetector {
  
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    // Add a parallax background
    add(await ParallaxComponent.load(
      [
        ParallaxImageData('skyline/back.png'),
        ParallaxImageData('skyline/buildings.png'),
        ParallaxImageData('skyline/front.png'),
      ],
      baseVelocity: Vector2(20, 0),
      velocityMultiplierDelta: Vector2(1.8, 1.0),
    ));

    add(TextComponent(
      text: 'Game Loaded!', 
      position: Vector2(100, 100),
      textRenderer: TextPaint(style: const TextStyle(color: Colors.white, fontSize: 24)),
    ));
  }
}
