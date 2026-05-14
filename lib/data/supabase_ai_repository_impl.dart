import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/repositories/ai_repository.dart';

class SupabaseAiRepositoryImpl implements AiRepository {
  final SupabaseClient _supabase;

  SupabaseAiRepositoryImpl(this._supabase);

  @override
  Stream<int> getUserTokensStream(String userId) {
    return _supabase
        .from('user_ai_tokens')
        .stream(primaryKey: ['user_id'])
        .eq('user_id', userId)
        .map((snapshot) {
          if (snapshot.isEmpty) return 0; // Fallback se non ci sono token
          return snapshot.first['available_tokens'] as int;
        });
  }

  @override
  Future<String> callAiFunction(
    String userId, 
    String functionName, 
    Map<String, dynamic> payload,
    int tokenCost,
  ) async {
    // Edge Function Call
    // NOTA ARCHITETTURALE: Il client passa solo payload e funzione desiderata.
    // L'Edge Function in Supabase si occupa in un'unica transazione sicura di:
    // 1. Verificare JWT e user_id (evitando spoofing)
    // 2. Controllare se l'utente ha token_cost >= available_tokens
    // 3. Eseguire l'API di OpenAI (tenendo nascosta la SECRET_KEY)
    // 4. Sottrarre i token
    // 5. Scrivere i log e restituire il risultato
    final response = await _supabase.functions.invoke(
      'cine_ai_router', // Edge Function universale per il routing
      body: {
        'action': functionName,
        'payload': payload,
        'token_cost': tokenCost,
      },
    );

    if (response.status != 200) {
      throw Exception('Errore AI: ${response.data}');
    }

    return response.data['result'] as String;
  }
}
