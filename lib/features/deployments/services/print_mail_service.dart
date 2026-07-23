// lib/features/deployments/services/print_mail_service.dart
//
// ✅ CORRIGÉ : le PDF n'est plus généré localement en Dart.
//    Il est désormais téléchargé depuis le backend via
//    DeploymentService().downloadDeploymentPdf(id), qui appelle
//    GET /api/deployments/{id}/pdf. Ce PDF backend contient le QR code
//    + lien de vérification publique, et son appel déclenche
//    l'archivage automatique (BLOB) côté serveur.
//
//    L'ancienne classe DeploymentPdfGenerator (génération locale avec
//    le package pdf) n'est plus utilisée ici et peut être supprimée si
//    elle n'est référencée nulle part ailleurs (voir aussi le doublon
//    lib/features/deployments/pdf/deployment_pdf_generator.dart).

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../models/deployment_model.dart';
import 'deployment_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  RÉSULTAT ENVOI E-MAIL
// ─────────────────────────────────────────────────────────────────────────────

sealed class MailResult {}

class MailSuccess extends MailResult {}

class MailError extends MailResult {
  final String message;
  MailError(this.message);
}

// ─────────────────────────────────────────────────────────────────────────────
//  PRINT SERVICE
// ─────────────────────────────────────────────────────────────────────────────

class PrintService {
  final DeploymentService _deploymentService = DeploymentService();

