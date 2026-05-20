import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkStatusService extends ChangeNotifier {
  static const Duration _requestTimeout = Duration(seconds: 4);

  bool _isOnline = true;
  bool _isChecking = false;
  bool _hasResolvedInitialStatus = false;
  bool _hasEverBeenOnline = false;
  
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  bool get isOnline => _isOnline;
  bool get hasResolvedInitialStatus => _hasResolvedInitialStatus;
  bool get hasEverBeenOnline => _hasEverBeenOnline;

  NetworkStatusService() {
    _startMonitoring();
  }

  void _startMonitoring() {
    // 1. Controllo iniziale
    unawaited(checkConnection());

    // 2. Ascolto i broadcast nativi di cambio rete invece del polling HTTP
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      // Se il telefono ci dice chiaramente che non ha rete, passiamo offline subito
      if (results.contains(ConnectivityResult.none)) {
        _handleReachabilityResult(false);
      } else {
        // Se il telefono dice che c'è rete (es. connesso al wifi),
        // facciamo un singolo ping HTTP per confermare la vera connettività
        unawaited(checkConnection());
      }
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
    _updateStatus(isReachable);
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
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}

