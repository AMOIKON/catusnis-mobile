// lib/features/deployments/services/print_mail_service.dart
//
// Trois responsabilités :
//   DeploymentPdfGenerator  → génère le PDF A4 depuis DeploymentModel
//   PrintService            → prévisualisation + impression système
//   MailerService           → partage natif (share_plus) + envoi SMTP (mailer)

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../models/deployment_model.dart';

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
  final _gen = DeploymentPdfGenerator();

  Future<void> previewFiche(BuildContext context, DeploymentModel dep) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => _PdfPreviewPage(deployment: dep)),
    );
  }

  Future<void> printFiche(BuildContext context, DeploymentModel dep) async {
    try {
      final bytes = await _gen.generate(dep);
      await Printing.layoutPdf(
        onLayout: (_) async => bytes,
        name: 'Fiche_${dep.codeDep}',
        format: PdfPageFormat.a4,
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
    final gen = DeploymentPdfGenerator();
    return Scaffold(
      appBar: AppBar(
        title: Text('Apercu — ${deployment.codeDep}'),
        backgroundColor: const Color(0xFF2E7D52),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () async {
              final bytes = await gen.generate(deployment);
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
        build: (format) => gen.generate(deployment),
        allowPrinting: true,
        allowSharing: true,
        canChangePageFormat: false,
        initialPageFormat: PdfPageFormat.a4,
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
  final _gen = DeploymentPdfGenerator();

  Future<void> sharePdf(DeploymentModel dep) async {
    final bytes = await _gen.generate(dep);
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
      final bytes = await _gen.generate(deployment);
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

// ─────────────────────────────────────────────────────────────────────────────
//  GÉNÉRATEUR PDF A4
// ─────────────────────────────────────────────────────────────────────────────

class DeploymentPdfGenerator {
  static final _green = PdfColor.fromHex('2E7D52');
  static final _greenDark = PdfColor.fromHex('1B5E37');
  static final _greenLight = PdfColor.fromHex('E8F5EE');
  static final _textDark = PdfColor.fromHex('1A237E');
  static final _textGray = PdfColor.fromHex('546E7A');
  static final _divider = PdfColor.fromHex('E8F5EE');
  static const _white = PdfColors.white;

  static final _statutColors = {
    'BROUILLON': PdfColor.fromHex('607D8B'),
    'EN_COURS': PdfColor.fromHex('1976D2'),
    'LIVRE': PdfColor.fromHex('2E7D52'),
    'ARCHIVE': PdfColor.fromHex('795548'),
    'ANNULE': PdfColor.fromHex('D32F2F'),
  };

  final _dateFmt = DateFormat('dd MMMM yyyy', 'fr_FR');

  Future<Uint8List> generate(DeploymentModel dep) async {
    final pdf = pw.Document(title: 'Fiche ${dep.codeDep}', author: 'CATUSNIS');

    final fontReg =
        pw.Font.ttf(await rootBundle.load('assets/fonts/Roboto-Regular.ttf'));
    final fontBold =
        pw.Font.ttf(await rootBundle.load('assets/fonts/Roboto-Bold.ttf'));
    final fontIta =
        pw.Font.ttf(await rootBundle.load('assets/fonts/Roboto-Italic.ttf'));
    final theme =
        pw.ThemeData.withFont(base: fontReg, bold: fontBold, italic: fontIta);

    pw.MemoryImage? logo;
    try {
      final d = await rootBundle.load('assets/images/catusnis_logo.png');
      logo = pw.MemoryImage(d.buffer.asUint8List());
    } catch (_) {}

    pdf.addPage(pw.MultiPage(
      theme: theme,
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.symmetric(horizontal: 36, vertical: 32),
      header: (ctx) => _header(ctx, dep, logo),
      footer: (ctx) => _footer(ctx, dep),
      build: (ctx) => [
        pw.SizedBox(height: 10),
        _statutBanner(dep),
        pw.SizedBox(height: 14),
        _section('INFORMATIONS', _tableInfos(dep)),
        pw.SizedBox(height: 12),
        _section('EQUIPEMENTS', _tableEquipements(dep)),
        pw.SizedBox(height: 12),
        if (dep.app != null || dep.partnerPrincipal != null) ...[
          _section('APPLICATION ET PARTENAIRES', _tableAppPartenaires(dep)),
          pw.SizedBox(height: 12),
        ],
        if (dep.observations?.isNotEmpty == true) ...[
          _section('OBSERVATIONS', _observations(dep)),
          pw.SizedBox(height: 12),
        ],
        _section('SIGNATURES', _signatures(dep)),
      ],
    ));

    return pdf.save();
  }

  pw.Widget _header(pw.Context ctx, DeploymentModel d, pw.MemoryImage? logo) {
    return pw.Column(children: [
      pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: pw.BoxDecoration(
          gradient: pw.LinearGradient(
              colors: [_greenDark, _green],
              begin: pw.Alignment.topLeft,
              end: pw.Alignment.bottomRight),
        ),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            logo != null
                ? pw.Image(logo, width: 48, height: 48)
                : pw.Container(
                    width: 48,
                    height: 48,
                    decoration: pw.BoxDecoration(
                        color: PdfColor.fromHex('A5D6A7'),
                        shape: pw.BoxShape.circle),
                    alignment: pw.Alignment.center,
                    child: pw.Text('C',
                        style: pw.TextStyle(
                            color: _white,
                            fontSize: 22,
                            fontWeight: pw.FontWeight.bold)),
                  ),
            pw.Expanded(
              child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text("REPUBLIQUE DE COTE D'IVOIRE",
                        style: pw.TextStyle(
                            color: _white, fontSize: 7.5, letterSpacing: 1)),
                    pw.SizedBox(height: 2),
                    pw.Text("MINISTERE DE LA SANTE ET DE L'HYGIENE PUBLIQUE",
                        style: pw.TextStyle(
                            color: PdfColor.fromHex('A5D6A7'), fontSize: 7),
                        textAlign: pw.TextAlign.center),
                    pw.SizedBox(height: 6),
                    pw.Text('CATUSNIS',
                        style: pw.TextStyle(
                            color: _white,
                            fontSize: 20,
                            fontWeight: pw.FontWeight.bold,
                            letterSpacing: 3)),
                    pw.Text('Gestion des Equipements de Sante',
                        style: pw.TextStyle(
                            color: PdfColor.fromHex('A5D6A7'), fontSize: 8)),
                  ]),
            ),
            pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
              pw.Text('Ref: ${d.codeDep}',
                  style: pw.TextStyle(
                      color: _white,
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 4),
              pw.Text('Genere le\n${_dateFmt.format(DateTime.now())}',
                  style: pw.TextStyle(
                      color: PdfColor.fromHex('A5D6A7'), fontSize: 7.5),
                  textAlign: pw.TextAlign.right),
            ]),
          ],
        ),
      ),
      pw.SizedBox(height: 4),
      pw.Center(
        child: pw.Text('FICHE DE DEPLOIEMENT D\'EQUIPEMENT',
            style: pw.TextStyle(
                color: _textDark,
                fontSize: 13,
                fontWeight: pw.FontWeight.bold,
                letterSpacing: 2)),
      ),
      pw.SizedBox(height: 6),
    ]);
  }

  pw.Widget _footer(pw.Context ctx, DeploymentModel d) => pw.Column(children: [
        pw.Divider(color: _divider, thickness: 0.8),
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
          pw.Text('CATUSNIS — Document officiel',
              style: pw.TextStyle(color: _textGray, fontSize: 7)),
          pw.Text('Page ${ctx.pageNumber} / ${ctx.pagesCount}',
              style: pw.TextStyle(color: _textGray, fontSize: 7)),
          pw.Text(d.codeDep,
              style: pw.TextStyle(
                  color: _textGray,
                  fontSize: 7,
                  fontStyle: pw.FontStyle.italic)),
        ]),
      ]);

  pw.Widget _statutBanner(DeploymentModel d) {
    final color = _statutColors[d.statut] ?? PdfColor.fromHex('607D8B');
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: pw.BoxDecoration(
          color: _greenLight,
          border: pw.Border.all(color: _divider),
          borderRadius: pw.BorderRadius.circular(6)),
      child: pw
          .Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
        pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          if (d.healthName != null) _iRow('Site', d.healthName!),
          if (d.dateReception != null)
            _iRow(
                'Date',
                _dateFmt.format(
                    DateTime.tryParse(d.dateReception!) ?? DateTime.now())),
        ]),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: pw.BoxDecoration(
              color: color, borderRadius: pw.BorderRadius.circular(20)),
          child: pw.Text(DeploymentStatut.label(d.statut).toUpperCase(),
              style: pw.TextStyle(
                  color: _white,
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  letterSpacing: 1.5)),
        ),
      ]),
    );
  }

  pw.Widget _section(String titre, pw.Widget content) =>
      pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: pw.BoxDecoration(
            color: _green,
            borderRadius: const pw.BorderRadius.only(
                topLeft: pw.Radius.circular(4),
                topRight: pw.Radius.circular(4)),
          ),
          child: pw.Text(titre,
              style: pw.TextStyle(
                  color: _white,
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  letterSpacing: 1.5)),
        ),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: _greenLight,
            border: pw.Border.all(color: _divider),
            borderRadius: const pw.BorderRadius.only(
                bottomLeft: pw.Radius.circular(4),
                bottomRight: pw.Radius.circular(4)),
          ),
          child: content,
        ),
      ]);

  pw.Widget _tableInfos(DeploymentModel d) => pw.Column(children: [
        pw.Row(children: [
          pw.Expanded(child: _cellule('Region', d.regionName ?? 'N/A')),
          pw.SizedBox(width: 10),
          pw.Expanded(child: _cellule('District', d.districtName ?? 'N/A')),
        ]),
        pw.SizedBox(height: 8),
        pw.Row(children: [
          pw.Expanded(child: _cellule('Site de sante', d.healthName ?? 'N/A')),
          pw.SizedBox(width: 10),
          pw.Expanded(
              child: _cellule('Equipements',
                  '${d.totalUnites} unite${d.totalUnites > 1 ? 's' : ''}')),
        ]),
      ]);

  pw.Widget _cellule(String label, String valeur) => pw.Container(
        padding: const pw.EdgeInsets.all(8),
        decoration: pw.BoxDecoration(
            color: PdfColors.white,
            borderRadius: pw.BorderRadius.circular(6),
            border: pw.Border.all(color: _divider)),
        child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(label,
                  style: pw.TextStyle(
                      color: _textGray,
                      fontSize: 7.5,
                      fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 3),
              pw.Text(valeur,
                  style: pw.TextStyle(
                      color: _textDark,
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold)),
            ]),
      );

  pw.Widget _tableEquipements(DeploymentModel d) {
    final grouped = d.itemsParType;
    final rows = <pw.Widget>[];
    rows.add(_thRow(['Type', 'Designation', 'N Serie', 'Statut', 'Rec.']));
    bool alt = false;
    for (final entry in grouped.entries) {
      for (final item in entry.value) {
        rows.add(_tdRow([
          entry.key,
          item.designation ?? entry.key,
          item.numeroSerie,
          item.statut ?? 'FONCTIONNEL',
        ], alt: alt, checked: item.receptionConfirm));
        alt = !alt;
      }
    }
    return pw.Column(children: rows);
  }

  pw.Widget _thRow(List<String> cols) => pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        color: _green,
        child: pw.Row(children: [
          ...cols.take(cols.length - 1).map((c) => pw.Expanded(
              child: pw.Text(c,
                  style: pw.TextStyle(
                      color: _white,
                      fontSize: 8,
                      fontWeight: pw.FontWeight.bold)))),
          pw.Text(cols.last,
              style: pw.TextStyle(
                  color: _white, fontSize: 8, fontWeight: pw.FontWeight.bold)),
        ]),
      );

  pw.Widget _tdRow(List<String> cells,
          {bool alt = false, bool checked = false}) =>
      pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        color: alt ? PdfColor.fromHex('F4FAF6') : PdfColors.white,
        child: pw.Row(children: [
          ...cells.map((c) => pw.Expanded(
              child: pw.Text(c,
                  style: pw.TextStyle(color: _textDark, fontSize: 8)))),
          pw.Container(
            width: 14,
            height: 14,
            decoration: pw.BoxDecoration(
              color: checked ? _green : PdfColors.white,
              border:
                  pw.Border.all(color: checked ? _green : _textGray, width: 1),
              borderRadius: pw.BorderRadius.circular(3),
            ),
            child: checked
                ? pw.Center(
                    child: pw.Text('v',
                        style: pw.TextStyle(
                            color: _white,
                            fontSize: 8,
                            fontWeight: pw.FontWeight.bold)))
                : null,
          ),
        ]),
      );

  pw.Widget _tableAppPartenaires(DeploymentModel d) => pw.Column(children: [
        if (d.app != null) _row2('Application', d.app!.nomComplet),
        if (d.partnerPrincipal != null)
          _row2('Partenaire principal', d.partnerPrincipal!.nom),
        if (d.partnerSecondaire != null)
          _row2('Partenaire secondaire', d.partnerSecondaire!.nom),
      ]);

  pw.Widget _observations(DeploymentModel d) => pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
            border:
                pw.Border.all(color: _divider, style: pw.BorderStyle.dashed),
            borderRadius: pw.BorderRadius.circular(4)),
        child: pw.Text(d.observations!,
            style: pw.TextStyle(
                fontSize: 9, color: _textDark, fontStyle: pw.FontStyle.italic)),
      );

  pw.Widget _signatures(DeploymentModel d) => pw.Row(children: [
        pw.Expanded(
            child: _sigBox('Responsable livraison', d.signatureResponsable)),
        pw.SizedBox(width: 24),
        pw.Expanded(
            child:
                _sigBox('Receptionionnaire site', d.signatureReceptionnaire)),
      ]);

  pw.Widget _sigBox(String role, DeploymentSignature? sig) =>
      pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.center, children: [
        pw.Text(role,
            style: pw.TextStyle(
                color: _green, fontSize: 8, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 4),
        if (sig?.isSigned == true) ...[
          pw.Text(sig!.nomSignataire!,
              style: pw.TextStyle(
                  color: _textDark,
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold)),
          if (sig.dateSignature != null)
            pw.Text(sig.dateSignature!,
                style: pw.TextStyle(
                    color: _textGray,
                    fontSize: 8,
                    fontStyle: pw.FontStyle.italic)),
        ],
        pw.SizedBox(height: 36),
        pw.Container(width: double.infinity, height: 0.8, color: _textGray),
        pw.SizedBox(height: 4),
        pw.Text('Date : ................................',
            style: pw.TextStyle(color: _textGray, fontSize: 7)),
      ]);

  pw.Widget _row2(String label, String value) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 3),
        child: pw.Row(children: [
          pw.SizedBox(
              width: 130,
              child: pw.Text(label,
                  style: pw.TextStyle(
                      color: _textGray,
                      fontSize: 8.5,
                      fontWeight: pw.FontWeight.bold))),
          pw.Container(width: 1, height: 12, color: _divider),
          pw.SizedBox(width: 8),
          pw.Expanded(
              child: pw.Text(value,
                  style: pw.TextStyle(color: _textDark, fontSize: 8.5))),
        ]),
      );

  pw.Widget _iRow(String label, String value) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 2),
        child: pw.Row(children: [
          pw.Text('$label : ',
              style: pw.TextStyle(
                  color: _textGray,
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold)),
          pw.Text(value, style: pw.TextStyle(color: _textDark, fontSize: 8)),
        ]),
      );
}
