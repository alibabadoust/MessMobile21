import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../api.dart';
import 'leaderboard_model.dart';

enum Direction { up, down, left, right }

class SnakeGame extends StatefulWidget {
  final int hastaId;

  const SnakeGame({super.key, required this.hastaId});

  @override
  State<SnakeGame> createState() => _SnakeGameState();
}

class _SnakeGameState extends State<SnakeGame> {
  // Board config
  static const int rowCount = 20;
  static const int colCount = 20;
  static const Duration tickRate = Duration(milliseconds: 180);
  static const String gameName = "Snake Oyunu";

  // Game state
  late List<Point<int>> snake;
  Point<int>? food;
  Direction direction = Direction.right;
  Timer? timer;
  int score = 0;
  bool isGameOver = false;

  @override
  void initState() {
    super.initState();
    _startGame();
  }

  // ---------------- GAME LOGIC ----------------

  void _startGame() {
    timer?.cancel();

    snake = [
      const Point(10, 10),
      const Point(10, 9),
      const Point(10, 8),
    ];

    direction = Direction.right;
    score = 0;
    isGameOver = false;
    _spawnFood();

    timer = Timer.periodic(tickRate, (_) => _update());

    setState(() {});
  }

  void _spawnFood() {
    final rand = Random();
    Point<int> p;

    do {
      p = Point(
        rand.nextInt(rowCount),
        rand.nextInt(colCount),
      );
    } while (snake.contains(p));

    food = p;
  }

  void _update() {
    if (isGameOver) return;

    final head = snake.first;
    late Point<int> newHead;

    switch (direction) {
      case Direction.up:
        newHead = Point(head.x - 1, head.y);
        break;
      case Direction.down:
        newHead = Point(head.x + 1, head.y);
        break;
      case Direction.left:
        newHead = Point(head.x, head.y - 1);
        break;
      case Direction.right:
        newHead = Point(head.x, head.y + 1);
        break;
    }

    // Collision check
    if (_isCollision(newHead)) {
      _endGame();
      return;
    }

    setState(() {
      snake.insert(0, newHead);

      if (newHead == food) {
        score += 10;
        _spawnFood();
      } else {
        snake.removeLast();
      }
    });
  }

  bool _isCollision(Point<int> p) {
    return p.x < 0 ||
        p.y < 0 ||
        p.x >= rowCount ||
        p.y >= colCount ||
        snake.contains(p);
  }

  void _changeDirection(Direction newDir) {
    final opposite = {
      Direction.up: Direction.down,
      Direction.down: Direction.up,
      Direction.left: Direction.right,
      Direction.right: Direction.left,
    };

    if (opposite[direction] == newDir) return;

    setState(() {
      direction = newDir;
    });
  }

  // ---------------- GAME OVER ----------------

  Future<void> _endGame() async {
    timer?.cancel();
    isGameOver = true;

    await ApiService.sendScore(
      hastaid: widget.hastaId,
      oyunadi: gameName,
      skor: score,
    );

    if (!mounted) return;

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

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Snake | Puan: $score"),
        backgroundColor: Colors.green,
      ),
      body: Column(
        children: [
          Expanded(child: _buildBoard()),
          _buildControls(),
        ],
      ),
    );
  }

  Widget _buildBoard() {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: colCount,
      ),
      itemCount: rowCount * colCount,
      itemBuilder: (_, index) {
        final x = index ~/ colCount;
        final y = index % colCount;
        final p = Point(x, y);

        Color color = Colors.black12;

        if (p == snake.first) {
          color = Colors.green;
        } else if (snake.contains(p)) {
          color = Colors.green.shade300;
        } else if (p == food) {
          color = Colors.red;
        }

        return Container(
          margin: const EdgeInsets.all(1),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        );
      },
    );
  }

  Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        children: [
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_up, size: 40),
            onPressed: () => _changeDirection(Direction.up),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.keyboard_arrow_left, size: 40),
                onPressed: () => _changeDirection(Direction.left),
              ),
              const SizedBox(width: 60),
              IconButton(
                icon: const Icon(Icons.keyboard_arrow_right, size: 40),
                onPressed: () => _changeDirection(Direction.right),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_down, size: 40),
            onPressed: () => _changeDirection(Direction.down),
          ),
        ],
      ),
    );
  }
}

// ---------------- LEADERBOARD DIALOG ----------------

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
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox(
              height: 80,
              child: Center(child: CircularProgressIndicator()),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Text("Henüz skor yok.");
          }

          final data = snapshot.data!;

          return SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: data.length,
              itemBuilder: (_, i) {
                final row = data[i];
                return ListTile(
                  leading: Text("#${i + 1}"),
                  title: Text(row.adsoyad),
                  trailing: Text(row.skor.toString()),
                );
              },
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
