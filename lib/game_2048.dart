import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../api.dart';
import 'leaderboard_model.dart';

class Game2048 extends StatefulWidget {
  final int hastaId;
  const Game2048({super.key, required this.hastaId});

  @override
  State<Game2048> createState() => _Game2048State();
}

class _Game2048State extends State<Game2048> {
  static const int size = 4;
  static const String gameName = "2048 Oyunu";

  late List<List<int>> grid;
  int score = 0;
  final rand = Random();
  bool isGameOver = false;

  @override
  void initState() {
    super.initState();
    _startGame();
  }

  // ---------------- INIT ----------------

  void _startGame() {
    grid = List.generate(size, (_) => List.filled(size, 0));
    score = 0;
    isGameOver = false;
    _addNumber();
    _addNumber();
    setState(() {});
  }

  void _addNumber() {
    final empty = <Point<int>>[];

    for (int i = 0; i < size; i++) {
      for (int j = 0; j < size; j++) {
        if (grid[i][j] == 0) empty.add(Point(i, j));
      }
    }

    if (empty.isEmpty) return;

    final p = empty[rand.nextInt(empty.length)];
    grid[p.x][p.y] = rand.nextInt(10) == 0 ? 4 : 2;
  }

  // ---------------- MOVE CORE ----------------

  bool _move(List<int> line) {
    final original = List<int>.from(line);

    line.removeWhere((e) => e == 0);

    for (int i = 0; i < line.length - 1; i++) {
      if (line[i] == line[i + 1]) {
        line[i] *= 2;
        score += line[i];
        line[i + 1] = 0;
      }
    }

    line.removeWhere((e) => e == 0);
    while (line.length < size) {
      line.add(0);
    }

    return !listEquals(original, line);
  }

  void _afterMove(bool moved) {
    if (!moved) return;

    setState(() {
      _addNumber();
      if (_isGameOver()) {
        _endGame();
      }
    });
  }

  // ---------------- DIRECTIONS ----------------

  void _moveLeft() {
    bool moved = false;
    for (int i = 0; i < size; i++) {
      moved |= _move(grid[i]);
    }
    _afterMove(moved);
  }

  void _moveRight() {
    bool moved = false;
    for (int i = 0; i < size; i++) {
      final row = grid[i].reversed.toList();
      moved |= _move(row);
      grid[i] = row.reversed.toList();
    }
    _afterMove(moved);
  }

  void _moveUp() {
    bool moved = false;
    for (int j = 0; j < size; j++) {
      final col = List.generate(size, (i) => grid[i][j]);
      moved |= _move(col);
      for (int i = 0; i < size; i++) {
        grid[i][j] = col[i];
      }
    }
    _afterMove(moved);
  }

  void _moveDown() {
    bool moved = false;
    for (int j = 0; j < size; j++) {
      final col = List.generate(size, (i) => grid[i][j]).reversed.toList();
      moved |= _move(col);
      final fixed = col.reversed.toList();
      for (int i = 0; i < size; i++) {
        grid[i][j] = fixed[i];
      }
    }
    _afterMove(moved);
  }

  // ---------------- GAME OVER ----------------

  bool _isGameOver() {
    for (int i = 0; i < size; i++) {
      for (int j = 0; j < size; j++) {
        if (grid[i][j] == 0) return false;
        if (i < size - 1 && grid[i][j] == grid[i + 1][j]) return false;
        if (j < size - 1 && grid[i][j] == grid[i][j + 1]) return false;
      }
    }
    return true;
  }

  Future<void> _endGame() async {
    isGameOver = true;

    await ApiService.sendScore(
      hastaid: widget.hastaId,
      oyunadi: gameName,
      skor: score,
    );

    if (!mounted) return;

    _showLeaderboard();
  }

  // ---------------- EXIT HANDLING ----------------

  Future<bool> _onWillPop() async {
    if (isGameOver) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Çıkış"),
        content: const Text("Oyundan çıkmak istiyor musunuz?"),
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

    if (result == true) {
      _showLeaderboard();
      return false;
    }

    return false;
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

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(title: Text("2048 | Puan: $score")),
        body: GestureDetector(
          onPanEnd: (details) {
            final v = details.velocity.pixelsPerSecond;
            if (v.dx.abs() > v.dy.abs()) {
              v.dx > 0 ? _moveRight() : _moveLeft();
            } else {
              v.dy > 0 ? _moveDown() : _moveUp();
            }
          },
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: size * size,
            gridDelegate:
            const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4),
            itemBuilder: (_, i) {
              final x = i ~/ size;
              final y = i % size;
              final value = grid[x][y];

              return Container(
                margin: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: value == 0 ? Colors.grey[300] : Colors.orange,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    value == 0 ? "" : "$value",
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
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
      content: FutureBuilder(
        future: ApiService.getLeaderboard(gameName),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const SizedBox(
              height: 80,
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final data = snapshot.data!;
          if (data.isEmpty) {
            return const Text("Henüz skor yok.");
          }

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
