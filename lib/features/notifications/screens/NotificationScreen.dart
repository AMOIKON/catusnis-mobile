// lib/features/notifications/screens/notification_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../notifications/models/NotificationModel.dart';
import '../../notifications/providers/NotificationProvider.dart';

const _kPrimary = Color(0xFF0D3380);
const _kGray = Color(0xFF6B7280);
const _kBg = Color(0xFFF0F4F8);

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});
  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().charger();
    });
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<NotificationProvider>();

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Notifications',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        actions: [
          if (prov.hasUnread)
            TextButton.icon(
              onPressed: prov.markAllRead,
              icon: const Icon(Icons.done_all, color: Colors.white, size: 18),
              label: const Text('Tout lire',
                  style: TextStyle(color: Colors.white, fontSize: 12)),
            ),
        ],
      ),
      body: prov.isLoading
          ? const Center(child: CircularProgressIndicator(color: _kPrimary))
          : prov.items.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                  color: _kPrimary,
                  onRefresh: prov.charger,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: prov.items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (_, i) => _NotifCard(notif: prov.items[i]),
                  ),
                ),
    );
  }

  Widget _buildEmpty() => Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: _kPrimary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.notifications_none_outlined,
                color: _kPrimary, size: 40),
          ),
          const SizedBox(height: 16),
          const Text('Aucune notification',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          const Text('Vous êtes à jour !', style: TextStyle(color: _kGray)),
        ]),
      );
}

// ── Carte notification ─────────────────────────────────────────────────────
class _NotifCard extends StatelessWidget {
  final NotificationModel notif;
  const _NotifCard({required this.notif});

  @override
  Widget build(BuildContext context) {
    final typeColor = _typeColor(notif.type);
    final typeIcon = _typeIcon(notif.type);

    return GestureDetector(
      onTap: () {
        if (!notif.isRead) {
          context.read<NotificationProvider>().markRead(notif.id);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color:
              notif.isRead ? Colors.white : _kPrimary.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: notif.isRead
                ? Colors.grey.shade200
                : _kPrimary.withValues(alpha: 0.15),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Icône type
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: typeColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(typeIcon, color: typeColor, size: 20),
          ),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  // Badge type
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: typeColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(notif.typeLabel,
                        style: TextStyle(
                            color: typeColor,
                            fontSize: 9,
                            fontWeight: FontWeight.w700)),
                  ),
                  const Spacer(),
                  Text(notif.timeAgo,
                      style: const TextStyle(fontSize: 10, color: _kGray)),
                  if (!notif.isRead) ...[
                    const SizedBox(width: 6),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                          color: _kPrimary, shape: BoxShape.circle),
                    ),
                  ],
                ]),
                const SizedBox(height: 6),
                Text(notif.title,
                    style: TextStyle(
                        fontWeight:
                            notif.isRead ? FontWeight.w500 : FontWeight.w700,
                        fontSize: 13,
                        color: const Color(0xFF111827))),
                const SizedBox(height: 3),
                Text(notif.body,
                    style: const TextStyle(fontSize: 12, color: _kGray),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                if (notif.relatedCode != null) ...[
                  const SizedBox(height: 4),
                  Text('Réf : ${notif.relatedCode}',
                      style: const TextStyle(
                          fontSize: 10,
                          color: _kGray,
                          fontStyle: FontStyle.italic)),
                ],
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

// ── Helpers couleurs/icônes par type ──────────────────────────────────────
Color _typeColor(String type) {
  switch (type) {
    case 'INTERVENTION':
      return const Color(0xFFC27803);
    case 'DEPLOIEMENT':
      return const Color(0xFF057A55);
    case 'VEHICULE':
      return const Color(0xFF0694A2);
    case 'EQUIPEMENT':
      return const Color(0xFFC81E1E);
    case 'BOOKLET':
      return const Color(0xFF0F4C81);
    default:
      return const Color(0xFF6B7280);
  }
}

IconData _typeIcon(String type) {
  switch (type) {
    case 'INTERVENTION':
      return Icons.build_outlined;
    case 'DEPLOIEMENT':
      return Icons.local_shipping_outlined;
    case 'VEHICULE':
      return Icons.directions_car_outlined;
    case 'EQUIPEMENT':
      return Icons.inventory_2_outlined;
    case 'BOOKLET':
      return Icons.menu_book_outlined;
    default:
      return Icons.notifications_outlined;
  }
}
