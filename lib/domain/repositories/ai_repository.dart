abstract class AiRepository {
  Stream<int> getUserTokensStream(String userId);
  
  /// Invia la richiesta all'Edge Function su Supabase.
  /// Sarà l'Edge Function a dedurre i token in modo sicuro tramite un Admin Client
  /// per evitare che un utente malintenzionato si "ridia" token bypassando il backend.
  Future<String> callAiFunction(
    String userId, 
    String functionName, 
    Map<String, dynamic> payload,
    int tokenCost
  );
}
