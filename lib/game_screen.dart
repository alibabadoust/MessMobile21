import 'package:flutter/material.dart';
import 'dart:async';
import 'api.dart'; // فایل api.dart که شامل توابع ارتباط با سرور است
import 'main.dart'; // برای دسترسی به متغیر رنگ kPrimaryColor

// =============================================================
// 1. GAME MENU (منوی بازی)
// =============================================================
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
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Beklerken Eğlenin!",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "Sıranız gelene kadar stres atın.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 40),
            _buildGameCard(
              context,
              title: "Hafıza Oyunu",
              subtitle: "Kartları Eşleştir",
              icon: Icons.flip,
              color: Colors.purple,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MemoryGame(hastaId: hastaId),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameCard(
      BuildContext context, {
        required String title,
        required String subtitle,
        required IconData icon,
        required Color color,
        required VoidCallback onTap,
      }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.2), blurRadius: 10),
          ],
          border: Border.all(color: color.withOpacity(0.5), width: 2),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: color),
            ),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold, color: color)),
                Text(subtitle,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600])),
              ],
            ),
            const Spacer(),
            Icon(Icons.play_circle_fill, color: color, size: 32),
          ],
        ),
      ),
    );
  }
}

// =============================================================
// 2. MEMORY GAME (بازی حافظه)
// =============================================================
class MemoryGame extends StatefulWidget {
  final int hastaId;

  const MemoryGame({super.key, required this.hastaId});

  @override
  State<MemoryGame> createState() => _MemoryGameState();
}

class _MemoryGameState extends State<MemoryGame> {
  final List<String> _baseIcons = ['🍎', '🚗', '🚀', '🐶', '⚽', '🌟'];
  late List<String> _icons;
  late List<bool> _flipped;
  late List<bool> _matched;

  int _previousIndex = -1;
  bool _isProcessing = false;
  int _score = 0;

  // نام دقیق بازی در دیتابیس باید یکی باشد تا لیدربورد درست کار کند
  final String _gameName = "Hafıza Oyunu";

  @override
  void initState() {
    super.initState();
    _resetGame();
  }

  // تابع ثبت امتیاز در دیتابیس
  Future<void> _saveScoreToApi() async {
    await ApiService.sendScore(
      hastaid: widget.hastaId,
      oyunadi: _gameName,
      skor: _score,
    );
  }

  void _resetGame() {
    _icons = [..._baseIcons, ..._baseIcons];
    _icons.shuffle();
    _flipped = List.filled(_icons.length, false);
    _matched = List.filled(_icons.length, false);
    _previousIndex = -1;
    _score = 0;
    setState(() {});
  }

  void _handleTap(int index) {
    if (_isProcessing || _flipped[index] || _matched[index]) return;

    setState(() {
      _flipped[index] = true;
    });

    if (_previousIndex == -1) {
      _previousIndex = index;
    } else {
      _isProcessing = true;
      if (_icons[_previousIndex] == _icons[index]) {
        // کارت‌ها مشابه بودند
        _matched[_previousIndex] = true;
        _matched[index] = true;
        _previousIndex = -1;
        _isProcessing = false;
        _score += 10;

        // چک کردن پایان بازی
        if (_matched.every((e) => e)) {
          _handleGameEnd();
        } else {
          setState(() {});
        }
      } else {
        // کارت‌ها مشابه نبودند
        Timer(const Duration(milliseconds: 500), () {
          if (!mounted) return;
          setState(() {
            _flipped[_previousIndex] = false;
            _flipped[index] = false;
            _previousIndex = -1;
            _isProcessing = false;
          });
        });
      }
    }
  }

  // تابع پایان بازی: اول امتیاز را ثبت می‌کند، بعد لیدربورد را نشان می‌دهد
  void _handleGameEnd() async {
    // ۱. ثبت امتیاز
    await _saveScoreToApi();

    if (!mounted) return;

    // ۲. نمایش دیالوگ لیدربورد
    showDialog(
      context: context,
      barrierDismissible: false, // کاربر باید دکمه خروج یا شروع مجدد را بزند
      builder: (ctx) => LeaderboardDialog(
        score: _score,
        gameName: _gameName,
        onReplay: () {
          Navigator.of(ctx).pop();
          _resetGame();
        },
        onExit: () {
          Navigator.of(ctx).pop();
          Navigator.of(context).pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Puan: $_score"),
        backgroundColor: Colors.purple,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: _icons.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => _handleTap(index),
            child: Container(
              decoration: BoxDecoration(
                color: _flipped[index] || _matched[index]
                    ? Colors.white
                    : Colors.purple,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.purple),
              ),
              child: Center(
                child: Text(
                  _flipped[index] || _matched[index] ? _icons[index] : "❓",
                  style: const TextStyle(fontSize: 40),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// =============================================================
// 3. LEADERBOARD DIALOG (ویجت نمایش لیست برترین‌ها)
// =============================================================
class LeaderboardDialog extends StatelessWidget {
  final int score;
  final String gameName;
  final VoidCallback onReplay;
  final VoidCallback onExit;

  const LeaderboardDialog({
    super.key,
    required this.score,
    required this.gameName,
    required this.onReplay,
    required this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Column(
        children: [
          const Text("Oyun Bitti!", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text("Senin Puanın: $score",
              style: const TextStyle(fontSize: 18, color: Colors.purple, fontWeight: FontWeight.bold)),
          const Divider(thickness: 1.5, height: 20),
          const Text("🏆 Liderlik Tablosu (Top 10) 🏆",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 300, // ارتفاع لیست
        child: FutureBuilder<List<dynamic>>(
          // فراخوانی تابع getLeaderboard که در api.dart نوشتیم
          future: ApiService.getLeaderboard(gameName),
          builder: (context, snapshot) {
            // حالت لودینگ
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            // حالت خطا
            else if (snapshot.hasError) {
              return const Center(child: Text("Liste yüklenemedi. Bağlantınızı kontrol edin.", textAlign: TextAlign.center));
            }
            // حالت لیست خالی
            else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text("Henüz kayıtlı skor yok. İlk sen ol!"));
            }

            // نمایش لیست
            final leaders = snapshot.data!;

            return ListView.separated(
              itemCount: leaders.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = leaders[index];
                final name = item['adsoyad'] ?? 'İsimsiz';
                final s = item['skor'] ?? 0;

                // رنگ‌بندی ۳ نفر اول
                Color? badgeColor;
                if (index == 0) badgeColor = Colors.amber; // طلا
                else if (index == 1) badgeColor = Colors.grey[400]; // نقره
                else if (index == 2) badgeColor = Colors.brown[300]; // برنز
                else badgeColor = Colors.blue[50]; // بقیه

                return ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    backgroundColor: badgeColor,
                    radius: 14,
                    child: Text("${index + 1}",
                        style: TextStyle(fontSize: 12, color: index < 3 ? Colors.white : Colors.black, fontWeight: FontWeight.bold)
                    ),
                  ),
                  title: Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  trailing: Text("$s", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.green)),
                );
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: onReplay,
          child: const Text("Tekrar Oyna"),
        ),
        ElevatedButton(
          onPressed: onExit,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white),
          child: const Text("Çıkış"),
        )
      ],
    );
  }
}