// lib/chat_screen.dart
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'main.dart'; // kPrimaryColor için
import 'api.dart'; // Api class için

// =================================================================
// API anahtarınızı buraya yerleştirin
// =================================================================
const String GEMINI_API_KEY = "AIzaSyDNitBfWzg5j4F25b497LUeYI0o1N4NWj4";

class ChatScreen extends StatefulWidget {
  final int biletId;
  final String bolumAdi;

  const ChatScreen({
    super.key,
    required this.biletId,
    required this.bolumAdi,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  bool _isGeneratingQuestions = true;

  final List<Map<String, String>> _messages = [];

  // İlerleme takibi için
  int _currentQuestionIndex = 0;
  final int _totalQuestions = 10;
  final List<Map<String, dynamic>> _answers = [];

  // Dinamik sorular (AI tarafından üretilecek)
  late final List<String> _questions;

  @override
  void initState() {
    super.initState();
    _generateQuestions();
  }

  Future<void> _generateQuestions() async {
    setState(() {
      _isGeneratingQuestions = true;
      _messages.add({
        "role": "gemini",
        "text": "Merhaba! ${widget.bolumAdi} bölümünüz için size özel 10 adet evet/hayır sorusu hazırlıyorum. Lütfen bekleyin..."
      });
      _scrollToBottom();
    });

    try {
      // Güncel model ismi: gemini-2.5-flash (2025 itibarıyla desteklenen model)
      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: GEMINI_API_KEY,
      );

      final prompt = """
Sen bir ${widget.bolumAdi} uzmanısın. Hasta için ${_totalQuestions} adet evet/hayır sorusu oluştur. 
Sorular, ${widget.bolumAdi} bölümüne özgü yaygın semptomlar, şikayetler ve risk faktörlerini kapsasın.
Her soru kısa, net ve Türkçe olsun. Sadece numaralandırılmış liste olarak cevap ver (örneğin: 1. Soru? 2. Soru? ...).
Başka hiçbir metin ekleme.
""";

      final response = await model.generateContent([Content.text(prompt)]);
      final generatedText = response.text ?? "Sorular oluşturulamadı.";

      // Yanıtı parse et: Numaralandırılmış listeyi çıkar
      final questions = _parseQuestions(generatedText);

      if (questions.length >= _totalQuestions) {
        _questions = questions.take(_totalQuestions).toList();
      } else {
        // Yedek genel sorular (eğer AI başarısız olursa)
        _questions = [
          "Ateşiniz var mı?",
          "Öksürük şikayetiniz var mı?",
          "Nefes darlığı yaşıyor musunuz?",
          "Baş ağrınız var mı?",
          "İştah kaybı yaşıyor musunuz?",
          "Halsizlik hissediyor musunuz?",
          "Boğaz ağrısı var mı?",
          "Mide bulantısı veya kusma var mı?",
          "Vücudunuzda ağrı var mı?",
          "Uyku problemi yaşıyor musunuz?"
        ];
      }

      // Mesajı güncelle ve ilk soruyu göster
      setState(() {
        _messages.removeLast(); // "hazırlıyorum" mesajını sil
        _messages.add({
          "role": "gemini",
          "text": "Merhaba! Size ${_totalQuestions} soru soracağım. Lütfen Evet veya Hayır olarak cevaplayın.\n\n${_questions[0]}"
        });
        _currentQuestionIndex = 1;
        _isGeneratingQuestions = false;
        _scrollToBottom();
      });

    } catch (e) {
      // Hata durumunda yedek sorular kullan
      _initializeBackupQuestions();

      setState(() {
        _messages.removeLast(); // "hazırlıyorum" mesajını sil
        _messages.add({
          "role": "gemini",
          "text": "⚠️ Sorular oluşturulamadı. Genel sorularla devam ediyorum.\n\n${_questions[0]}"
        });
        _currentQuestionIndex = 1;
        _isGeneratingQuestions = false;
        _scrollToBottom();
      });
    }
  }

  List<String> _parseQuestions(String text) {
    final lines = text.split('\n');
    final questions = <String>[];
    final regex = RegExp(r'^\s*\d+\.\s*(.+?)\?');

    for (var line in lines) {
      final match = regex.firstMatch(line.trim());
      if (match != null) {
        questions.add(match.group(1)! + '?');
      }
    }

    return questions;
  }

  void _initializeBackupQuestions() {
    _questions = [
      "Ateşiniz var mı?",
      "Öksürük şikayetiniz var mı?",
      "Nefes darlığı yaşıyor musunuz?",
      "Baş ağrınız var mı?",
      "İştah kaybı yaşıyor musunuz?",
      "Halsizlik hissediyor musunuz?",
      "Boğaz ağrısı var mı?",
      "Mide bulantısı veya kusma var mı?",
      "Vücudunuzda ağrı var mı?",
      "Uyku problemi yaşıyor musunuz?"
    ];
  }

  Future<void> _sendYesNoAnswer(bool isYes) async {
    final userAnswer = isYes ? "Evet" : "Hayır";

    setState(() {
      _messages.add({"role": "user", "text": userAnswer});
      _answers.add({
        "question": _questions[_currentQuestionIndex - 1],
        "answer": userAnswer
      });
      _scrollToBottom();
    });

    if (_currentQuestionIndex >= _totalQuestions) {
      await _generateSummary();
    } else {
      setState(() {
        _messages.add({
          "role": "gemini",
          "text": _questions[_currentQuestionIndex]
        });
        _currentQuestionIndex++;
        _scrollToBottom();
      });
    }
  }

  Future<void> _generateSummary() async {
    setState(() {
      _isLoading = true;
      _messages.add({
        "role": "gemini",
        "text": "Cevaplarınızı değerlendiriyorum..."
      });
      _scrollToBottom();
    });

    try {
      String answersText = "";
      for (var answer in _answers) {
        answersText += "- ${answer['question']}: ${answer['answer']}\n";
      }

      // Güncel model ismi: gemini-2.5-flash (2025 itibarıyla desteklenen model)
      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: GEMINI_API_KEY,
      );

      final prompt = """
Sen bir ${widget.bolumAdi} uzmanısın. Aşağıdaki hasta cevaplarına göre:
1. Kısa bir özet yaz (2-3 cümle)
2. Olası ön tanı belirt

Hasta Cevapları:
$answersText

Lütfen Türkçe cevap ver ve profesyonel ol.
""";

      final response = await model.generateContent([Content.text(prompt)]);
      final summary = response.text ?? "Özet oluşturulamadı.";

      final bool saveSuccess = await _saveSummaryToBackend(summary);

      setState(() {
        _messages.removeLast();
        _messages.add({
          "role": "gemini",
          "text": summary
        });

        if (saveSuccess) {
          _messages.add({
            "role": "gemini",
            "text": "\n✅ Bilgileriniz başarıyla doktora gönderildi."
          });
        } else {
          _messages.add({
            "role": "gemini",
            "text": "\n⚠️ Kayıt sırasında sorun oluştu. Lütfen resepsiyona bildirin."
          });
        }

        _isLoading = false;
        _scrollToBottom();
      });

      if (saveSuccess) {
        await Future.delayed(const Duration(seconds: 3));
        if (mounted) Navigator.pop(context);
      }

    } catch (e) {
      setState(() {
        _messages.removeLast();
        _messages.add({
          "role": "gemini",
          "text": "⚠️ API Hatası\n\nLütfen yeni bir API anahtarı alın:\nhttps://aistudio.google.com/app/apikey\n\nHata: ${e.toString()}"
        });
        _isLoading = false;
        _scrollToBottom();
      });
    }
  }

  Future<bool> _saveSummaryToBackend(String aiOzet) async {
    return await Api.saveAiSummary(
      biletId: widget.biletId,
      summary: aiOzet,
      details: {
        "answers": _answers,
        "full_conversation": _messages
      },
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    double progress = _currentQuestionIndex / _totalQuestions;
    if (progress > 1.0) progress = 1.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text("İlk Bilgi Formu"),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(kPrimaryColor),
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      "$_currentQuestionIndex / $_totalQuestions",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  "${(progress * 100).toInt()}% tamamlandı",
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(8.0),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isUser = message['role'] == 'user';
                return _buildMessageBubble(message['text']!, isUser);
              },
            ),
          ),

          if (_isGeneratingQuestions || _isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),

          if (!_isGeneratingQuestions && !_isLoading && _currentQuestionIndex <= _totalQuestions)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _sendYesNoAnswer(false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[400],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Hayır",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _sendYesNoAnswer(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[400],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Evet",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(String text, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUser ? kPrimaryColor : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 3,
              offset: const Offset(0, 1),
            )
          ],
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isUser ? Colors.white : Colors.black87,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}