// lib/features/archives/widgets/archive_bottom_sheet.dart

import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../screens/signature_capture_screen.dart';
import '../services/archive_auto_service.dart';
import '../services/pdf_generator_service.dart';

// ✅ _kBlue au niveau fichier — accessible dans toutes les const expressions
const _kBlue = Color(0xFF0D3380);

enum ArchiveCategory { deployment, intervention }

Future<bool> showArchiveBottomSheet({
  required BuildContext context,
  required ArchiveCategory category,
  required Map<String, dynamic> data,
  required String archivedBy,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (ctx) => _ArchiveSheet(
      category: category,
      data: data,
      archivedBy: archivedBy,
    ),
  );
  return result == true;
}

class _ArchiveSheet extends StatefulWidget {
  final ArchiveCategory category;
  final Map<String, dynamic> data;
  final String archivedBy;

  // ✅ const supprimé — Map<String, dynamic> ne peut pas être const
  _ArchiveSheet({
    required this.category,
    required this.data,
    required this.archivedBy,
  });

  @override
  State<_ArchiveSheet> createState() => _ArchiveSheetState();
}

class _ArchiveSheetState extends State<_ArchiveSheet> {
  bool _loading = false;
  String? _error;

  String get _label => widget.category == ArchiveCategory.deployment
      ? 'déploiement'
      : 'intervention';

  String get _code => widget.category == ArchiveCategory.deployment
      ? widget.data['codeDep']?.toString() ?? '—'
      : widget.data['codeInter']?.toString() ?? '—';

  Future<void> _archiveWithSignature() async {
    final Uint8List? sigBytes = await Navigator.push<Uint8List?>(
      context,
      MaterialPageRoute(
        builder: (_) => SignatureCaptureScreen(
          title: 'Signature requise',
          subtitle: 'Faire signer le responsable du site',
        ),
      ),
    );
    if (sigBytes == null) return;
    await _doArchive(withSignature: true, signatureBytes: sigBytes);
  }

  Future<void> _archiveWithoutSignature() async {
    await _doArchive(withSignature: false, signatureBytes: null);
  }

  Future<void> _doArchive({
    required bool withSignature,
    required Uint8List? signatureBytes,
  }) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final Uint8List pdfBytes;
      if (widget.category == ArchiveCategory.deployment) {
        pdfBytes = await PdfGeneratorService.generateDeploymentPdf(
          deployment: widget.data,
          signatureBytes: signatureBytes,
        );
      } else {
        pdfBytes = await PdfGeneratorService.generateInterventionPdf(
          intervention: widget.data,
          signatureBytes: signatureBytes,
        );
      }

      final service = ArchiveAutoService();
      if (widget.category == ArchiveCategory.deployment) {
        await service.archiveDeployment(
          deployment: widget.data,
          pdfBytes: pdfBytes,
          withSignature: withSignature,
          archivedBy: widget.archivedBy,
        );
      } else {
        await service.archiveIntervention(
          intervention: widget.data,
          pdfBytes: pdfBytes,
          withSignature: withSignature,
          archivedBy: widget.archivedBy,
        );
      }

      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      final navigator = Navigator.of(context);
      navigator.pop(true);
      messenger.showSnackBar(SnackBar(
        content: Row(children: [
          const Icon(Icons.check_circle, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text(withSignature
              ? 'Archive signée sauvegardée ✓'
              : 'Archive sauvegardée ✓'),
        ]),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Titre
          Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _kBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child:
                  const Icon(Icons.archive_outlined, color: _kBlue, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Archiver ce $_label',
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _kBlue)),
                  Text('Code : $_code',
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 8),
          const Divider(),
          const SizedBox(height: 8),

          // Erreur
          if (_error != null) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(_error!,
                      style: const TextStyle(color: Colors.red, fontSize: 12)),
                ),
              ]),
            ),
            const SizedBox(height: 12),
          ],

          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Column(children: [
                CircularProgressIndicator(),
                SizedBox(height: 12),
                Text('Génération du PDF en cours...',
                    style: TextStyle(color: Colors.grey)),
              ]),
            )
          else ...[
            _OptionCard(
              icon: Icons.draw_outlined,
              color: _kBlue,
              title: 'Avec signature',
              description:
                  'Ouvre l\'écran de signature. Le PDF inclura la signature du responsable.',
              onTap: _archiveWithSignature,
            ),
            const SizedBox(height: 10),
            _OptionCard(
              icon: Icons.picture_as_pdf_outlined,
              color: Colors.teal,
              title: 'Sans signature',
              description:
                  'Génère et archive le PDF immédiatement, sans signature.',
              onTap: _archiveWithoutSignature,
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Plus tard',
                    style: TextStyle(color: Colors.grey)),
              ),
            ),
          ],
        ]),
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _OptionCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.25)),
            ),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: color)),
                    const SizedBox(height: 2),
                    Text(description,
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade600)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: color.withValues(alpha: 0.6)),
            ]),
          ),
        ),
      );
}
