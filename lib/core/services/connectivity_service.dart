// lib/core/services/connectivity_service.dart

import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class ConnectivityService extends ChangeNotifier {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  bool _isReallyOnline = true;
  bool _isSimulatingOffline = false;

  bool get isSimulatingOffline => _isSimulatingOffline;
  bool get isOnline => _isReallyOnline && !_isSimulatingOffline;
  bool get isOffline => !isOnline;

  StreamSubscription? _subscription;

  // ── Initialiser l'écoute réseau ───────────────────────────────────
  Future<void> initialize() async {
    final result = await Connectivity().checkConnectivity();
    _isReallyOnline = _isConnected(result);

    _subscription = Connectivity().onConnectivityChanged.listen(
      (result) {
        final wasOnline = isOnline;
        _isReallyOnline = _isConnected(result);
        if (wasOnline != isOnline) {
          debugPrint(isOnline ? '🟢 Réseau connecté' : '🔴 Réseau déconnecté');
          notifyListeners();
        }
      },
    );
  }

  // ✅ Toggle simulation hors ligne depuis l'app
  void toggleSimulation() {
    _isSimulatingOffline = !_isSimulatingOffline;
    debugPrint(_isSimulatingOffline
        ? '🔴 Mode hors ligne simulé activé'
        : '🟢 Mode hors ligne simulé désactivé');
    notifyListeners();
  }

  bool _isConnected(List<ConnectivityResult> results) {
    return results.any((r) =>
        r == ConnectivityResult.mobile ||
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.ethernet);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
