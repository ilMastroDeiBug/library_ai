import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class NetworkStatusService extends ChangeNotifier {
  static const int _failuresBeforeOffline = 2;
  static const Duration _requestTimeout = Duration(seconds: 4);

  bool _isOnline = true;
  bool _isChecking = false;
  bool _hasResolvedInitialStatus = false;
  bool _hasEverBeenOnline = false;
  int _consecutiveFailures = 0;
  Timer? _timer;

  bool get isOnline => _isOnline;
  bool get hasResolvedInitialStatus => _hasResolvedInitialStatus;
  bool get hasEverBeenOnline => _hasEverBeenOnline;

  NetworkStatusService() {
    _startMonitoring();
  }

  void _startMonitoring() {
    unawaited(checkConnection());
    _timer = Timer.periodic(const Duration(seconds: kIsWeb ? 5 : 3), (_) {
      unawaited(checkConnection());
    });
  }

  Future<void> checkConnection() async {
    if (_isChecking) return;
    _isChecking = true;
    try {
      final isReachable = await _hasInternetAccess();
      _handleReachabilityResult(isReachable);
    } catch (_) {
      _handleReachabilityResult(false);
    } finally {
      _isChecking = false;
    }
  }

  Future<bool> _hasInternetAccess() async {
    const urls = [
      'https://jsonplaceholder.typicode.com/todos/1',
      'https://api.themoviedb.org/3/configuration',
      'https://vmbshnrphkmuqtjjfdah.supabase.co/auth/v1/health',
    ];

    final results = await Future.wait(urls.map(_isEndpointReachable));
    return results.any((isReachable) => isReachable);
  }

  Future<bool> _isEndpointReachable(String url) async {
    try {
      final response = await http.get(Uri.parse(url)).timeout(_requestTimeout);
      return response.statusCode < 500;
    } catch (_) {
      return false;
    }
  }

  void _handleReachabilityResult(bool isReachable) {
    if (isReachable) {
      _consecutiveFailures = 0;
      _updateStatus(true);
      return;
    }

    _consecutiveFailures++;
    _hasResolvedInitialStatus = true;

    if (_consecutiveFailures >= _failuresBeforeOffline) {
      _updateStatus(false);
    } else {
      notifyListeners();
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
