import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:flame_audio/flame_audio.dart';
import 'game.dart'; // Ensure this points to your SideScrollerGame file
import 'package:google_mobile_ads/google_mobile_ads.dart'; // ads

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MobileAds.instance.initialize();

  // Preload tap sound so it plays instantly
  await FlameAudio.audioCache.load('tap.wav');

  runApp(const GameWrapper());
}

class GameWrapper extends StatefulWidget {
  const GameWrapper({super.key});

  @override
  State<GameWrapper> createState() => _GameWrapperState();
}

class _GameWrapperState extends State<GameWrapper> {
  
  // Can't just post all my secrets on main (:
}
