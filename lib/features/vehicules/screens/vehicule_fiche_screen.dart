// lib/features/vehicules/screens/vehicule_fiche_screen.dart

import 'package:flutter/material.dart';
import '../models/vehicule_model.dart';
import '../services/vehicule_print_service.dart';
import '../services/vehicule_service.dart';

const _kGreen = Color(0xFF2E7D32);
const _kGreenBg = Color(0xFFF4FAF6);
const _kTextDark = Color(0xFF1A237E);
const _kTextGray = Color(0xFF546E7A);
const _kOrange = Color(0xFFFF6F00);

class VehiculeFicheScreen extends StatefulWidget {
  final int vehiculeId;
  const VehiculeFicheScreen({super.key, required this.vehiculeId});

  @override
  State<VehiculeFicheScreen> createState() => _VehiculeFicheScreenState();
}

class _VehiculeFicheScreenState extends State<VehiculeFicheScreen> {
  final _service = VehiculeService();
  final _print = VehiculePrintService();

  VehiculeModel? _vehicule;
  bool _loading = true;
  String? _error;
  bool _pdfEnCours = false;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final v = await _service.getVehicule(widget.vehiculeId);
      if (!mounted) return;
      setState(() {
        _vehicule = v;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kGreenBg,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: _kGreen));
    }
    if (_error != null) {
      return _ErreurView(message: _error!, onRetry: _charger);
    }
    if (_vehicule == null) {
      return const Center(child: Text('Aucune donnée'));
    }

    final v = _vehicule!;

    return CustomScrollView(slivers: [
      _SliverHeader(vehicule: v, onRefresh: _charger),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
        sliver: SliverList(
          delegate: SliverChildListDelegate([
            const SizedBox(height: 16),
            _SectionInfos(vehicule: v),
            const SizedBox(height: 14),
            _SectionDocuments(vehicule: v),
            const SizedBox(height: 14),
            _SectionActions(
              vehicule: v,
              print: _print,
              pdfEnCours: _pdfEnCours,
              onPdfEnCoursChanged: (val) => setState(() => _pdfEnCours = val),
            ),
            const SizedBox(height: 8),
          ]),
        ),
      ),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  SLIVER HEADER
// ─────────────────────────────────────────────────────────────────────────────

class _SliverHeader extends StatelessWidget {
  final VehiculeModel vehicule;
  final VoidCallback onRefresh;
  const _SliverHeader({required this.vehicule, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 150,
      pinned: true,
      backgroundColor: _kGreen,
      foregroundColor: Colors.white,
      actions: [
        IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualiser',
            onPressed: onRefresh),
        const SizedBox(width: 4),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                        child: Text(vehicule.immatriculation,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border:
                              Border.all(color: Colors.white.withOpacity(0.4)),
                        ),
                        child: Text(
                          vehicule.statut.replaceAll('_', ' '),
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              letterSpacing: 0.5),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 8),
                    if (vehicule.marque != null || vehicule.modele != null)
                      Text(
                          '${vehicule.marque ?? ''} ${vehicule.modele ?? ''}'
                              .trim(),
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 13)),
                  ]),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  SECTION INFORMATIONS
// ─────────────────────────────────────────────────────────────────────────────

class _SectionInfos extends StatelessWidget {
  final VehiculeModel vehicule;
  const _SectionInfos({required this.vehicule});

  @override
  Widget build(BuildContext context) {
    return _Carte(
      titre: 'INFORMATIONS',
      icone: Icons.info_outline,
      child: Column(children: [
        Row(children: [
          Expanded(child: _InfoCellule(label: 'Type', valeur: vehicule.type)),
          const SizedBox(width: 10),
          Expanded(
              child: _InfoCellule(
                  label: 'Couleur', valeur: vehicule.couleur ?? '—')),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
              child: _InfoCellule(
                  label: 'Kilométrage',
                  valeur: vehicule.kilometrage != null
                      ? '${vehicule.kilometrage} km'
                      : '—')),
          const SizedBox(width: 10),
          Expanded(
              child: _InfoCellule(
                  label: 'Conducteur', valeur: vehicule.conducteur)),
        ]),
        if (vehicule.observations != null &&
            vehicule.observations!.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFE8F5EE)),
          const SizedBox(height: 12),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.notes_outlined, size: 16, color: _kTextGray),
            const SizedBox(width: 8),
            Expanded(
                child: Text(vehicule.observations!,
                    style: const TextStyle(
                        fontSize: 13,
                        color: _kTextGray,
                        fontStyle: FontStyle.italic,
                        height: 1.5))),
          ]),
        ],
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  SECTION DOCUMENTS
// ─────────────────────────────────────────────────────────────────────────────

class _SectionDocuments extends StatelessWidget {
  final VehiculeModel vehicule;
  const _SectionDocuments({required this.vehicule});

