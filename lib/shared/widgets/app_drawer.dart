// lib/shared/widgets/app_drawer.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../core/models/user_model.dart';
import '../../features/home/screens/home_screen.dart';

class AppDrawer extends StatelessWidget {
  final AppRoute currentRoute;
  final void Function(AppRoute) onRouteSelected;

  const AppDrawer({
    super.key,
    required this.currentRoute,
    required this.onRouteSelected,
  });

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    final bool isAdmin = user?.isSuperAdmin == true || user?.isAdmin == true;
    final bool isTechnicien = user?.isTechnicien == true;
    final bool isLogisticien = user?.role.toUpperCase() == 'LOGISTICIEN';

    return Drawer(
      child: Column(children: [
        _DrawerHeader(user: user),
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              const _SectionLabel('PRINCIPAL'),
              _DrawerItem(
                icon: Icons.dashboard_outlined,
                label: 'Tableau de bord',
                route: AppRoute.dashboard,
                current: currentRoute,
                onTap: () => _navigate(context, AppRoute.dashboard),
              ),
              if (isAdmin || isTechnicien) ...[
                const _SectionLabel('ÉQUIPEMENTS'),
                _DrawerItem(
                  icon: Icons.inventory_2_outlined,
                  label: 'Acquisitions',
                  route: AppRoute.acquisitions,
                  current: currentRoute,
                  onTap: () => _navigate(context, AppRoute.acquisitions),
                ),
                _DrawerItem(
                  icon: Icons.local_shipping_outlined,
                  label: 'Déploiements',
                  route: AppRoute.deployments,
                  current: currentRoute,
                  onTap: () => _navigate(context, AppRoute.deployments),
                ),
                _DrawerItem(
                  icon: Icons.build_outlined,
                  label: 'Interventions',
                  route: AppRoute.interventions,
                  current: currentRoute,
                  onTap: () => _navigate(context, AppRoute.interventions),
                ),
                _DrawerItem(
                  icon: Icons.archive_outlined,
                  label: 'Archives',
                  route: AppRoute.archives,
                  current: currentRoute,
                  onTap: () => _navigate(context, AppRoute.archives),
                ),
                _DrawerItem(
                  icon: Icons.menu_book_outlined,
                  label: 'Booklets',
                  route: AppRoute.booklets,
                  current: currentRoute,
                  onTap: () => _navigate(context, AppRoute.booklets),
                ),
              ],
              if (isAdmin || isLogisticien) ...[
                const _SectionLabel('LOGISTIQUE'),
                _DrawerItem(
                  icon: Icons.directions_car_outlined,
                  label: 'Parc véhicules',
                  route: AppRoute.vehicules,
                  current: currentRoute,
                  iconColor: const Color(0xFF2E7D32),
                  onTap: () => _navigate(context, AppRoute.vehicules),
                ),
                _DrawerItem(
                  icon: Icons.category_outlined,
                  label: 'Fournitures',
                  route: AppRoute.fournitures,
                  current: currentRoute,
                  iconColor: const Color(0xFF1565C0),
                  onTap: () => _navigate(context, AppRoute.fournitures),
                ),
              ],
              if (isAdmin || isTechnicien || isLogisticien) ...[
                const _SectionLabel('ORGANISATION'),
                _DrawerItem(
                  icon: Icons.map_outlined,
                  label: 'Périmètre géographique',
                  route: AppRoute.technicianSites,
                  current: currentRoute,
                  iconColor: const Color(0xFF0F4C81),
                  onTap: () => _navigate(context, AppRoute.technicianSites),
                ),
              ],
              const Divider(height: 24, indent: 16, endIndent: 16),
              // ✅ ListTile profil avec shape natif — pas de DecoratedBox parent
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                child: ListTile(
                  dense: true,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  leading: Icon(Icons.person_outline,
                      size: 22, color: Colors.grey.shade600),
                  title: const Text('Mon profil',
                      style:
                          TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/profile');
                  },
                ),
              ),
            ],
          ),
        ),
        _DrawerFooter(
          onLogout: () => _logout(context, context.read<AuthProvider>()),
        ),
      ]),
    );
  }

  void _navigate(BuildContext context, AppRoute route) {
    Navigator.pop(context);
    onRouteSelected(route);
  }

  void _logout(BuildContext context, AuthProvider auth) {
    Navigator.pop(context);
    auth.logout();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// En-tête
// ─────────────────────────────────────────────────────────────────────────────
class _DrawerHeader extends StatelessWidget {
  final UserModel? user;
  const _DrawerHeader({this.user});

  @override
  Widget build(BuildContext context) {
    final firstName = user?.firstName ?? '';
    final lastName = user?.lastName ?? '';
    final role = user?.role ?? '';
    final name = '$firstName $lastName'.trim();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
          16, MediaQuery.of(context).padding.top + 16, 16, 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D3380), Color(0xFF1565C0)],
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: Colors.white.withValues(alpha: 0.2),
          child: Text(
            _initials(firstName, lastName),
            style: const TextStyle(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          name.isEmpty ? 'Utilisateur' : name,
          style: const TextStyle(
              color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(_roleLabel(role),
              style: const TextStyle(color: Colors.white70, fontSize: 11)),
        ),
      ]),
    );
  }

  static String _initials(String firstName, String lastName) {
    final f = firstName.isNotEmpty ? firstName[0].toUpperCase() : '';
    final l = lastName.isNotEmpty ? lastName[0].toUpperCase() : '';
    return (f.isEmpty && l.isEmpty) ? '?' : '$f$l';
  }

  static String _roleLabel(String role) {
    switch (role.toUpperCase()) {
      case 'SUPER_ADMIN':
        return 'Super Administrateur';
      case 'ADMIN':
        return 'Administrateur';
      case 'TECHNICIEN':
        return 'Technicien';
      case 'LOGISTICIEN':
        return 'Logisticien';
      case 'USER':
        return 'Utilisateur';
      default:
        return role.isEmpty ? '—' : role;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Item de menu — tileColor + shape natifs, pas de Container avec color
// ─────────────────────────────────────────────────────────────────────────────
class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final AppRoute route;
  final AppRoute current;
  final VoidCallback onTap;
  final Color? iconColor;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.route,
    required this.current,
    required this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = route == current;
    final color = iconColor ?? const Color(0xFF0D3380);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      child: ListTile(
        dense: true,
        tileColor: isActive ? color.withValues(alpha: 0.1) : Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        leading: Icon(icon,
            size: 22, color: isActive ? color : Colors.grey.shade600),
        title: Text(label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              color: isActive ? color : Colors.grey.shade800,
            )),
        trailing: isActive
            ? Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                    color: color, borderRadius: BorderRadius.circular(2)))
            : null,
        onTap: onTap,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section label
// ─────────────────────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 2),
        child: Text(text,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade500,
              letterSpacing: 1.2,
            )),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Pied de drawer
// ─────────────────────────────────────────────────────────────────────────────
class _DrawerFooter extends StatelessWidget {
  final VoidCallback onLogout;
  const _DrawerFooter({required this.onLogout});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onLogout,
            icon: const Icon(Icons.logout, size: 18, color: Colors.red),
            label: const Text('Déconnexion',
                style:
                    TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.red, width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
      );
}
