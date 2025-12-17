import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:flame_audio/flame_audio.dart';
import 'youcantcopymygame.dart'; // Ensure this points to your SideScrollerGame file
import 'package:google_mobile_ads/google_mobile_ads.dart'; // ads
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await dotenv.load(fileName: ".env");
    // Don't await AdMob init to prevent black screen if it hangs
    MobileAds.instance.initialize();

    // Preload tap sound (non-blocking)
    FlameAudio.audioCache.load('tap.wav').catchError((e) => debugPrint('Audio load failed: $e'));
    
    runApp(const GameWrapper());
  } catch (e, stack) {
    debugPrint('Initialization failed: $e\n$stack');
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text('Initialization Failed:\n$e', textAlign: TextAlign.center),
        ),
      ),
    ));
  }
}

class GameWrapper extends StatefulWidget {
  const GameWrapper({super.key});

  @override
  State<GameWrapper> createState() => _GameWrapperState();
}

class _GameWrapperState extends State<GameWrapper> {
  @override
  Widget build(BuildContext context) {
    return GameWidget(game: SideScrollerGame());
  }
}
