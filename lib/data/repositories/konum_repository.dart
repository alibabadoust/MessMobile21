// ============================================================================
// MESS - Mobil Entegre Akıllı Sıra Takip Sistemi
// Konum (Location) Repository
// ============================================================================
// Şehir, ilçe ve hastane verilerini yöneten repository sınıfı
// API isteklerini soyutlar ve model dönüşümlerini yapar
// ============================================================================

import '../models/sehir_model.dart';
import '../models/api_response.dart';
import '../network/api_service.dart';
import '../network/api_endpoints.dart';

/// Konum verilerini yöneten repository sınıfı
class KonumRepository {
  // ApiService singleton instance
  final ApiService _apiService = ApiService();

  // ===========================================================================
  // ŞEHİR (CITY) İŞLEMLERİ
  // ===========================================================================

  /// Tüm şehirleri getirir
  /// 
  /// Örnek kullanım:
  /// ```dart
  /// final repository = KonumRepository();
  /// final response = await repository.getSehirler();
  /// 
  /// response.when(
  ///   success: (sehirler) => print('${sehirler.length} şehir bulundu'),
  ///   failure: (error) => print('Hata: $error'),
  /// );
  /// ```
  Future<ApiResponse<List<SehirModel>>> getSehirler() async {
    try {
      // GET isteği gönder
      final response = await _apiService.get(ApiEndpoints.sehirler);
      
      // JSON listesini model listesine dönüştür
      final sehirler = SehirModel.fromJsonList(response as List<dynamic>);
      
      return ApiResponse.success(
        data: sehirler,
        statusCode: 200,
      );
    } on ApiException catch (e) {
      return ApiResponse.failure(
        error: e.message,
        statusCode: e.statusCode,
      );
    } catch (e) {
      return ApiResponse.failure(
        error: 'Şehirler yüklenirken beklenmeyen bir hata oluştu: $e',
      );
    }
  }

  /// Tek bir şehir bilgisini ID ile getirir
  Future<ApiResponse<SehirModel>> getSehirById(int sehirId) async {
    try {
      final response = await _apiService.get('${ApiEndpoints.sehirler}/$sehirId');
      final sehir = SehirModel.fromJson(response as Map<String, dynamic>);
      
      return ApiResponse.success(data: sehir, statusCode: 200);
    } on ApiException catch (e) {
      return ApiResponse.failure(error: e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.failure(
        error: 'Şehir bilgisi alınırken hata oluştu: $e',
      );
    }
  }

  // ===========================================================================
  // İLÇE (DISTRICT) İŞLEMLERİ
  // ===========================================================================

  /// Belirli bir şehrin ilçelerini getirir
  /// 
  /// [sehirId]: Şehir ID'si
  Future<ApiResponse<List<Map<String, dynamic>>>> getIlceler(int sehirId) async {
    try {
      final response = await _apiService.get(
        ApiEndpoints.ilceler,
        queryParameters: {'sehir_id': sehirId},
      );
      
      final ilceler = (response as List<dynamic>)
          .map((e) => e as Map<String, dynamic>)
          .toList();
      
      return ApiResponse.success(data: ilceler, statusCode: 200);
    } on ApiException catch (e) {
      return ApiResponse.failure(error: e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.failure(
        error: 'İlçeler yüklenirken hata oluştu: $e',
      );
    }
  }

  // ===========================================================================
  // HASTANE (HOSPITAL) İŞLEMLERİ
  // ===========================================================================

  /// Tüm hastaneleri getirir
  Future<ApiResponse<List<Map<String, dynamic>>>> getHastaneler() async {
    try {
      final response = await _apiService.get(ApiEndpoints.hastaneler);
      
      final hastaneler = (response as List<dynamic>)
          .map((e) => e as Map<String, dynamic>)
          .toList();
      
      return ApiResponse.success(data: hastaneler, statusCode: 200);
    } on ApiException catch (e) {
      return ApiResponse.failure(error: e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.failure(
        error: 'Hastaneler yüklenirken hata oluştu: $e',
      );
    }
  }

  /// Belirli bir şehir veya ilçedeki hastaneleri getirir
  /// 
  /// [sehirId]: Şehir ID'si (opsiyonel)
  /// [ilceId]: İlçe ID'si (opsiyonel)
  Future<ApiResponse<List<Map<String, dynamic>>>> getHastanelerByKonum({
    int? sehirId,
    int? ilceId,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (sehirId != null) queryParams['sehir_id'] = sehirId;
      if (ilceId != null) queryParams['ilce_id'] = ilceId;
      
      final response = await _apiService.get(
        ApiEndpoints.hastaneler,
        queryParameters: queryParams,
      );
      
      final hastaneler = (response as List<dynamic>)
          .map((e) => e as Map<String, dynamic>)
          .toList();
      
      return ApiResponse.success(data: hastaneler, statusCode: 200);
    } on ApiException catch (e) {
      return ApiResponse.failure(error: e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.failure(
        error: 'Hastaneler yüklenirken hata oluştu: $e',
      );
    }
  }
}
