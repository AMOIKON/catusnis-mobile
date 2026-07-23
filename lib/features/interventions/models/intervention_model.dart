// lib/features/interventions/models/intervention_model.dart

class InterventionModel {
  final int id;
  final String codeInter;
  final String typeInter;
  final String actionInter;
  final String? commentInter;
  final String? dateInter;
  final int? durationMinutes;
  final int? regionId;
  final String? regionName;
  final String? districtName;
  final String? healthName;
  final String? typeName;
  final String? evlName;
  final String? deploymentCode;
  final String? appName;
  final String? technicianName;
  final String? partnerName;
  final String? personName;
  final String? personContact;
  final String? personPost;
  final bool enAttenteMaintenance;
  final int? structureEtatiqueId;
  final String? structureEtatiqueName;
  final List<InterventionItemModel> deploymentItems;

  InterventionModel({
    required this.id,
    required this.codeInter,
    required this.typeInter,
    required this.actionInter,
    this.commentInter,
    this.dateInter,
    this.durationMinutes,
    this.regionId,
    this.regionName,
    this.districtName,
    this.healthName,
    this.typeName,
    this.evlName,
    this.deploymentCode,
    this.appName,
    this.technicianName,
    this.partnerName,
    this.personName,
    this.personContact,
    this.personPost,
    this.enAttenteMaintenance = false,
    this.structureEtatiqueId,
    this.structureEtatiqueName,
    this.deploymentItems = const [],
  });

  factory InterventionModel.fromJson(Map<String, dynamic> json) {
    return InterventionModel(
      id: json['id'] ?? 0,
      codeInter: json['codeInter'] ?? '',
      typeInter: json['typeInter'] ?? '',
      actionInter: json['actionInter'] ?? '',
      commentInter: json['commentInter'],
      dateInter: json['dateInter'],
      durationMinutes: json['durationMinutes'],
      regionId: json['regionId'],
      regionName: json['regionName'],
      districtName: json['districtName'],
      healthName: json['healthName'],
      typeName: json['typeName'],
      evlName: json['evlName'],
      deploymentCode: json['deploymentCode'],
      appName: json['appName'],
      technicianName: json['technicianName'],
      partnerName: json['partnerName'],
      personName: json['personName'],
      personContact: json['personContact'],
      personPost: json['personPost'],
      enAttenteMaintenance: json['enAttenteMaintenance'] ?? false,
      structureEtatiqueId: json['structureEtatiqueId'],
      structureEtatiqueName: json['structureEtatiqueName'],
      deploymentItems: (json['deploymentItems'] as List<dynamic>? ?? [])
          .map((e) => InterventionItemModel.fromJson(e))
          .toList(),
    );
  }
}

class InterventionItemModel {
  final int id;
  final String? tag;
  final String? serial;
  final String? typeName;
  final String status;
  final String? etatAvant;
  final String? etatApres;
  final String? replacementTag;

  InterventionItemModel({
    required this.id,
    this.tag,
    this.serial,
    this.typeName,
    required this.status,
    this.etatAvant,
    this.etatApres,
    this.replacementTag,
  });

  factory InterventionItemModel.fromJson(Map<String, dynamic> json) {
    return InterventionItemModel(
      id: json['id'] ?? 0,
      tag: json['tag'],
      serial: json['serial'],
      typeName: json['typeName'],
      status: json['status'] ?? '',
      etatAvant: json['etatAvant'],
      etatApres: json['etatApres'],
      replacementTag: json['replacementTag'],
    );
  }
}
