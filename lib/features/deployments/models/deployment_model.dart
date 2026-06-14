// lib/features/deployments/models/deployment_model.dart

class DeploymentModel {
  final int id;
  final String codeDep;
  final String statut; // BROUILLON | EN_COURS | LIVRE | ARCHIVE | ANNULE
  final String? dateReception;
  final String? observations;

  final int? regionId;
  final String? regionName;
  final int? districtId;
  final String? districtName;
  final int? healthId;
  final String? healthName;

  final DeploymentApp? app;
  final DeploymentPartner? partnerPrincipal;
  final DeploymentPartner? partnerSecondaire;
  final List<DeploymentItem> items;
  final DeploymentSignature? signatureResponsable;
  final DeploymentSignature? signatureReceptionnaire;

  final String? createdAt;
  final String? updatedAt;

  const DeploymentModel({
    required this.id,
    required this.codeDep,
    required this.statut,
    this.dateReception,
    this.observations,
    this.regionId,
    this.regionName,
    this.districtId,
    this.districtName,
    this.healthId,
    this.healthName,
    this.app,
    this.partnerPrincipal,
    this.partnerSecondaire,
    this.items = const [],
    this.signatureResponsable,
    this.signatureReceptionnaire,
    this.createdAt,
    this.updatedAt,
  });

  // ── Propriétés calculées ──────────────────────────────────────────────────

  int get totalUnites => items.length;

  String get resumeEquipements {
    final counts = <String, int>{};
    for (final item in items) {
      final key = item.typeName ?? item.designation ?? 'Inconnu';
      counts[key] = (counts[key] ?? 0) + 1;
    }
    return counts.entries.map((e) => '${e.key} ×${e.value}').join(', ');
  }

  String get localisationComplete {
    final parts = <String>[];
    if (healthName != null) parts.add(healthName!);
    if (regionName != null) parts.add(regionName!);
    return parts.join(' · ');
  }

  Map<String, List<DeploymentItem>> get itemsParType {
    final map = <String, List<DeploymentItem>>{};
    for (final item in items) {
      final key = item.typeName ?? item.designation ?? 'Autre';
      map.putIfAbsent(key, () => []).add(item);
    }
    return map;
  }

  // ── JSON ──────────────────────────────────────────────────────────────────

