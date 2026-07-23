// lib/features/vehicules/services/vehicule_print_service.dart
//
// Le PDF est téléchargé depuis le backend via
// VehiculeService().downloadVehiculePdf(id), qui appelle
// GET /api/vehicules/{id}/pdf. Ce PDF contient le QR code de vérification
// publique, et son appel déclenche l'archivage automatique (BLOB) côté serveur.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../models/vehicule_model.dart';
import 'vehicule_service.dart';

class VehiculePrintService {
  final VehiculeService _service = VehiculeService();

  Future<void> previewFiche(
      BuildContext context, VehiculeModel vehicule) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => _PdfPreviewPage(vehicule: vehicule)),
    );
  }

  Future<void> printFiche(BuildContext context, VehiculeModel vehicule) async {
    try {
      final bytes = await _service.downloadVehiculePdf(vehicule.id);
      await Printing.layoutPdf(
        onLayout: (_) async => bytes,
        name: 'Fiche_${vehicule.immatriculation}',
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

  Future<void> sharePdf(VehiculeModel vehicule) async {
    final bytes = await _service.downloadVehiculePdf(vehicule.id);
    final tmpDir = await getTemporaryDirectory();
    final file = File('${tmpDir.path}/Fiche_${vehicule.immatriculation}.pdf');
    await file.writeAsBytes(bytes);
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/pdf')],
      subject: 'Fiche engin — ${vehicule.immatriculation}',
      text: 'Immatriculation : ${vehicule.immatriculation}',
    );
  }
}

class _PdfPreviewPage extends StatelessWidget {
  final VehiculeModel vehicule;
  const _PdfPreviewPage({required this.vehicule});

  @override
  Widget build(BuildContext context) {
    final service = VehiculeService();
    return Scaffold(
      appBar: AppBar(
        title: Text('Aperçu — ${vehicule.immatriculation}'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () async {
              final bytes = await service.downloadVehiculePdf(vehicule.id);
              await Printing.layoutPdf(
                  onLayout: (_) async => bytes,
                  name: 'Fiche_${vehicule.immatriculation}');
            },
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => VehiculePrintService().sharePdf(vehicule),
          ),
        ],
      ),
      body: PdfPreview(
        build: (format) => service.downloadVehiculePdf(vehicule.id),
        allowPrinting: true,
        allowSharing: true,
        canChangePageFormat: false,
      ),
    );
  }
}
