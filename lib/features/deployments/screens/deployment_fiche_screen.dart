// lib/features/deployments/screens/deployment_fiche_screen.dart
//
// Corrections :
//   ✅ PrintMailService() → PrintService() / MailerService()
//   ✅ Import print_mail_service.dart ajouté

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/deployment_model.dart';
import '../providers/deployment_provider.dart';
import '../services/print_mail_service.dart'; // ← import corrigé
import 'deployment_form_screen.dart';

const _kGreen = Color(0xFF2E7D52);
const _kGreenLight = Color(0xFFE8F5EE);
const _kGreenBg = Color(0xFFF4FAF6);
const _kTextDark = Color(0xFF1A237E);
const _kTextGray = Color(0xFF546E7A);

class DeploymentFicheScreen extends StatefulWidget {
  final int deploiementId;
  const DeploymentFicheScreen({super.key, required this.deploiementId});

  @override
  State<DeploymentFicheScreen> createState() => _DeploymentFicheScreenState();
}

class _DeploymentFicheScreenState extends State<DeploymentFicheScreen> {
  late final DeploymentFicheProvider _prov;

  @override
  void initState() {
    super.initState();
    _prov = DeploymentFicheProvider();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _prov.charger(widget.deploiementId);
    });
  }

  @override
  void dispose() {
    _prov.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _prov,
      child: Consumer<DeploymentFicheProvider>(
        builder: (ctx, prov, _) => Scaffold(
          backgroundColor: _kGreenBg,
          body: _buildBody(ctx, prov),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext ctx, DeploymentFicheProvider prov) {
    if (prov.isLoading) {
      return const Center(child: CircularProgressIndicator(color: _kGreen));
    }
    if (prov.hasError) {
      return _ErreurView(
          message: prov.errorMessage ?? 'Erreur inconnue',
          onRetry: () => prov.charger(widget.deploiementId));
    }
    if (prov.fiche == null) {
      return const Center(child: Text('Aucune donnée'));
    }

    final dep = prov.fiche!;

    return CustomScrollView(slivers: [
      _SliverHeader(
          dep: dep, prov: prov, onEditer: () => _ouvrirEdition(ctx, dep)),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
        sliver: SliverList(
          delegate: SliverChildListDelegate([
            const SizedBox(height: 16),
            _SectionInfos(dep: dep),
            const SizedBox(height: 14),
            _SectionEquipements(dep: dep, prov: prov),
            const SizedBox(height: 14),
            _SectionActions(dep: dep, prov: prov),
            const SizedBox(height: 14),
            _SectionSignatures(dep: dep),
            const SizedBox(height: 8),
          ]),
        ),
      ),
    ]);
  }

  void _ouvrirEdition(BuildContext ctx, DeploymentModel dep) async {
    final result = await Navigator.push<DeploymentModel>(
      ctx,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider(
          create: (_) => DeploymentFormProvider(),
          child: DeploymentFormScreen(deploymentExistant: dep),
        ),
      ),
    );
    if (result != null && mounted) _prov.charger(result.id);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  SLIVER HEADER
// ─────────────────────────────────────────────────────────────────────────────

class _SliverHeader extends StatelessWidget {
  final DeploymentModel dep;
  final DeploymentFicheProvider prov;
  final VoidCallback onEditer;

  const _SliverHeader({
    required this.dep,
    required this.prov,
    required this.onEditer,
  });

  @override
  Widget build(BuildContext context) {
    final couleur = Color(DeploymentStatut.color(dep.statut));

    return SliverAppBar(
      expandedHeight: 170,
      pinned: true,
      backgroundColor: _kGreen,
      foregroundColor: Colors.white,
      actions: [
        if (dep.statut != DeploymentStatut.archive)
          IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Modifier',
              onPressed: onEditer),
        IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualiser',
            onPressed: () => prov.refresh()),
        const SizedBox(width: 4),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1B5E37), Color(0xFF2E7D52)],
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
                        child: Text(dep.codeDep,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold)),
                      ),
                      _BadgeStatutGrand(statut: dep.statut, couleur: couleur),
                    ]),
                    const SizedBox(height: 8),
                    Row(children: [
                      if (dep.healthName != null) ...[
                        const Icon(Icons.location_on_outlined,
                            color: Colors.white70, size: 15),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(dep.healthName!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 13)),
                        ),
                      ],
                      if (dep.dateReception != null) ...[
                        const SizedBox(width: 12),
                        const Icon(Icons.calendar_today_outlined,
                            color: Colors.white70, size: 13),
                        const SizedBox(width: 4),
                        Text(_formatDate(dep.dateReception!),
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 13)),
                      ],
                    ]),
                  ]),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      final d = DateTime.parse(iso);
      const m = [
        '',
        'Jan',
        'Fév',
        'Mar',
        'Avr',
        'Mai',
        'Jun',
        'Jul',
        'Aoû',
        'Sep',
        'Oct',
        'Nov',
        'Déc',
      ];
      return '${d.day} ${m[d.month]} ${d.year}';
    } catch (_) {
      return iso;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  SECTION INFORMATIONS
// ─────────────────────────────────────────────────────────────────────────────

class _SectionInfos extends StatelessWidget {
  final DeploymentModel dep;
  const _SectionInfos({required this.dep});

  @override
  Widget build(BuildContext context) {
    return _Carte(
      titre: 'INFORMATIONS',
      icone: Icons.info_outline,
      child: Column(children: [
        Row(children: [
          Expanded(
              child:
                  _InfoCellule(label: 'Région', valeur: dep.regionName ?? '—')),
          const SizedBox(width: 10),
          Expanded(
              child: _InfoCellule(
                  label: 'District', valeur: dep.districtName ?? '—')),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
              child: _InfoCellule(
                  label: 'Réception',
                  valeur: dep.dateReception != null
                      ? _formatDate(dep.dateReception!)
                      : '—')),
          const SizedBox(width: 10),
          Expanded(
              child: _InfoCellule(
                  label: 'Équipements',
                  valeur:
                      '${dep.totalUnites} unité${dep.totalUnites > 1 ? 's' : ''}')),
        ]),
        if (dep.app != null) ...[
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFE8F5EE)),
          const SizedBox(height: 12),
          _InfoLigne(
              icone: Icons.apps_outlined,
              label: 'Application',
              valeur: dep.app!.nomComplet),
        ],
        if (dep.partnerPrincipal != null) ...[
          const SizedBox(height: 8),
          _InfoLigne(
              icone: Icons.business_outlined,
              label: 'Partenaire principal',
              valeur: dep.partnerPrincipal!.nom),
        ],
        if (dep.partnerSecondaire != null) ...[
          const SizedBox(height: 8),
          _InfoLigne(
              icone: Icons.business_center_outlined,
              label: 'Partenaire secondaire',
              valeur: dep.partnerSecondaire!.nom),
        ],
        if (dep.observations != null && dep.observations!.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFE8F5EE)),
          const SizedBox(height: 12),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.notes_outlined, size: 16, color: _kTextGray),
            const SizedBox(width: 8),
            Expanded(
                child: Text(dep.observations!,
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

  String _formatDate(String iso) {
    try {
      final d = DateTime.parse(iso);
      return '${d.day.toString().padLeft(2, '0')}/'
          '${d.month.toString().padLeft(2, '0')}/'
          '${d.year}';
    } catch (_) {
      return iso;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  SECTION ÉQUIPEMENTS
// ─────────────────────────────────────────────────────────────────────────────

class _SectionEquipements extends StatelessWidget {
  final DeploymentModel dep;
  final DeploymentFicheProvider prov;
  const _SectionEquipements({required this.dep, required this.prov});

  @override
  Widget build(BuildContext context) {
    final grouped = dep.itemsParType;

    return _Carte(
      titre: 'ÉQUIPEMENTS',
      icone: Icons.medical_services_outlined,
      child: Column(
          children: grouped.entries.map((entry) {
        final type = entry.key;
        final items = entry.value;
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(children: [
              Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                      color: _kGreen, borderRadius: BorderRadius.circular(3))),
              Expanded(
                  child: Text(type,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: _kTextDark))),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                    color: _kGreenLight,
                    borderRadius: BorderRadius.circular(20)),
                child: Text('×${items.length}',
                    style: const TextStyle(
                        color: _kGreen,
                        fontWeight: FontWeight.bold,
                        fontSize: 12)),
              ),
            ]),
          ),
          ...items.map((item) => _LigneItem(
                item: item,
                onToggle: item.id != null
                    ? () => prov.toggleReceptionItem(item.id!)
                    : null,
              )),
          if (entry.key != grouped.entries.last.key)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Divider(height: 1, color: Color(0xFFE8F5EE)),
            ),
        ]);
      }).toList()),
    );
  }
}

