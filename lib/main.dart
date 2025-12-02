// main.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'chat_screen.dart'; // اضافه شد
import 'game_screen.dart';


void main() {
  runApp(const MyApp());
}

// ----------------- Theme -----------------
const Color kPrimaryColor = Color(0xFF3B82F6);
const Color kSecondaryColor = Color(0xFF10B981);
const Color kBackgroundColor = Color(0xFFF4F7FC);
const Color kInputBackgroundColor = Colors.white;

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MESS Projesi',
      theme: ThemeData(
        primaryColor: kPrimaryColor,
        scaffoldBackgroundColor: kBackgroundColor,
        fontFamily: 'Roboto',
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: kPrimaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: kInputBackgroundColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          hintStyle: TextStyle(color: Colors.grey[400]),
        ),
      ),
      home: const GirisScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// ----------------- GirisScreen (Login) -----------------
class GirisScreen extends StatefulWidget {
  const GirisScreen({super.key});
  @override
  State<GirisScreen> createState() => _GirisScreenState();
}

class _GirisScreenState extends State<GirisScreen> {
  final TextEditingController _telefonController = TextEditingController();
  final TextEditingController _siraKoduController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    if (_telefonController.text.isEmpty || _siraKoduController.text.isEmpty) {
      _showError("Lütfen tüm alanları doldurun.");
      return;
    }
    if (_siraKoduController.text.length < 11) {
      _showError("Lütfen 11 haneli bilet kodunuzu girin.");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final String apiUrl = "http://10.0.2.2:8000/api/biletler/takip/";
      final body = jsonEncode({
        "baglantikodu": _siraKoduController.text,
        "telefon": _telefonController.text
      });

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        if (data == null || data is! Map<String, dynamic>) {
          _showError("Sunucudan beklenmeyen veri alındı.");
          return;
        }

        if (!data.containsKey('biletid')) {
          _showError("Sunucudan 'biletid' alınamadı.");
          return;
        }
        if (!data.containsKey('bolum_adi')) {
          _showError("Sunucudan 'bolum_adi' alınamadı.");
          return;
        }

        final int biletId = (data['biletid'] is int) ? data['biletid'] : int.tryParse("${data['biletid']}") ?? 0;
        final String bolumAdi = "${data['bolum_adi']}";

        final Map<String, dynamic> biletDetay = {
          "durum": data['durum'] ?? "Bilinmiyor",
          "sizin_numaraniz": data['sizin_numaraniz'] ?? 0,
          "mevcut_sira": data['mevcut_sira'] ?? 0,
          "kalan_hasta": data['kalan_hasta'] ?? 0,
          "doktor_adi": data['doktor_adi'] ?? "-",
          "tahmini_bekleme_suresi": data['tahmini_bekleme_suresi'] ?? "-",
          "giris_zamani": data['giris_zamani'] ?? DateTime.now().toIso8601String(),
          "hastaid": (data['hastaid'] is int) ? data['hastaid'] : int.tryParse("${data['hastaid']}") ?? 0,
        };

        if (!mounted) return;
        // --- اینجا baglantiKodu رو هم می‌فرستیم تا دکمه‌های Ertele بتونن ازش استفاده کنن
        final String baglantiKodu = _siraKoduController.text.trim();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SiraTakipScreen(
              biletDetay: biletDetay,
              biletId: biletId,
              bolumAdi: bolumAdi,
              baglantiKodu: baglantiKodu,
            ),
          ),
        );
      } else if (response.statusCode == 404) {
        _showError("Bu koda ait aktif bir bilet bulunamadı.");
      } else if (response.statusCode == 403) {
        _showError("Telefon numarası bilet ile eşleşmiyor.");
      } else {
        _showError("Hata: ${response.statusCode}");
      }
    } catch (e) {
      _showError("Bağlantı hatası: ${e.toString()}");
    } finally {
      if (mounted) setState(() {
        _isLoading = false;
      });
    }
  }

  void _navigateToKayit() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const KayitScreen()),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sıra Takibi"),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              const Icon(Icons.medical_services, size: 80, color: kPrimaryColor),
              const SizedBox(height: 40),
              const Text("Telefon Numarası", style: TextStyle(fontSize: 14, color: Colors.black54)),
              const SizedBox(height: 8),
              TextField(
                controller: _telefonController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  hintText: "0(555) 555-55-55",
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
              const SizedBox(height: 20),
              const Text("Sıra Takip Kodu", style: TextStyle(fontSize: 14, color: Colors.black54)),
              const SizedBox(height: 8),
              TextField(
                controller: _siraKoduController,
                keyboardType: TextInputType.text,
                maxLength: 11,
                decoration: const InputDecoration(
                  hintText: "11 Haneli Bilet Kodunuz",
                  prefixIcon: Icon(Icons.confirmation_number_outlined),
                  counterText: "",
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _login,
                child: _isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text(
                  "Sıra Takip Et",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Kaydınız yok mu? ", style: TextStyle(color: Colors.black54)),
                  GestureDetector(
                    onTap: _navigateToKayit,
                    child: const Text(
                      "Kayıt Olun",
                      style: TextStyle(
                        color: kPrimaryColor,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _telefonController.dispose();
    _siraKoduController.dispose();
    super.dispose();
  }
}

// ----------------- SiraTakipScreen with delay buttons -----------------
class SiraTakipScreen extends StatefulWidget {
  final Map<String, dynamic> biletDetay;
  final int biletId;
  final String bolumAdi;
  final String baglantiKodu; // اضافه شد

  const SiraTakipScreen({
    super.key,
    required this.biletDetay,
    required this.biletId,
    required this.bolumAdi,
    required this.baglantiKodu,
  });

  @override
  State<SiraTakipScreen> createState() => _SiraTakipScreenState();
}

class _SiraTakipScreenState extends State<SiraTakipScreen> {
  int? _selectedDelayMinutes;
  bool _isErteleLoading = false;

  // تابعی که درخواست POST به API ertele می‌فرستد
  Future<void> _erteleBilet(String aksiyon) async {
    if (_isErteleLoading) return;

    setState(() {
      _isErteleLoading = true;
    });

    final String apiUrl = "http://10.0.2.2:8000/api/biletler/ertele/";
    final body = jsonEncode({
      "baglantikodu": widget.baglantiKodu,
      "aksiyon": aksiyon,
    });

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      if (response.statusCode == 200) {
        // موفقیت — پاسخ سرور را می‌گیریم و پیام می‌دهیم
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        String yeniKod = data['baglantikodu'] ?? widget.baglantiKodu;
        String mesaj = "İşlem başarılı. Yeni bilet kodu: $yeniKod";
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(mesaj), backgroundColor: Colors.green),
        );
        // اگر خواستی صفحه رو رفرش کنی، اینجا انجام بده
        // برای مثال: بازخوانی صفحه یا برگردوندن data به صفحه قبلی
      } else if (response.statusCode == 404) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Aktif bilet bulunamadı veya işlem yapılmış."), backgroundColor: Colors.red),
        );
      } else if (response.statusCode == 400) {
        final err = utf8.decode(response.bodyBytes);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Geçersiz işlem: $err"), backgroundColor: Colors.red),
        );
      } else {
        final err = utf8.decode(response.bodyBytes);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Sunucu Hatası: ${response.statusCode} - $err"), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Bağlantı hatası: ${e.toString()}"), backgroundColor: Colors.red),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isErteleLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final String durum = "${widget.biletDetay['durum']}";
    final int sizinNumaraniz = (widget.biletDetay['sizin_numaraniz'] is int) ? widget.biletDetay['sizin_numaraniz'] : int.tryParse("${widget.biletDetay['sizin_numaraniz']}") ?? 0;
    final int mevcutSira = (widget.biletDetay['mevcut_sira'] is int) ? widget.biletDetay['mevcut_sira'] : int.tryParse("${widget.biletDetay['mevcut_sira']}") ?? 0;
    final int kalanHasta = (widget.biletDetay['kalan_hasta'] is int) ? widget.biletDetay['kalan_hasta'] : int.tryParse("${widget.biletDetay['kalan_hasta']}") ?? 0;
    final String doktorAdi = "${widget.biletDetay['doktor_adi']}";
    final String tahminiSure = "${widget.biletDetay['tahmini_bekleme_suresi']}";
    final DateTime girisZamani = DateTime.tryParse("${widget.biletDetay['giris_zamani']}") ?? DateTime.now();
    final String formattedGirisZamani = DateFormat('dd.MM.yyyy HH:mm').format(girisZamani);

    double progressValue = 0.0;
    if (sizinNumaraniz > 0) {
      progressValue = (mevcutSira / sizinNumaraniz).clamp(0.0, 1.0);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Sıra Takibi"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                // --- تغییر از اینجا شروع می‌شود ---
                child: SingleChildScrollView( // ۱. این ویجت اضافه شد
                  scrollDirection: Axis.horizontal, // ۲. جهت اسکرول افقی شد
                  child: Row(
                    children: [
                      const Text("Ertelenecek Süre: ", style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      _delayButton(15),
                      const SizedBox(width: 8),
                      _delayButton(30),
                      const SizedBox(width: 8),
                      _delayButton(45),
                      const SizedBox(width: 12),
                      if (_selectedDelayMinutes != null)
                        Text("Seçildi: ${_selectedDelayMinutes} dk", style: const TextStyle(color: Colors.black54)),
                    ],
                  ),
                ),
                // --- پایان تغییر ---
              ),
            ),
            Card(
              color: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Text(
                      durum.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: kPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatColumn("Mevcut Sıra", mevcutSira.toString()),
                        _buildStatColumn("Sizin Numaranız", sizinNumaraniz.toString()),
                        _buildStatColumn("Kalan Hasta", kalanHasta.toString()),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildInfoRow("Bölüm", widget.bolumAdi),
                    _buildInfoRow("Doktor", doktorAdi),
                    _buildInfoRow("Giriş Zamanı", formattedGirisZamani),
                    _buildInfoRow("Tahmini Bekleme Süresi", tahminiSure),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              color: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Mevcut: $mevcutSira", style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text("Sizin Numaranız: $sizinNumaraniz", style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text("Kalan Hasta: $kalanHasta", style: const TextStyle(color: Colors.grey)),
                    const SizedBox(height: 16),
                    LinearProgressIndicator(
                      value: progressValue,
                      minHeight: 10,
                      backgroundColor: Colors.grey[200],
                      valueColor: const AlwaysStoppedAnimation(kPrimaryColor),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(
                      biletId: widget.biletId,
                      bolumAdi: widget.bolumAdi,
                    ),
                  ),
                );
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.description_outlined),
                  SizedBox(width: 8),
                  Text(" Ön Bilgi Formu Doldur "),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                final dynamic rawHastaId = widget.biletDetay['hastaid'];
                final int? hastaId = (rawHastaId is int)
                    ? rawHastaId
                    : int.tryParse(rawHastaId.toString());

                if (hastaId == null || hastaId == 0) {
                  print("❌ HATA: Geçerli bir HastaID bulunamadı!");
                  print("➡️ Gelen bilet verileri:");
                  print(widget.biletDetay);
                  return;
                }

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GameMenuScreen(hastaId: hastaId),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: kSecondaryColor,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.gamepad_outlined),
                  SizedBox(width: 8),
                  Text("Oyun Oyna"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _delayButton(int minutes) {
    final bool selected = _selectedDelayMinutes == minutes;
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: selected ? kPrimaryColor : Colors.white,
        foregroundColor: selected ? Colors.white : Colors.black,
        elevation: selected ? 4 : 0,
        side: BorderSide(color: kPrimaryColor.withOpacity(0.7)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      ),
      onPressed: _isErteleLoading ? null : () async {
        setState(() {
          if (_selectedDelayMinutes == minutes) {
            _selectedDelayMinutes = null;
          } else {
            _selectedDelayMinutes = minutes;
          }
        });

        if (_selectedDelayMinutes != null) {
          // confirm and call API
          final aksiyon = "${_selectedDelayMinutes}_dk";
          final confirm = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text("Onay"),
              content: Text("$minutes dakika ertelesin mi?"),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Hayır")),
                TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Evet")),
              ],
            ),
          );

          if (confirm == true) {
            await _erteleBilet(aksiyon);
          } else {
            // kullanıcı onaylamadı, seçim kaldırılsın
            setState(() {
              _selectedDelayMinutes = null;
            });
          }
        }
      },
      child: _isErteleLoading ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text("$minutes dk"),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: kPrimaryColor)),
      ],
    );
  }
}

