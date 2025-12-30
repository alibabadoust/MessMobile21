// home_screen.dart
// Queue Tracking Entry Screen for Hospital Appointment App

import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'main.dart'; // For SiraTakipScreen and KayitScreen
import 'api.dart'; // For Api class

// ═══════════════════════════════════════════════════════════════════════════
// QUEUE TRACKING ENTRY SCREEN
// Login screen for queue tracking system
// ═══════════════════════════════════════════════════════════════════════════

class QueueTrackingEntryScreen extends StatefulWidget {
  const QueueTrackingEntryScreen({super.key});

  @override
  State<QueueTrackingEntryScreen> createState() => _QueueTrackingEntryScreenState();
}

class _QueueTrackingEntryScreenState extends State<QueueTrackingEntryScreen> {
  final TextEditingController _telefonController = TextEditingController();
  final TextEditingController _siraKoduController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _telefonController.dispose();
    _siraKoduController.dispose();
    super.dispose();
  }

  Future<void> _trackQueue() async {
    if (_telefonController.text.isEmpty || _siraKoduController.text.isEmpty) {
      _showError("Lütfen tüm alanları doldurun.");
      return;
    }

    setState(() => _isLoading = true);

    final result = await Api.trackQueue(
      phone: _telefonController.text,
      code: _siraKoduController.text,
    );

    if (!mounted) return;

    if (result.success && result.data != null) {
      final data = result.data!;
      final biletDetay = data['bilet_detay'] ?? data;
      final biletId = biletDetay['biletid'] ?? 0;
      final bolumAdi = biletDetay['bolum_adi']?.toString() ?? 'Bilinmiyor';
      final baglantiKodu = _siraKoduController.text;

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
    } else {
      _showError(result.errorMessage ?? "Bilinmeyen hata");
    }

    if (mounted) {
      setState(() => _isLoading = false);
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
      SnackBar(
        content: Text(message),
        backgroundColor: CalmColors.emergencyRed,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CalmColors.softGray,
      appBar: AppBar(
        title: const Text('Sıra Takibi'),
        backgroundColor: CalmColors.pureWhite,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(CalmSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: CalmSpacing.xl),
              
              // Icon
              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: CalmColors.primaryGradient,
                    borderRadius: BorderRadius.circular(CalmRadius.xxl),
                    boxShadow: [
                      BoxShadow(
                        color: CalmColors.medicalBlue.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.confirmation_number_rounded,
                    size: 48,
                    color: CalmColors.pureWhite,
                  ),
                ),
              ),
              const SizedBox(height: CalmSpacing.xl),
              
              // Title
              Text(
                'Sıranızı Takip Edin',
                style: CalmTextStyles.headlineLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: CalmSpacing.sm),
              Text(
                'Bilet kodunuz ve telefon numaranızı girerek sıranızı görüntüleyin.',
                style: CalmTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: CalmSpacing.xl),
              
              // Phone Number Field
              Text(
                'Telefon Numarası',
                style: CalmTextStyles.labelLarge,
              ),
              const SizedBox(height: CalmSpacing.sm),
              TextField(
                controller: _telefonController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: '0(555) 555-55-55',
                  prefixIcon: Container(
                    margin: const EdgeInsets.all(CalmSpacing.sm),
                    padding: const EdgeInsets.all(CalmSpacing.sm),
                    decoration: BoxDecoration(
                      color: CalmColors.calmBlue,
                      borderRadius: BorderRadius.circular(CalmRadius.sm),
                    ),
                    child: const Icon(
                      Icons.phone_rounded,
                      color: CalmColors.medicalBlue,
                      size: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: CalmSpacing.md),
              
              // Ticket Code Field
              Text(
                'Sıra Takip Kodu',
                style: CalmTextStyles.labelLarge,
              ),
              const SizedBox(height: CalmSpacing.sm),
              TextField(
                controller: _siraKoduController,
                keyboardType: TextInputType.text,
                maxLength: 11,
                decoration: InputDecoration(
                  hintText: '11 Haneli Bilet Kodunuz',
                  counterText: '',
                  prefixIcon: Container(
                    margin: const EdgeInsets.all(CalmSpacing.sm),
                    padding: const EdgeInsets.all(CalmSpacing.sm),
                    decoration: BoxDecoration(
                      color: CalmColors.calmBlue,
                      borderRadius: BorderRadius.circular(CalmRadius.sm),
                    ),
                    child: const Icon(
                      Icons.confirmation_number_rounded,
                      color: CalmColors.medicalBlue,
                      size: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: CalmSpacing.xl),
              
              // Submit Button
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _trackQueue,
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: CalmColors.pureWhite,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Sıra Takip Et',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: CalmSpacing.lg),
              
              // Register Link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Kaydınız yok mu? ',
                    style: CalmTextStyles.bodyMedium,
                  ),
                  TextButton(
                    onPressed: () => _navigateToKayit(),
                    child: const Text(
                      'Kayıt Olun',
                      style: TextStyle(fontWeight: FontWeight.bold),
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
}
