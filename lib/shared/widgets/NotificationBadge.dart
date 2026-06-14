// lib/shared/widgets/notification_badge.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../features/notifications/providers/NotificationProvider.dart';
import '../../features/notifications/screens/NotificationScreen.dart';

/// Icône cloche avec badge rouge indiquant le nombre de notifs non lues.
/// À placer dans les `actions` de l'AppBar.
class NotificationBadge extends StatelessWidget {
  const NotificationBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<NotificationProvider>();

    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined, color: Colors.white),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NotificationScreen()),
          ),
        ),
        if (prov.hasUnread)
          Positioned(
            top: 6,
            right: 6,
            child: Container(
              width: 18,
              height: 18,
              decoration: const BoxDecoration(
                color: Color(0xFFC81E1E),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                prov.unreadCount > 99 ? '99+' : '${prov.unreadCount}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
