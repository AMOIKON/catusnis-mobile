// lib/features/archives/screens/signature_capture_screen.dart

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:signature/signature.dart';

class SignatureCaptureScreen extends StatefulWidget {
  final String title;
  final String subtitle;

  const SignatureCaptureScreen({
    super.key,
    this.title = 'Signature',
    this.subtitle = 'Veuillez signer dans le cadre ci-dessous',
  });

  @override
  State<SignatureCaptureScreen> createState() => _SignatureCaptureScreenState();
}

class _SignatureCaptureScreenState extends State<SignatureCaptureScreen> {
  static const _kBlue = Color(0xFF0D3380);

  late final SignatureController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = SignatureController(
      penStrokeWidth: 2.5,
      penColor: Colors.black,
      exportBackgroundColor: Colors.white,
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    if (_ctrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez signer avant de confirmer'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final Uint8List? png = await _ctrl.toPngBytes();
    if (!mounted) return;
    Navigator.of(context).pop(png);
  }

  void _clear() => _ctrl.clear();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        backgroundColor: _kBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(widget.title,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(null),
        ),
      ),
      body: Column(children: [
        // Instructions
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _kBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.edit_outlined, color: _kBlue, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.subtitle,
                style: const TextStyle(fontSize: 13, color: Color(0xFF374151)),
              ),
            ),
          ]),
        ),
        const Divider(height: 1),

        // Zone de signature
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: _kBlue.withValues(alpha: 0.3), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Signature(
                  controller: _ctrl,
                  width: double.infinity,
                  height: double.infinity,
                  backgroundColor: Colors.white,
                ),
              ),
            ),
          ),
        ),

        // Boutons
        Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          color: Colors.white,
          child: Row(children: [
            // Effacer
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _clear,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Effacer'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey[700],
                  side: BorderSide(color: Colors.grey.shade300),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Confirmer
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: _confirm,
                icon: const Icon(Icons.check, size: 18, color: Colors.white),
                label: const Text('Confirmer la signature',
                    style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kBlue,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}
