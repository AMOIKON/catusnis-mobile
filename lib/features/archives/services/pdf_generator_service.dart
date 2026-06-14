// lib/features/archives/services/pdf_generator_service.dart

import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';

class PdfGeneratorService {
  static final DateFormat _df = DateFormat('dd/MM/yyyy HH:mm');

  // ── Déploiement ───────────────────────────────────────────────────────────
  static Future<Uint8List> generateDeploymentPdf({
    required Map<String, dynamic> deployment,
    Uint8List? signatureBytes,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.all(32),
      build: (ctx) => [
        _header('FICHE DE DÉPLOIEMENT', signatureBytes != null),
        pw.SizedBox(height: 16),
        _infoRow('Code déploiement', deployment['codeDep']?.toString() ?? '—'),
        _infoRow('Région', deployment['regionName']?.toString() ?? '—'),
        _infoRow('District', deployment['districtName']?.toString() ?? '—'),
        _infoRow('Site de santé', deployment['healthName']?.toString() ?? '—'),
        _infoRow('Statut', deployment['statut']?.toString() ?? '—'),
        _infoRow('Date déploiement', deployment['dateDep']?.toString() ?? '—'),
        _infoRow(
            'Date réception', deployment['dateReception']?.toString() ?? '—'),
        pw.SizedBox(height: 16),
        _sectionTitle('Équipements déployés'),
        _equipmentTable(deployment['items'] as List? ?? []),
        if (signatureBytes != null) ...[
          pw.SizedBox(height: 24),
          _signatureBlock(signatureBytes, deployment['signedBy']?.toString()),
        ],
        pw.SizedBox(height: 16),
        _footer(),
      ],
    ));

