// lib/features/profile/screens/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: AppTheme.lightBg,
      appBar: AppBar(title: const Text('Mon Profil')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ── Avatar ───────────────────────────────────────────
            const SizedBox(height: 12),
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 52,
                    backgroundColor: AppTheme.primary.withOpacity(0.12),
                    child: Text(
                      '${user.firstName[0]}${user.lastName[0]}'.toUpperCase(),
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(Icons.person,
                          color: Colors.white, size: 14),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Nom + Rôle ────────────────────────────────────────
            Text(user.fullName,
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.dark)),
            const SizedBox(height: 6),
            _RoleBadge(role: user.role),
            const SizedBox(height: 24),

            // ── Infos ─────────────────────────────────────────────
            _InfoCard(children: [
              _InfoRow(
                icon: Icons.email_outlined,
                label: 'Email',
                value: user.email,
              ),
              if (user.contact != null && user.contact!.isNotEmpty)
                _InfoRow(
                  icon: Icons.phone_outlined,
                  label: 'Contact',
                  value: user.contact!,
                ),
              if (user.partnerName != null)
                _InfoRow(
                  icon: Icons.business_outlined,
                  label: 'Partenaire',
                  value: user.partnerName!,
                ),
              _InfoRow(
                icon: Icons.badge_outlined,
                label: 'ID',
                value: '#${user.id}',
              ),
            ]),
            const SizedBox(height: 16),

            // ── Permissions ───────────────────────────────────────
            _InfoCard(children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: Text('Permissions',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppTheme.dark)),
              ),
              _PermRow(
                label: 'Créer des enregistrements',
                allowed: user.canCreate,
              ),
              _PermRow(
                label: 'Supprimer des enregistrements',
                allowed: user.canDelete,
              ),
              _PermRow(
                label: 'Accès Super Admin',
                allowed: user.isSuperAdmin,
              ),
            ]),
            const SizedBox(height: 24),

            // ── Bouton déconnexion ────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _confirmLogout(context),
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text('Se déconnecter',
                    style: TextStyle(color: Colors.red)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthProvider>().logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Déconnecter',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ── Widgets internes ──────────────────────────────────────────────────────────

class _RoleBadge extends StatelessWidget {
  final String role;
  const _RoleBadge({required this.role});

  Color get _color {
    switch (role) {
      case 'SUPER_ADMIN':
        return Colors.purple;
      case 'ADMIN':
        return AppTheme.primary;
      case 'TECHNICIEN':
        return AppTheme.warning;
      default:
        return AppTheme.gray;
    }
  }

  String get _label {
    switch (role) {
      case 'SUPER_ADMIN':
        return 'Super Administrateur';
      case 'ADMIN':
        return 'Administrateur';
      case 'TECHNICIEN':
        return 'Technicien';
      default:
        return 'Utilisateur';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withOpacity(0.3)),
      ),
      child: Text(_label,
          style: TextStyle(
              color: _color, fontWeight: FontWeight.w600, fontSize: 13)),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      );
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: AppTheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(fontSize: 11, color: AppTheme.gray)),
                Text(value,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.dark)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PermRow extends StatelessWidget {
  final String label;
  final bool allowed;
  const _PermRow({required this.label, required this.allowed});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            allowed ? Icons.check_circle_outline : Icons.cancel_outlined,
            color: allowed ? AppTheme.success : AppTheme.gray,
            size: 18,
          ),
          const SizedBox(width: 10),
          Text(label,
              style: TextStyle(
                  fontSize: 13,
                  color: allowed ? AppTheme.dark : AppTheme.gray)),
        ],
      ),
    );
  }
}
