// lib/features/vehicules/widgets/vehicule_card.dart

import 'package:flutter/material.dart';
import '../models/vehicule_model.dart';

const _kGreen = Color(0xFF2E7D52);
const _kOrange = Color(0xFFFF6F00);
const _kRed = Color(0xFFC62828);
const _kBlue = Color(0xFF1565C0);
const _kGray = Color(0xFF6B7280);

// ✅ Classes de config — remplace les records Dart 3 (tuples)
class _VStatut {
  final String label;
  final Color color;
  final IconData icon;
  const _VStatut(this.label, this.color, this.icon);
}

const _statutConfig = <String, _VStatut>{
  'DISPONIBLE':
      _VStatut('Disponible', Color(0xFF2E7D52), Icons.check_circle_outline),
  'EN_MISSION':
      _VStatut('En mission', Color(0xFF1565C0), Icons.navigation_outlined),
  'EN_PANNE': _VStatut('En panne', Color(0xFFC62828), Icons.error_outline),
  'EN_MAINTENANCE':
      _VStatut('Maintenance', Color(0xFFF57C00), Icons.build_outlined),
  'RETIRE': _VStatut('Retiré', Color(0xFF6B7280), Icons.block_outlined),
};

const _typeIcons = <String, IconData>{
  'VOITURE': Icons.directions_car_outlined,
  'MOTO': Icons.two_wheeler_outlined,
  'CAMION': Icons.local_shipping_outlined,
  'MINIBUS': Icons.airport_shuttle_outlined,
  'AUTRE': Icons.directions_bus_outlined,
};

// ── VehiculeCard ──────────────────────────────────────────────────────────────
class VehiculeCard extends StatelessWidget {
  final VehiculeModel vehicule;
  final bool canEdit;
  final bool canDelete;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const VehiculeCard({
    super.key,
    required this.vehicule,
    required this.canEdit,
    required this.canDelete,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    // ✅ accès par .label, .color, .icon au lieu de .$1, .$2, .$3
    final statut = _statutConfig[vehicule.statut] ??
        const _VStatut('Inconnu', _kGray, Icons.help_outline);
    final typeIcon = _typeIcons[vehicule.type] ?? Icons.directions_car_outlined;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 1.5,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Ligne 1 : immatriculation + statut
          Row(children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                  color: _kGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(typeIcon, color: _kGreen, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(vehicule.immatriculation,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                  if (vehicule.marque != null || vehicule.modele != null)
                    Text(
                        '${vehicule.marque ?? ''} ${vehicule.modele ?? ''}'
                            .trim(),
                        style: const TextStyle(color: _kGray, fontSize: 12)),
                ])),
            _StatutBadge(
                label: statut.label, color: statut.color, icon: statut.icon),
          ]),

          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 8),

          // Ligne 2 : conducteur + région
          Row(children: [
            _InfoChip(Icons.person_outline, vehicule.conducteur, _kBlue),
            const SizedBox(width: 8),
            if (vehicule.regionName != null)
              _InfoChip(
                  Icons.location_on_outlined, vehicule.regionName!, _kGray),
          ]),

          // Alertes documents
          if (vehicule.hasAlert) ...[
            const SizedBox(height: 8),
            Wrap(
                spacing: 6,
                runSpacing: 4,
                children: vehicule.alertesDocs
                    .map(
                      (a) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: (vehicule.hasExpiredDoc ? _kRed : _kOrange)
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: (vehicule.hasExpiredDoc ? _kRed : _kOrange)
                                  .withOpacity(0.3)),
                        ),
                        child: Text(a,
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color:
                                    vehicule.hasExpiredDoc ? _kRed : _kOrange)),
                      ),
                    )
                    .toList()),
          ],

          // Actions
          if (canEdit || canDelete) ...[
            const SizedBox(height: 10),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              if (canEdit)
                _ActionBtn(Icons.edit_outlined, 'Modifier', _kBlue, onEdit),
              if (canEdit && canDelete) const SizedBox(width: 8),
              if (canDelete)
                _ActionBtn(Icons.delete_outline, 'Supprimer', _kRed, onDelete),
            ]),
          ],
        ]),
      ),
    );
  }
}

// ── IncidentCard ──────────────────────────────────────────────────────────────
class IncidentCard extends StatelessWidget {
  final VehiculeIncidentModel incident;
  final bool canEdit, canDelete;
  final VoidCallback onEdit, onDelete;

  const IncidentCard({
    super.key,
    required this.incident,
    required this.canEdit,
    required this.canDelete,
    required this.onEdit,
    required this.onDelete,
  });

  Color get _typeColor {
    switch (incident.typeIncident) {
      case 'ACCIDENT':
        return _kRed;
      case 'VOL':
        return Colors.purple;
      default:
        return _kOrange;
    }
  }

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 1.5,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                    color: _typeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10)),
                child: Icon(Icons.warning_amber_outlined,
                    color: _typeColor, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(incident.immatriculation,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                    Text(_formatDate(incident.dateIncident),
                        style: const TextStyle(color: _kGray, fontSize: 12)),
                  ])),
              _TypeBadge(incident.typeIncident, _typeColor),
            ]),
            if (incident.description != null) ...[
              const SizedBox(height: 8),
              Text(incident.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _kGray, fontSize: 12)),
            ],
            if (incident.lieuIncident != null)
              Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: _InfoChip(Icons.location_on_outlined,
                      incident.lieuIncident!, _kGray)),
            if (incident.coutEstime != null)
              Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                      'Coût estimé : ${incident.coutEstime!.toStringAsFixed(0)} FCFA',
                      style: const TextStyle(
                          color: _kOrange,
                          fontSize: 12,
                          fontWeight: FontWeight.w600))),
            if (canEdit || canDelete) ...[
              const SizedBox(height: 10),
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                if (canEdit)
                  _ActionBtn(Icons.edit_outlined, 'Modifier', _kBlue, onEdit),
                if (canDelete) const SizedBox(width: 8),
                if (canDelete)
                  _ActionBtn(
                      Icons.delete_outline, 'Supprimer', _kRed, onDelete),
              ]),
            ],
          ]),
        ),
      );
}

