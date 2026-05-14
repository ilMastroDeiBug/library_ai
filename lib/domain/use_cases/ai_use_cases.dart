import '../repositories/ai_repository.dart';

class GetAiTokensUseCase {
  final AiRepository repository;
  GetAiTokensUseCase(this.repository);

  Stream<int> call(String userId) {
    return repository.getUserTokensStream(userId);
  }
}

class CallAiFunctionUseCase {
  final AiRepository repository;
  CallAiFunctionUseCase(this.repository);

  Future<String> call({
    required String userId,
    required String functionName,
    required Map<String, dynamic> payload,
    required int tokenCost,
  }) {
    return repository.callAiFunction(userId, functionName, payload, tokenCost);
  }
}
