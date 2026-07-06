import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiAiService {
  // Singleton Pattern - Loyiha bo'yicha faqat 1 ta obyekt xotirada turishi uchun
  static final GeminiAiService _instance = GeminiAiService._internal();
  factory GeminiAiService() => _instance;
  GeminiAiService._internal();

  // 🔐 API Kalit (Uni xavfsizlik uchun const yoki kelajakda .env fayldan o'qish tavsiya etiladi)
  static const String _apiKey = "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";

  // Hugging Face-ning OpenAI bilan mos keladigan birlashgan API manzili
  static const String _baseUrl =
      "https://router.huggingface.co/v1/chat/completions";

  Future<String> getCoachResponse(String userPrompt) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          // 🚀 BARQAROR MODEL: Qwen o'zbek tilida juda zo'r ishlaydi
          "model": "Qwen/Qwen2.5-7B-Instruct",
          "messages": [
            {
              "role": "system",
              "content":
                  "Siz Fokus AI ilovasining professional va motivatsiya beruvchi shaxsiy murabbiyisiz (AI Coach). Foydalanuvchiga odatlarini shakllantirishda yordam bering va har doim o'zbek tilida juda qisqa, tushunarli va ruhlantiruvchi javob qaytaring."
            },
            {"role": "user", "content": userPrompt}
          ],
          "max_tokens": 250,
          "temperature": 0.7
        }),
      );

      if (response.statusCode == 200) {
        // UTF-8 formatida o'zbekcha harflar (g', o', sh, ch) buzilmasligi ta'minlangan
        final Map<String, dynamic> data =
            jsonDecode(utf8.decode(response.bodyBytes));

        if (data['choices'] != null && data['choices'].isNotEmpty) {
          return data['choices'][0]['message']['content'].toString().trim();
        }
        return "Xatolik: Sun'iy intellekt noto'g'ri formatda javob qaytardi.";
      } else {
        return "Sun'iy intellekt bilan bog'lanib bo'lmadi (Kod: ${response.statusCode})";
      }
    } catch (e) {
      return "Internet ulanishi mavjud emas yoki uzilish yuz berdi.";
    }
  }
}