  @override
  Widget build(BuildContext context) {
    return _Carte(
      titre: 'DOCUMENTS ADMINISTRATIFS',
      icone: Icons.description_outlined,
      child: Column(children: [
        if (vehicule.hasAlert) ...[
          Wrap(
              spacing: 6,
              runSpacing: 6,
              children: vehicule.alertesDocs
                  .map((a) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                            color: _kOrange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8)),
                        child: Text(a,
                            style: const TextStyle(
                                color: _kOrange,
                                fontSize: 11,
                                fontWeight: FontWeight.w600)),
                      ))
                  .toList()),
          const SizedBox(height: 10),
        ] else
          Row(children: [
            const Icon(Icons.check_circle_outline, color: _kGreen, size: 16),
            const SizedBox(width: 6),
            const Text('Tous les documents sont à jour',
                style: TextStyle(
                    color: _kGreen, fontSize: 12, fontWeight: FontWeight.w500)),
          ]),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  SECTION ACTIONS
// ─────────────────────────────────────────────────────────────────────────────

class _SectionActions extends StatelessWidget {
  final VehiculeModel vehicule;
  final VehiculePrintService print;
  final bool pdfEnCours;
  final ValueChanged<bool> onPdfEnCoursChanged;

  const _SectionActions({
    required this.vehicule,
    required this.print,
    required this.pdfEnCours,
    required this.onPdfEnCoursChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _Carte(
      titre: 'ACTIONS',
      icone: Icons.bolt_outlined,
      child: Column(children: [
        _ActionTuile(
          icone: Icons.picture_as_pdf_outlined,
          couleurIcone: _kGreen,
          titre: 'Générer PDF',
          sousTitre: 'Créer la fiche avec QR code',
          loading: pdfEnCours,
          onTap: () => _genererPdf(context),
        ),
        const SizedBox(height: 10),
        _ActionTuile(
          icone: Icons.share_outlined,
          couleurIcone: const Color(0xFF1565C0),
          titre: 'Partager',
          sousTitre: 'Partager la fiche PDF',
          onTap: () => print.sharePdf(vehicule),
        ),
        const SizedBox(height: 10),
        _ActionTuile(
          icone: Icons.print_outlined,
          couleurIcone: const Color(0xFF6A1B9A),
          titre: 'Imprimer',
          sousTitre: 'Via imprimante réseau',
          onTap: () => _imprimer(context),
        ),
      ]),
    );
  }

  Future<void> _genererPdf(BuildContext ctx) async {
    onPdfEnCoursChanged(true);
    try {
      await print.previewFiche(ctx, vehicule);
    } finally {
      onPdfEnCoursChanged(false);
    }
  }

  Future<void> _imprimer(BuildContext ctx) async {
    onPdfEnCoursChanged(true);
    try {
      await print.printFiche(ctx, vehicule);
    } finally {
      onPdfEnCoursChanged(false);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  COMPOSANTS RÉUTILISABLES
// ─────────────────────────────────────────────────────────────────────────────

class _Carte extends StatelessWidget {
  final String titre;
  final IconData icone;
  final Widget child;
  const _Carte({required this.titre, required this.icone, required this.child});

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(children: [
              Icon(icone, size: 16, color: _kGreen),
              const SizedBox(width: 7),
              Text(titre,
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: _kTextGray,
                      letterSpacing: 1.2)),
            ]),
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          Padding(padding: const EdgeInsets.all(16), child: child),
        ]),
      );
}

class _InfoCellule extends StatelessWidget {
  final String label;
  final String valeur;
  const _InfoCellule({required this.label, required this.valeur});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _kGreenBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFDCEDC8)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 10,
                  color: _kTextGray,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(valeur,
              style: const TextStyle(
                  fontSize: 14,
                  color: _kTextDark,
                  fontWeight: FontWeight.bold)),
        ]),
      );
}

class _ActionTuile extends StatelessWidget {
  final IconData icone;
  final Color couleurIcone;
  final String titre;
  final String sousTitre;
  final VoidCallback onTap;
  final bool loading;

  const _ActionTuile({
    required this.icone,
    required this.couleurIcone,
    required this.titre,
    required this.sousTitre,
    required this.onTap,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: loading ? null : onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: couleurIcone.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: couleurIcone.withOpacity(0.15)),
          ),
          child: Row(children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: couleurIcone.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: loading
                  ? Padding(
                      padding: const EdgeInsets.all(10),
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: couleurIcone))
                  : Icon(icone, color: couleurIcone, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titre,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: couleurIcone)),
                    Text(sousTitre,
                        style:
                            const TextStyle(fontSize: 11, color: _kTextGray)),
                  ]),
            ),
            Icon(Icons.arrow_forward_ios,
                size: 14, color: couleurIcone.withOpacity(0.5)),
          ]),
        ),
      );
}

class _ErreurView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErreurView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.cloud_off, size: 64, color: Color(0xFF90A4AE)),
            const SizedBox(height: 16),
            const Text('Impossible de charger la fiche',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _kTextDark)),
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: _kTextGray, fontSize: 13)),
            const SizedBox(height: 24),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: _kGreen),
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
              onPressed: onRetry,
            ),
          ]),
        ),
      );
}
