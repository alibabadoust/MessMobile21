// ============================================================================
// MESS - Mobil Entegre Akıllı Sıra Takip Sistemi
// Genel API Yanıt Sarmalayıcı (Response Wrapper)
// ============================================================================
// API yanıtlarını standart bir formatta sarmalar
// Başarılı/başarısız durumları ve hataları yönetir
// ============================================================================

/// Genel API yanıt sarmalayıcı sınıfı
/// T: Yanıt verisinin tipi
class ApiResponse<T> {
  /// Yanıt verisi (başarılı durumda dolu)
  final T? data;
  
  /// Hata mesajı (başarısız durumda dolu)
  final String? error;
  
  /// İşlem başarılı mı?
  final bool success;
  
  /// HTTP durum kodu
  final int? statusCode;
  
  /// Ek meta veriler (sayfalama vb.)
  final Map<String, dynamic>? meta;

  /// Başarılı yanıt constructor'ı
  ApiResponse.success({
    required this.data,
    this.statusCode,
    this.meta,
  })  : success = true,
        error = null;

  /// Başarısız yanıt constructor'ı
  ApiResponse.failure({
    required this.error,
    this.statusCode,
    this.data,
    this.meta,
  }) : success = false;

  /// Yükleniyor durumu için factory
  factory ApiResponse.loading() {
    return ApiResponse._(
      data: null,
      error: null,
      success: false,
      statusCode: null,
      meta: {'loading': true},
    );
  }

  /// Private constructor
  ApiResponse._({
    this.data,
    this.error,
    required this.success,
    this.statusCode,
    this.meta,
  });

  /// Yanıtın yüklenme durumunda olup olmadığını kontrol eder
  bool get isLoading => meta?['loading'] == true;

  /// Yanıtın hata durumunda olup olmadığını kontrol eder
  bool get hasError => error != null && error!.isNotEmpty;

  /// Yanıtın veri içerip içermediğini kontrol eder
  bool get hasData => data != null;

  /// Debug için string temsili
  @override
  String toString() {
    if (success) {
      return 'ApiResponse.success(data: $data, statusCode: $statusCode)';
    } else {
      return 'ApiResponse.failure(error: $error, statusCode: $statusCode)';
    }
  }

  /// Veriyi dönüştürme metodu
  /// Başka bir tipe map etmek için kullanılır
  ApiResponse<R> map<R>(R Function(T data) mapper) {
    if (success && data != null) {
      return ApiResponse.success(
        data: mapper(data as T),
        statusCode: statusCode,
        meta: meta,
      );
    } else {
      return ApiResponse.failure(
        error: error,
        statusCode: statusCode,
        meta: meta,
      );
    }
  }

  /// Veriyi elde etme veya varsayılan değer döndürme
  T getOrElse(T defaultValue) {
    return data ?? defaultValue;
  }

  /// Başarılı durumda callback çalıştırma
  void whenSuccess(void Function(T data) callback) {
    if (success && data != null) {
      callback(data as T);
    }
  }

  /// Başarısız durumda callback çalıştırma
  void whenFailure(void Function(String error) callback) {
    if (!success && error != null) {
      callback(error!);
    }
  }

  /// Pattern matching benzeri işlem
  R when<R>({
    required R Function(T data) success,
    required R Function(String error) failure,
    R Function()? loading,
  }) {
    if (isLoading && loading != null) {
      return loading();
    } else if (this.success && data != null) {
      return success(data as T);
    } else {
      return failure(error ?? 'Bilinmeyen hata');
    }
  }
}

/// Sayfalama meta verisi
class PaginationMeta {
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final int itemsPerPage;
  final bool hasNextPage;
  final bool hasPreviousPage;

  PaginationMeta({
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.itemsPerPage,
  })  : hasNextPage = currentPage < totalPages,
        hasPreviousPage = currentPage > 1;

  factory PaginationMeta.fromJson(Map<String, dynamic> json) {
    return PaginationMeta(
      currentPage: json['current_page'] as int,
      totalPages: json['total_pages'] as int,
      totalItems: json['total_items'] as int,
      itemsPerPage: json['items_per_page'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'current_page': currentPage,
      'total_pages': totalPages,
      'total_items': totalItems,
      'items_per_page': itemsPerPage,
      'has_next_page': hasNextPage,
      'has_previous_page': hasPreviousPage,
    };
  }
}

/// Sayfalanmış API yanıtı
class PaginatedResponse<T> {
  final List<T> items;
  final PaginationMeta pagination;

  PaginatedResponse({
    required this.items,
    required this.pagination,
  });

  /// Boş sayfa mı?
  bool get isEmpty => items.isEmpty;

  /// Eleman sayısı
  int get length => items.length;
}
