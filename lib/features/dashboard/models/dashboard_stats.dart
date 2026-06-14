// lib/features/dashboard/models/dashboard_stats.dart

class DashboardStats {
  // ── Équipements ────────────────────────────────────────────────────────────
  final int deploymentsTotal;
  final int deploymentsBrouillon;
  final int deploymentsEnCours;
  final int deploymentsLivres;
  final int interventionsTotal;
  final int interventionsEnLigne;
  final int interventionsSurSite;
  final int interventionsEnAttente;
  final int acquisitionsTotal;
  final int acquisitionsDisponibles;
  final int acquisitionsDeployees;
  final int acquisitionsEnPanne;
  final int sitesTotal;
  final int archivesTotal;

  // ── Logistique ─────────────────────────────────────────────────────────────
  final int vehiculesTotal;
  final int vehiculesDisponibles;
  final int vehiculesEnMission;
  final int vehiculesEnPanne;
  final int vehiculesAlertes;
  final int fournituresTotal;
  final int fournituresDisponibles;
  final int fournituresDeployees;
  final int fournituresEnRupture;

  const DashboardStats({
    this.deploymentsTotal = 0,
    this.deploymentsBrouillon = 0,
    this.deploymentsEnCours = 0,
    this.deploymentsLivres = 0,
    this.interventionsTotal = 0,
    this.interventionsEnLigne = 0,
    this.interventionsSurSite = 0,
    this.interventionsEnAttente = 0,
    this.acquisitionsTotal = 0,
    this.acquisitionsDisponibles = 0,
    this.acquisitionsDeployees = 0,
    this.acquisitionsEnPanne = 0,
    this.sitesTotal = 0,
    this.archivesTotal = 0,
    this.vehiculesTotal = 0,
    this.vehiculesDisponibles = 0,
    this.vehiculesEnMission = 0,
    this.vehiculesEnPanne = 0,
    this.vehiculesAlertes = 0,
    this.fournituresTotal = 0,
    this.fournituresDisponibles = 0,
    this.fournituresDeployees = 0,
    this.fournituresEnRupture = 0,
  });

  factory DashboardStats.empty() => const DashboardStats();
}

// ── Modèle Déploiement ────────────────────────────────────────────────────────
class DeploymentItem {
  final int id;
  final String codeDep;
  final String? healthName;
  final String? regionName;
  final String? districtName;
  final String? dateRecept;
  final String? appName;
  final String statut;

  const DeploymentItem({
    required this.id,
    required this.codeDep,
    this.healthName,
    this.regionName,
    this.districtName,
    this.dateRecept,
    this.appName,
    this.statut = 'BROUILLON',
  });

  factory DeploymentItem.fromJson(Map<String, dynamic> json) => DeploymentItem(
        id: json['id'] as int,
        codeDep: (json['codeDep'] as String?) ?? '',
        // ✅ Vrais champs API
        healthName:
            json['healthDeploy'] as String? ?? json['healthName'] as String?,
        regionName:
            json['regionDeploy'] as String? ?? json['regionName'] as String?,
        districtName: json['districtDeploy'] as String? ??
            json['districtName'] as String?,
        dateRecept: json['dateRecep'] as String? ??
            json['dateRecept'] as String? ??
            json['dateReception'] as String? ??
            json['createdAt'] as String?,
        appName: json['appsDeploy'] as String? ?? json['appName'] as String?,
        statut: (json['statut'] as String?) ?? 'BROUILLON',
      );
}

// ── Modèle Intervention ───────────────────────────────────────────────────────
class InterventionItem {
  final int id;
  final String codeInter;
  final String? typeInter;
  final String? actionInter;
  final String? healthName;
  final String? dateIntervention;
  final String? technicianName;
  final bool enAttenteMaintenance;

  const InterventionItem({
    required this.id,
    required this.codeInter,
    this.typeInter,
    this.actionInter,
    this.healthName,
    this.dateIntervention,
    this.technicianName,
    this.enAttenteMaintenance = false,
  });

  factory InterventionItem.fromJson(Map<String, dynamic> json) =>
      InterventionItem(
        id: json['id'] as int,
        codeInter: (json['codeInter'] as String?) ?? '',
        typeInter: json['typeInter'] as String?,
        actionInter: json['actionInter'] as String? ??
            json['action'] as String? ??
            json['description'] as String?,
        healthName:
            json['healthName'] as String? ?? json['siteName'] as String?,
        dateIntervention: json['dateIntervention'] as String? ??
            json['dateInter'] as String? ??
            json['createdAt'] as String?,
        technicianName:
            json['technicianName'] as String? ?? json['techName'] as String?,
        enAttenteMaintenance: (json['enAttenteMaintenance'] as bool?) ?? false,
      );
}

// ── Modèle Acquisition ────────────────────────────────────────────────────────
class AcquisitionItem {
  final int id;
  final String? tag;
  final String? serial;
  final String? typeName;
  final String? status;
  final String? dateAcq;
  final bool deployed;

  const AcquisitionItem({
    required this.id,
    this.tag,
    this.serial,
    this.typeName,
    this.status,
    this.dateAcq,
    required this.deployed,
  });

  factory AcquisitionItem.fromJson(Map<String, dynamic> json) =>
      AcquisitionItem(
        id: json['id'] as int,
        // ✅ Cascade tag : tag → codeTag → code
        tag: json['tag'] as String? ??
            json['codeTag'] as String? ??
            json['code'] as String?,
        // ✅ Cascade serial : serial → numeroSerie → serialNumber → numSerie
        serial: json['serial'] as String? ??
            json['numeroSerie'] as String? ??
            json['serialNumber'] as String? ??
            json['numSerie'] as String?,
        // ✅ Cascade typeName : Type (API réelle) → typeName → typeEquipement → type
        typeName: json['Type'] as String? ??
            json['typeName'] as String? ??
            json['typeEquipement'] as String? ??
            json['type'] as String?,
        // ✅ Cascade status : status → statut
        status: json['status'] as String? ?? json['statut'] as String?,
        // ✅ Cascade dateAcq : dateAcq → dateAcquisition → createdAt
        dateAcq: json['dateAcq'] as String? ??
            json['dateAcquisition'] as String? ??
            json['createdAt'] as String?,
        deployed: (json['deployed'] as bool?) ??
            (json['status'] == 'DEPLOYE' || json['statut'] == 'DEPLOYE'),
      );
}

// ── Modèle Alerte Véhicule ────────────────────────────────────────────────────
class VehiculeAlerteItem {
  final int id;
  final String immatriculation;
  final String typeAlerte;
  final String niveau;
  final int joursRestants;

  const VehiculeAlerteItem({
    required this.id,
    required this.immatriculation,
    required this.typeAlerte,
    required this.niveau,
    required this.joursRestants,
  });

  bool get isExpire => niveau == 'EXPIRE';

  factory VehiculeAlerteItem.fromJson(Map<String, dynamic> json) =>
      VehiculeAlerteItem(
        id: (json['id'] as num?)?.toInt() ?? 0,
        immatriculation: json['immatriculation'] as String? ??
            json['matricule'] as String? ??
            '',
        typeAlerte:
            json['typeAlerte'] as String? ?? json['type'] as String? ?? '',
        niveau: json['niveau'] as String? ?? json['level'] as String? ?? '',
        joursRestants: (json['joursRestants'] as num?)?.toInt() ??
            (json['jours'] as num?)?.toInt() ??
            0,
      );
}
