// ============================================================================
// MESS - Mobil Entegre Akıllı Sıra Takip Sistemi
// API Facade - Business-specific API methods
// ============================================================================
// Bu sınıf, ekran katmanı için basit static metodlar sağlar.
// Arka planda Dio-tabanlı NetworkApiService kullanır.
// Tüm metodlar 15 saniye timeout ve birleşik hata yönetimi içerir.
// ============================================================================

import 'dart:io';
import 'dart:async';
import 'package:siralamahastane/leaderboard_model.dart';
import 'data/network/api_service.dart' as network;
import 'data/network/api_endpoints.dart';

/// API sonuç sınıfı - başarı/hata durumunu ve veriyi taşır
class ApiResult<T> {
  final bool success;
  final T? data;
  final String? errorMessage;
  final int? statusCode;

  ApiResult({
    required this.success,
    this.data,
    this.errorMessage,
    this.statusCode,
  });

  factory ApiResult.success(T data) => ApiResult(success: true, data: data);
  
  factory ApiResult.error(String message, {int? statusCode}) => ApiResult(
    success: false,
    errorMessage: message,
    statusCode: statusCode,
  );
}

/// API Facade - Screen katmanı için basitleştirilmiş metodlar
class Api {
  // Singleton ApiService instance from network layer
  static final network.ApiService _apiService = network.ApiService();

  // Private constructor
  Api._();

  // ===========================================================================
  // BİLET TAKİP İŞLEMLERİ
  // ===========================================================================

  /// Sıra takibi - telefon ve bağlantı kodu ile bilet bilgilerini alır
  /// [phone]: Telefon numarası
  /// [code]: 11 haneli bağlantı kodu
  /// Returns: ApiResult with ticket details or error
  static Future<ApiResult<Map<String, dynamic>>> trackQueue({
    required String phone,
    required String code,
  }) async {
    try {
      final response = await _apiService.post(
        ApiEndpoints.biletTakip,
        data: {
          'telefon': phone,  // Send phone as-is (with spaces to match database format)
          'baglantikodu': code,
        },
      );

      if (response != null && response is Map<String, dynamic>) {
        return ApiResult.success(response);
      } else {
        return ApiResult.error('Sunucudan beklenmeyen veri alındı.');
      }
    } on network.ApiException catch (e) {
      return ApiResult.error(
        _getLocalizedError(e.statusCode, e.message),
        statusCode: e.statusCode,
      );
    } on SocketException {
      return ApiResult.error('İnternet bağlantısı yok. Lütfen bağlantınızı kontrol edin.');
    } on TimeoutException {
      return ApiResult.error('İstek zaman aşımına uğradı. Lütfen tekrar deneyin.');
    } catch (e) {
      return ApiResult.error('Bağlantı hatası: ${e.toString()}');
    }
  }

  /// Bilet erteleme - bağlantı kodu ve aksiyon ile sırayı erteler
  /// [code]: 11 haneli bağlantı kodu
  /// [action]: Erteleme aksiyonu (örn: "15_dk", "30_dk", "45_dk")
  /// Returns: ApiResult with new ticket code or error
  static Future<ApiResult<Map<String, dynamic>>> postponeTicket({
    required String code,
    required String action,
  }) async {
    try {
      final response = await _apiService.post(
        ApiEndpoints.biletErtele,
        data: {
          'baglantikodu': code,
          'aksiyon': action,
        },
      );

      if (response != null && response is Map<String, dynamic>) {
        return ApiResult.success(response);
      } else {
        return ApiResult.error('Sunucudan beklenmeyen veri alındı.');
      }
    } on network.ApiException catch (e) {
      return ApiResult.error(
        _getLocalizedError(e.statusCode, e.message),
        statusCode: e.statusCode,
      );
    } on SocketException {
      return ApiResult.error('İnternet bağlantısı yok. Lütfen bağlantınızı kontrol edin.');
    } on TimeoutException {
      return ApiResult.error('İstek zaman aşımına uğradı. Lütfen tekrar deneyin.');
    } catch (e) {
      return ApiResult.error('Bağlantı hatası: ${e.toString()}');
    }
  }

  // ===========================================================================
  // HASTA KAYIT İŞLEMLERİ
  // ===========================================================================