class _LigneItem extends StatelessWidget {
  final DeploymentItem item;
  final VoidCallback? onToggle;
  const _LigneItem({required this.item, this.onToggle});

  @override
  Widget build(BuildContext context) {
    final checked = item.receptionConfirm;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(children: [
        const SizedBox(width: 18),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item.numeroSerie,
                style: const TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                    color: _kTextDark,
                    fontWeight: FontWeight.w500)),
            if (item.observations != null && item.observations!.isNotEmpty)
              Text(item.observations!,
                  style: const TextStyle(
                      fontSize: 11,
                      color: _kTextGray,
                      fontStyle: FontStyle.italic)),
          ]),
        ),
        if (item.statut != null && item.statut != 'FONCTIONNEL')
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6)),
            child: Text(item.statut!.replaceAll('_', ' '),
                style: const TextStyle(
                    color: Colors.orange,
                    fontSize: 10,
                    fontWeight: FontWeight.w600)),
          ),
        GestureDetector(
          onTap: onToggle,
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: checked ? _kGreen : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                  color: checked ? _kGreen : const Color(0xFFCFD8DC),
                  width: 1.5),
            ),
            child: checked
                ? const Icon(Icons.check, color: Colors.white, size: 16)
                : null,
          ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  SECTION ACTIONS  ← PrintMailService → PrintService / MailerService