// ----------------- KayitScreen (Register) -----------------
// (بقیه‌ی فایل بدون تغییر — از کد شما کپی شده)
class KayitScreen extends StatefulWidget {
  const KayitScreen({super.key});
  @override
  State<KayitScreen> createState() => _KayitScreenState();
}

class _KayitScreenState extends State<KayitScreen> {
  final String baseUrl = "http://10.0.2.2:8000/api/hastalar/";
  final TextEditingController _adsoyadController = TextEditingController();
  final TextEditingController _tcController = TextEditingController();
  final TextEditingController _dogumController = TextEditingController();
  final TextEditingController _telefonController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _sifreController = TextEditingController();
  final TextEditingController _sifreTekrarController = TextEditingController();
  bool _sifreGizli = true;
  bool _sifreTekrarGizli = true;
  bool _sozlesmeKabul = false;
  bool _isLoading = false;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime(2000, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (selectedDate != null) {
      String formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);
      setState(() {
        _dogumController.text = formattedDate;
      });
    }
  }

  Future<void> kayitOl() async {
    if (_adsoyadController.text.isEmpty ||
        _tcController.text.isEmpty ||
        _dogumController.text.isEmpty ||
        _telefonController.text.isEmpty ||
        _sifreController.text.isEmpty ||
        _sifreTekrarController.text.isEmpty) {
      _showError("Lütfen tüm zorunlu alanları doldurun");
      return;
    }
    if (_sifreController.text != _sifreTekrarController.text) {
      _showError("Şifreler eşleşmiyor");
      return;
    }
    if (!_sozlesmeKabul) {
      _showError("Lütfen üyelik sözleşmesini kabul edin");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      Map<String, dynamic> requestBody = {
        "adsoyad": _adsoyadController.text,
        "tckimlik": _tcController.text,
        "sifre": _sifreController.text,
        "telefon": _telefonController.text,
        "dogumtarihi": _dogumController.text,
      };
      if (_emailController.text.isNotEmpty) {
        requestBody["email"] = _emailController.text;
      }
      final body = jsonEncode(requestBody);

      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      if (response.statusCode == 200) {
        _showSuccess("Kayıt başarılı!");
        _temizle();
      } else if (response.statusCode == 400) {
        final error = jsonDecode(utf8.decode(response.bodyBytes));
        _showError(error['detail'] ?? "Hata 400");
      } else if (response.statusCode == 422) {
        _showError("Veri doğrulama hatası. (error 422)");
      } else {
        _showError("Kayıt başarısız: ${response.statusCode}");
      }
    } catch (e) {
      _showError("Bağlantı hatası: ${e.toString()}");
    } finally {
      if (mounted) setState(() {
        _isLoading = false;
      });
    }
  }

  void _temizle() {
    _adsoyadController.clear();
    _tcController.clear();
    _dogumController.clear();
    _telefonController.clear();
    _emailController.clear();
    _sifreController.clear();
    _sifreTekrarController.clear();
    setState(() {
      _sozlesmeKabul = false;
    });
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Yeni Kayıt Oluştur"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                const Text(
                  "Kayıt Ol",
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 32),
                const Text("Ad Soyad (Zorunlu)", style: TextStyle(fontSize: 14, color: Colors.black54)),
                const SizedBox(height: 8),
                TextField(controller: _adsoyadController, decoration: const InputDecoration(hintText: "Adınızı ve Soyadınızı Giriniz", prefixIcon: Icon(Icons.person_outline))),
                const SizedBox(height: 20),
                const Text("TC Kimlik Numarası (Zorunlu)", style: TextStyle(fontSize: 14, color: Colors.black54)),
                const SizedBox(height: 8),
                TextField(controller: _tcController, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: "T.C Kimlik Numaranızı Giriniz", prefixIcon: Icon(Icons.person_outline))),
                const SizedBox(height: 20),
                const Text("Doğum Tarihi (Zorunlu)", style: TextStyle(fontSize: 14, color: Colors.black54)),
                const SizedBox(height: 8),
                TextField(controller: _dogumController, readOnly: true, decoration: const InputDecoration(hintText: "Doğum Tarihinizi Seçiniz", prefixIcon: Icon(Icons.calendar_today_outlined)), onTap: () => _selectDate(context)),
                const SizedBox(height: 20),
                const Text("Telefon Numarası (Zorunlu)", style: TextStyle(fontSize: 14, color: Colors.black54)),
                const SizedBox(height: 8),
                TextField(controller: _telefonController, keyboardType: TextInputType.phone, decoration: const InputDecoration(hintText: "0(555) 555-55-55", prefixIcon: Icon(Icons.phone_outlined))),
                const SizedBox(height: 20),
                const Text("E-posta (Opsiyonel)", style: TextStyle(fontSize: 14, color: Colors.black54)),
                const SizedBox(height: 8),
                TextField(controller: _emailController, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(hintText: "E-Posta Adresi Giriniz", prefixIcon: Icon(Icons.email_outlined))),
                const SizedBox(height: 20),
                const Text("Şifre (Zorunlu)", style: TextStyle(fontSize: 14, color: Colors.black54)),
                const SizedBox(height: 8),
                TextField(controller: _sifreController, obscureText: _sifreGizli, decoration: InputDecoration(hintText: "Şifrenizi Giriniz", prefixIcon: const Icon(Icons.lock_outlined), suffixIcon: IconButton(icon: Icon(_sifreGizli ? Icons.visibility_outlined : Icons.visibility_off_outlined), onPressed: () => setState(() => _sifreGizli = !_sifreGizli)))),
                const SizedBox(height: 20),
                const Text("Şifre Tekrar (Zorunlu)", style: TextStyle(fontSize: 14, color: Colors.black54)),
                const SizedBox(height: 8),
                TextField(controller: _sifreTekrarController, obscureText: _sifreTekrarGizli, decoration: InputDecoration(hintText: "Şifrenizi Tekrar Giriniz", prefixIcon: const Icon(Icons.lock_outlined), suffixIcon: IconButton(icon: Icon(_sifreTekrarGizli ? Icons.visibility_outlined : Icons.visibility_off_outlined), onPressed: () => setState(() => _sifreTekrarGizli = !_sifreTekrarGizli)))),
                const SizedBox(height: 20),
                Row(children: [
                  Checkbox(value: _sozlesmeKabul, onChanged: (value) => setState(() => _sozlesmeKabul = value ?? false), activeColor: kPrimaryColor),
                  Expanded(child: RichText(text: const TextSpan(style: TextStyle(color: Colors.black87, fontSize: 13), children: [TextSpan(text: "Üyelik Sözleşmesini Kabul Ediniz.\n", style: TextStyle(color: kPrimaryColor, decoration: TextDecoration.underline)), TextSpan(text: "KVKK Aydınlatma Metni")])))
                ]),
                const SizedBox(height: 24),
                SizedBox(height: 54, child: ElevatedButton(onPressed: _isLoading ? null : kayitOl, child: _isLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text("Kayıt Ol", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)))),
                const SizedBox(height: 20),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Text("Zaten bir hesabınız var mı? ", style: TextStyle(color: Colors.black54)),
                  GestureDetector(onTap: () => Navigator.pop(context), child: const Text("GİRİŞ YAP", style: TextStyle(color: kPrimaryColor, fontWeight: FontWeight.bold))),
                ]),
                const SizedBox(height: 40),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: const [Icon(Icons.medical_services, color: Colors.blue, size: 30), SizedBox(width: 8), Text("mergentech", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.blue))]),
                const SizedBox(height: 8),
                const Text("© Mergen Yazılım 2025", textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.black45)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _adsoyadController.dispose();
    _tcController.dispose();
    _dogumController.dispose();
    _telefonController.dispose();
    _emailController.dispose();
    _sifreController.dispose();
    _sifreTekrarController.dispose();
    super.dispose();
  }
}
