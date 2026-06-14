// lib/features/deployments/pdf/deployment_pdf_generator.dart

import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/fiche_pdf_models.dart';

class DeploymentPdfGenerator {
  static final _primary = PdfColor.fromHex('0D47A1');
  static final _secondary = PdfColor.fromHex('1565C0');
  static final _accent = PdfColor.fromHex('42A5F5');
  static final _surface = PdfColor.fromHex('F5F9FF');
  static final _textDark = PdfColor.fromHex('1A237E');
  static final _textLight = PdfColor.fromHex('546E7A');
  static final _divider = PdfColor.fromHex('BBDEFB');
  static const _white = PdfColors.white;
  static final _statutColors = {
    'EN_COURS': PdfColor.fromHex('1976D2'),
    'TERMINE': PdfColor.fromHex('388E3C'),
    'SUSPENDU': PdfColor.fromHex('E64A19'),
  };
  static final _etatColors = {
    'BON': PdfColor.fromHex('388E3C'),
    'MOYEN': PdfColor.fromHex('F57C00'),
    'MAUVAIS': PdfColor.fromHex('D32F2F'),
    'HORS_SERVICE': PdfColor.fromHex('616161'),
  };

  final _dateFmt = DateFormat('dd MMMM yyyy', 'fr_FR');
  final _moneyFmt = NumberFormat('#,##0', 'fr_FR');

  Future<Uint8List> generate(FichePdf d) async {
    final pdf = pw.Document(title: 'Fiche ${d.reference}', author: 'CATUSNIS');
    final fontData = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
    final fontBoldData = await rootBundle.load('assets/fonts/Roboto-Bold.ttf');
    final fontItalicData =
        await rootBundle.load('assets/fonts/Roboto-Italic.ttf');
    final theme = pw.ThemeData.withFont(
      base: pw.Font.ttf(fontData),
      bold: pw.Font.ttf(fontBoldData),
      italic: pw.Font.ttf(fontItalicData),
    );
    pw.MemoryImage? logo;
    try {
      final data = await rootBundle.load('assets/images/catusnis_logo.png');
      logo = pw.MemoryImage(data.buffer.asUint8List());
    } catch (_) {}
    pdf.addPage(pw.MultiPage(
      theme: theme,
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.symmetric(horizontal: 36, vertical: 32),
      header: (ctx) => _header(ctx, d, logo),
      footer: (ctx) => _footer(ctx, d),
      build: (ctx) => [
        pw.SizedBox(height: 8),
        _statutBanner(d),
        pw.SizedBox(height: 14),
        _section('INFORMATIONS ÉQUIPEMENT', _equipementTable(d)),
        pw.SizedBox(height: 12),
        _section('LOCALISATION', _localisationTable(d)),
        pw.SizedBox(height: 12),
        if (d.acquisition != null) ...[
          _section('ACQUISITION', _acquisitionTable(d.acquisition!)),
          pw.SizedBox(height: 12),
        ],
        _section('RESPONSABLES', _responsablesTable(d)),
        pw.SizedBox(height: 12),
        _section('OBSERVATIONS', _observations(d)),
        pw.SizedBox(height: 24),
        _signatures(d),
      ],
    ));
    return pdf.save();
  }