// ─────────────────────────────────────────────────────────────────────────────

class _SectionActions extends StatelessWidget {
  final DeploymentModel dep;
  final DeploymentFicheProvider prov;
  const _SectionActions({required this.dep, required this.prov});

  // ✅ Instances corrigées
  PrintService get _print => PrintService();
  MailerService get _mailer => MailerService();

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
          sousTitre: 'Créer un document imprimable',
          loading: prov.pdfEnCours,
          onTap: () => _genererPdf(context),
        ),
        const SizedBox(height: 10),
        _ActionTuile(
          icone: Icons.email_outlined,
          couleurIcone: const Color(0xFF1565C0),
          titre: 'Envoyer par e-mail',
          sousTitre: 'Partager la fiche PDF',
          onTap: () => _envoyerEmail(context),
        ),
        const SizedBox(height: 10),
        _ActionTuile(
          icone: Icons.print_outlined,
          couleurIcone: const Color(0xFF6A1B9A),
          titre: 'Imprimer',
          sousTitre: 'Via imprimante réseau',
          onTap: () => _imprimer(context),
        ),
        if (dep.statut == DeploymentStatut.livre) ...[
          const SizedBox(height: 10),
          _ActionTuile(
            icone: Icons.archive_outlined,
            couleurIcone: const Color(0xFF795548),
            titre: 'Archiver',
            sousTitre: 'Stocker dans les archives',
            loading: prov.archivageEnCours,
            onTap: () => _archiver(context),
          ),
        ],
      ]),
    );
  }

  Future<void> _genererPdf(BuildContext ctx) async {
    prov.setPdfEnCours(true);
    try {
      await _print.previewFiche(ctx, dep);
    } finally {
      prov.setPdfEnCours(false);
    }
  }

  Future<void> _imprimer(BuildContext ctx) async {
    prov.setPdfEnCours(true);
    try {
      await _print.printFiche(ctx, dep);
    } finally {
      prov.setPdfEnCours(false);
    }
  }

  Future<void> _envoyerEmail(BuildContext ctx) async {
    await _showEmailDialog(ctx);
  }

  Future<void> _archiver(BuildContext ctx) async {
    final ok = await showDialog<bool>(
          context: ctx,
          builder: (_) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Archiver ce déploiement ?',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            content: Text('${dep.codeDep} sera déplacé dans les archives.'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Annuler')),
              FilledButton(
                  style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF795548)),
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Archiver',
                      style: TextStyle(color: Colors.white))),
            ],
          ),
        ) ??
        false;
    if (!ok) return;
    final succes = await prov.archiver();
    if (ctx.mounted) {
      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
        content: Text(succes
            ? 'Déploiement archivé avec succès'
            : prov.errorMessage ?? 'Erreur'),
        backgroundColor: succes ? Colors.green.shade700 : Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Future<void> _showEmailDialog(BuildContext ctx) async {
    final recipCtrl = TextEditingController();
    final msgCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool sending = false;

    await showDialog(
      context: ctx,
      barrierDismissible: false,
      builder: (dCtx) => StatefulBuilder(
        builder: (dCtx, setS) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(children: [
            Icon(Icons.email, color: _kGreen),
            SizedBox(width: 8),
            Text('Envoyer la fiche',
                style: TextStyle(
                    color: _kGreen, fontSize: 16, fontWeight: FontWeight.bold)),
          ]),
          content: Form(
            key: formKey,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextFormField(
                controller: recipCtrl,
                decoration: const InputDecoration(
                  labelText: 'Destinataire(s)',
                  hintText: 'email@exemple.ci',
                  prefixIcon: Icon(Icons.alternate_email),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Requis' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: msgCtrl,
                decoration: const InputDecoration(
                  labelText: 'Message (optionnel)',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              if (sending) ...[
                const SizedBox(height: 16),
                const Row(children: [
                  SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: _kGreen)),
                  SizedBox(width: 10),
                  Text('Envoi en cours…'),
                ]),
              ],
            ]),
          ),
          actions: sending
              ? []
              : [
                  TextButton(
                      onPressed: () => Navigator.pop(dCtx),
                      child: const Text('Annuler')),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.share, size: 16),
                    label: const Text('Partager'),
                    style: OutlinedButton.styleFrom(
                        foregroundColor: _kGreen,
                        side: const BorderSide(color: _kGreen)),
                    onPressed: () {
                      Navigator.pop(dCtx);
                      _mailer.sharePdf(dep);
                    },
                  ),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: _kGreen),
                    icon: const Icon(Icons.send, size: 16),
                    label: const Text('Envoyer'),
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      setS(() => sending = true);
                      final recipients = recipCtrl.text
                          .split(',')
                          .map((e) => e.trim())
                          .where((e) => e.isNotEmpty)
                          .toList();
                      final result = await _mailer.sendEmail(
                        deployment: dep,
                        recipients: recipients,
                        customMessage: msgCtrl.text.trim(),
                      );
                      if (dCtx.mounted) Navigator.pop(dCtx);
                      if (ctx.mounted) {
                        final (msg, color) = switch (result) {
                          MailSuccess() => (
                              'E-mail envoyé',
                              Colors.green.shade700
                            ),
                          MailError(:final message) => (
                              'Erreur : $message',
                              Colors.red.shade700
                            ),
                        };
                        ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                          content: Text(msg),
                          backgroundColor: color,
                          behavior: SnackBarBehavior.floating,
                        ));
                      }
                    },
                  ),
                ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  SECTION SIGNATURES
