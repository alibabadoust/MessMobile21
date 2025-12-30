// ============================================================================
// MESS - Mobil Entegre Akıllı Sıra Takip Sistemi
// Uygulama Yapılandırma Dosyası (App Configuration)
// ============================================================================
// Bu dosya, uygulama ortamları arasında geçiş yapmayı kolaylaştırır.
// Emülatör için localhost, fiziksel cihaz için ngrok URL'i kullanılır.
// ============================================================================

import 'dart:io';

/// Uygulama ortamlarını tanımlayan enum
/// Development: Geliştirme ortamı (localhost)
/// Staging: Test ortamı (ngrok)
/// Production: Üretim ortamı (gerçek sunucu)
enum Environment {
  development,
  staging,
  production,
}

/// Uygulama yapılandırma sınıfı
/// Singleton pattern kullanılarak tek bir instance oluşturulur
class AppConfig {
  // Singleton instance
  static final AppConfig _instance = AppConfig._internal();
  factory AppConfig() => _instance;
  AppConfig._internal();

  // Varsayılan ortam - production (Vercel) olarak ayarlandı
  Environment _environment = Environment.production;

  // ==========================================================================
  // URL YAPILANDIRMASI
  // ==========================================================================
  
  /// Android Emülatör için localhost adresi
  /// Android emülatör 10.0.2.2 adresini host makinenin localhost'u olarak görür
  static const String _androidEmulatorUrl = 'http://10.0.2.2:8000';
  
  /// iOS Simulator için localhost adresi
  static const String _iosSimulatorUrl = 'http://localhost:8000';
  
  /// ngrok static domain URL'i
  /// Fiziksel cihaz testleri için kullanılır
  static const String _ngrokUrl = 'https://unignoring-punctate-harold.ngrok-free.dev';
  
  /// Production sunucu URL'i (Vercel deployment)
  static const String _productionUrl = 'https://backend-siralamahastanesi.vercel.app';

  // ==========================================================================
  // TIMEOUT AYARLARI (milisaniye cinsinden)
  // ==========================================================================
  
  /// Bağlantı zaman aşımı - 15 saniye (production standard)
  static const int connectTimeout = 15000;
  
  /// Veri alma zaman aşımı - 15 saniye (production standard)
  static const int receiveTimeout = 15000;
  
  /// Veri gönderme zaman aşımı - 15 saniye (production standard)
  static const int sendTimeout = 15000;

  // ==========================================================================
  // GETTER VE SETTER METODLARI
  // ==========================================================================

  /// Mevcut ortamı döndürür
  Environment get environment => _environment;

  /// Ortamı değiştirir
  void setEnvironment(Environment env) {
    _environment = env;
  }

  /// Mevcut ortama göre base URL döndürür
  /// Platform tespiti yaparak uygun adresi seçer
  String get baseUrl {
    switch (_environment) {
      case Environment.development:
        // Geliştirme ortamında platform kontrolü yapılır
        return _getLocalhostUrl();
      case Environment.staging:
        // Staging ortamında ngrok URL kullanılır
        return _ngrokUrl;
      case Environment.production:
        // Üretim ortamında gerçek sunucu URL kullanılır
        return _productionUrl;
    }
  }

  /// ngrok kullanılıp kullanılmadığını kontrol eder
  /// ngrok header'ı eklemek için kullanılır
  bool get isUsingNgrok => _environment == Environment.staging;

  /// Debug modu kontrolü
  bool get isDebugMode => _environment != Environment.production;

  // ==========================================================================
  // YARDIMCI METODLAR
  // ==========================================================================

  /// Platform'a göre localhost URL'ini belirler
  String _getLocalhostUrl() {
    try {
      if (Platform.isAndroid) {
        return _androidEmulatorUrl;
      } else if (Platform.isIOS) {
        return _iosSimulatorUrl;
      } else {
        // Windows, macOS, Linux için
        return 'http://localhost:8000';
      }
    } catch (e) {
      // Platform tespit edilemezse Android varsayılan
      return _androidEmulatorUrl;
    }
  }

  /// Yapılandırma bilgilerini yazdırır (debug için)
  void printConfig() {
    print('╔══════════════════════════════════════════════════════════════╗');
    print('║           MESS API YAPILANDIRMASI                            ║');
    print('╠══════════════════════════════════════════════════════════════╣');
    print('║ Ortam: ${_environment.name.padRight(52)}║');
    print('║ Base URL: ${baseUrl.padRight(50)}║');
    print('║ ngrok Aktif: ${isUsingNgrok.toString().padRight(47)}║');
    print('║ Debug Modu: ${isDebugMode.toString().padRight(48)}║');
    print('╚══════════════════════════════════════════════════════════════╝');
  }
}