  /// Yeni hasta kaydı oluşturur
  /// [data]: Hasta bilgileri (adsoyad, tckimlik, sifre, telefon, dogumtarihi, email)
  /// Returns: ApiResult with registration response or error
  static Future<ApiResult<Map<String, dynamic>>> registerPatient({
    required Map<String, dynamic> data,
  }) async {
    try {
      final response = await _apiService.post(
        ApiEndpoints.hastalar,
        data: data,
      );

      if (response != null && response is Map<String, dynamic>) {
        return ApiResult.success(response);
      } else {
        return ApiResult.success({'message': 'Kayıt başarılı'});
      }
    } on network.ApiException catch (e) {
      return ApiResult.error(
        _getLocalizedError(e.statusCode, e.message, data: e.data),
        statusCode: e.statusCode,
      );
    } on SocketException {
      return ApiResult.error('İnternet bağlantısı yok. Lütfen bağlantınızı kontrol edin.');
    } on TimeoutException {
      return ApiResult.error('İstek zaman aşımına uğradı. Lütfen tekrar deneyin.');
    } catch (e) {
      return ApiResult.error('Bağlantı hatası: ${e.toString()}');
    }
  }

  // ===========================================================================
  // FORM (AI ÖZET) İŞLEMLERİ
  // ===========================================================================

  /// AI özet ve form verisini kaydeder
  /// [biletId]: Bilet ID
  /// [summary]: AI tarafından oluşturulan özet
  /// [details]: Form detayları (answers, full_conversation)
  /// Returns: true if successful, false otherwise
  static Future<bool> saveAiSummary({
    required int biletId,
    required String summary,
    required Map<String, dynamic> details,
  }) async {
    try {
      await _apiService.post(
        ApiEndpoints.formlar,
        data: {
          'biletid': biletId,
          'ai_ozet': summary,
          'formverisi_json': details,
        },
      );
      return true;
    } catch (e) {
      print('Error saving AI summary: $e');
      return false;
    }
  }

  // ===========================================================================
  // OYUN (GAME) İŞLEMLERİ
  // ===========================================================================

  /// Oyun skorunu sunucuya gönderir
  /// [hastaid]: Hasta ID
  /// [oyunadi]: Oyun adı
  /// [skor]: Oyun skoru
  /// Returns: true if successful, false otherwise
  static Future<bool> sendScore({
    required int hastaid,
    required String oyunadi,
    required int skor,
  }) async {
    try {
      await _apiService.post(
        ApiEndpoints.oyunSkor,
        data: {
          'hastaid': hastaid,
          'oyunadi': oyunadi,
          'skor': skor,
        },
      );
      return true;
    } catch (e) {
      print('Error sending score: $e');
      return false;
    }
  }

  /// Oyun lider tablosunu getirir (TYPE SAFE)
  /// [gameName]: Oyun adı
  /// Returns: List of LeaderboardModel entries
  static Future<List<LeaderboardModel>> getLeaderboard(String gameName) async {
    try {
      final response = await _apiService.get(
        ApiEndpoints.oyunLiderler(gameName),
      );

      if (response == null) return [];

      final List<dynamic> decoded = response is List ? response : [];

      return decoded
          .map((e) => LeaderboardModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting leaderboard: $e');
      return [];
    }
  }

  // ===========================================================================
  // YARDIMCI METODLAR
  // ===========================================================================

  /// Hata koduna göre Türkçe hata mesajı döndürür
  static String _getLocalizedError(int? statusCode, String defaultMessage, {dynamic data}) {
    // API'den gelen detail mesajını kontrol et
    if (data != null && data is Map<String, dynamic> && data.containsKey('detail')) {
      return data['detail'].toString();
    }

    switch (statusCode) {
      case 400:
        return 'Geçersiz istek. Girdiğiniz bilgileri kontrol edin.';
      case 403:
        return 'Telefon numarası bilet ile eşleşmiyor.';
      case 404:
        return 'Bu koda ait aktif bir bilet bulunamadı.';
      case 422:
        return 'Veri doğrulama hatası. Lütfen bilgileri kontrol edin.';
      case 500:
        return 'Sunucu hatası. Lütfen daha sonra tekrar deneyin.';
      default:
        return defaultMessage;
    }
  }
}

// ===========================================================================
// BACKWARD COMPATIBILITY - Eski ApiService referansları için
// ===========================================================================
// Eski kod ile uyumluluk sağlamak için ApiService sınıfı
// Bu sınıf, dino_game.dart gibi eski dosyaların çalışmaya devam etmesini sağlar

class ApiService {
  // Delegate to Api class for all static methods
  static Future<bool> sendScore({
    required int hastaid,
    required String oyunadi,
    required int skor,
  }) => Api.sendScore(hastaid: hastaid, oyunadi: oyunadi, skor: skor);

  static Future<List<LeaderboardModel>> getLeaderboard(String gameName) =>
      Api.getLeaderboard(gameName);
}