// lib/features/technician_sites/models/technician_site.dart

class TechnicianSite {
  final int id;
  final int personId;
  final String? technicianName;
  final String? personRole;
  final int? regionId;
  final String? regionName;
  final int? districtId;
  final String? districtName;
  final int? healthId;
  final String? healthName;
  final String? niveau;
  final String? createdAt;
  final String? updatedAt;

  const TechnicianSite({
    required this.id,
    required this.personId,
    this.technicianName,
    this.personRole,
    this.regionId,
    this.regionName,
    this.districtId,
    this.districtName,
    this.healthId,
    this.healthName,
    this.niveau,
    this.createdAt,
    this.updatedAt,
  });

  factory TechnicianSite.fromJson(Map<String, dynamic> json) => TechnicianSite(
        id: json['id'] as int,
        personId: json['personId'] as int,
        technicianName: json['technicianName'] as String?,
        personRole: json['personRole'] as String?,
        regionId: json['regionId'] as int?,
        regionName: json['regionName'] as String?,
        districtId: json['districtId'] as int?,
        districtName: json['districtName'] as String?,
        healthId: json['healthId'] as int?,
        healthName: json['healthName'] as String?,
        niveau: json['niveau'] as String?,
        createdAt: json['createdAt'] as String?,
        updatedAt: json['updatedAt'] as String?,
      );

  /// Détermine le niveau depuis les IDs si le champ niveau est absent
  String get niveauEffectif {
    if (niveau != null && niveau!.isNotEmpty) return niveau!;
    if (healthId != null) return 'SITE';
    if (districtId != null) return 'DISTRICT';
    return 'REGION';
  }

  /// Label lisible du niveau
  String get niveauLabel {
    switch (niveauEffectif) {
      case 'SITE':
        return 'Site de santé';
      case 'DISTRICT':
        return 'District';
      default:
        return 'Région';
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Nœuds de l'arbre hiérarchique
// ─────────────────────────────────────────────────────────────────────────────

class RegionNode {
  final int? regionId;
  final String regionName;
  TechnicianSite? assignment; // assignation région directe
  final List<DistrictNode> districts;

  RegionNode({
    required this.regionId,
    required this.regionName,
    this.assignment,
    List<DistrictNode>? districts,
  }) : districts = districts ?? [];
}

class DistrictNode {
  final int? districtId;
  final String districtName;
  TechnicianSite? assignment; // assignation district directe
  final List<TechnicianSite> sites;

  DistrictNode({
    required this.districtId,
    required this.districtName,
    this.assignment,
    List<TechnicianSite>? sites,
  }) : sites = sites ?? [];
}

/// Construit l'arbre hiérarchique à partir d'une liste plate
List<RegionNode> buildTree(List<TechnicianSite> assignments) {
  final Map<String, RegionNode> regionMap = {};

  for (final a in assignments) {
    final rKey = (a.regionId ?? 'none').toString();
    final rName = a.regionName ?? '(sans région)';

    regionMap.putIfAbsent(
      rKey,
      () => RegionNode(regionId: a.regionId, regionName: rName),
    );
    final region = regionMap[rKey]!;

    if (a.districtId == null && a.healthId == null) {
      region.assignment = a;
      continue;
    }

    final dKey = (a.districtId ?? 'none').toString();
    final dName = a.districtName ?? '(sans district)';

    DistrictNode? distNode;
    try {
      distNode = region.districts.firstWhere(
        (d) => d.districtId?.toString() == dKey,
      );
    } catch (_) {
      distNode = DistrictNode(districtId: a.districtId, districtName: dName);
      region.districts.add(distNode);
    }

    if (a.healthId == null) {
      distNode.assignment = a;
    } else {
      distNode.sites.add(a);
    }
  }

  return regionMap.values.toList();
}
