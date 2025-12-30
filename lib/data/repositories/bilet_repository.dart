// ============================================================================
// MESS - Mobil Entegre Akıllı Sıra Takip Sistemi
// Bilet (Ticket) Repository
// ============================================================================
// Bilet oluşturma, listeleme, güncelleme ve silme işlemlerini yönetir
// API isteklerini soyutlar ve model dönüşümlerini yapar
// ============================================================================

import '../models/bilet_model.dart';
import '../models/api_response.dart';
import '../network/api_service.dart';
import '../network/api_endpoints.dart';

/// Bilet işlemlerini yöneten repository sınıfı
class BiletRepository {
  // ApiService singleton instance
  final ApiService _apiService = ApiService();

  // ===========================================================================
  // BİLET OLUŞTURMA (CREATE)
  // ===========================================================================

  /// Yeni bir bilet oluşturur
  /// 
  /// Örnek kullanım:
  /// ```dart
  /// final repository = BiletRepository();
  /// 
  /// final yeniBilet = BiletModel(
  ///   hastaid: 123,
  ///   poliklinikid: 456,
  ///   tarih: DateTime.now(),
  /// );
  /// 
  /// final response = await repository.createBilet(yeniBilet);
  /// 
  /// response.when(
  ///   success: (bilet) => print('Bilet oluşturuldu. Sıra No: ${bilet.siraNo}'),
  ///   failure: (error) => print('Hata: $error'),
  /// );
  /// ```
  Future<ApiResponse<BiletModel>> createBilet(BiletModel bilet) async {
    try {
      // POST isteği gönder (minimal JSON kullan)
      final response = await _apiService.post(
        ApiEndpoints.biletler,
        data: bilet.toCreateJson(),
      );
      
      // Yanıtı modele dönüştür
      final createdBilet = BiletModel.fromJson(response as Map<String, dynamic>);
      
      return ApiResponse.success(
        data: createdBilet,
        statusCode: 201,
      );
    } on ApiException catch (e) {
      return ApiResponse.failure(
        error: e.message,
        statusCode: e.statusCode,
      );
    } catch (e) {
      return ApiResponse.failure(
        error: 'Bilet oluşturulurken beklenmeyen bir hata oluştu: $e',
      );
    }
  }

  // ===========================================================================
  // BİLET LİSTELEME (READ)
  // ===========================================================================

