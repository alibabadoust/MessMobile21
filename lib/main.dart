// main.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'chat_screen.dart';
import 'game_screen.dart';
import 'app_theme.dart';
import 'home_screen.dart';

void main() {
  runApp(const MyApp());
}

// ----------------- App Entry Point -----------------
class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hastane Randevu',
      theme: CalmTheme.lightTheme,
      home: const QueueTrackingEntryScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// Legacy color constants for backward compatibility with existing screens
const Color kPrimaryColor = CalmColors.medicalBlue;
const Color kSecondaryColor = CalmColors.mintGreen;
const Color kBackgroundColor = CalmColors.softGray;
const Color kInputBackgroundColor = CalmColors.pureWhite;


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

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B6B).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.logout_rounded, color: Color(0xFFFF6B6B)),
            ),
            const SizedBox(width: 12),
            const Text("Çıkış Yap"),
          ],
        ),
        content: const Text("Oturumunuzu kapatmak istediğinizden emin misiniz?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("İptal"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              // Replace entire stack with fresh login screen (clears form fields)
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const QueueTrackingEntryScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B6B),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text("Çıkış Yap"),
          ),
        ],
      ),
    );
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
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text("Sıra Takibi"),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2C3E50),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Color(0xFFFF6B6B)),
            tooltip: 'Çıkış Yap',
            onPressed: () => _showLogoutDialog(),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: [
              // ═══════════════════════════════════════════════════════════
              // DELAY SECTION - Modern Redesign
              // ═══════════════════════════════════════════════════════════
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF1976D2).withOpacity(0.1),
                      const Color(0xFFE3F2FD),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF1976D2).withOpacity(0.15)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1976D2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.schedule_rounded, color: Colors.white, size: 18),
                        ),
                        const SizedBox(width: 10),
                        const Text("Sıranızı Erteleyin", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF2C3E50))),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: _buildModernDelayButton(15)),
                        const SizedBox(width: 8),
                        Expanded(child: _buildModernDelayButton(30)),
                        const SizedBox(width: 8),
                        Expanded(child: _buildModernDelayButton(45)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // STATUS CARD - Compact
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Status Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF1976D2), Color(0xFF42A5F5)]),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          durum.toUpperCase(),
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Stats Row
                      Row(
                        children: [
                          Expanded(child: _buildModernStatCard("Mevcut", mevcutSira.toString(), const Color(0xFF26A69A))),
                          const SizedBox(width: 8),
                          Expanded(child: _buildModernStatCard("Numaranız", sizinNumaraniz.toString(), const Color(0xFF1976D2))),
                          const SizedBox(width: 8),
                          Expanded(child: _buildModernStatCard("Kalan", kalanHasta.toString(), const Color(0xFFFF9800))),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Info Rows
                      _buildModernInfoRow(Icons.local_hospital_rounded, "Bölüm", widget.bolumAdi),
                      _buildModernInfoRow(Icons.person_rounded, "Doktor", doktorAdi),
                      _buildModernInfoRow(Icons.access_time_rounded, "Giriş", formattedGirisZamani),
                      _buildModernInfoRow(Icons.hourglass_bottom_rounded, "Bekleme", tahminiSure),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // ACTION BUTTONS - Compact Row
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
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
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1976D2),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.description_rounded, size: 18),
                            SizedBox(width: 6),
                            Text("Ön Bilgi Formu", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          final dynamic rawHastaId = widget.biletDetay['hastaid'];
                          final int? hastaId = (rawHastaId is int) ? rawHastaId : int.tryParse(rawHastaId.toString());
                          if (hastaId == null || hastaId == 0) return;
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => GameMenuScreen(hastaId: hastaId)),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFA8E6CF),
                          foregroundColor: const Color(0xFF2C3E50),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.sports_esports_rounded, size: 18),
                            SizedBox(width: 4),
                            Text("Oyun", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  // Modern delay button
  Widget _buildModernDelayButton(int minutes) {
    final bool selected = _selectedDelayMinutes == minutes;
    return GestureDetector(
      onTap: _isErteleLoading ? null : () async {
        setState(() {
          if (_selectedDelayMinutes == minutes) {
            _selectedDelayMinutes = null;
          } else {
            _selectedDelayMinutes = minutes;
          }
        });

        if (_selectedDelayMinutes != null) {
          final aksiyon = "${_selectedDelayMinutes}_dk";
          final confirm = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1976D2).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.schedule_rounded, color: Color(0xFF1976D2)),
                  ),
                  const SizedBox(width: 12),
                  const Text("Erteleme Onayı"),
                ],
              ),
              content: Text("Sıranızı $minutes dakika ertelemek istiyor musunuz?"),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text("Hayır"),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1976D2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text("Evet, Ertele"),
                ),
              ],
            ),
          );

          if (confirm == true) {
            await _erteleBilet(aksiyon);
          } else {
            setState(() {
              _selectedDelayMinutes = null;
            });
          }
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          gradient: selected 
              ? const LinearGradient(colors: [Color(0xFF1976D2), Color(0xFF42A5F5)])
              : null,
          color: selected ? null : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? Colors.transparent : const Color(0xFF1976D2).withOpacity(0.25),
            width: 1.5,
          ),
        ),
        child: Center(
          child: _isErteleLoading && _selectedDelayMinutes == minutes
              ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Text(
                  "$minutes dk",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: selected ? Colors.white : const Color(0xFF1976D2),
                  ),
                ),
        ),
      ),
    );
  }

  // Compact stat card
  Widget _buildModernStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: Color(0xFF7F8C8D), fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // Compact info row
  Widget _buildModernInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F7FA),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFF7F8C8D), size: 16),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 55,
            child: Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF7F8C8D))),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF2C3E50)),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
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