    return pdf.save();
  }

  // ── Intervention ──────────────────────────────────────────────────────────
  static Future<Uint8List> generateInterventionPdf({
    required Map<String, dynamic> intervention,
    Uint8List? signatureBytes,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.all(32),
      build: (ctx) => [
        _header('RAPPORT D\'INTERVENTION', signatureBytes != null),
        pw.SizedBox(height: 16),
        _infoRow(
            'Code intervention', intervention['codeInter']?.toString() ?? '—'),
        _infoRow('Type', intervention['typeInter']?.toString() ?? '—'),
        _infoRow('Action', intervention['actionInter']?.toString() ?? '—'),
        _infoRow(
            'Site de santé', intervention['healthName']?.toString() ?? '—'),
        _infoRow(
            'Technicien', intervention['technicianName']?.toString() ?? '—'),
        _infoRow('Date', intervention['dateInter']?.toString() ?? '—'),
        pw.SizedBox(height: 12),
        _sectionTitle('Description'),
        pw.Text(
          intervention['commentInter']?.toString() ?? 'Aucune description.',
          style: const pw.TextStyle(fontSize: 11),
        ),
        if ((intervention['actionEffectuee']?.toString() ?? '').isNotEmpty) ...[
          pw.SizedBox(height: 12),
          _sectionTitle('Actions effectuées'),
          pw.Text(
            intervention['actionEffectuee'].toString(),
            style: const pw.TextStyle(fontSize: 11),
          ),
        ],
        if (signatureBytes != null) ...[
          pw.SizedBox(height: 24),
          _signatureBlock(signatureBytes, intervention['signedBy']?.toString()),
        ],
        pw.SizedBox(height: 16),
        _footer(),
      ],
    ));

    return pdf.save();
  }

  // ── Archive imprimée avec 2 signatures ────────────────────────────────────
  static Future<Uint8List> generateArchiveImprimePdf({
    required String titre,
    required String categorie,
    required String refCode,
    required String description,
    required String archivedBy,
    required Uint8List signatureResponsable,
    required Uint8List signatureTechnicien,
    required String nomResponsable,
    required String nomTechnicien,
  }) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final dateStr = _df.format(now);

    final imgResponsable = pw.MemoryImage(signatureResponsable);
    final imgTechnicien = pw.MemoryImage(signatureTechnicien);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(40),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // ── En-tête ───────────────────────────────────────────────────
            pw.Container(
              width: double.infinity,
              padding: pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: PdfColors.blue800,
                borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('CATUSNIS',
                          style: pw.TextStyle(
                              color: PdfColors.white,
                              fontSize: 20,
                              fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 2),
                      pw.Text(
                          'Centre d\'Assistance Technique aux Utilisateurs du SNIS',
                          style: pw.TextStyle(
                              color: const PdfColor(1, 1, 1, 0.7),
                              fontSize: 9)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Container(
                        padding:
                            pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.green,
                          borderRadius:
                              pw.BorderRadius.all(pw.Radius.circular(4)),
                        ),
                        child: pw.Text('✓ SIGNÉ',
                            style: pw.TextStyle(
                                color: PdfColors.white,
                                fontSize: 9,
                                fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(dateStr,
                          style: pw.TextStyle(
                              color: const PdfColor(1, 1, 1, 0.7),
                              fontSize: 9)),
                    ],
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 16),

            // ── Titre + ref ───────────────────────────────────────────────
            pw.Center(
                child: pw.Text('BON DE RÉCEPTION — DOCUMENT IMPRIMÉ',
                    style: pw.TextStyle(
                        fontSize: 13,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue800))),
            pw.SizedBox(height: 6),
            pw.Center(
                child: pw.Container(
              padding: pw.EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: pw.BoxDecoration(
                color: PdfColors.blue50,
                borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
                border: pw.Border.all(color: PdfColors.blue200),
              ),
              child: pw.Text(refCode,
                  style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue800)),
            )),

            pw.SizedBox(height: 16),

            // ── Infos document ────────────────────────────────────────────
            pw.Container(
              padding: pw.EdgeInsets.all(14),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('INFORMATIONS DU DOCUMENT',
                      style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.grey600)),
                  pw.SizedBox(height: 8),
                  _infoRow('Titre', titre),
                  _infoRow('Catégorie', _catLabel(categorie)),
                  _infoRow('Date', dateStr),
                  _infoRow('Archivé par', archivedBy),
                  if (description.isNotEmpty)
                    _infoRow('Description', description),
                ],
              ),
            ),

            pw.SizedBox(height: 16),

            // ── Texte confirmation ────────────────────────────────────────
            pw.Container(
              padding: pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.amber50,
                borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
                border: pw.Border.all(color: PdfColors.amber200),
              ),
              child: pw.Text(
                'Je soussigné(e) confirme avoir bien reçu le document imprimé '
                'référencé ci-dessus et en atteste par ma signature.',
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.brown),
              ),
            ),

            pw.SizedBox(height: 20),

            // ── Deux signatures côte à côte ───────────────────────────────
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Signature Responsable
                pw.Expanded(
                    child: pw.Container(
                  padding: pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text('RESPONSABLE DU SITE',
                          style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.grey700)),
                      pw.SizedBox(height: 8),
                      pw.Container(
                        height: 80,
                        decoration: pw.BoxDecoration(
                          color: PdfColors.white,
                          border: pw.Border.all(color: PdfColors.grey200),
                          borderRadius:
                              pw.BorderRadius.all(pw.Radius.circular(4)),
                        ),
                        child: pw.Image(imgResponsable, fit: pw.BoxFit.contain),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Container(
                          width: double.infinity,
                          height: 1,
                          color: PdfColors.grey400),
                      pw.SizedBox(height: 4),
                      pw.Text(nomResponsable,
                          style: pw.TextStyle(
                              fontSize: 9, fontWeight: pw.FontWeight.bold),
                          textAlign: pw.TextAlign.center),
                      pw.Text('Responsable du site',
                          style: const pw.TextStyle(
                              fontSize: 8, color: PdfColors.grey600),
                          textAlign: pw.TextAlign.center),
                    ],
                  ),
                )),

                pw.SizedBox(width: 16),

                // Signature Technicien/Admin
                pw.Expanded(
                    child: pw.Container(
                  padding: pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text('TECHNICIEN / ADMIN',
                          style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.grey700)),
                      pw.SizedBox(height: 8),
                      pw.Container(
                        height: 80,
                        decoration: pw.BoxDecoration(
                          color: PdfColors.white,
                          border: pw.Border.all(color: PdfColors.grey200),
                          borderRadius:
                              pw.BorderRadius.all(pw.Radius.circular(4)),
                        ),
                        child: pw.Image(imgTechnicien, fit: pw.BoxFit.contain),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Container(
                          width: double.infinity,
                          height: 1,
                          color: PdfColors.grey400),
                      pw.SizedBox(height: 4),
                      pw.Text(nomTechnicien,
                          style: pw.TextStyle(
                              fontSize: 9, fontWeight: pw.FontWeight.bold),
                          textAlign: pw.TextAlign.center),
                      pw.Text('Technicien / Administrateur',
                          style: const pw.TextStyle(
                              fontSize: 8, color: PdfColors.grey600),
                          textAlign: pw.TextAlign.center),
                    ],
                  ),
                )),
              ],
            ),

            pw.Spacer(),
            _footer(),
          ],
        ),
      ),
    );

    return pdf.save();
  }

  // ── Widgets internes ──────────────────────────────────────────────────────

  static pw.Widget _header(String title, bool hasSig) {
    return pw.Container(
      padding: pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue800,
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('CATUSNIS',
              style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold)),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(title,
                  style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 13,
                      fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 2),
              pw.Text(_df.format(DateTime.now()),
                  style: pw.TextStyle(
                      color: const PdfColor(1, 1, 1, 0.7), fontSize: 9)),
              if (hasSig)
                pw.Container(
                  margin: pw.EdgeInsets.only(top: 3),
                  padding: pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.green,
                    borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
                  ),
                  child: pw.Text('✓ SIGNÉ',
                      style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _sectionTitle(String text) => pw.Padding(
        padding: pw.EdgeInsets.only(bottom: 4, top: 8),
        child: pw.Text(text,
            style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue800)),
      );

  static pw.Widget _infoRow(String label, String value) => pw.Padding(
        padding: pw.EdgeInsets.symmetric(vertical: 3),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(
                width: 150,
                child: pw.Text('$label :',
                    style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.grey700))),
            pw.Expanded(
                child: pw.Text(value, style: const pw.TextStyle(fontSize: 10))),
          ],
        ),
      );

  static pw.Widget _equipmentTable(List items) {
    if (items.isEmpty) {
      return pw.Text('Aucun équipement.',
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey));
    }
    return pw.TableHelper.fromTextArray(
      headers: ['N°', 'Équipement', 'N° Série', 'État'],
      headerStyle: pw.TextStyle(
          fontWeight: pw.FontWeight.bold, fontSize: 9, color: PdfColors.white),
      headerDecoration: pw.BoxDecoration(color: PdfColors.blue800),
      cellStyle: const pw.TextStyle(fontSize: 9),
      cellAlignments: {
        0: pw.Alignment.center,
        1: pw.Alignment.centerLeft,
        2: pw.Alignment.centerLeft,
        3: pw.Alignment.center,
      },
      data: items.asMap().entries.map((e) {
        final item = e.value as Map<String, dynamic>;
        return [
          '${e.key + 1}',
          item['typeName']?.toString() ?? '—',
          item['serial']?.toString() ?? '—',
          item['etatApres']?.toString() ?? '—',
        ];
      }).toList(),
    );
  }

  static pw.Widget _signatureBlock(Uint8List sigBytes, String? signedBy) {
    return pw.Container(
      padding: pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.blue800),
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Signature du responsable',
              style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue800)),
          pw.SizedBox(height: 8),
          pw.Center(
              child: pw.Image(pw.MemoryImage(sigBytes),
                  width: 200, height: 80, fit: pw.BoxFit.contain)),
          if (signedBy != null) ...[
            pw.SizedBox(height: 4),
            pw.Text('Signé par : $signedBy',
                style:
                    const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
          ],
          pw.Text('Date : ${_df.format(DateTime.now())}',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
        ],
      ),
    );
  }

  static pw.Widget _footer() => pw.Column(children: [
        pw.Divider(color: PdfColors.grey300),
        pw.Center(
            child: pw.Text(
                'Document généré automatiquement par CATUSNIS Mobile',
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey))),
      ]);

  static String _catLabel(String c) {
    switch (c) {
      case 'INTERVENTION':
        return 'Intervention';
      case 'DEPLOIEMENT':
        return 'Déploiement';
      case 'ACQUISITION':
        return 'Acquisition';
      case 'BOOKLET':
        return 'Cahier';
      case 'ACTIVE':
        return 'Actif';
      default:
        return 'Autre';
    }
  }
}
