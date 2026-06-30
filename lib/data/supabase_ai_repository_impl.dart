import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/repositories/ai_repository.dart';

class SupabaseAiRepositoryImpl implements AiRepository {
  final SupabaseClient _supabase;
  
  final Map<String, StreamController<int>> _tokenControllers = {};

  SupabaseAiRepositoryImpl(this._supabase);

  @override
  Stream<int> getUserTokensStream(String userId) async* {
    yield 0;

    final initialTokens = await _fetchTokens(userId);
    yield initialTokens;

    if (!_tokenControllers.containsKey(userId)) {
      _tokenControllers[userId] = StreamController<int>.broadcast();
    }
    yield* _tokenControllers[userId]!.stream;
  }

  Future<int> _fetchTokens(String userId) async {
    try {
      final res = await _supabase
          .from('user_ai_profiles')
          .select('tokens_balance')
          .eq('user_id', userId)
          .maybeSingle();
      
      if (res != null && res['tokens_balance'] != null) {
        return res['tokens_balance'] as int;
      }
    } catch (e) {
      debugPrint("Errore fetch token (RLS o inesistente?): $e");
    }
    return 0;
  }

  void _triggerTokenRefresh(String userId) async {
    final t = await _fetchTokens(userId);
    if (_tokenControllers.containsKey(userId) && !_tokenControllers[userId]!.isClosed) {
      _tokenControllers[userId]!.add(t);
    }
  }

  @override
  Future<String> callAiFunction(
    String userId,
    String functionName,
    Map<String, dynamic> payload,
    int tokenCost,
  ) async {
    final response = await _supabase.functions.invoke(
      'clever-action',
      body: {
        'action': functionName,
        'payload': payload,
        'token_cost': tokenCost,
      },
    );

    if (response.status != 200) {
      if (response.status == 402) {
        throw Exception('Token insufficienti. Attendi il rinnovo settimanale.');
      }
      final errorMsg = response.data is Map 
          ? (response.data['error'] ?? 'Errore sconosciuto')
          : 'Errore AI: status ${response.status}';
      throw Exception(errorMsg);
    }

    final data = response.data;
    if (data == null) throw Exception('Risposta AI vuota');
    if (data is! Map) throw Exception('Risposta AI non valida');
    if (data['result'] == null) throw Exception(data['error'] ?? 'Risultato AI mancante');

    // Chiamata completata con successo, il server ha scalato i token.
    // Aggiorniamo i token localmente con 1 singola lettura:
    _triggerTokenRefresh(userId);

    return data['result'] as String;
  }

  @override
  Future<void> syncTokens() async {
    try {
      await _supabase.rpc('refresh_ai_tokens');
      // Trigger all listeners to refresh
      for (final userId in _tokenControllers.keys) {
        _triggerTokenRefresh(userId);
      }
    } catch (e) {
      debugPrint("Errore durante il sync dei token: $e");
    }
  }

  @override
  Future<DateTime?> getNextResetDate(String userId) async {
    try {
      final res = await _supabase
          .from('user_ai_profiles')
          .select('last_token_reset')
          .eq('user_id', userId)
          .maybeSingle();
      if (res != null && res['last_token_reset'] != null) {
        final lastReset = DateTime.parse(res['last_token_reset']);
        return lastReset.add(const Duration(days: 7));
      }
    } catch (e) {
      debugPrint("Errore fetch reset date: $e");
    }
    return null;
  }
}
