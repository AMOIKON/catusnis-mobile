// lib/features/notifications/providers/notification_provider.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../notifications/models/NotificationModel.dart';
import '../../notifications/services/NotificationApiService.dart';

class NotificationProvider extends ChangeNotifier {
  static final NotificationProvider _instance =
      NotificationProvider._internal();
  factory NotificationProvider() => _instance;
  NotificationProvider._internal();

  final NotificationApiService _api = NotificationApiService();

  // ── flutter_local_notifications ───────────────────────────────────────────
  final _localNotif = FlutterLocalNotificationsPlugin();
  bool _localInitialized = false;

  // ── État ──────────────────────────────────────────────────────────────────
  List<NotificationModel> _items = [];
  int _unreadCount = 0;
  int? _userId;
  DateTime _lastPoll = DateTime.now().subtract(const Duration(minutes: 5));
  Timer? _pollTimer;
  bool _loading = false;

  List<NotificationModel> get items => _items;
  int get unreadCount => _unreadCount;
  bool get hasUnread => _unreadCount > 0;
  bool get isLoading => _loading;

  // ── Initialisation ────────────────────────────────────────────────────────
  Future<void> initialize(int userId) async {
    _userId = userId;
    await _initLocalNotifications();
    await _poll(); // premier poll immédiat
    _startPolling();
  }

  Future<void> _initLocalNotifications() async {
    if (_localInitialized || kIsWeb) return;
    try {
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const ios = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      await _localNotif.initialize(
        const InitializationSettings(android: android, iOS: ios),
      );
      _localInitialized = true;
      debugPrint('🔔 LocalNotifications initialisées');
    } catch (e) {
      debugPrint('⚠️ LocalNotifications non disponible: $e');
    }
  }

  // ── Polling toutes les 5 minutes ──────────────────────────────────────────
  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _poll(),
    );
  }

  Future<void> _poll() async {
    if (_userId == null) return;
    try {
      final nouvelles = await _api.getSince(
        userId: _userId!,
        since: _lastPoll,
      );
      _lastPoll = DateTime.now();

      if (nouvelles.isNotEmpty) {
        // Afficher une notif locale pour chaque nouvelle
        for (final n in nouvelles) {
          _showLocalNotification(n);
        }
        // Recharger la liste complète
        await charger();
      }

      // Mettre à jour le badge
      _unreadCount = await _api.getUnreadCount(_userId!);
      notifyListeners();
    } catch (e) {
      debugPrint('⚠️ Polling notifications: $e');
    }
  }

  // ── Charger la liste complète ─────────────────────────────────────────────
  Future<void> charger() async {
    if (_userId == null) return;
    _loading = true;
    notifyListeners();
    try {
      _items = await _api.getAll(userId: _userId!);
      _unreadCount = _items.where((n) => !n.isRead).length;
    } catch (e) {
      debugPrint('❌ NotificationProvider.charger: $e');
    }
    _loading = false;
    notifyListeners();
  }

  // ── Marquer comme lu ─────────────────────────────────────────────────────
  Future<void> markRead(int notifId) async {
    await _api.markRead(notifId);
    _items = _items
        .map((n) => n.id == notifId ? n.copyWith(isRead: true) : n)
        .toList();
    _unreadCount = _items.where((n) => !n.isRead).length;
    notifyListeners();
  }

  Future<void> markAllRead() async {
    if (_userId == null) return;
    await _api.markAllRead(_userId!);
    _items = _items.map((n) => n.copyWith(isRead: true)).toList();
    _unreadCount = 0;
    notifyListeners();
  }

  // ── Notif locale ──────────────────────────────────────────────────────────
  Future<void> _showLocalNotification(NotificationModel n) async {
    if (kIsWeb || !_localInitialized) return;
    try {
      await _localNotif.show(
        n.id,
        n.title,
        n.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'catusnis_channel',
            'CATUSNIS',
            channelDescription: 'Notifications CATUSNIS',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
    } catch (e) {
      debugPrint('⚠️ Local notif: $e');
    }
  }

  // ── Nettoyage ─────────────────────────────────────────────────────────────
  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  void reset() {
    stopPolling();
    _items = [];
    _unreadCount = 0;
    _userId = null;
    notifyListeners();
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
}
