import 'dart:async';
import 'package:flutter/foundation.dart'; // Ci serve per capire se siamo su Web (kIsWeb)
import 'package:http/http.dart' as http;

class NetworkStatusService extends ChangeNotifier {
  bool _isOnline = true;
  bool _isChecking = false;
  bool _hasResolvedInitialStatus = false;
  bool _hasEverBeenOnline = false;
  Timer? _timer;

  bool get isOnline => _isOnline;
  bool get hasResolvedInitialStatus => _hasResolvedInitialStatus;
  bool get hasEverBeenOnline => _hasEverBeenOnline;

  NetworkStatusService() {
    _startMonitoring();
  }

  void _startMonitoring() {
    unawaited(checkConnection());
    // Su Web controlliamo ogni 5 secondi, su Mobile ogni 3 per non stressare il browser
    _timer = Timer.periodic(const Duration(seconds: kIsWeb ? 5 : 3), (_) {
      unawaited(checkConnection());
    });
  }

  Future<void> checkConnection() async {
    if (_isChecking) return;
    _isChecking = true;
    try {
      final isReachable = await _hasInternetAccess();
      _updateStatus(isReachable);
    } catch (_) {
      _updateStatus(false);
    } finally {
      _isChecking = false;
    }
  }

  Future<bool> _hasInternetAccess() async {
    try {
      // Soluzione Universale (Web + Mobile): Ping HTTP
      // Usiamo un endpoint pubblico ultra-veloce e che permette il CORS dai browser
      final response = await http
          .get(Uri.parse('https://jsonplaceholder.typicode.com/todos/1'))
          .timeout(const Duration(seconds: 3));

      return response.statusCode == 200;
    } catch (_) {
      return false; // Se va in timeout o c'è errore, siamo offline
    }
  }

  void _updateStatus(bool nextStatus) {
    final didChange = _isOnline != nextStatus;
    final wasInitial = !_hasResolvedInitialStatus;

    _isOnline = nextStatus;
    _hasResolvedInitialStatus = true;

    if (nextStatus) {
      _hasEverBeenOnline = true;
    }

    if (didChange || wasInitial) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
