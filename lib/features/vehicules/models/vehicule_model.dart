// lib/features/vehicules/models/vehicule_model.dart

// ── Véhicule principal ────────────────────────────────────────────────────────
class VehiculeModel {
  final int id;
  final String immatriculation;
  final String type; // VOITURE | MOTO | CAMION | MINIBUS | AUTRE
  final String? marque;
  final String? modele;
  final String? couleur;
  final String
      statut; // DISPONIBLE | EN_MISSION | EN_PANNE | EN_MAINTENANCE | RETIRE
  final String? dateAcquisition;
  final int? kilometrage;
  final String? numeroCarteGrise;
  final String? observations;

  // ── Documents ──────────────────────────────────────────────────────────────
  final String? dateFinAssurance;
  final String? dateFinVisiteTechnique;
  final String? dateFinVignette;
  final bool assuranceExpiree;
  final bool assuranceBientotExpiree;
  final bool visiteTechniqueExpiree;
  final bool visiteTechniqueBientotExpiree;
  final bool vignetteExpiree;
  final bool vignetteBientotExpiree;

  // ── Affectation ────────────────────────────────────────────────────────────
  final String? conducteurNom;
  final String? conducteurActifNom;

  // ── Localisation ──────────────────────────────────────────────────────────
  final int? regionId;
  final String? regionName;
  final int? districtId;
  final String? districtName;

  const VehiculeModel({
    required this.id,
    required this.immatriculation,
    required this.type,
    required this.statut,
    this.marque,
    this.modele,
    this.couleur,
    this.dateAcquisition,
    this.kilometrage,
    this.numeroCarteGrise,
    this.observations,
    this.dateFinAssurance,
    this.dateFinVisiteTechnique,
    this.dateFinVignette,
    this.assuranceExpiree = false,
    this.assuranceBientotExpiree = false,
    this.visiteTechniqueExpiree = false,
    this.visiteTechniqueBientotExpiree = false,
    this.vignetteExpiree = false,
    this.vignetteBientotExpiree = false,
    this.conducteurNom,
    this.conducteurActifNom,
    this.regionId,
    this.regionName,
    this.districtId,
    this.districtName,
  });

  // ── Helpers ─────────────────────────────────────────────────────────────────
  bool get hasAlert =>
      assuranceExpiree ||
      assuranceBientotExpiree ||
      visiteTechniqueExpiree ||
      visiteTechniqueBientotExpiree ||
      vignetteExpiree ||
      vignetteBientotExpiree;

  bool get hasExpiredDoc =>
      assuranceExpiree || visiteTechniqueExpiree || vignetteExpiree;

  String get conducteur => conducteurActifNom ?? conducteurNom ?? '—';

  List<String> get alertesDocs {
    final list = <String>[];
    if (assuranceExpiree)
      list.add('Assurance expirée');
    else if (assuranceBientotExpiree) list.add('Assurance bientôt');
    if (visiteTechniqueExpiree)
      list.add('Visite expirée');
    else if (visiteTechniqueBientotExpiree) list.add('Visite bientôt');
    if (vignetteExpiree)
      list.add('Vignette expirée');
    else if (vignetteBientotExpiree) list.add('Vignette bientôt');
    return list;
  }

  factory VehiculeModel.fromJson(Map<String, dynamic> j) => VehiculeModel(
        id: j['id'] as int? ?? 0,
        immatriculation: j['immatriculation'] as String? ?? '',
        type: j['type'] as String? ?? 'AUTRE',
        statut: j['statut'] as String? ?? 'DISPONIBLE',
        marque: j['marque'] as String?,
        modele: j['modele'] as String?,
        couleur: j['couleur'] as String?,
        dateAcquisition: j['dateAcquisition'] as String?,
        kilometrage: (j['kilometrage'] as num?)?.toInt(),
        numeroCarteGrise: j['numeroCarteGrise'] as String?,
        observations: j['observations'] as String?,
        dateFinAssurance: j['dateFinAssurance'] as String?,
        dateFinVisiteTechnique: j['dateFinVisiteTechnique'] as String?,
        dateFinVignette: j['dateFinVignette'] as String?,
        assuranceExpiree: j['assuranceExpiree'] as bool? ?? false,
        assuranceBientotExpiree: j['assuranceBientotExpiree'] as bool? ?? false,
        visiteTechniqueExpiree: j['visiteTechniqueExpiree'] as bool? ?? false,
        visiteTechniqueBientotExpiree:
            j['visiteTechniqueBientotExpiree'] as bool? ?? false,
        vignetteExpiree: j['vignetteExpiree'] as bool? ?? false,
        vignetteBientotExpiree: j['vignetteBientotExpiree'] as bool? ?? false,
        conducteurNom: j['conducteurNom'] as String?,
        conducteurActifNom: j['conducteurActifNom'] as String?,
        regionId: (j['regionId'] as num?)?.toInt(),
        regionName: j['regionName'] as String?,
        districtId: (j['districtId'] as num?)?.toInt(),
        districtName: j['districtName'] as String?,
      );
}

// ── Incident ─────────────────────────────────────────────────────────────────
class VehiculeIncidentModel {
  final int id;
  final int vehiculeId;
  final String immatriculation;
  final String vehiculeType;
  final String dateIncident;
  final String typeIncident; // ACCIDENT | PANNE | VOL | AUTRE
  final String statut; // EN_ATTENTE | EN_COURS | RESOLU
  final String? description;
  final String? lieuIncident;
  final String? signalePar;
  final double? coutEstime;

