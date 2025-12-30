// ============================================================================
// MESS - Mobil Entegre Akıllı Sıra Takip Sistemi
// Dio Interceptor'ları
// ============================================================================
// Bu dosya, tüm HTTP isteklerine otomatik olarak eklenen middleware'leri içerir.
// ngrok bypass header'ı, loglama ve hata yakalama burada yapılır.
// ============================================================================

import 'package:dio/dio.dart';
import '../config/app_config.dart';

// =============================================================================
// NGROK INTERCEPTOR
// =============================================================================
/// ngrok ücretsiz kullanıcıları için tarayıcı uyarı sayfasını bypass eder.
/// 
/// ngrok ücretsiz planında, ilk ziyarette "Visit Site" butonu olan bir
/// uyarı sayfası gösterilir. Bu header sayesinde API istekleri doğrudan
/// backend'e ulaşır.
/// 
/// Header: ngrok-skip-browser-warning: true
class NgrokInterceptor extends Interceptor {
  final AppConfig _config = AppConfig();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Sadece ngrok kullanılıyorsa header ekle
    if (_config.isUsingNgrok) {
      options.headers['ngrok-skip-browser-warning'] = 'true';
      
      // Opsiyonel: User-Agent header'ı da eklenebilir (bazı durumlarda gerekli)
      options.headers['User-Agent'] = 'MESS-Mobile-App/1.0';
    }
    
    // İsteği devam ettir
    handler.next(options);
  }
}

// =============================================================================
// LOGGING INTERCEPTOR
// =============================================================================
/// Debug modunda tüm HTTP isteklerini ve yanıtlarını konsola yazdırır.
/// Production'da otomatik olarak devre dışı kalır.
class LoggingInterceptor extends Interceptor {
  final AppConfig _config = AppConfig();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (_config.isDebugMode) {
      print('');
      print('╔══════════════════════════════════════════════════════════════╗');
      print('║ 📤 HTTP İSTEĞİ                                               ║');
      print('╠══════════════════════════════════════════════════════════════╣');
      print('║ Method: ${options.method.padRight(52)}║');
      print('║ URL: ${options.uri.toString().padRight(55)}');
      print('║ Headers: ${options.headers.toString().substring(0, 50).padRight(51)}...');
      if (options.data != null) {
        print('║ Body: ${options.data.toString().substring(0, 50).padRight(53)}...');
      }
      print('╚══════════════════════════════════════════════════════════════╝');
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (_config.isDebugMode) {
      print('');
      print('╔══════════════════════════════════════════════════════════════╗');
      print('║ 📥 HTTP YANITI                                               ║');
      print('╠══════════════════════════════════════════════════════════════╣');
      print('║ Status: ${response.statusCode.toString().padRight(52)}║');
      print('║ URL: ${response.requestOptions.uri.toString().padRight(55)}');
      final dataStr = response.data.toString();
      if (dataStr.length > 100) {
        print('║ Data: ${dataStr.substring(0, 100)}...');
      } else {
        print('║ Data: $dataStr');
      }
      print('╚══════════════════════════════════════════════════════════════╝');
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (_config.isDebugMode) {
      print('');
      print('╔══════════════════════════════════════════════════════════════╗');
      print('║ ❌ HTTP HATASI                                               ║');
      print('╠══════════════════════════════════════════════════════════════╣');
      print('║ Type: ${err.type.toString().padRight(54)}║');
      print('║ Message: ${(err.message ?? 'Bilinmeyen hata').padRight(51)}║');
      print('║ URL: ${err.requestOptions.uri.toString().padRight(55)}');
      print('╚══════════════════════════════════════════════════════════════╝');
    }
    handler.next(err);
  }
}

// =============================================================================
// AUTH INTERCEPTOR (İleride kullanılmak üzere)
// =============================================================================
/// JWT token yönetimi için interceptor.
/// Token'ı otomatik olarak header'a ekler ve 401 durumunda yeniler.
class AuthInterceptor extends Interceptor {
  // Token depolama (SharedPreferences veya secure storage kullanılabilir)
  String? _accessToken;

  /// Token'ı ayarlar
  void setToken(String token) {
    _accessToken = token;
  }

  /// Token'ı temizler (logout)
  void clearToken() {
    _accessToken = null;
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Token varsa Authorization header'ına ekle
    if (_accessToken != null && _accessToken!.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $_accessToken';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // 401 Unauthorized - Token geçersiz veya süresi dolmuş
    if (err.response?.statusCode == 401) {
      // TODO: Token yenileme veya logout işlemi
      print('⚠️ Oturum süresi dolmuş. Lütfen tekrar giriş yapın.');
    }
    handler.next(err);
  }
}

// =============================================================================
// RETRY INTERCEPTOR
// =============================================================================
/// Başarısız istekleri otomatik olarak yeniden dener.
/// Ağ hataları ve sunucu hataları (5xx) için çalışır.
class RetryInterceptor extends Interceptor {
  final Dio dio;
  final int maxRetries;

  RetryInterceptor({
    required this.dio,
    this.maxRetries = 3,
  });

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Yeniden deneme yapılabilecek hata türleri
    final shouldRetry = _shouldRetry(err);
    
    if (shouldRetry) {
      final retryCount = err.requestOptions.extra['retryCount'] ?? 0;
      
      if (retryCount < maxRetries) {
        print('🔄 İstek yeniden deneniyor... (${retryCount + 1}/$maxRetries)');
        
        // Retry sayısını artır
        err.requestOptions.extra['retryCount'] = retryCount + 1;
        
        // Kısa bir bekleme süresi (exponential backoff)
        await Future.delayed(Duration(milliseconds: (500 * (retryCount + 1)).toInt()));
        
        try {
          // İsteği tekrar gönder
          final response = await dio.fetch(err.requestOptions);
          return handler.resolve(response);
        } catch (e) {
          // Yeniden deneme de başarısız oldu
          return handler.next(err);
        }
      }
    }
    
    handler.next(err);
  }

  /// Yeniden deneme yapılıp yapılmayacağını kontrol eder
  bool _shouldRetry(DioException err) {
    return err.type == DioExceptionType.connectionTimeout ||
           err.type == DioExceptionType.sendTimeout ||
           err.type == DioExceptionType.receiveTimeout ||
           err.type == DioExceptionType.connectionError ||
           (err.response?.statusCode != null && 
            err.response!.statusCode! >= 500);
  }
}
