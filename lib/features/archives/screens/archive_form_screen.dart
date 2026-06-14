// lib/features/archives/screens/archive_form_screen.dart

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:signature/signature.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../shared/theme/app_theme.dart';
import '../models/archive_model.dart';
import '../services/archive_service.dart';
import '../services/pdf_generator_service.dart';

// ── Génération automatique du code de référence ───────────────────────────────
String _generateRefCode(String categorie) {
  final now = DateTime.now();
  final year = now.year;
  final timestamp = now.millisecondsSinceEpoch % 10000;
  final prefix = _catPrefix(categorie);
  return 'ARC-$prefix-$year-${timestamp.toString().padLeft(4, '0')}';
}

String _catPrefix(String categorie) {
  switch (categorie) {
    case 'INTERVENTION':
      return 'INT';
    case 'DEPLOIEMENT':
      return 'DEP';
    case 'ACQUISITION':
      return 'ACQ';
    case 'BOOKLET':
      return 'CAH';
    case 'ACTIVE':
      return 'ACT';
    default:
      return 'AUT';
  }
}

class ArchiveFormScreen extends StatefulWidget {
  final ArchiveModel? archive;
  const ArchiveFormScreen({super.key, this.archive});
  @override
  State<ArchiveFormScreen> createState() => _ArchiveFormScreenState();
}

class _ArchiveFormScreenState extends State<ArchiveFormScreen> {
  final ArchiveService _service = ArchiveService();
  final _formKey = GlobalKey<FormState>();
  final _titreCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _relatedCodeCtrl = TextEditingController();
  final _nomResponsableCtrl = TextEditingController();
  final _nomTechnicienCtrl = TextEditingController();

  final _sigResponsable = SignatureController(
    penStrokeWidth: 2,
    penColor: AppTheme.dark,
    exportBackgroundColor: Colors.white,
  );
  final _sigTechnicien = SignatureController(
    penStrokeWidth: 2,
    penColor: AppTheme.dark,
    exportBackgroundColor: Colors.white,
  );

  String _type = 'IMPRIME';
  String _categorie = 'AUTRE';
  bool _submitting = false;
  bool _autoCode = true;

  Uint8List? _bytesResponsable;
  Uint8List? _bytesTechnicien;

  File? _selectedFile;
  Uint8List? _selectedBytes;
  String? _selectedFileName;
  int? _selectedFileSize;

  bool get _isEdit => widget.archive != null;
  bool get _hasFile => kIsWeb ? _selectedBytes != null : _selectedFile != null;
  bool get _sigResponsableOk => _bytesResponsable != null;
  bool get _sigTechnicienOk => _bytesTechnicien != null;

