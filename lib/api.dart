import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:siralamahastane/leaderboard_model.dart';

// اگر فایل api.dart مستقیماً داخل پوشه lib است، این خط باید کار کند
import '../leaderboard_model.dart';

class ApiService {
  // برای شبیه‌ساز اندروید آدرس 10.0.2.2 صحیح است
  static const String baseUrl = "http://10.0.2.2:8000";

  // -----------------------------
  // ارسال امتیاز بازی
  // -----------------------------
  static Future<bool> sendScore({
    required int hastaid,
    required String oyunadi,
    required int skor,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/oyun/skor'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({
          'hastaid': hastaid,
          'oyunadi': oyunadi,
          'skor': skor,
        }),
      );

      return response.statusCode == 200;
    } catch (e) { // اصلاح شد: استفاده از e به جای _
      print("Error sending score: $e");
      return false;
    }
  }

  // -----------------------------
  // دریافت Leaderboard (TYPE SAFE)
  // -----------------------------
  static Future<List<LeaderboardModel>> getLeaderboard(String gameName) async {
    try {
      final encodedGameName = Uri.encodeComponent(gameName);
      final response = await http.get(
        Uri.parse('$baseUrl/api/oyun/liderler/$encodedGameName'),
      );

      if (response.statusCode != 200) return [];

      final List<dynamic> decoded = jsonDecode(utf8.decode(response.bodyBytes));

      return decoded
          .map((e) => LeaderboardModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) { // اصلاح شد
      print("Error getting leaderboard: $e");
      return [];
    }
  }
}