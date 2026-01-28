import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
// import '../secrets.dart'; // Scommenta se usi il file secrets, altrimenti usa la stringa sotto

class AIService {
  late final GenerativeModel _model;

  AIService() {
    // Usiamo gemini-1.5-flash: veloce e gratuito
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      // Incolla qui la tua chiave (o usa Secrets.geminiApiKey)
      apiKey: "AIzaSyB1ZIVjRZemKHbY-9noiiGAJKDM5uKrBbI",
    );
  }

  // --- FUNZIONE MVP (DIAGNOSTICA) ---
  Future<String> pingAI() async {
    try {
      print("AI_DEBUG: Ping in corso...");
      final response = await _model.generateContent([
        Content.text("Rispondi solo con la parola: 'CONNESSO'"),
      ]);
      print("AI_DEBUG: Risposta -> ${response.text}");
      return response.text?.trim() ?? "Nessuna risposta";
    } catch (e) {
      print("AI_DEBUG: Errore Ping -> $e");
      return "ERRORE: $e";
    }
  }

  // --- FUNZIONE PRINCIPALE (ANALISI) ---
  Future<Map<String, dynamic>> analyzeBook({
    required String title,
    required String author,
    required String userProfile,
  }) async {
    final prompt =
        '''
      Agisci come un mentore esperto per un giovane "Architect" ambizioso.
      PROFILO UTENTE: $userProfile
      LIBRO DA ANALIZZARE: "$title" di $author
      
      COMPITO:
      Analizza questo libro e spiega perché è utile (o inutile) per il profilo dell'utente.
      Sii cinico, diretto e tecnico.
      
      FORMATO RISPOSTA (Obbligatorio JSON):
      Restituisci esclusivamente un oggetto JSON. Non aggiungere commenti o introduzioni.
      {
        "compatibility": (intero 0-100),
        "reason": (stringa breve),
        "key_takeaways": (lista di 3 stringhe),
        "action_plan": (stringa)
      }
    ''';

    try {
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      String text = response.text ?? "{}";

      // LOGICA DI PULIZIA JSON ROBUSTA
      // Cerca la prima parentesi graffa e l'ultima per estrarre solo il JSON
      if (text.contains("{")) {
        int startIndex = text.indexOf("{");
        int endIndex = text.lastIndexOf("}") + 1;
        text = text.substring(startIndex, endIndex);
      }

      return json.decode(text.trim());
    } catch (e) {
      print("AI_ERROR: $e");
      return {
        "compatibility": 0,
        "reason": "Errore nel parsing della risposta AI o connessione assente.",
        "key_takeaways": ["Controlla i log", "Verifica API Key", "Riprova"],
        "action_plan": "Esegui il Test di Connessione.",
      };
    }
  }
}