  pw.Widget _header(pw.Context ctx, FichePdf d, pw.MemoryImage? logo) {
    return pw.Column(children: [
      pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: pw.BoxDecoration(color: _primary),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            logo != null
                ? pw.Image(logo, width: 50, height: 50)
                : pw.Container(
                    width: 50,
                    height: 50,
                    decoration: pw.BoxDecoration(
                        color: _accent, shape: pw.BoxShape.circle),
                    alignment: pw.Alignment.center,
                    child: pw.Text('C',
                        style: pw.TextStyle(
                            color: _white,
                            fontSize: 24,
                            fontWeight: pw.FontWeight.bold)),
                  ),
            pw.Expanded(
              child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text("REPUBLIQUE DE COTE D'IVOIRE",
                        style: pw.TextStyle(
                            color: _white, fontSize: 8, letterSpacing: 1.2)),
                    pw.SizedBox(height: 2),
                    pw.Text("MINISTERE DE LA SANTE ET DE L'HYGIENE PUBLIQUE",
                        style: pw.TextStyle(color: _accent, fontSize: 7),
                        textAlign: pw.TextAlign.center),
                    pw.SizedBox(height: 6),
                    pw.Text('CATUSNIS',
                        style: pw.TextStyle(
                            color: _white,
                            fontSize: 20,
                            fontWeight: pw.FontWeight.bold,
                            letterSpacing: 3)),
                    pw.Text('Gestion des Equipements de Sante',
                        style: pw.TextStyle(color: _accent, fontSize: 8)),
                  ]),
            ),
            pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
              pw.Text('Ref. : ${d.reference}',
                  style: pw.TextStyle(
                      color: _white,
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 4),
              pw.Text('Genere le\n${_dateFmt.format(DateTime.now())}',
                  style: pw.TextStyle(color: _accent, fontSize: 7.5),
                  textAlign: pw.TextAlign.right),
            ]),
          ],
        ),
      ),
      pw.Container(
          height: 4,
          decoration: pw.BoxDecoration(
              gradient:
                  pw.LinearGradient(colors: [_primary, _accent, _primary]))),
      pw.SizedBox(height: 4),
      pw.Center(
          child: pw.Text('FICHE DE DEPLOIEMENT D\'EQUIPEMENT',
              style: pw.TextStyle(
                  color: _textDark,
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  letterSpacing: 2))),
      pw.SizedBox(height: 8),
    ]);
  }

  pw.Widget _footer(pw.Context ctx, FichePdf d) => pw.Column(children: [
        pw.Divider(color: _divider, thickness: 0.8),
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
          pw.Text('CATUSNIS - Document officiel',
              style: pw.TextStyle(color: _textLight, fontSize: 7)),
          pw.Text('Page ${ctx.pageNumber} / ${ctx.pagesCount}',
              style: pw.TextStyle(color: _textLight, fontSize: 7)),
          pw.Text(d.reference,
              style: pw.TextStyle(
                  color: _textLight,
                  fontSize: 7,
                  fontStyle: pw.FontStyle.italic)),
        ]),
      ]);

  pw.Widget _statutBanner(FichePdf d) {
    final color = _statutColors[d.statut] ?? PdfColor.fromHex('607D8B');
    final label = switch (d.statut) {
      'EN_COURS' => 'EN COURS',
      'TERMINE' => 'TERMINE',
      'SUSPENDU' => 'SUSPENDU',
      _ => d.statut,
    };
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: pw.BoxDecoration(
          color: _surface,
          border: pw.Border.all(color: _divider),
          borderRadius: pw.BorderRadius.circular(6)),
      child: pw
          .Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
        pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          _iRow('Date de deploiement', _dateFmt.format(d.dateDeploiement)),
          if (d.dateFin != null)
            _iRow('Date de fin', _dateFmt.format(d.dateFin!)),
        ]),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          decoration: pw.BoxDecoration(
              color: color, borderRadius: pw.BorderRadius.circular(20)),
          child: pw.Text(label,
              style: pw.TextStyle(
                  color: _white,
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  letterSpacing: 1.5)),
        ),
      ]),
    );
  }

  pw.Widget _section(String title, pw.Widget content) =>
      pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: pw.BoxDecoration(
              color: _primary,
              borderRadius: const pw.BorderRadius.only(
                  topLeft: pw.Radius.circular(4),
                  topRight: pw.Radius.circular(4))),
          child: pw.Text(title,
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
              color: _surface,
              border: pw.Border.all(color: _divider),
              borderRadius: const pw.BorderRadius.only(
                  bottomLeft: pw.Radius.circular(4),
                  bottomRight: pw.Radius.circular(4))),
          child: content,
        ),
      ]);

  pw.Widget _equipementTable(FichePdf d) {
    final eq = d.equipement;
    final ec = _etatColors[eq.etat] ?? PdfColor.fromHex('607D8B');
    return pw.Column(children: [
      _row2('Designation', eq.designation),
      _row2('Numero de serie', eq.numeroSerie),
      _row2('Marque / Modele', '${eq.marque} - ${eq.modele}'),
      _row2('Categorie', eq.categorie),
      pw.Row(children: [
        pw.Expanded(
            child: pw.Text('Etat :',
                style: pw.TextStyle(
                    color: _textLight,
                    fontSize: 8.5,
                    fontWeight: pw.FontWeight.bold))),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 3),
          decoration: pw.BoxDecoration(
              color: ec, borderRadius: pw.BorderRadius.circular(10)),
          child: pw.Text(eq.etat.replaceAll('_', ' '),
              style: pw.TextStyle(
                  color: _white, fontSize: 8, fontWeight: pw.FontWeight.bold)),
        ),
      ]),
    ]);
  }

  pw.Widget _localisationTable(FichePdf d) => pw.Column(children: [
        _row2('Direction Regionale', d.region.nom),
        _row2('District Sanitaire', d.district.nom),
        _row2('Site de destination', d.site.nom),
      ]);

  pw.Widget _acquisitionTable(FichePdfAcquisition a) => pw.Column(children: [
        _row2('Reference', a.reference),
        _row2('Fournisseur', a.fournisseur),
        _row2("Date d acquisition", _dateFmt.format(a.dateAcquisition)),
        _row2('Prix unitaire', '${_moneyFmt.format(a.prixUnitaire)} FCFA'),
      ]);

  pw.Widget _responsablesTable(FichePdf d) =>
      pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Expanded(
            child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
              _roleH('TECHNICIEN'),
              if (d.technicien != null) ...[
                _iRow('Nom', d.technicien!.nomComplet),
                _iRow('Email', d.technicien!.email),
                if (d.technicien!.telephone != null)
                  _iRow('Tel.', d.technicien!.telephone!),
              ] else
                _na(),
            ])),
        pw.SizedBox(width: 16),
        pw.Expanded(
            child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
              _roleH('LOGISTICIEN'),
              if (d.logisticien != null) ...[
                _iRow('Nom', d.logisticien!.nomComplet),
                _iRow('Email', d.logisticien!.email),
                if (d.logisticien!.telephone != null)
                  _iRow('Tel.', d.logisticien!.telephone!),
              ] else
                _na(),
            ])),
      ]);

  pw.Widget _observations(FichePdf d) => pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
            border:
                pw.Border.all(color: _divider, style: pw.BorderStyle.dashed),
            borderRadius: pw.BorderRadius.circular(4)),
        child: pw.Text(
            d.observations?.isNotEmpty == true ? d.observations! : 'Aucune',
            style: pw.TextStyle(
                fontSize: 9, color: _textDark, fontStyle: pw.FontStyle.italic)),
      );

  pw.Widget _signatures(FichePdf d) => pw.Container(
        padding: const pw.EdgeInsets.all(14),
        decoration: pw.BoxDecoration(
            border: pw.Border.all(color: _divider),
            borderRadius: pw.BorderRadius.circular(6)),
        child: pw.Column(children: [
          pw.Text('SIGNATURES ET APPROBATIONS',
              style: pw.TextStyle(
                  color: _primary,
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  letterSpacing: 1.5)),
          pw.SizedBox(height: 14),
          pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _sig('Technicien', d.technicien?.nomComplet ?? '---'),
                _sig('Logisticien', d.logisticien?.nomComplet ?? '---'),
                _sig('Responsable du site', d.site.nom),
              ]),
        ]),
      );

  pw.Widget _row2(String l, String v) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 3),
        child: pw.Row(children: [
          pw.SizedBox(
              width: 120,
              child: pw.Text(l,
                  style: pw.TextStyle(
                      color: _textLight,
                      fontSize: 8.5,
                      fontWeight: pw.FontWeight.bold))),
          pw.Container(width: 1, height: 12, color: _divider),
          pw.SizedBox(width: 8),
          pw.Expanded(
              child: pw.Text(v,
                  style: pw.TextStyle(color: _textDark, fontSize: 8.5))),
        ]),
      );

  pw.Widget _iRow(String l, String v) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 2),
        child: pw.Row(children: [
          pw.Text('$l : ',
              style: pw.TextStyle(
                  color: _textLight,
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold)),
          pw.Text(v, style: pw.TextStyle(color: _textDark, fontSize: 8)),
        ]),
      );

  pw.Widget _roleH(String r) => pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 6),
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: pw.BoxDecoration(
            color: _secondary, borderRadius: pw.BorderRadius.circular(3)),
        child: pw.Text(r,
            style: pw.TextStyle(
                color: _white,
                fontSize: 7.5,
                fontWeight: pw.FontWeight.bold,
                letterSpacing: 1)),
      );

  pw.Widget _na() => pw.Text('Non assigne',
      style: pw.TextStyle(
          color: _textLight, fontSize: 8, fontStyle: pw.FontStyle.italic));

  pw.Widget _sig(String role, String nom) =>
      pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.center, children: [
        pw.Text(role,
            style: pw.TextStyle(
                color: _primary, fontSize: 8, fontWeight: pw.FontWeight.bold)),
        pw.Text(nom,
            style: pw.TextStyle(
                color: _textLight,
                fontSize: 7.5,
                fontStyle: pw.FontStyle.italic)),
        pw.SizedBox(height: 28),
        pw.Container(width: 110, height: 0.8, color: _textDark),
        pw.SizedBox(height: 4),
        pw.Text('Date : ..............................',
            style: pw.TextStyle(color: _textLight, fontSize: 7)),
      ]);
}
