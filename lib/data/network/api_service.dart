// ============================================================================
// MESS - Mobil Entegre Akıllı Sıra Takip Sistemi
// Ana API Servis Sınıfı (Dio ile)
// ============================================================================
// Bu sınıf, tüm HTTP isteklerini yönetir.
// Singleton pattern kullanılarak tek bir Dio instance'ı oluşturulur.
// ============================================================================

import 'package:dio/dio.dart';
import '../config/app_config.dart';
import 'dio_interceptors.dart';

/// Özel API hata sınıfı
/// Tüm API hatalarını standart bir formatta döndürür
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  ApiException({
    required this.message,
    this.statusCode,
    this.data,
  });

  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';
}

/// Ana API Servis Sınıfı
/// Singleton pattern - uygulama genelinde tek instance
class ApiService {
  // Singleton instance
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  // Dio instance
  late final Dio _dio;
  
  // App config reference
  final AppConfig _config = AppConfig();
  
  // Auth interceptor reference (token yönetimi için)
  late final AuthInterceptor _authInterceptor;

  /// Private constructor - Dio yapılandırması burada yapılır
  ApiService._internal() {
    _initializeDio();
  }

  /// Dio instance'ını yapılandırır
  void _initializeDio() {
    // Base options
    final options = BaseOptions(
      baseUrl: _config.baseUrl,
      connectTimeout: Duration(milliseconds: AppConfig.connectTimeout),
      receiveTimeout: Duration(milliseconds: AppConfig.receiveTimeout),
      sendTimeout: Duration(milliseconds: AppConfig.sendTimeout),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      // Response tipini otomatik dönüştür
      responseType: ResponseType.json,
      // Hata durumunda exception fırlatma
      validateStatus: (status) => status != null && status < 500,
    );

    _dio = Dio(options);

    // Interceptor'ları ekle
    _authInterceptor = AuthInterceptor();
    
    _dio.interceptors.addAll([
      NgrokInterceptor(),      // ngrok bypass header'ı
      _authInterceptor,        // JWT token yönetimi
      LoggingInterceptor(),    // Debug loglama
      RetryInterceptor(dio: _dio, maxRetries: 3), // Otomatik yeniden deneme
    ]);

    // Yapılandırmayı yazdır (debug modunda)
    if (_config.isDebugMode) {
      _config.printConfig();
    }
  }

  // ===========================================================================
  // TEMEL HTTP METODLARI
  // ===========================================================================

  /// GET isteği gönderir
  /// [endpoint]: API endpoint'i (örn: '/api/konum/sehirler')
  /// [queryParameters]: URL query parametreleri (opsiyonel)
  Future<dynamic> get(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.get(
        endpoint,
        queryParameters: queryParameters,
      );
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// POST isteği gönderir
  /// [endpoint]: API endpoint'i
  /// [data]: İstek gövdesi (JSON olarak gönderilir)
  /// [queryParameters]: URL query parametreleri (opsiyonel)
  Future<dynamic> post(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.post(
        endpoint,
        data: data,
        queryParameters: queryParameters,
      );
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// PUT isteği gönderir (güncellemeler için)
  Future<dynamic> put(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.put(
        endpoint,
        data: data,
        queryParameters: queryParameters,
      );
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// PATCH isteği gönderir (kısmi güncellemeler için)
  Future<dynamic> patch(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.patch(
        endpoint,
        data: data,
        queryParameters: queryParameters,
      );
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// DELETE isteği gönderir
  Future<dynamic> delete(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.delete(
        endpoint,
        data: data,
        queryParameters: queryParameters,
      );
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Dosya yükleme (multipart/form-data)
  Future<dynamic> uploadFile(
    String endpoint, {
    required String filePath,
    required String fieldName,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final formData = FormData.fromMap({
        fieldName: await MultipartFile.fromFile(filePath),
        ...?additionalData,
      });

      final response = await _dio.post(
        endpoint,
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
        ),
      );
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // ===========================================================================
  // TOKEN YÖNETİMİ
  // ===========================================================================

  /// JWT token'ı ayarlar
  void setAuthToken(String token) {
    _authInterceptor.setToken(token);
  }

  /// JWT token'ı temizler (logout)
  void clearAuthToken() {
    _authInterceptor.clearToken();
  }

  // ===========================================================================
  // YARDIMCI METODLAR
  // ===========================================================================

  /// Response'u işler ve data'yı döndürür
  dynamic _handleResponse(Response response) {
    if (response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300) {
      return response.data;
    } else {
      throw ApiException(
        message: _getErrorMessage(response.statusCode),
        statusCode: response.statusCode,
        data: response.data,
      );
    }
  }

  /// DioException'ı ApiException'a dönüştürür
  ApiException _handleDioError(DioException error) {
    String message;
    int? statusCode = error.response?.statusCode;

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        message = 'Bağlantı zaman aşımına uğradı. Lütfen internet bağlantınızı kontrol edin.';
        break;
      case DioExceptionType.sendTimeout:
        message = 'İstek gönderilirken zaman aşımı oluştu.';
        break;
      case DioExceptionType.receiveTimeout:
        message = 'Sunucudan yanıt alınırken zaman aşımı oluştu.';
        break;
      case DioExceptionType.badCertificate:
        message = 'Güvenlik sertifikası doğrulanamadı.';
        break;
      case DioExceptionType.badResponse:
        message = _getErrorMessage(statusCode);
        break;
      case DioExceptionType.cancel:
        message = 'İstek iptal edildi.';
        break;
      case DioExceptionType.connectionError:
        message = 'Bağlantı hatası. Sunucuya ulaşılamıyor.';
        break;
      case DioExceptionType.unknown:
        message = error.message ?? 'Bilinmeyen bir hata oluştu.';
        break;
    }

    return ApiException(
      message: message,
      statusCode: statusCode,
      data: error.response?.data,
    );
  }

  /// HTTP durum koduna göre Türkçe hata mesajı döndürür
  String _getErrorMessage(int? statusCode) {
    switch (statusCode) {
      case 400:
        return 'Geçersiz istek. Lütfen girdiğiniz bilgileri kontrol edin.';
      case 401:
        return 'Oturum süresi dolmuş. Lütfen tekrar giriş yapın.';
      case 403:
        return 'Bu işlem için yetkiniz bulunmamaktadır.';
      case 404:
        return 'İstenen kaynak bulunamadı.';
      case 409:
        return 'Çakışma hatası. Kayıt zaten mevcut olabilir.';
      case 422:
        return 'Doğrulama hatası. Lütfen girdiğiniz bilgileri kontrol edin.';
      case 429:
        return 'Çok fazla istek gönderdiniz. Lütfen biraz bekleyin.';
      case 500:
        return 'Sunucu hatası. Lütfen daha sonra tekrar deneyin.';
      case 502:
        return 'Sunucu geçici olarak kullanılamıyor.';
      case 503:
        return 'Servis kullanılamıyor. Bakım yapılıyor olabilir.';
      default:
        return 'Bir hata oluştu. (Kod: $statusCode)';
    }
  }

  // ===========================================================================
  // YAPILANDIRMA
  // ===========================================================================

  /// Base URL'i değiştirir (ortam değişikliği için)
  void updateBaseUrl() {
    _dio.options.baseUrl = _config.baseUrl;
  }

  /// Ortamı değiştirir ve Dio'yu günceller
  void setEnvironment(Environment environment) {
    _config.setEnvironment(environment);
    updateBaseUrl();
    
    if (_config.isDebugMode) {
      _config.printConfig();
    }
  }

  /// Mevcut base URL'i döndürür
  String get currentBaseUrl => _dio.options.baseUrl;
}