  final List<String> _categories = [
    'INTERVENTION',
    'DEPLOIEMENT',
    'ACQUISITION',
    'BOOKLET',
    'AUTRE',
    'ACTIVE'
  ];

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _titreCtrl.text = widget.archive!.titre;
      _descriptionCtrl.text = widget.archive!.description ?? '';
      _relatedCodeCtrl.text = widget.archive!.relatedCode ?? '';
      _type = widget.archive!.type;
      _categorie = widget.archive!.categorie;
      _autoCode = false;
    } else {
      _relatedCodeCtrl.text = _generateRefCode(_categorie);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final user = context.read<AuthProvider>().user;
        if (user != null) {
          _nomTechnicienCtrl.text = '${user.firstName} ${user.lastName}'.trim();
        }
      });
    }
  }

  @override
  void dispose() {
    _titreCtrl.dispose();
    _descriptionCtrl.dispose();
    _relatedCodeCtrl.dispose();
    _nomResponsableCtrl.dispose();
    _nomTechnicienCtrl.dispose();
    _sigResponsable.dispose();
    _sigTechnicien.dispose();
    super.dispose();
  }

  void _onCategorieChanged(String c) {
    setState(() {
      _categorie = c;
      if (_autoCode && !_isEdit) _relatedCodeCtrl.text = _generateRefCode(c);
    });
  }

  Future<void> _captureResponsable() async {
    if (_sigResponsable.isEmpty) return;
    final bytes = await _sigResponsable.toPngBytes();
    setState(() => _bytesResponsable = bytes);
  }

  Future<void> _captureTechnicien() async {
    if (_sigTechnicien.isEmpty) return;
    final bytes = await _sigTechnicien.toPngBytes();
    setState(() => _bytesTechnicien = bytes);
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        allowMultiple: false,
        withData: kIsWeb,
      );
      if (result != null && result.files.isNotEmpty) {
        final f = result.files.single;
        final fileSize = f.size;
        final fileName = f.name;
        if (kIsWeb) {
          final bytes = f.bytes;
          setState(() {
            _selectedFileName = fileName;
            _selectedFileSize = fileSize;
            _selectedBytes = bytes;
            _selectedFile = null;
          });
        } else {
          final file = File(f.path!);
          setState(() {
            _selectedFileName = fileName;
            _selectedFileSize = fileSize;
            _selectedFile = file;
            _selectedBytes = null;
          });
        }
      }
    } catch (e) {
      _showError('Erreur sélection fichier : $e');
    }
  }

  Future<void> _pickFromCamera() async {
    if (kIsWeb) return;
    try {
      final XFile? photo = await ImagePicker()
          .pickImage(source: ImageSource.camera, imageQuality: 85);
      if (photo != null) {
        final file = File(photo.path);
        final size = await file.length();
        setState(() {
          _selectedFile = file;
          _selectedBytes = null;
          _selectedFileName = photo.name;
          _selectedFileSize = size;
        });
      }
    } catch (e) {
      _showError('Erreur caméra : $e');
    }
  }

  Future<void> _pickFromGallery() async {
    if (kIsWeb) return;
    try {
      final XFile? image = await ImagePicker()
          .pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (image != null) {
        final file = File(image.path);
        final size = await file.length();
        setState(() {
          _selectedFile = file;
          _selectedBytes = null;
          _selectedFileName = image.name;
          _selectedFileSize = size;
        });
      }
    } catch (e) {
      _showError('Erreur galerie : $e');
    }
  }

  void _showFilePickerSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            const Text('Ajouter un fichier',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            if (!kIsWeb) ...[
              _PickerOption(
                  icon: Icons.camera_alt_outlined,
                  color: AppTheme.primary,
                  label: 'Prendre une photo',
                  subtitle: 'Scanner un document avec la caméra',
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickFromCamera();
                  }),
              const SizedBox(height: 12),
              _PickerOption(
                  icon: Icons.photo_library_outlined,
                  color: AppTheme.success,
                  label: 'Galerie photos',
                  subtitle: 'Choisir une image existante',
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickFromGallery();
                  }),
              const SizedBox(height: 12),
            ],
            _PickerOption(
                icon: Icons.picture_as_pdf_outlined,
                color: Colors.red,
                label: 'Fichier PDF / Image',
                subtitle: 'Sélectionner depuis les fichiers',
                onTap: () {
                  Navigator.pop(ctx);
                  _pickFile();
                }),
          ]),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_type == 'SCANNE' && !_isEdit && !_hasFile) {
      _showError('Veuillez sélectionner un fichier');
      return;
    }

    if (_type == 'IMPRIME' && !_isEdit) {
      if (_nomResponsableCtrl.text.trim().isEmpty) {
        _showError('Veuillez saisir le nom du responsable');
        return;
      }
      if (_nomTechnicienCtrl.text.trim().isEmpty) {
        _showError('Veuillez saisir le nom du technicien / admin');
        return;
      }
      if (!_sigResponsableOk) {
        if (_sigResponsable.isEmpty) {
          _showError('La signature du responsable est obligatoire');
          return;
        }
        await _captureResponsable();
      }
      if (!_sigTechnicienOk) {
        if (_sigTechnicien.isEmpty) {
          _showError('La signature du technicien / admin est obligatoire');
          return;
        }
        await _captureTechnicien();
      }
    }

    setState(() => _submitting = true);
    try {
      final relatedCode = _relatedCodeCtrl.text.trim().isEmpty
          ? null
          : _relatedCodeCtrl.text.trim();
      final user = context.read<AuthProvider>().user;
      final archivedBy =
          user != null ? '${user.firstName} ${user.lastName}'.trim() : '';

      if (_isEdit) {
        await _service.updateArchive(widget.archive!.id, {
          'titre': _titreCtrl.text.trim(),
          'type': _type,
          'categorie': _categorie,
          'description': _descriptionCtrl.text.trim(),
          'relatedCode': relatedCode,
        });
      } else if (_type == 'IMPRIME') {
        // Générer PDF avec les 2 signatures
        final pdfBytes = await PdfGeneratorService.generateArchiveImprimePdf(
          titre: _titreCtrl.text.trim(),
          categorie: _categorie,
          refCode: relatedCode ?? _relatedCodeCtrl.text,
          description: _descriptionCtrl.text.trim(),
          archivedBy: archivedBy,
          signatureResponsable: _bytesResponsable!,
          signatureTechnicien: _bytesTechnicien!,
          nomResponsable: _nomResponsableCtrl.text.trim(),
          nomTechnicien: _nomTechnicienCtrl.text.trim(),
        );
        final pdfName =
            '${(relatedCode ?? 'ARC').replaceAll('-', '_')}_signe.pdf';
        await _service.createArchiveScanne(
          bytes: pdfBytes,
          fileName: pdfName,
          titre: _titreCtrl.text.trim(),
          categorie: _categorie,
          description: _descriptionCtrl.text.trim(),
          relatedCode: relatedCode,
        );
      } else if (_type == 'SCANNE' && _hasFile) {
        await _service.createArchiveScanne(
          file: kIsWeb ? null : _selectedFile,
          bytes: kIsWeb ? _selectedBytes : null,
          fileName: _selectedFileName!,
          titre: _titreCtrl.text.trim(),
          categorie: _categorie,
          description: _descriptionCtrl.text.trim(),
          relatedCode: relatedCode,
        );
      }
      if (!mounted) return;
      _showSuccess();
    } catch (e) {
      if (!mounted) return;
      _showError('Erreur : $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showSuccess() => showDialog(
      context: context,
      builder: (_) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            content: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                      color: AppTheme.success.withOpacity(0.1),
                      shape: BoxShape.circle),
                  child: Icon(
                      _isEdit ? Icons.edit_note : Icons.check_circle_outline,
                      color: AppTheme.success,
                      size: 40)),
              const SizedBox(height: 16),
              Text(_isEdit ? 'Archive mise à jour !' : 'Archive créée !',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8)),
                child: Text(_relatedCodeCtrl.text,
                    style: const TextStyle(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 12)),
              ),
              if (_type == 'IMPRIME' && !_isEdit) ...[
                const SizedBox(height: 8),
                const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.picture_as_pdf,
                          size: 14, color: AppTheme.success),
                      SizedBox(width: 4),
                      Text('PDF avec signatures sauvegardé',
                          style:
                              TextStyle(fontSize: 11, color: AppTheme.success)),
                    ]),
              ],
              const SizedBox(height: 8),
              Text(_titreCtrl.text,
                  style: const TextStyle(color: AppTheme.gray),
                  textAlign: TextAlign.center),
            ]),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8))),
                child: const Text('OK', style: TextStyle(color: Colors.white)),
              )
            ],
          ));

  void _showError(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(msg),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating));

  String _catLabel(String c) {
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

  String _fileSizeLabel(int bytes) {
    if (bytes < 1024) return '$bytes o';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} Ko';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} Mo';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightBg,
      appBar: AppBar(
        title: Text(_isEdit ? 'Modifier archive' : 'Nouvelle archive'),
        actions: [
          if (_submitting)
            const Padding(
                padding: EdgeInsets.all(14),
                child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white)))
          else
            TextButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.save_outlined, color: Colors.white),
              label: Text(_isEdit ? 'Mettre à jour' : 'Enregistrer',
                  style: const TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // ── Type ──────────────────────────────────────────────────────
            _sectionTitle('Type d\'archive', Icons.folder_outlined),
            _card([
              Row(
                  children: ['IMPRIME', 'SCANNE'].map((t) {
                final sel = _type == t;
                final label = t == 'IMPRIME' ? 'Imprimé' : 'Scanné';
                final icon = t == 'IMPRIME'
                    ? Icons.print_outlined
                    : Icons.document_scanner_outlined;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() {
                      _type = t;
                      if (t == 'IMPRIME') {
                        _selectedFile = null;
                        _selectedBytes = null;
                      }
                    }),
                    child: Container(
                      margin: EdgeInsets.only(right: t == 'IMPRIME' ? 8 : 0),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                          color: sel
                              ? AppTheme.primary
                              : AppTheme.primary.withOpacity(0.07),
                          borderRadius: BorderRadius.circular(10)),
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(icon,
                                size: 16,
                                color: sel ? Colors.white : AppTheme.primary),
                            const SizedBox(width: 6),
                            Text(label,
                                style: TextStyle(
                                    color:
                                        sel ? Colors.white : AppTheme.primary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13)),
                          ]),
                    ),
                  ),
                );
              }).toList()),
              if (_type == 'SCANNE' && !_isEdit) ...[
                const SizedBox(height: 12),
                _hasFile ? _buildSelectedFileCard() : _buildFilePickerZone(),
              ],
            ]),

            // ── Informations ──────────────────────────────────────────────
            _sectionTitle('Informations', Icons.info_outline),
            _card([
              _buildTextField(
                  controller: _titreCtrl,
                  label: 'Titre *',
                  icon: Icons.title_outlined,
                  validator: (v) => v!.isEmpty ? 'Champ requis' : null),
              const SizedBox(height: 12),
              _buildTextField(
                  controller: _descriptionCtrl,
                  label: 'Description',
                  icon: Icons.notes_outlined,
                  maxLines: 3),
            ]),

            // ── Catégorie ─────────────────────────────────────────────────
            _sectionTitle('Catégorie', Icons.category_outlined),
            _card([
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _categories.map((c) {
                  final sel = _categorie == c;
                  return GestureDetector(
                    onTap: () => _onCategorieChanged(c),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                          color: sel
                              ? AppTheme.primary
                              : AppTheme.primary.withOpacity(0.07),
                          borderRadius: BorderRadius.circular(20)),
                      child: Text(_catLabel(c),
                          style: TextStyle(
                              color: sel ? Colors.white : AppTheme.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500)),
                    ),
                  );
                }).toList(),
              ),
            ]),

            // ── Référence ─────────────────────────────────────────────────
            _sectionTitle('Référence', Icons.link_outlined),
            _card([
              if (!_isEdit)
                Row(children: [
                  const Icon(Icons.auto_fix_high,
                      size: 16, color: AppTheme.primary),
                  const SizedBox(width: 8),
                  const Expanded(
                      child: Text('Générer automatiquement',
                          style:
                              TextStyle(fontSize: 13, color: AppTheme.dark))),
                  Switch(
                      value: _autoCode,
                      activeColor: AppTheme.primary,
                      onChanged: (v) => setState(() {
                            _autoCode = v;
                            if (v)
                              _relatedCodeCtrl.text =
                                  _generateRefCode(_categorie);
                          })),
                ]),
              if (!_isEdit) const SizedBox(height: 8),
              TextFormField(
                controller: _relatedCodeCtrl,
                readOnly: _autoCode && !_isEdit,
                decoration: InputDecoration(
                  labelText: 'Code de référence',
                  prefixIcon: const Icon(Icons.link_outlined,
                      size: 18, color: AppTheme.gray),
                  suffixIcon: (_autoCode && !_isEdit)
                      ? const Tooltip(
                          message: 'Généré automatiquement',
                          child: Icon(Icons.auto_awesome,
                              size: 18, color: AppTheme.primary))
                      : IconButton(
                          icon: const Icon(Icons.refresh,
                              size: 18, color: AppTheme.primary),
                          onPressed: () => setState(() => _relatedCodeCtrl
                              .text = _generateRefCode(_categorie))),
                  filled: true,
                  fillColor: (_autoCode && !_isEdit)
                      ? AppTheme.primary.withOpacity(0.05)
                      : Colors.grey[100],
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          BorderSide(color: AppTheme.primary, width: 1.5)),
                ),
              ),
            ]),

            // ── Signatures (IMPRIME + création uniquement) ────────────────
            if (_type == 'IMPRIME' && !_isEdit) ...[
              _sectionTitle('Signatures', Icons.draw_outlined),
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: AppTheme.warning.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border:
                        Border.all(color: AppTheme.warning.withOpacity(0.3))),
                child: const Row(children: [
                  Icon(Icons.info_outline, size: 16, color: AppTheme.warning),
                  SizedBox(width: 8),
                  Expanded(
                      child: Text(
                          'Les deux signatures sont obligatoires. Un PDF sera généré '
                          'et sauvegardé automatiquement.',
                          style: TextStyle(
                              fontSize: 11, color: AppTheme.warning))),
                ]),
              ),
              _buildSignatureCard(
                title: 'Signature du Responsable du site',
                subtitle: 'Nom du responsable *',
                nameCtrl: _nomResponsableCtrl,
                controller: _sigResponsable,
                isCaptured: _sigResponsableOk,
                color: const Color(0xFF0F4C81),
                icon: Icons.person_outlined,
                onCapture: _captureResponsable,
                onClear: () {
                  _sigResponsable.clear();
                  setState(() => _bytesResponsable = null);
                },
              ),
              const SizedBox(height: 12),
              _buildSignatureCard(
                title: 'Signature du Technicien / Admin',
                subtitle: 'Nom du technicien / admin *',
                nameCtrl: _nomTechnicienCtrl,
                controller: _sigTechnicien,
                isCaptured: _sigTechnicienOk,
                color: const Color(0xFF057A55),
                icon: Icons.engineering_outlined,
                onCapture: _captureTechnicien,
                onClear: () {
                  _sigTechnicien.clear();
                  setState(() => _bytesTechnicien = null);
                },
              ),
            ],

            const SizedBox(height: 100),
          ]),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _submitting ? null : _submit,
        icon: const Icon(Icons.save_outlined, color: Colors.white),
        label: Text(_isEdit ? 'Mettre à jour' : 'Enregistrer',
            style: const TextStyle(color: Colors.white)),
        backgroundColor: AppTheme.primary,
      ),
    );
  }

  Widget _buildSignatureCard({
    required String title,
    required String subtitle,
    required TextEditingController nameCtrl,
    required SignatureController controller,
    required bool isCaptured,
    required Color color,
    required IconData icon,
    required VoidCallback onCapture,
    required VoidCallback onClear,
  }) =>
      _card([
        Row(children: [
          Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 18)),
          const SizedBox(width: 12),
          Expanded(
              child: Text(title,
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: color))),
          if (isCaptured)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                  color: AppTheme.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8)),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.check_circle, size: 12, color: AppTheme.success),
                SizedBox(width: 4),
                Text('Capturée',
                    style: TextStyle(
                        fontSize: 10,
                        color: AppTheme.success,
                        fontWeight: FontWeight.w600)),
              ]),
            ),
        ]),
        const SizedBox(height: 12),
        TextFormField(
          controller: nameCtrl,
          validator: (_type == 'IMPRIME' && !_isEdit)
              ? (v) => v!.trim().isEmpty ? 'Champ requis' : null
              : null,
          decoration: InputDecoration(
            labelText: subtitle,
            prefixIcon: const Icon(Icons.person_outline,
                size: 18, color: AppTheme.gray),
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: color, width: 1.5)),
          ),
        ),
        const SizedBox(height: 12),
        const Text('Signez dans le cadre ci-dessous :',
            style: TextStyle(fontSize: 12, color: AppTheme.gray)),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Container(
            decoration: BoxDecoration(
                border: Border.all(color: color.withOpacity(0.4), width: 1.5),
                borderRadius: BorderRadius.circular(10),
                color: Colors.white),
            child: Signature(
                controller: controller,
                height: 130,
                backgroundColor: Colors.white),
          ),
        ),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onClear,
              icon: const Icon(Icons.clear, size: 16),
              label: const Text('Effacer'),
              style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.danger,
                  side: BorderSide(color: AppTheme.danger.withOpacity(0.4)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8))),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: onCapture,
              icon: const Icon(Icons.check, size: 16, color: Colors.white),
              label: const Text('Confirmer',
                  style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8))),
            ),
          ),
        ]),
      ]);

  Widget _buildFilePickerZone() => GestureDetector(
        onTap: _showFilePickerSheet,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.04),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppTheme.primary.withOpacity(0.3), width: 1.5)),
          child: Column(children: [
            Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14)),
                child: const Icon(Icons.upload_file_outlined,
                    color: AppTheme.primary, size: 28)),
            const SizedBox(height: 12),
            const Text('Appuyez pour ajouter un fichier',
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppTheme.primary)),
            const SizedBox(height: 4),
            Text(
                kIsWeb
                    ? 'Fichier PDF ou image'
                    : 'Photo, galerie ou fichier PDF',
                style: const TextStyle(fontSize: 12, color: AppTheme.gray)),
          ]),
        ),
      );

  Widget _buildSelectedFileCard() {
    final ext = _selectedFileName?.split('.').last.toLowerCase() ?? '';
    final isPdf = ext == 'pdf';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: AppTheme.success.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.success.withOpacity(0.3))),
      child: Row(children: [
        Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
                color: isPdf
                    ? Colors.red.withOpacity(0.1)
                    : AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(isPdf ? Icons.picture_as_pdf : Icons.image_outlined,
                color: isPdf ? Colors.red : AppTheme.primary, size: 24)),
        const SizedBox(width: 12),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_selectedFileName ?? '',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          if (_selectedFileSize != null)
            Text(_fileSizeLabel(_selectedFileSize!),
                style: const TextStyle(fontSize: 11, color: AppTheme.gray)),
        ])),
        GestureDetector(
          onTap: _showFilePickerSheet,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8)),
            child: const Text('Changer',
                style: TextStyle(
                    color: AppTheme.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => setState(() {
            _selectedFile = null;
            _selectedBytes = null;
            _selectedFileName = null;
            _selectedFileSize = null;
          }),
          child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.close, color: Colors.red, size: 16)),
        ),
      ]),
    );
  }

  Widget _sectionTitle(String title, IconData icon) => Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 8),
        child: Row(children: [
          Icon(icon, size: 18, color: AppTheme.primary),
          const SizedBox(width: 8),
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AppTheme.dark)),
        ]),
      );

  Widget _card(List<Widget> children) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2))
            ]),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: children),
      );

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) =>
      TextFormField(
        controller: controller,
        maxLines: maxLines,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 18, color: AppTheme.gray),
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppTheme.primary, width: 1.5)),
        ),
      );
}

class _PickerOption extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  const _PickerOption(
      {required this.icon,
      required this.color,
      required this.label,
      required this.subtitle,
      required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: color.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.2))),
          child: Row(children: [
            Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: color, size: 22)),
            const SizedBox(width: 14),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(label,
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: color)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style:
                          const TextStyle(fontSize: 11, color: AppTheme.gray)),
                ])),
            Icon(Icons.arrow_forward_ios,
                size: 14, color: color.withOpacity(0.5)),
          ]),
        ),
      );
}
