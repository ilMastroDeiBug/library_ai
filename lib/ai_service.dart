import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../secrets.dart'; // Importiamo la chiave nascosta

class AIService {
  late final GenerativeModel _model;

  AIService() {
    // Inizializziamo il modello "Gemini 1.5 Flash"
    _model = GenerativeModel(model: 'gemini-pro', apiKey: Secrets.geminiApiKey);
  }

  // Funzione Principale: Analizza il libro
  Future<Map<String, dynamic>> analyzeBook({
    required String title,
    required String author,
    required String userProfile, // "Sono un 16enne, dev full stack..."
  }) async {
    // 1. Costruiamo il PROMPT (L'istruzione segreta per l'AI)
    // Diciamo all'AI di rispondere ESCLUSIVAMENTE in JSON.
    final prompt =
        '''
      Agisci come un mentore esperto per un giovane "Architect" ambizioso.
      
      PROFILO UTENTE:
      $userProfile
      
      LIBRO DA ANALIZZARE:
      Titolo: $title
      Autore: $author
      
      COMPITO:
      Analizza questo libro e spiega perché è utile (o inutile) per il profilo dell'utente.
      
      FORMATO RISPOSTA (Obbligatorio JSON):
      Restituisci SOLO un oggetto JSON puro (senza markdown ```json) con questi campi esatti:
      {
        "compatibility": (intero da 0 a 100),
        "reason": (stringa, max 2 frasi, diretta e tagliente),
        "key_takeaways": (lista di 3 stringhe, lezioni pratiche),
        "action_plan": (stringa, un'azione concreta da fare oggi)
      }
    ''';

    try {
      // 2. Inviamo la richiesta a Google
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);

      // 3. Puliamo la risposta (A volte Gemini aggiunge ```json all'inizio)
      String cleanJson = response.text ?? "{}";
      cleanJson = cleanJson
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      // 4. Convertiamo il testo in una Mappa (Dati utilizzabili da Flutter)
      return json.decode(cleanJson);
    } catch (e) {
      print("Errore AI: $e");
      // Se fallisce, restituiamo un errore gestito invece di far crashare l'app
      return {
        'compatibility': 0,
        'reason':
            "Impossibile contattare l'Intelligence AI. Riprova più tardi.",
        'key_takeaways': ["Nessun dato", "Errore di connessione", "Riprova"],
        'action_plan': "Controlla la tua connessione internet.",
      };
    }
  }
}