  factory DeploymentModel.fromJson(Map<String, dynamic> json) {
    return DeploymentModel(
      id: json['id'] as int,
      codeDep: json['codeDep'] as String? ?? '',
      statut: json['statut'] as String? ?? 'BROUILLON',
      dateReception: json['dateReception'] as String?,
      observations: json['observations'] as String?,
      regionId: json['regionId'] as int?,
      regionName: json['regionName'] as String?,
      districtId: json['districtId'] as int?,
      districtName: json['districtName'] as String?,
      healthId: json['healthId'] as int?,
      healthName: json['healthName'] as String?,
      app: json['app'] != null
          ? DeploymentApp.fromJson(json['app'] as Map<String, dynamic>)
          : null,
      partnerPrincipal: json['partnerPrincipal'] != null
          ? DeploymentPartner.fromJson(
              json['partnerPrincipal'] as Map<String, dynamic>)
          : null,
      partnerSecondaire: json['partnerSecondaire'] != null
          ? DeploymentPartner.fromJson(
              json['partnerSecondaire'] as Map<String, dynamic>)
          : null,
      items: (json['items'] as List<dynamic>? ?? [])
          .map((e) => DeploymentItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      signatureResponsable: json['signatureResponsable'] != null
          ? DeploymentSignature.fromJson(
              json['signatureResponsable'] as Map<String, dynamic>)
          : null,
      signatureReceptionnaire: json['signatureReceptionnaire'] != null
          ? DeploymentSignature.fromJson(
              json['signatureReceptionnaire'] as Map<String, dynamic>)
          : null,
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'codeDep': codeDep,
        'statut': statut,
        'dateReception': dateReception,
        'observations': observations,
        'regionId': regionId,
        'regionName': regionName,
        'districtId': districtId,
        'districtName': districtName,
        'healthId': healthId,
        'healthName': healthName,
        'app': app?.toJson(),
        'partnerPrincipal': partnerPrincipal?.toJson(),
        'partnerSecondaire': partnerSecondaire?.toJson(),
        'items': items.map((i) => i.toJson()).toList(),
        'signatureResponsable': signatureResponsable?.toJson(),
        'signatureReceptionnaire': signatureReceptionnaire?.toJson(),
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      };

  DeploymentModel copyWith({
    int? id,
    String? codeDep,
    String? statut,
    String? dateReception,
    String? observations,
    int? regionId,
    String? regionName,
    int? districtId,
    String? districtName,
    int? healthId,
    String? healthName,
    DeploymentApp? app,
    DeploymentPartner? partnerPrincipal,
    DeploymentPartner? partnerSecondaire,
    List<DeploymentItem>? items,
    DeploymentSignature? signatureResponsable,
    DeploymentSignature? signatureReceptionnaire,
    String? createdAt,
    String? updatedAt,
  }) =>
      DeploymentModel(
        id: id ?? this.id,
        codeDep: codeDep ?? this.codeDep,
        statut: statut ?? this.statut,
        dateReception: dateReception ?? this.dateReception,
        observations: observations ?? this.observations,
        regionId: regionId ?? this.regionId,
        regionName: regionName ?? this.regionName,
        districtId: districtId ?? this.districtId,
        districtName: districtName ?? this.districtName,
        healthId: healthId ?? this.healthId,
        healthName: healthName ?? this.healthName,
        app: app ?? this.app,
        partnerPrincipal: partnerPrincipal ?? this.partnerPrincipal,
        partnerSecondaire: partnerSecondaire ?? this.partnerSecondaire,
        items: items ?? this.items,
        signatureResponsable: signatureResponsable ?? this.signatureResponsable,
        signatureReceptionnaire:
            signatureReceptionnaire ?? this.signatureReceptionnaire,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  // ── Données de démonstration ──────────────────────────────────────────────

  static List<DeploymentModel> get samples => [
        DeploymentModel(
          id: 1,
          codeDep: 'DEP-2025-0041',
          statut: 'LIVRE',
          dateReception: '2025-01-12',
          healthId: 3,
          healthName: 'CS Abobo-Baoulé',
          regionId: 1,
          regionName: 'Abidjan',
          districtId: 2,
          districtName: 'Abobo',
          app: DeploymentApp(id: 1, nom: 'SantéNet', version: 'v2.1.0'),
          partnerPrincipal:
              DeploymentPartner(id: 1, nom: 'OMS', type: 'PRINCIPAL'),
          partnerSecondaire:
              DeploymentPartner(id: 2, nom: 'UNICEF', type: 'SECONDAIRE'),
          items: [
            DeploymentItem(
                id: 1,
                typeName: 'Échographe',
                designation: 'Échographe portable',
                numeroSerie: 'ECH-2025-001',
                statut: 'FONCTIONNEL'),
            DeploymentItem(
                id: 2,
                typeName: 'Tensiomètre',
                designation: 'Tensiomètre numérique',
                numeroSerie: 'TEN-2025-001',
                statut: 'FONCTIONNEL'),
            DeploymentItem(
                id: 3,
                typeName: 'Tensiomètre',
                designation: 'Tensiomètre numérique',
                numeroSerie: 'TEN-2025-002',
                statut: 'FONCTIONNEL'),
          ],
          signatureResponsable: DeploymentSignature(
              role: 'RESPONSABLE_LIVRAISON',
              nomSignataire: 'Dr. Kouassi A.',
              dateSignature: '2025-01-12'),
        ),
        DeploymentModel(
          id: 2,
          codeDep: 'DEP-2025-0038',
          statut: 'EN_COURS',
          dateReception: '2025-01-08',
          healthId: 5,
          healthName: 'HG Yopougon',
          regionId: 1,
          regionName: 'Abidjan',
          districtId: 4,
          districtName: 'Yopougon',
          items: [
            DeploymentItem(
                id: 4,
                typeName: 'Glucomètre',
                designation: 'Glucomètre',
                numeroSerie: 'GLU-2025-001',
                statut: 'FONCTIONNEL'),
            DeploymentItem(
                id: 5,
                typeName: 'Glucomètre',
                designation: 'Glucomètre',
                numeroSerie: 'GLU-2025-002',
                statut: 'FONCTIONNEL'),
            DeploymentItem(
                id: 6,
                typeName: 'Glucomètre',
                designation: 'Glucomètre',
                numeroSerie: 'GLU-2025-003',
                statut: 'FONCTIONNEL'),
            DeploymentItem(
                id: 7,
                typeName: 'Glucomètre',
                designation: 'Glucomètre',
                numeroSerie: 'GLU-2025-004',
                statut: 'FONCTIONNEL'),
            DeploymentItem(
                id: 8,
                typeName: 'Glucomètre',
                designation: 'Glucomètre',
                numeroSerie: 'GLU-2025-005',
                statut: 'FONCTIONNEL'),
            DeploymentItem(
                id: 9,
                typeName: 'Oxymètre',
                designation: 'Oxymètre de pouls',
                numeroSerie: 'OXY-2025-001',
                statut: 'FONCTIONNEL'),
            DeploymentItem(
                id: 10,
                typeName: 'Oxymètre',
                designation: 'Oxymètre de pouls',
                numeroSerie: 'OXY-2025-002',
                statut: 'FONCTIONNEL'),
            DeploymentItem(
                id: 11,
                typeName: 'Oxymètre',
                designation: 'Oxymètre de pouls',
                numeroSerie: 'OXY-2025-003',
                statut: 'FONCTIONNEL'),
          ],
        ),
        DeploymentModel(
          id: 3,
          codeDep: 'DEP-2025-0031',
          statut: 'ARCHIVE',
          dateReception: '2024-12-20',
          healthId: 7,
          healthName: 'CS Marcory',
          regionId: 1,
          regionName: 'Abidjan',
          districtId: 6,
          districtName: 'Marcory',
          items: [
            DeploymentItem(
                id: 12,
                typeName: 'Table examen',
                designation: "Table d'examen",
                numeroSerie: 'TAB-2024-001',
                statut: 'FONCTIONNEL'),
          ],
        ),
      ];
}

// ─────────────────────────────────────────────────────────────────────────────
//  ÉQUIPEMENT UNITAIRE
// ─────────────────────────────────────────────────────────────────────────────

class DeploymentItem {
  final int? id;
  final String? typeName;
  final String? designation;
  final String numeroSerie;
  final String? statut;
  final String? observations;
  final bool receptionConfirm;

  const DeploymentItem({
    this.id,
    this.typeName,
    this.designation,
    required this.numeroSerie,
    this.statut,
    this.observations,
    this.receptionConfirm = false,
  });

  factory DeploymentItem.fromJson(Map<String, dynamic> json) => DeploymentItem(
        id: json['id'] as int?,
        typeName: json['typeName'] as String? ?? json['Type'] as String?,
        designation: json['designation'] as String?,
        numeroSerie:
            json['numeroSerie'] as String? ?? json['serial'] as String? ?? '',
        statut: json['statut'] as String?,
        observations: json['observations'] as String?,
        receptionConfirm: json['receptionConfirm'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'typeName': typeName,
        'designation': designation,
        'numeroSerie': numeroSerie,
        'statut': statut,
        'observations': observations,
        'receptionConfirm': receptionConfirm,
      };

  DeploymentItem copyWith({
    int? id,
    String? typeName,
    String? designation,
    String? numeroSerie,
    String? statut,
    String? observations,
    bool? receptionConfirm,
  }) =>
      DeploymentItem(
        id: id ?? this.id,
        typeName: typeName ?? this.typeName,
        designation: designation ?? this.designation,
        numeroSerie: numeroSerie ?? this.numeroSerie,
        statut: statut ?? this.statut,
        observations: observations ?? this.observations,
        receptionConfirm: receptionConfirm ?? this.receptionConfirm,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
//  APPLICATION LIÉE
// ─────────────────────────────────────────────────────────────────────────────

class DeploymentApp {
  final int id;
  final String nom;
  final String? version;
  final String? description;

  const DeploymentApp({
    required this.id,
    required this.nom,
    this.version,
    this.description,
  });

  String get nomComplet => version != null ? '$nom $version' : nom;

  factory DeploymentApp.fromJson(Map<String, dynamic> json) => DeploymentApp(
        id: json['id'] as int,
        nom: json['nom'] as String? ?? json['appsName'] as String? ?? '',
        version: json['version'] as String?,
        description: json['description'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'nom': nom,
        'version': version,
        'description': description,
      };
}

// ─────────────────────────────────────────────────────────────────────────────
//  PARTENAIRE
// ─────────────────────────────────────────────────────────────────────────────

class DeploymentPartner {
  final int id;
  final String nom;
  final String type;
  final String? contact;
  final String? logoUrl;

  const DeploymentPartner({
    required this.id,
    required this.nom,
    required this.type,
    this.contact,
    this.logoUrl,
  });

  factory DeploymentPartner.fromJson(Map<String, dynamic> json) =>
      DeploymentPartner(
        id: json['id'] as int,
        nom: json['nom'] as String? ?? json['partnerName'] as String? ?? '',
        type: json['type'] as String? ?? 'PRINCIPAL',
        contact: json['contact'] as String?,
        logoUrl: json['logoUrl'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'nom': nom,
        'type': type,
        'contact': contact,
        'logoUrl': logoUrl,
      };
}

// ─────────────────────────────────────────────────────────────────────────────
//  SIGNATURE
// ─────────────────────────────────────────────────────────────────────────────

class DeploymentSignature {
  final String role;
  final String? nomSignataire;
  final String? dateSignature;
  final String? imageBase64;

  const DeploymentSignature({
    required this.role,
    this.nomSignataire,
    this.dateSignature,
    this.imageBase64,
  });

  bool get isSigned => nomSignataire != null && nomSignataire!.isNotEmpty;

  factory DeploymentSignature.fromJson(Map<String, dynamic> json) =>
      DeploymentSignature(
        role: json['role'] as String,
        nomSignataire: json['nomSignataire'] as String?,
        dateSignature: json['dateSignature'] as String?,
        imageBase64: json['imageBase64'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'role': role,
        'nomSignataire': nomSignataire,
        'dateSignature': dateSignature,
        'imageBase64': imageBase64,
      };
}

// ─────────────────────────────────────────────────────────────────────────────
//  HELPERS STATUT
// ─────────────────────────────────────────────────────────────────────────────

class DeploymentStatut {
  static const brouillon = 'BROUILLON';
  static const enCours = 'EN_COURS';
  static const livre = 'LIVRE';
  static const archive = 'ARCHIVE';
  static const annule = 'ANNULE';

  static String label(String s) => switch (s) {
        'BROUILLON' => 'Brouillon',
        'EN_COURS' => 'En cours',
        'LIVRE' => 'Livré',
        'ARCHIVE' => 'Archivé',
        'ANNULE' => 'Annulé',
        _ => s,
      };

  static int color(String s) => switch (s) {
        'BROUILLON' => 0xFF607D8B,
        'EN_COURS' => 0xFF1976D2,
        'LIVRE' => 0xFF2E7D52,
        'ARCHIVE' => 0xFF795548,
        'ANNULE' => 0xFFD32F2F,
        _ => 0xFF607D8B,
      };

  static List<String> get all => [brouillon, enCours, livre, archive, annule];
}
