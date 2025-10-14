import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:flame_audio/flame_audio.dart';
import 'game.dart'; // Ensure this points to your SideScrollerGame file

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
  String? selectedCharacter;
  late SideScrollerGame game;

  final List<String> characters = List.generate(
    18,
    (i) => 'assets/images/person${(i + 1).toString().padLeft(3, '0')}.png',
  );

  @override
  void initState() {
    super.initState();
    _initGame();
  }

  void _initGame() {
    game = SideScrollerGame();

    // Remove any lingering GameOver overlay immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      game.overlays.remove('GameOver');
    });

    // Show overlay only on game over
    game.onGameOver = () {
      game.overlays.add('GameOver');
    };
  }

  /// Wrapper to play tap sound and then execute action
  void _playTapAndRun(VoidCallback action) {
    FlameAudio.play('tap.wav'); // Play the tap sound
    action(); // Execute the intended action
  }

  void _startGameWithCharacter(String character) {
    setState(() {
      selectedCharacter = character;
      _initGame();
    });
  }

  void _goToCharacterSelect() {
    setState(() {
      selectedCharacter = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.black,
        body: selectedCharacter == null
            ? Center(
                child: GridView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(20),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1,
                  ),
                  itemCount: characters.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () => _playTapAndRun(
                          () => _startGameWithCharacter(characters[index])),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.grey[900],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Image.asset(
                          characters[index],
                          fit: BoxFit.contain,
                        ),
                      ),
                    );
                  },
                ),
              )
            : GameWidget<SideScrollerGame>(
                game: game,
                overlayBuilderMap: {
                  'GameOver': (context, game) {
                    return Positioned(
                      top: 20,
                      right: 20,
                      child: ElevatedButton(
                        onPressed: () =>
                            _playTapAndRun(_goToCharacterSelect),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[800],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 30, vertical: 20),
                          textStyle: const TextStyle(
                              fontSize: 25, fontWeight: FontWeight.bold),
                        ),
                        child: const Text('Character Select'),
                      ),
                    );
                  },
                },
                // Ensure overlay is empty during gameplay
                initialActiveOverlays: const [],
              ),
      ),
    );
  }
}