// ─────────────────────────────────────────────────────────────────────────────

class _SectionSignatures extends StatelessWidget {
  final DeploymentModel dep;
  const _SectionSignatures({required this.dep});

  @override
  Widget build(BuildContext context) {
    return _Carte(
      titre: 'SIGNATURES',
      icone: Icons.draw_outlined,
      child: Row(children: [
        Expanded(
          child: _ZoneSignature(
              role: 'Responsable livraison',
              signature: dep.signatureResponsable),
        ),
        Container(width: 1, height: 100, color: const Color(0xFFE8F5EE)),
        Expanded(
          child: _ZoneSignature(
              role: 'Réceptionionnaire site',
              signature: dep.signatureReceptionnaire),
        ),
      ]),
    );
  }
}

class _ZoneSignature extends StatelessWidget {
  final String role;
  final DeploymentSignature? signature;
  const _ZoneSignature({required this.role, this.signature});

  @override
  Widget build(BuildContext context) {
    final signed = signature?.isSigned == true;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(children: [
        Container(
          height: 70,
          decoration: BoxDecoration(
            color: signed ? _kGreenLight : const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color:
                    signed ? _kGreen.withOpacity(0.3) : const Color(0xFFE0E0E0),
                width: 1.5),
          ),
          child: signed
              ? Center(
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                      const Icon(Icons.check_circle, color: _kGreen, size: 24),
                      const SizedBox(height: 4),
                      Text(signature!.nomSignataire!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 11,
                              color: _kGreen,
                              fontWeight: FontWeight.w600)),
                    ]))
              : const Center(
                  child: Icon(Icons.edit_outlined,
                      color: Color(0xFFBDBDBD), size: 24)),
        ),
        const SizedBox(height: 6),
        Text(role,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 11, color: _kTextGray, fontWeight: FontWeight.w500)),
        if (signature?.dateSignature != null)
          Text(signature!.dateSignature!,
              style: const TextStyle(fontSize: 10, color: Color(0xFF90A4AE))),
      ]),
    );
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

class _InfoLigne extends StatelessWidget {
  final IconData icone;
  final String label;
  final String valeur;
  const _InfoLigne(
      {required this.icone, required this.label, required this.valeur});

  @override
  Widget build(BuildContext context) => Row(children: [
        Icon(icone, size: 16, color: _kTextGray),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 13),
              children: [
                TextSpan(
                    text: '$label : ',
                    style: const TextStyle(
                        color: _kTextGray, fontWeight: FontWeight.w500)),
                TextSpan(
                    text: valeur,
                    style: const TextStyle(
                        color: _kTextDark, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ]);
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

class _BadgeStatutGrand extends StatelessWidget {
  final String statut;
  final Color couleur;
  const _BadgeStatutGrand({required this.statut, required this.couleur});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.4)),
        ),
        child: Text(
          DeploymentStatut.label(statut),
          style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 0.5),
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
