// ============================================================================
// MESS - Mobil Entegre Akıllı Sıra Takip Sistemi
// Bilet (Ticket) Model Sınıfı
// ============================================================================
// /api/biletler endpoint'i için model
// Hasta randevu/sıra biletlerini temsil eder
// ============================================================================

/// Bilet durumunu tanımlayan enum
enum BiletDurumu {
  beklemede,    // Sırada bekliyor
  cagrildi,     // Hasta çağrıldı
  muayenede,    // Muayene yapılıyor
  tamamlandi,   // İşlem tamamlandı
  iptal,        // Bilet iptal edildi
}

/// String'den BiletDurumu enum'una dönüştürme
BiletDurumu biletDurumuFromString(String? durum) {
  switch (durum?.toLowerCase()) {
    case 'beklemede':
      return BiletDurumu.beklemede;
    case 'cagrildi':
      return BiletDurumu.cagrildi;
    case 'muayenede':
      return BiletDurumu.muayenede;
    case 'tamamlandi':
      return BiletDurumu.tamamlandi;
    case 'iptal':
      return BiletDurumu.iptal;
    default:
      return BiletDurumu.beklemede;
  }
}

/// BiletDurumu enum'undan String'e dönüştürme
String biletDurumuToString(BiletDurumu durum) {
  return durum.name;
}

/// Bilet verisini temsil eden model sınıfı
class BiletModel {
  /// Bilet ID'si (yeni bilet için null)
  final int? id;
  
  /// Hasta ID'si
  final int hastaid;
  
  /// Poliklinik ID'si
  final int poliklinikid;
  
  /// Doktor ID'si (opsiyonel - doktor seçimi yapılmadıysa null)
  final int? doktorid;
  
  /// Randevu/bilet tarihi
  final DateTime tarih;
  
  /// Sıra numarası (backend tarafından atanır)
  final int? siraNo;
  
  /// Bilet durumu
  final BiletDurumu durum;
  
  /// Tahmini bekleme süresi (dakika cinsinden)
  final int? tahminiBeklemeSuresi;
  
  /// Oluşturulma zamanı
  final DateTime? olusturulmaTarihi;
  
  /// Güncellenme zamanı
  final DateTime? guncellenmeTarihi;
  
  /// Notlar (opsiyonel)
  final String? notlar;

  /// Constructor
  BiletModel({
    this.id,
    required this.hastaid,
    required this.poliklinikid,
    this.doktorid,
    required this.tarih,
    this.siraNo,
    this.durum = BiletDurumu.beklemede,
    this.tahminiBeklemeSuresi,
    this.olusturulmaTarihi,
    this.guncellenmeTarihi,
    this.notlar,
  });

  /// JSON'dan BiletModel oluşturur
  factory BiletModel.fromJson(Map<String, dynamic> json) {
    return BiletModel(
      id: json['id'] as int?,
      hastaid: json['hastaid'] as int,
      poliklinikid: json['poliklinikid'] as int,
      doktorid: json['doktorid'] as int?,
      tarih: DateTime.parse(json['tarih'] as String),
      siraNo: json['sira_no'] as int?,
      durum: biletDurumuFromString(json['durum'] as String?),
      tahminiBeklemeSuresi: json['tahmini_bekleme_suresi'] as int?,
      olusturulmaTarihi: json['olusturulma_tarihi'] != null
          ? DateTime.parse(json['olusturulma_tarihi'] as String)
          : null,
      guncellenmeTarihi: json['guncellenme_tarihi'] != null
          ? DateTime.parse(json['guncellenme_tarihi'] as String)
          : null,
      notlar: json['notlar'] as String?,
    );
  }

  /// BiletModel'i JSON'a dönüştürür (API'ye gönderim için)
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'hastaid': hastaid,
      'poliklinikid': poliklinikid,
      if (doktorid != null) 'doktorid': doktorid,
      'tarih': tarih.toIso8601String(),
      if (siraNo != null) 'sira_no': siraNo,
      'durum': biletDurumuToString(durum),
      if (tahminiBeklemeSuresi != null) 
        'tahmini_bekleme_suresi': tahminiBeklemeSuresi,
      if (notlar != null) 'notlar': notlar,
    };
  }

  /// Yeni bilet oluşturmak için minimal JSON (POST için)
  Map<String, dynamic> toCreateJson() {
    return {
      'hastaid': hastaid,
      'poliklinikid': poliklinikid,
      if (doktorid != null) 'doktorid': doktorid,
      'tarih': tarih.toIso8601String(),
      if (notlar != null) 'notlar': notlar,
    };
  }

  /// JSON listesinden BiletModel listesi oluşturur
  static List<BiletModel> fromJsonList(List<dynamic> jsonList) {
    return jsonList
        .map((json) => BiletModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Nesne eşitliği kontrolü
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BiletModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  /// Debug için string temsili
  @override
  String toString() {
    return 'BiletModel(id: $id, hastaid: $hastaid, poliklinikid: $poliklinikid, '
           'siraNo: $siraNo, durum: ${durum.name})';
  }

  /// Kopyalama metodu (immutable update için)
  BiletModel copyWith({
    int? id,
    int? hastaid,
    int? poliklinikid,
    int? doktorid,
    DateTime? tarih,
    int? siraNo,
    BiletDurumu? durum,
    int? tahminiBeklemeSuresi,
    DateTime? olusturulmaTarihi,
    DateTime? guncellenmeTarihi,
    String? notlar,
  }) {
    return BiletModel(
      id: id ?? this.id,
      hastaid: hastaid ?? this.hastaid,
      poliklinikid: poliklinikid ?? this.poliklinikid,
      doktorid: doktorid ?? this.doktorid,
      tarih: tarih ?? this.tarih,
      siraNo: siraNo ?? this.siraNo,
      durum: durum ?? this.durum,
      tahminiBeklemeSuresi: tahminiBeklemeSuresi ?? this.tahminiBeklemeSuresi,
      olusturulmaTarihi: olusturulmaTarihi ?? this.olusturulmaTarihi,
      guncellenmeTarihi: guncellenmeTarihi ?? this.guncellenmeTarihi,
      notlar: notlar ?? this.notlar,
    );
  }

  /// Biletin aktif olup olmadığını kontrol eder
  bool get aktifMi => 
      durum == BiletDurumu.beklemede || 
      durum == BiletDurumu.cagrildi || 
      durum == BiletDurumu.muayenede;

  /// Biletin tamamlanıp tamamlanmadığını kontrol eder
  bool get tamamlandiMi => durum == BiletDurumu.tamamlandi;

  /// Biletin iptal edilip edilmediğini kontrol eder
  bool get iptalMi => durum == BiletDurumu.iptal;
}
