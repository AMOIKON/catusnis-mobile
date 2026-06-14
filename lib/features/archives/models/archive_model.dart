// lib/features/archives/models/archive_model.dart

class ArchiveModel {
  final int id;
  final String titre;
  final String type;
  final String categorie;
  final String? fileName;
  final String? mimeType;
  final int? fileSize;
  final String? description;
  final String? archivedBy;
  final String? archivedAt;
  final String? relatedCode;
  final int? relatedId;
  final String? downloadUrl;

  ArchiveModel({
    required this.id,
    required this.titre,
    required this.type,
    required this.categorie,
    this.fileName,
    this.mimeType,
    this.fileSize,
    this.description,
    this.archivedBy,
    this.archivedAt,
    this.relatedCode,
    this.relatedId,
    this.downloadUrl,
  });

  factory ArchiveModel.fromJson(Map<String, dynamic> json) {
    return ArchiveModel(
      id: json['id'] ?? 0,
      titre: json['titre'] ?? '',
      type: json['type'] ?? '',
      categorie: json['categorie'] ?? '',
      fileName: json['fileName'],
      mimeType: json['mimeType'],
      fileSize: (json['fileSize'] as num?)?.toInt(),
      description: json['description'],
      archivedBy: json['archivedBy'],
      archivedAt: json['archivedAt'],
      relatedCode: json['relatedCode'],
      relatedId: (json['relatedId'] as num?)?.toInt(),
      downloadUrl: json['downloadUrl'],
    );
  }

  // ✅ Taille fichier lisible
  String get fileSizeLabel {
    if (fileSize == null) return '';
    if (fileSize! < 1024) return '$fileSize o';
    if (fileSize! < 1024 * 1024)
      return '${(fileSize! / 1024).toStringAsFixed(1)} Ko';
    return '${(fileSize! / (1024 * 1024)).toStringAsFixed(1)} Mo';
  }

  bool get isPdf => mimeType == 'application/pdf';
  bool get isScanne => type == 'SCANNE';
}
