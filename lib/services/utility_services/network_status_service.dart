import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';

class NetworkStatusService extends ChangeNotifier {
  static const List<(String, int)> _socketTargets = [
    ('1.1.1.1', 53),
    ('8.8.8.8', 53),
  ];

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
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
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
    for (final target in _socketTargets) {
      Socket? socket;
      try {
        socket = await Socket.connect(
          target.$1,
          target.$2,
          timeout: const Duration(seconds: 2),
        );
        await socket.close();
        return true;
      } catch (_) {
        await socket?.close();
      }
    }
    return false;
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
