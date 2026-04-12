import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:library_ai/secrets.dart';

class AIService {
  // --- CHIAVE API (La tua è già configurata) ---
  static const String _apiKey = Secrets.grokApiKey;

  static const String _baseUrl =
      "https://api.groq.com/openai/v1/chat/completions";

  // --- 1. FUNZIONE PING (Test Connessione) ---
  Future<String> pingAI() async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          "model": "llama-3.1-8b-instant", // Modello veloce per il ping
          "messages": [
            {"role": "user", "content": "Dimmi solo: CONNESSO"},
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else {
        return "Errore HTTP: ${response.statusCode}";
      }
    } catch (e) {
      return "Errore di Connessione: $e";
    }
  }

  // --- 2. FUNZIONE ANALISI UNIVERSALE (Libri & Film) ---
  Future<String> analyzeMedia({
    required String title,
    required String type, // 'book' o 'movie'
    required String userProfile,
    String? creator, // Autore o Regista (opzionale)
  }) async {
    // A. Costruiamo il contesto in base al tipo
    String mediaLabel = "";
    String specificQuestions = "";

    if (type == 'movie') {
      mediaLabel = "FILM: \"$title\"";
      specificQuestions = '''
      1. 🎥 Compatibilità % (Tra la mia mentalità e questo film)
      2. 🧠 Analisi Architect: È solo intrattenimento o c'è una lezione strategica/psicologica?
      3. 🎬 Verdetto: Guardalo se cerchi... / Evitalo se...
      ''';
    } else {
      // Default: Libro
      mediaLabel = "LIBRO: \"$title\" ${creator != null ? "di $creator" : ""}";
      specificQuestions = '''
      1. 📚 Compatibilità % (Quanto serve alla mia crescita)
      2. 🚀 Perché mi potrebbe piacere (o perché è tempo perso)
      3. 🛠 Un'azione pratica ("Architect Move") da applicare subito.
      ''';
    }

    // B. Il Prompt di Sistema (Il "Personaggio")
    final systemPrompt =
        "Sei il 'Core Vault AI', un mentore per un giovane Architect (16 anni, Dev Full Stack, MMA). "
        "Il tuo tono è analitico, leggermente cinico, diretto e motivante. "
        "Non usare frasi fatte. Vai dritto al punto.";

    // C. Il Prompt Utente (La Richiesta)
    final userMessage =
        '''
        PROFILO UTENTE: $userProfile
        
        OGGETTO DA ANALIZZARE: $mediaLabel
        
        Analizzalo brutalmente per me.
        Rispondi ESATTAMENTE a questi punti:
        $specificQuestions
        
        Sii breve (massimo 150 parole). Usa emoji in base alle preferenze dell' utente.
        ''';

    // D. Chiamata API
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          // Usiamo il modello potente per l'analisi
          "model": "llama-3.3-70b-versatile",
          "messages": [
            {"role": "system", "content": systemPrompt},
            {"role": "user", "content": userMessage},
          ],
          "temperature": 0.7, // Creatività bilanciata
          "max_tokens": 600,
        }),
      );

      if (response.statusCode == 200) {
        // Decodifica UTF8 per gestire emoji e accenti italiani correttamente
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['choices'][0]['message']['content'];
      } else {
        return "Errore AI Core: ${response.statusCode} - ${response.body}";
      }
    } catch (e) {
      return "Impossibile connettersi al server: $e";
    }
  }
}
