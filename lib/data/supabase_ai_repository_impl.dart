import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/repositories/ai_repository.dart';

class SupabaseAiRepositoryImpl implements AiRepository {
  final SupabaseClient _supabase;

  SupabaseAiRepositoryImpl(this._supabase);

  @override
  Stream<int> getUserTokensStream(String userId) async* {
    // Rendiamo lo stream totalmente robusto contro crash RLS o righe mancanti
    yield 15; // Valore ottimistico iniziale (o di default se non c'è DB)

    try {
      final tokenStream = _supabase
          .from('user_ai_profiles')
          .stream(primaryKey: ['user_id'])
          .eq('user_id', userId);

      await for (final event in tokenStream) {
        if (event.isEmpty) {
          yield 15; // Nessun record = regaliamo 15 token visivi (Edge func li creerà)
        } else {
          yield event.first['tokens_balance'] as int;
        }
      }
    } catch (error) {
      print("Errore critico nello stream token (RLS?): $error");
      // Se il DB crasha o blocca la lettura, manteniamo il default
      yield 15;
    }
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
      'clever-action', // Edge Function universale per il routing
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

  @override
  Future<void> syncTokens() async {
    try {
      await _supabase.rpc('refresh_ai_tokens');
    } catch (e) {
      print("Errore durante il sync dei token: $e");
    }
  }

  @override
  Future<DateTime?> getNextResetDate(String userId) async {
    try {
      final res = await _supabase
          .from('user_ai_profiles')
          .select('next_reset_date')
          .eq('user_id', userId)
          .maybeSingle();
      if (res != null && res['next_reset_date'] != null) {
        return DateTime.parse(res['next_reset_date']);
      }
    } catch (e) {
      print("Errore fetch reset date: $e");
    }
    return null;
  }
}
