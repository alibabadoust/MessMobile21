// ============================================================================
// MESS - Mobil Entegre Akıllı Sıra Takip Sistemi
// Şehir (City) Model Sınıfı
// ============================================================================
// /api/konum/sehirler endpoint'inden dönen veri için model
// ============================================================================

/// Şehir verisini temsil eden model sınıfı
class SehirModel {
  /// Şehir ID'si (veritabanı primary key)
  final int id;
  
  /// Şehir adı (örn: "İstanbul", "Ankara")
  final String ad;
  
  /// Plaka kodu (opsiyonel, örn: "34", "06")
  final String? plakaKodu;
  
  /// Aktif durumu (opsiyonel)
  final bool? aktif;

  /// Constructor
  SehirModel({
    required this.id,
    required this.ad,
    this.plakaKodu,
    this.aktif,
  });

  /// JSON'dan SehirModel oluşturur
  /// API'den gelen veriyi parse etmek için kullanılır
  factory SehirModel.fromJson(Map<String, dynamic> json) {
    return SehirModel(
      id: json['id'] as int,
      ad: json['ad'] as String,
      plakaKodu: json['plaka_kodu'] as String?,
      aktif: json['aktif'] as bool?,
    );
  }

  /// SehirModel'i JSON'a dönüştürür
  /// API'ye veri göndermek için kullanılır
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ad': ad,
      if (plakaKodu != null) 'plaka_kodu': plakaKodu,
      if (aktif != null) 'aktif': aktif,
    };
  }

  /// JSON listesinden SehirModel listesi oluşturur
  static List<SehirModel> fromJsonList(List<dynamic> jsonList) {
    return jsonList
        .map((json) => SehirModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Nesne eşitliği kontrolü
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SehirModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  /// Debug için string temsili
  @override
  String toString() => 'SehirModel(id: $id, ad: $ad)';

  /// Kopyalama metodu (immutable update için)
  SehirModel copyWith({
    int? id,
    String? ad,
    String? plakaKodu,
    bool? aktif,
  }) {
    return SehirModel(
      id: id ?? this.id,
      ad: ad ?? this.ad,
      plakaKodu: plakaKodu ?? this.plakaKodu,
      aktif: aktif ?? this.aktif,
    );
  }
}
