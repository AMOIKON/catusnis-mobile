// lib/features/acquisitions/models/acquisition_model.dart

import 'dart:convert';

class AcquisitionModel {
  final int id;
  final String tag;
  final String serial;
  final int? quantity;
  final String status;
  final String? image;
  final bool deployed;
  final String? dateAcq;
  final String? typeName;
  final String? partnerName;
  final int? partnerId;

  AcquisitionModel({
    required this.id,
    required this.tag,
    required this.serial,
    this.quantity,
    required this.status,
    this.image,
    this.deployed = false,
    this.dateAcq,
    this.typeName,
    this.partnerName,
    this.partnerId,
  });

  /// Corrige l'encodage CP850/Latin-1 mal interprété en UTF-8
  /// Exemple : "├ëcran" → "Écran" / "Cl├® WiFi" → "Clé WiFi"
  static String? _fixEncoding(String? s) {
    if (s == null || s.isEmpty) return s;
    try {
      return utf8.decode(latin1.encode(s));
    } catch (_) {
      return s;
    }
  }

  factory AcquisitionModel.fromJson(Map<String, dynamic> json) {
    // ── typeName : essaie plusieurs clés possibles du backend ──────────
    final rawType = json['Type'] as String? ??
        json['typeName'] as String? ??
        json['type'] as String? ??
        json['equipmentType'] as String?;

    // ── partnerName : essaie plusieurs clés possibles du backend ───────
    final rawPartner = json['partnerName'] as String? ??
        json['partner_name'] as String? ??
        (json['partner'] is Map
            ? (json['partner']['partnerName'] as String? ??
                json['partner']['name'] as String?)
            : null);

    return AcquisitionModel(
      id: json['id'] ?? 0,
      tag: json['tag'] ?? '',
      serial: json['serial'] ?? '',
      quantity: json['quantity'],
      status: json['status'] ?? '',
      image: json['image'],
      deployed: json['deployed'] ?? false,
      dateAcq: json['dateAcq'],
      typeName: _fixEncoding(rawType),
      partnerName: _fixEncoding(rawPartner),
      partnerId: json['partnerId'],
    );
  }
}