  Future<void> previewFiche(BuildContext context, DeploymentModel dep) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => _PdfPreviewPage(deployment: dep)),
    );
  }

  Future<void> printFiche(BuildContext context, DeploymentModel dep) async {
    try {
      final bytes = await _deploymentService.downloadDeploymentPdf(dep.id);
      await Printing.layoutPdf(
        onLayout: (_) async => bytes,
        name: 'Fiche_${dep.codeDep}',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Erreur d'impression : $e"),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }
}

class _PdfPreviewPage extends StatelessWidget {
  final DeploymentModel deployment;
  const _PdfPreviewPage({required this.deployment});

  @override
  Widget build(BuildContext context) {
    final service = DeploymentService();
    return Scaffold(
      appBar: AppBar(
        title: Text('Apercu — ${deployment.codeDep}'),
        backgroundColor: const Color(0xFF2E7D52),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () async {
              final bytes = await service.downloadDeploymentPdf(deployment.id);
              await Printing.layoutPdf(
                  onLayout: (_) async => bytes,
                  name: 'Fiche_${deployment.codeDep}');
            },
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => MailerService().sharePdf(deployment),
          ),
        ],
      ),
      body: PdfPreview(
        build: (format) => service.downloadDeploymentPdf(deployment.id),
        allowPrinting: true,
        allowSharing: true,
        canChangePageFormat: false,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  MAILER SERVICE
// ─────────────────────────────────────────────────────────────────────────────

class _SmtpConfig {
  static const host = 'mail.catusnis.ci';
  static const port = 587;
  static const username = 'noreply@catusnis.ci';
  static const password = 'MOT_DE_PASSE_SMTP';
  static const displayName = 'CATUSNIS Equipements';
}

class MailerService {
  final DeploymentService _deploymentService = DeploymentService();

  Future<void> sharePdf(DeploymentModel dep) async {
    final bytes = await _deploymentService.downloadDeploymentPdf(dep.id);
    final tmpDir = await getTemporaryDirectory();
    final file = File('${tmpDir.path}/Fiche_${dep.codeDep}.pdf');
    await file.writeAsBytes(bytes);
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/pdf')],
      subject: 'Fiche deploiement — ${dep.codeDep}',
      text:
          'Ref: ${dep.codeDep}\nSite: ${dep.healthName ?? ''}\nEquipements: ${dep.totalUnites} unite(s)',
    );
  }

  Future<MailResult> sendEmail({
    required DeploymentModel deployment,
    required List<String> recipients,
    String? customMessage,
  }) async {
    try {
      final Uint8List bytes =
          await _deploymentService.downloadDeploymentPdf(deployment.id);
      final smtp = SmtpServer(
        _SmtpConfig.host,
        port: _SmtpConfig.port,
        username: _SmtpConfig.username,
        password: _SmtpConfig.password,
        ssl: false,
        allowInsecure: true,
      );
      final msg = Message()
        ..from = Address(_SmtpConfig.username, _SmtpConfig.displayName)
        ..recipients.addAll(recipients)
        ..subject = '[CATUSNIS] Fiche deploiement — ${deployment.codeDep}'
        ..html = _bodyHtml(deployment, customMessage)
        ..attachments.add(StreamAttachment(
          Stream.fromIterable([bytes]),
          'application/pdf',
          fileName: 'Fiche_${deployment.codeDep}.pdf',
        ));
      await send(msg, smtp);
      return MailSuccess();
    } on MailerException catch (e) {
      return MailError(e.problems.map((p) => p.msg).join(', '));
    } catch (e) {
      return MailError(e.toString());
    }
  }

  String _bodyHtml(DeploymentModel d, String? custom) {
    final hex = _statutHex(d.statut);
    final rows = d.itemsParType.entries
        .map((e) => '<tr><td>${e.key}</td><td>x${e.value.length}</td></tr>')
        .join();
    return '''<!DOCTYPE html><html><head><meta charset="UTF-8"><style>
body{font-family:Arial,sans-serif;color:#1A237E;margin:0}
.hdr{background:#2E7D52;color:white;padding:20px 28px}
.hdr h1{margin:0;font-size:20px;letter-spacing:2px}
.hdr p{margin:4px 0 0;font-size:12px;color:#A5D6A7}
.bdy{padding:20px 28px}
.badge{display:inline-block;padding:4px 12px;border-radius:20px;color:white;font-weight:bold;font-size:11px;background:$hex}
.grid{display:grid;grid-template-columns:1fr 1fr;gap:8px;margin:14px 0}
.cell{background:#F4FAF6;border-radius:6px;padding:10px;border:1px solid #DCEDC8}
.cell .lbl{font-size:10px;color:#546E7A}
.cell .val{font-size:14px;font-weight:bold;color:#1A237E;margin-top:2px}
table{border-collapse:collapse;width:100%;margin-top:10px}
th{background:#2E7D52;color:white;padding:7px 10px;font-size:11px;text-align:left}
td{padding:6px 10px;font-size:12px;border-bottom:1px solid #E8F5EE}
.ftr{background:#F4FAF6;padding:12px 28px;font-size:11px;color:#546E7A;text-align:center;border-top:2px solid #E8F5EE}
.msg{background:#E8F5EE;border-left:4px solid #2E7D52;padding:10px;margin:10px 0;font-style:italic;border-radius:0 4px 4px 0}
</style></head><body>
<div class="hdr"><h1>CATUSNIS</h1><p>Gestion des Equipements de Sante — Cote d Ivoire</p></div>
<div class="bdy">
<p style="font-size:16px;font-weight:bold">${d.codeDep} &nbsp;<span class="badge">${DeploymentStatut.label(d.statut)}</span></p>
${custom != null && custom.isNotEmpty ? '<div class="msg">$custom</div>' : ''}
<div class="grid">
  <div class="cell"><div class="lbl">Region</div><div class="val">${d.regionName ?? '—'}</div></div>
  <div class="cell"><div class="lbl">District</div><div class="val">${d.districtName ?? '—'}</div></div>
  <div class="cell"><div class="lbl">Site</div><div class="val">${d.healthName ?? '—'}</div></div>
  <div class="cell"><div class="lbl">Equipements</div><div class="val">${d.totalUnites} unite(s)</div></div>
</div>
${d.app != null ? '<p>Application : <strong>${d.app!.nomComplet}</strong></p>' : ''}
<table><tr><th>Type equipement</th><th>Qte</th></tr>$rows</table>
<p style="margin-top:16px;font-size:12px;color:#546E7A">PDF joint. Message genere par CATUSNIS.</p>
</div>
<div class="ftr">CATUSNIS — Ministere de la Sante — Republique de Cote d Ivoire</div>
</body></html>''';
  }

  String _statutHex(String s) => switch (s) {
        'BROUILLON' => '#607D8B',
        'EN_COURS' => '#1976D2',
        'LIVRE' => '#2E7D52',
        'ARCHIVE' => '#795548',
        'ANNULE' => '#D32F2F',
        _ => '#607D8B',
      };
}