  /// Tüm biletleri getirir (filtreleme opsiyonel)
  /// 
  /// [poliklinikId]: Poliklinik filtresi
  /// [durum]: Durum filtresi
  /// [tarih]: Tarih filtresi
  Future<ApiResponse<List<BiletModel>>> getBiletler({
    int? poliklinikId,
    BiletDurumu? durum,
    DateTime? tarih,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (poliklinikId != null) queryParams['poliklinik_id'] = poliklinikId;
      if (durum != null) queryParams['durum'] = biletDurumuToString(durum);
      if (tarih != null) queryParams['tarih'] = tarih.toIso8601String().split('T')[0];
      
      final response = await _apiService.get(
        ApiEndpoints.biletler,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
      
      final biletler = BiletModel.fromJsonList(response as List<dynamic>);
      
      return ApiResponse.success(data: biletler, statusCode: 200);
    } on ApiException catch (e) {
      return ApiResponse.failure(error: e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.failure(
        error: 'Biletler yüklenirken hata oluştu: $e',
      );
    }
  }

  /// Tek bir biletin detaylarını getirir
  Future<ApiResponse<BiletModel>> getBiletById(int biletId) async {
    try {
      final response = await _apiService.get(ApiEndpoints.biletById(biletId));
      final bilet = BiletModel.fromJson(response as Map<String, dynamic>);
      
      return ApiResponse.success(data: bilet, statusCode: 200);
    } on ApiException catch (e) {
      return ApiResponse.failure(error: e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.failure(
        error: 'Bilet bilgisi alınırken hata oluştu: $e',
      );
    }
  }

  /// Bir hastanın tüm biletlerini getirir
  Future<ApiResponse<List<BiletModel>>> getHastaBiletleri(int hastaId) async {
    try {
      final response = await _apiService.get(
        ApiEndpoints.hastaBiletleri(hastaId),
      );
      
      final biletler = BiletModel.fromJsonList(response as List<dynamic>);
      
      return ApiResponse.success(data: biletler, statusCode: 200);
    } on ApiException catch (e) {
      return ApiResponse.failure(error: e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.failure(
        error: 'Hasta biletleri yüklenirken hata oluştu: $e',
      );
    }
  }

  /// Bir hastanın aktif biletlerini getirir (beklemede, çağrıldı, muayenede)
  Future<ApiResponse<List<BiletModel>>> getAktifBiletler(int hastaId) async {
    try {
      final response = await getHastaBiletleri(hastaId);
      
      if (response.success && response.data != null) {
        final aktifBiletler = response.data!
            .where((bilet) => bilet.aktifMi)
            .toList();
        
        return ApiResponse.success(data: aktifBiletler, statusCode: 200);
      }
      
      return response;
    } catch (e) {
      return ApiResponse.failure(
        error: 'Aktif biletler alınırken hata oluştu: $e',
      );
    }
  }

  // ===========================================================================
  // BİLET GÜNCELLEME (UPDATE)
  // ===========================================================================

  /// Bileti günceller
  Future<ApiResponse<BiletModel>> updateBilet(BiletModel bilet) async {
    if (bilet.id == null) {
      return ApiResponse.failure(
        error: 'Güncellenecek biletin ID\'si belirtilmeli.',
      );
    }
    
    try {
      final response = await _apiService.put(
        ApiEndpoints.biletById(bilet.id!),
        data: bilet.toJson(),
      );
      
      final updatedBilet = BiletModel.fromJson(response as Map<String, dynamic>);
      
      return ApiResponse.success(data: updatedBilet, statusCode: 200);
    } on ApiException catch (e) {
      return ApiResponse.failure(error: e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.failure(
        error: 'Bilet güncellenirken hata oluştu: $e',
      );
    }
  }

  /// Bilet durumunu günceller
  Future<ApiResponse<BiletModel>> updateBiletDurumu(
    int biletId, 
    BiletDurumu yeniDurum,
  ) async {
    try {
      final response = await _apiService.patch(
        ApiEndpoints.biletById(biletId),
        data: {'durum': biletDurumuToString(yeniDurum)},
      );
      
      final updatedBilet = BiletModel.fromJson(response as Map<String, dynamic>);
      
      return ApiResponse.success(data: updatedBilet, statusCode: 200);
    } on ApiException catch (e) {
      return ApiResponse.failure(error: e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.failure(
        error: 'Bilet durumu güncellenirken hata oluştu: $e',
      );
    }
  }

  // ===========================================================================
  // BİLET SİLME/İPTAL (DELETE)
  // ===========================================================================

  /// Bileti iptal eder (soft delete - durumu iptal olarak günceller)
  Future<ApiResponse<BiletModel>> cancelBilet(int biletId) async {
    return updateBiletDurumu(biletId, BiletDurumu.iptal);
  }

  /// Bileti kalıcı olarak siler (hard delete)
  Future<ApiResponse<bool>> deleteBilet(int biletId) async {
    try {
      await _apiService.delete(ApiEndpoints.biletById(biletId));
      
      return ApiResponse.success(data: true, statusCode: 200);
    } on ApiException catch (e) {
      return ApiResponse.failure(error: e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.failure(
        error: 'Bilet silinirken hata oluştu: $e',
      );
    }
  }

  // ===========================================================================
  // SIRA TAKİBİ
  // ===========================================================================

  /// Biletin güncel sıra durumunu getirir
  Future<ApiResponse<Map<String, dynamic>>> getSiraDurumu(int biletId) async {
    try {
      final response = await _apiService.get(
        ApiEndpoints.siraDurumu,
        queryParameters: {'bilet_id': biletId},
      );
      
      return ApiResponse.success(
        data: response as Map<String, dynamic>,
        statusCode: 200,
      );
    } on ApiException catch (e) {
      return ApiResponse.failure(error: e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.failure(
        error: 'Sıra durumu alınırken hata oluştu: $e',
      );
    }
  }
}
