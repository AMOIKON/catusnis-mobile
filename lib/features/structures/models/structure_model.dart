// lib/features/structures/models/structure_model.dart

class StructureModel {
  final int id;
  final String nom;
  final int? regionId;
  final String? regionName;
  final int? districtId;
  final String? districtName;
  final String? contact;
  final String? logo; // base64
  final String? createdAt;

  const StructureModel({
    required this.id,
    required this.nom,
    this.regionId,
    this.regionName,
    this.districtId,
    this.districtName,
    this.contact,
    this.logo,
    this.createdAt,
  });

  factory StructureModel.fromJson(Map<String, dynamic> json) {
    final region = json['region'] as Map<String, dynamic>?;
    final district = json['district'] as Map<String, dynamic>?;
    return StructureModel(
      id: json['id'] as int,
      nom: json['nom'] as String? ?? '',
      regionId: region?['id'] as int?,
      regionName: region?['regionName'] as String?,
      districtId: district?['id'] as int?,
      districtName: district?['DistrictName'] as String? ??
          district?['districtName'] as String?,
      contact: json['contact'] as String?,
      logo: json['logo'] as String?,
      createdAt: json['createdAt'] as String?,
    );
  }

  String get initials {
    final w = nom.trim().split(RegExp(r'\s+'));
    return (w.length >= 2
            ? '${w[0][0]}${w[1][0]}'
            : nom.substring(0, nom.length >= 2 ? 2 : 1))
        .toUpperCase();
  }
}
