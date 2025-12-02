// lib/api.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // آدرس پایه سرور (برای شبیه‌ساز اندروید 10.0.2.2 است)
  static const String baseUrl = "http://10.0.2.2:8000";

  /// 1. ثبت امتیاز بازی (POST)
  static Future<bool> sendScore({
    required int hastaid,
    required String oyunadi,
    required int skor,
  }) async {
    final url = Uri.parse("$baseUrl/api/oyun/skor");

    final body = {
      "hastaid": hastaid,
      "oyunadi": oyunadi,
      "skor": skor,
    };

    // برای دیباگ: نمایش اطلاعات ارسالی در کنسول
    print("📤 API → /api/oyun/skor");
    print("Gönderilen JSON: ${jsonEncode(body)}");

    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode(body),
      );

      print("📥 API CEVABI (${response.statusCode}): ${response.body}");

      if (response.statusCode == 200) {
        print("✔️ Skor başarıyla kaydedildi.");
        return true;
      } else {
        print("❌ Skor kaydedilemedi. Kod: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      print("🔥 Ağ hatası: $e");
      return false;
    }
  }

  /// 2. دریافت لیست برترین‌ها (GET)
  static Future<List<dynamic>> getLeaderboard(String gameName) async {
    try {
      // نام بازی ممکن است فاصله داشته باشد، آن را encode می‌کنیم
      final encodedGameName = Uri.encodeComponent(gameName);

      // ساخت آدرس کامل API
      final url = Uri.parse('$baseUrl/api/oyun/liderler/$encodedGameName');

      print("📤 GET Leaderboard: $url");

      final response = await http.get(url);

      if (response.statusCode == 200) {
        // تبدیل بدنه پاسخ به لیست (با پشتیبانی از حروف ترکی/فارسی utf8)
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        print("📥 Leaderboard Data: $data");
        return data;
      } else {
        print("❌ Leaderboard hatası: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      print("🔥 Bağlantı hatası: $e");
      return [];
    }
  }
}