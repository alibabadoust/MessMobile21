import 'dart:async';
import 'package:flutter/material.dart';
import '../api.dart';
import 'leaderboard_model.dart';

class DinoGame extends StatefulWidget {
  final int hastaId;
  const DinoGame({super.key, required this.hastaId});

  @override
  State<DinoGame> createState() => _DinoGameState();
}

class _DinoGameState extends State<DinoGame> {
  static const String gameName = "Dino Jump";

  // Dino physics
  double dinoY = 0; // 0 = ground
  double velocity = 0;
  final double gravity = 0.9;
  final double jumpForce = -14;

  // Obstacle
  double obstacleX = 1.2;

  int score = 0;
  bool isGameOver = false;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    _startGame();
  }

  // ---------------- GAME START ----------------

  void _startGame() {
    timer?.cancel();
    dinoY = 0;
    velocity = 0;
    obstacleX = 1.2;
    score = 0;
    isGameOver = false;

    timer = Timer.periodic(const Duration(milliseconds: 30), _update);
    setState(() {});
  }

  // ---------------- UPDATE LOOP ----------------

  void _update(Timer t) {
    if (isGameOver) return;

    // Gravity
    velocity += gravity;
    dinoY += velocity * 0.02;

    // Ground collision
    if (dinoY > 0) {
      dinoY = 0;
      velocity = 0;
    }

    // Move obstacle
    obstacleX -= 0.025;
    if (obstacleX < -1.3) {
      obstacleX = 1.2;
      score += 5;
    }

    // Collision
    if (_isColliding()) {
      _gameOver();
      return;
    }

    setState(() {});
  }

  bool _isColliding() {
    final bool horizontalHit = obstacleX < -0.4 && obstacleX > -0.7;
    final bool verticalHit = dinoY >= -0.05; // on ground
    return horizontalHit && verticalHit;
  }

  // ---------------- CONTROLS ----------------

  void _jump() {
    if (dinoY == 0) {
      velocity = jumpForce;
    }
  }

  // ---------------- GAME OVER ----------------

  Future<void> _gameOver() async {
    timer?.cancel();
    isGameOver = true;

    await ApiService.sendScore(
      hastaid: widget.hastaId,
      oyunadi: gameName,
      skor: score,
    );

    if (!mounted) return;

    _showLeaderboard();
  }

  void _showLeaderboard() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => LeaderboardDialog(
        gameName: gameName,
        score: score,
        onReplay: () {
          Navigator.pop(context);
          _startGame();
        },
        onExit: () {
          Navigator.pop(context);
          Navigator.pop(context);
        },
      ),
    );
  }

  // ---------------- EXIT CONFIRM ----------------

  Future<bool> _onWillPop() async {
    if (isGameOver) return true;

    final exit = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Oyundan çıkmak istiyor musun?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Hayır"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Evet"),
          ),
        ],
      ),
    );

    if (exit == true) {
      timer?.cancel();
      _showLeaderboard();
      return false;
    }

    return false;
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text("Dino Jump | $score"),
          backgroundColor: Colors.blue,
        ),
        body: GestureDetector(
          onTap: _jump,
          child: Container(
            color: Colors.lightBlue[100],
            child: Stack(
              children: [
                // Ground
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    height: 80,
                    color: Colors.green[700],
                  ),
                ),

                // Dino
                Align(
                  alignment: Alignment(-0.7, dinoY),
                  child: Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),

                // Obstacle
                Align(
                  alignment: Alignment(obstacleX, 0),
                  child: Container(
                    width: 30,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }
}

// ---------------- LEADERBOARD ----------------

class LeaderboardDialog extends StatelessWidget {
  final String gameName;
  final int score;
  final VoidCallback onReplay;
  final VoidCallback onExit;

  const LeaderboardDialog({
    super.key,
    required this.gameName,
    required this.score,
    required this.onReplay,
    required this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("🏆 Leaderboard"),
      content: FutureBuilder<List<LeaderboardModel>>(
        future: ApiService.getLeaderboard(gameName),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const SizedBox(
              height: 80,
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final data = snapshot.data!;
          if (data.isEmpty) return const Text("Henüz skor yok.");

          return SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: data.length,
              itemBuilder: (_, i) => ListTile(
                leading: Text("#${i + 1}"),
                title: Text(data[i].adsoyad),
                trailing: Text(data[i].skor.toString()),
              ),
            ),
          );
        },
      ),
      actions: [
        TextButton(onPressed: onExit, child: const Text("Çık")),
        ElevatedButton(onPressed: onReplay, child: const Text("Tekrar Oyna")),
      ],
    );
  }
}