  const VehiculeIncidentModel({
    required this.id,
    required this.vehiculeId,
    required this.immatriculation,
    required this.vehiculeType,
    required this.dateIncident,
    required this.typeIncident,
    required this.statut,
    this.description,
    this.lieuIncident,
    this.signalePar,
    this.coutEstime,
  });

  factory VehiculeIncidentModel.fromJson(Map<String, dynamic> j) =>
      VehiculeIncidentModel(
        id: j['id'] as int? ?? 0,
        vehiculeId: j['vehiculeId'] as int? ?? 0,
        immatriculation: j['immatriculation'] as String? ?? '',
        vehiculeType: j['vehiculeType'] as String? ?? '',
        dateIncident: j['dateIncident'] as String? ?? '',
        typeIncident: j['typeIncident'] as String? ?? '',
        statut: j['statut'] as String? ?? '',
        description: j['description'] as String?,
        lieuIncident: j['lieuIncident'] as String?,
        signalePar: j['signalePar'] as String?,
        coutEstime: (j['coutEstime'] as num?)?.toDouble(),
      );
}

// ── Maintenance ───────────────────────────────────────────────────────────────
class VehiculeMaintenanceModel {
  final int id;
  final int vehiculeId;
  final String immatriculation;
  final String dateMaintenance;
  final String typeMaintenance; // PREVENTIVE | CURATIVE
  final String statut; // PLANIFIEE | EN_COURS | TERMINEE
  final String? description;
  final String? prestataire;
  final double? coutReel;
  final int? kilometrageIntervention;

  const VehiculeMaintenanceModel({
    required this.id,
    required this.vehiculeId,
    required this.immatriculation,
    required this.dateMaintenance,
    required this.typeMaintenance,
    required this.statut,
    this.description,
    this.prestataire,
    this.coutReel,
    this.kilometrageIntervention,
  });

  factory VehiculeMaintenanceModel.fromJson(Map<String, dynamic> j) =>
      VehiculeMaintenanceModel(
        id: j['id'] as int? ?? 0,
        vehiculeId: j['vehiculeId'] as int? ?? 0,
        immatriculation: j['immatriculation'] as String? ?? '',
        dateMaintenance: j['dateMaintenance'] as String? ?? '',
        typeMaintenance: j['typeMaintenance'] as String? ?? '',
        statut: j['statut'] as String? ?? '',
        description: j['description'] as String?,
        prestataire: j['prestataire'] as String?,
        coutReel: (j['coutReel'] as num?)?.toDouble(),
        kilometrageIntervention:
            (j['kilometrageIntervention'] as num?)?.toInt(),
      );
}

// ── Affectation ───────────────────────────────────────────────────────────────
class VehiculeAffectationModel {
  final int id;
  final int vehiculeId;
  final String immatriculation;
  final String vehiculeType;
  final String personNom;
  final String? personPoste;
  final String dateAffectation;
  final String? dateRetour;
  final String? motif;
  final String? regionName;
  final String? districtName;
  final bool active;

  const VehiculeAffectationModel({
    required this.id,
    required this.vehiculeId,
    required this.immatriculation,
    required this.vehiculeType,
    required this.personNom,
    required this.dateAffectation,
    required this.active,
    this.personPoste,
    this.dateRetour,
    this.motif,
    this.regionName,
    this.districtName,
  });

  factory VehiculeAffectationModel.fromJson(Map<String, dynamic> j) =>
      VehiculeAffectationModel(
        id: j['id'] as int? ?? 0,
        vehiculeId: j['vehiculeId'] as int? ?? 0,
        immatriculation: j['immatriculation'] as String? ?? '',
        vehiculeType: j['vehiculeType'] as String? ?? '',
        personNom: j['personNom'] as String? ?? '',
        personPoste: j['personPoste'] as String?,
        dateAffectation: j['dateAffectation'] as String? ?? '',
        dateRetour: j['dateRetour'] as String?,
        motif: j['motif'] as String?,
        regionName: j['regionName'] as String?,
        districtName: j['districtName'] as String?,
        active: j['active'] as bool? ?? false,
      );
}

// ── Alerte document ───────────────────────────────────────────────────────────
class VehiculeAlerteModel {
  final int id;
  final String immatriculation;
  final String vehiculeType;
  final String typeAlerte; // ASSURANCE | VISITE_TECHNIQUE | VIGNETTE
  final String niveau; // EXPIRE | BIENTOT
  final String dateExpiration;
  final int joursRestants;

  const VehiculeAlerteModel({
    required this.id,
    required this.immatriculation,
    required this.vehiculeType,
    required this.typeAlerte,
    required this.niveau,
    required this.dateExpiration,
    required this.joursRestants,
  });

  bool get isExpire => niveau == 'EXPIRE';

  factory VehiculeAlerteModel.fromJson(Map<String, dynamic> j) =>
      VehiculeAlerteModel(
        id: j['id'] as int? ?? 0,
        immatriculation: j['immatriculation'] as String? ?? '',
        vehiculeType: j['vehiculeType'] as String? ?? '',
        typeAlerte: j['typeAlerte'] as String? ?? '',
        niveau: j['niveau'] as String? ?? '',
        dateExpiration: j['dateExpiration'] as String? ?? '',
        joursRestants: (j['joursRestants'] as num?)?.toInt() ?? 0,
      );
}
