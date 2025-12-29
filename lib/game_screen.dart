import 'package:flutter/material.dart';
import 'snake_game.dart';
import 'game_2048.dart';
import 'dino_game.dart';
import '../main.dart';

class GameMenuScreen extends StatelessWidget {
  final int hastaId;
  const GameMenuScreen({super.key, required this.hastaId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Oyun Alanı"),
        backgroundColor: kPrimaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _btn(
              context,
              "🐍 Snake",
              Colors.green,
                  () => SnakeGame(hastaId: hastaId),
            ),
            _btn(
              context,
              "🔢 2048",
              Colors.orange,
                  () => Game2048(hastaId: hastaId),
            ),
            _btn(
              context,
              "⚫ Dino Jump",
              Colors.blueGrey,
                  () => DinoGame(hastaId: hastaId),
            ),
          ],
        ),
      ),
    );
  }

  /// ⬇⬇⬇
  /// نکته‌ی مهم: اینجا Widget نمی‌گیریم
  /// Widget Function() می‌گیریم
  Widget _btn(
      BuildContext ctx,
      String text,
      Color color,
      Widget Function() pageBuilder,
      ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          minimumSize: const Size(double.infinity, 55),
          textStyle: const TextStyle(fontSize: 18),
        ),
        onPressed: () {
          Navigator.push(
            ctx,
            MaterialPageRoute(
              builder: (_) => pageBuilder(),
            ),
          );
        },
        child: Text(text),
      ),
    );
  }
}
