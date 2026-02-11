import 'dart:convert';
import 'package:http/http.dart' as http;

class AIService {
  // --- INCOLLA QUI LA TUA CHIAVE (gsk_...) ---
  static const String _apiKey =
      "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";

  static const String _baseUrl =
      "https://api.groq.com/openai/v1/chat/completions";

  // --- FUNZIONE PING (Test Connessione) ---
  Future<String> pingAI() async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          // MODELLO AGGIORNATO (Veloce)
          "model": "llama-3.1-8b-instant",
          "messages": [
            {"role": "user", "content": "Dimmi solo: CONNESSO"},
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else {
        return "Errore HTTP: ${response.statusCode}\n${response.body}";
      }
    } catch (e) {
      return "Errore di Connessione: $e";
    }
  }

  // --- FUNZIONE ANALISI (TESTO PURO) ---
  Future<String> analyzeBook({
    required String title,
    required String author,
    required String userProfile,
  }) async {
    final systemPrompt =
        "Sei un mentore esperto per un giovane 'Architect' ambizioso (Dev Full Stack, MMA). Sii diretto, cinico e pratico.";

    final userMessage =
        '''
      PROFILO UTENTE: $userProfile
      LIBRO: "$title" di $author
      
      Analizzalo per me.
      Voglio sapere:
      1. Compatibilità % (Stima onesta)
      2. Perché mi serve (o perché fa schifo)
      3. Un'azione pratica da applicare subito.
      
      Usa delle emoji per separare i punti. Sii breve.
    ''';

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          // MODELLO AGGIORNATO (Intelligente)
          "model": "llama-3.3-70b-versatile",
          "messages": [
            {"role": "system", "content": systemPrompt},
            {"role": "user", "content": userMessage},
          ],
          "temperature": 0.7,
          "max_tokens": 600,
        }),
      );

      if (response.statusCode == 200) {
        // UTF8 per gli accenti
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['choices'][0]['message']['content'];
      } else {
        return "Errore dal cervello AI: ${response.statusCode} - ${response.body}";
      }
    } catch (e) {
      return "Impossibile raggiungere l'AI: $e";
    }
  }
}
