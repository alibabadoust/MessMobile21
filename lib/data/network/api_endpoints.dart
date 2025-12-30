// ============================================================================
// MESS - Mobil Entegre Akıllı Sıra Takip Sistemi
// API Endpoint Sabitleri
// ============================================================================
// Tüm API endpoint'leri merkezi olarak burada tanımlanır.
// Yeni endpoint eklemek için bu dosyayı güncelleyin.
// ============================================================================

/// API endpoint'lerini içeren sınıf
/// Tüm endpoint'ler static const olarak tanımlanır
class ApiEndpoints {
  // Private constructor - instantiation önlenir
  ApiEndpoints._();

  // ==========================================================================
  // KONUM (LOCATION) ENDPOINT'LERİ
  // ==========================================================================
  
  /// Şehirler listesi - GET
  /// Response: List<Sehir>
  static const String sehirler = '/api/konum/sehirler';
  
  /// İlçeler listesi - GET (şehir ID'si ile)
  /// Response: List<Ilce>
  static const String ilceler = '/api/konum/ilceler';
  
  /// Hastaneler listesi - GET
  /// Response: List<Hastane>
  static const String hastaneler = '/api/konum/hastaneler';

  // ==========================================================================
  // BİLET (TICKET) ENDPOINT'LERİ
  // ==========================================================================
  
  /// Bilet işlemleri - GET/POST/PUT/DELETE
  /// GET: Tüm biletler veya filtrelenmiş biletler
  /// POST: Yeni bilet oluştur
  static const String biletler = '/api/biletler';
  
  /// Tek bilet detayı - GET/PUT/DELETE
  /// Path parameter: biletId
  static String biletById(int biletId) => '/api/biletler/$biletId';
  
  /// Hasta biletleri - GET
  /// Path parameter: hastaId
  static String hastaBiletleri(int hastaId) => '/api/biletler/hasta/$hastaId';

  // ==========================================================================
  // HASTA (PATIENT) ENDPOINT'LERİ
  // ==========================================================================
  
  /// Hasta işlemleri - GET/POST
  static const String hastalar = '/api/hastalar';
  
  /// Tek hasta detayı - GET/PUT/DELETE
  static String hastaById(int hastaId) => '/api/hastalar/$hastaId';
  
  /// Hasta girişi - POST
  static const String hastaGiris = '/api/hastalar/giris';
  
  /// Hasta kaydı - POST
  static const String hastaKayit = '/api/hastalar/kayit';

  // ==========================================================================
  // POLİKLİNİK (POLYCLINIC) ENDPOINT'LERİ
  // ==========================================================================
  
  /// Poliklinik listesi - GET
  static const String poliklinikler = '/api/poliklinikler';
  
  /// Hastaneye göre poliklinikler - GET
  static String polikliniklerByHastane(int hastaneId) => 
      '/api/poliklinikler/hastane/$hastaneId';

  // ==========================================================================
  // DOKTOR (DOCTOR) ENDPOINT'LERİ
  // ==========================================================================
  
  /// Doktor listesi - GET
  static const String doktorlar = '/api/doktorlar';
  
  /// Poliklinik doktorları - GET
  static String doktorlarByPoliklinik(int poliklinikId) => 
      '/api/doktorlar/poliklinik/$poliklinikId';

  // ==========================================================================
  // SIRA (QUEUE) ENDPOINT'LERİ
  // ==========================================================================
  
  /// Sıra durumu - GET
  static const String siraDurumu = '/api/sira/durum';
  
  /// Anlık sıra bilgisi - GET
  static String siraById(int siraId) => '/api/sira/$siraId';

  // ==========================================================================
  // BİLET TAKİP (TICKET TRACKING) ENDPOINT'LERİ
  // ==========================================================================
  
  /// Bilet takip - POST (telefon ve bağlantı kodu ile)
  static const String biletTakip = '/api/biletler/takip/';
  
  /// Bilet erteleme - POST (bağlantı kodu ve aksiyon ile)
  static const String biletErtele = '/api/biletler/ertele/';

  // ==========================================================================
  // FORM ENDPOINT'LERİ
  // ==========================================================================
  
  /// AI özet ve form verisi kaydetme - POST
  static const String formlar = '/api/formlar/';

  // ==========================================================================
  // OYUN (GAME) ENDPOINT'LERİ
  // ==========================================================================
  
  /// Skor gönderme - POST
  static const String oyunSkor = '/api/oyun/skor';
  
  /// Lider tablosu - GET
  static String oyunLiderler(String oyunAdi) => 
      '/api/oyun/liderler/${Uri.encodeComponent(oyunAdi)}';
}