// ── MaintenanceCard ───────────────────────────────────────────────────────────
class MaintenanceCard extends StatelessWidget {
  final VehiculeMaintenanceModel maintenance;
  final bool canEdit, canDelete;
  final VoidCallback onEdit, onDelete;

  const MaintenanceCard({
    super.key,
    required this.maintenance,
    required this.canEdit,
    required this.canDelete,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isPreventive = maintenance.typeMaintenance == 'PREVENTIVE';
    final color = isPreventive ? _kGreen : _kRed;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 1.5,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(Icons.build_outlined, color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(maintenance.immatriculation,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(_formatDate(maintenance.dateMaintenance),
                      style: const TextStyle(color: _kGray, fontSize: 12)),
                ])),
            _TypeBadge(isPreventive ? 'Préventive' : 'Curative', color),
          ]),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 4, children: [
            if (maintenance.prestataire != null)
              _InfoChip(
                  Icons.business_outlined, maintenance.prestataire!, _kGray),
            if (maintenance.coutReel != null)
              _InfoChip(Icons.attach_money_outlined,
                  '${maintenance.coutReel!.toStringAsFixed(0)} FCFA', _kOrange),
            if (maintenance.kilometrageIntervention != null)
              _InfoChip(Icons.speed_outlined,
                  '${maintenance.kilometrageIntervention} km', _kBlue),
          ]),
          if (canEdit || canDelete) ...[
            const SizedBox(height: 10),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              if (canEdit)
                _ActionBtn(Icons.edit_outlined, 'Modifier', _kBlue, onEdit),
              if (canDelete) const SizedBox(width: 8),
              if (canDelete)
                _ActionBtn(Icons.delete_outline, 'Supprimer', _kRed, onDelete),
            ]),
          ],
        ]),
      ),
    );
  }
}

// ── AffectationCard ───────────────────────────────────────────────────────────
class AffectationCard extends StatelessWidget {
  final VehiculeAffectationModel affectation;
  final bool canEdit;
  const AffectationCard(
      {super.key, required this.affectation, required this.canEdit});

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 1.5,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: _kBlue.withOpacity(0.1),
              child: Text(
                affectation.personNom.isNotEmpty
                    ? affectation.personNom[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                    color: _kBlue, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(affectation.personNom,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  if (affectation.personPoste != null)
                    Text(affectation.personPoste!,
                        style: const TextStyle(color: _kGray, fontSize: 12)),
                  Text(affectation.immatriculation,
                      style: const TextStyle(
                          color: _kGreen,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                  Text('Depuis le ${_formatDate(affectation.dateAffectation)}',
                      style: const TextStyle(color: _kGray, fontSize: 11)),
                ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                  color:
                      (affectation.active ? _kGreen : _kGray).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20)),
              child: Text(
                affectation.active ? '✓ Active' : 'Clôturée',
                style: TextStyle(
                    color: affectation.active ? _kGreen : _kGray,
                    fontSize: 11,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ]),
        ),
      );
}

// ── AlerteCard ────────────────────────────────────────────────────────────────
class AlerteCard extends StatelessWidget {
  final VehiculeAlerteModel alerte;
  const AlerteCard({super.key, required this.alerte});

  @override
  Widget build(BuildContext context) {
    final color = alerte.isExpire ? _kRed : _kOrange;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      color: color.withOpacity(0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: color.withOpacity(0.3)),
      ),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: color.withOpacity(0.15), shape: BoxShape.circle),
            child: Icon(
                alerte.isExpire
                    ? Icons.error_outline
                    : Icons.access_time_outlined,
                color: color,
                size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(alerte.immatriculation,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14)),
                Text(alerte.typeAlerte.replaceAll('_', ' '),
                    style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
                Text('Expiration : ${_formatDate(alerte.dateExpiration)}',
                    style: const TextStyle(color: _kGray, fontSize: 11)),
              ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(20)),
            child: Text(
              alerte.isExpire ? 'EXPIRÉ' : '${alerte.joursRestants}j',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ]),
      ),
    );
  }
}

// ── Widgets réutilisables ─────────────────────────────────────────────────────
class _StatutBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  const _StatutBadge(
      {required this.label, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 11, fontWeight: FontWeight.w600)),
        ]),
      );
}

class _TypeBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _TypeBadge(this.label, this.color);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20)),
        child: Text(label,
            style: TextStyle(
                color: color, fontSize: 11, fontWeight: FontWeight.w600)),
      );
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _InfoChip(this.icon, this.label, this.color);

  @override
  Widget build(BuildContext context) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 3),
        Flexible(
            child: Text(label,
                style: TextStyle(color: color, fontSize: 11),
                overflow: TextOverflow.ellipsis,
                maxLines: 1)),
      ]);
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn(this.icon, this.label, this.color, this.onTap);

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    color: color, fontSize: 12, fontWeight: FontWeight.w600)),
          ]),
        ),
      );
}

String _formatDate(String? iso) {
  if (iso == null || iso.isEmpty) return '—';
  try {
    final d = DateTime.parse(iso);
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  } catch (_) {
    return iso;
  }
}
