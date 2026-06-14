// lib/features/fournitures/models/fourniture_model.dart

class FournitureModel {
  final int id;
  final String code;
  final String designation;
  final String
      categorie; // INFORMATIQUE|MOBILIER|PAPETERIE|BUREAUTIQUE|ELECTROMENAGER|AUTRE
  final int quantite;
  final int quantiteDisponible;
  final int quantiteDeployee;
  final String? unite;
  final String? fournisseur;
  final double? prixUnitaire;
  final String statut; // DISPONIBLE|DEPLOYE|EN_RUPTURE

  const FournitureModel({
    required this.id,
    required this.code,
    required this.designation,
    required this.categorie,
    required this.quantite,
    required this.quantiteDisponible,
    required this.quantiteDeployee,
    required this.statut,
    this.unite,
    this.fournisseur,
    this.prixUnitaire,
  });

  bool get isEnRupture => statut == 'EN_RUPTURE';
  bool get isDisponible => statut == 'DISPONIBLE';

  factory FournitureModel.fromJson(Map<String, dynamic> j) => FournitureModel(
        id: j['id'] as int? ?? 0,
        code: j['code'] as String? ?? '',
        designation: j['designation'] as String? ?? '',
        categorie: j['categorie'] as String? ?? 'AUTRE',
        quantite: (j['quantite'] as num?)?.toInt() ?? 0,
        quantiteDisponible: (j['quantiteDisponible'] as num?)?.toInt() ?? 0,
        quantiteDeployee: (j['quantiteDeployee'] as num?)?.toInt() ?? 0,
        unite: j['unite'] as String?,
        fournisseur: j['fournisseur'] as String?,
        prixUnitaire: (j['prixUnitaire'] as num?)?.toDouble(),
        statut: j['statut'] as String? ?? 'DISPONIBLE',
      );
}

class FournitureDeploiementModel {
  final int id;
  final int fournitureId;
  final String fournitureCode;
  final String fournitureDesignation;
  final String fournitureCategorie;
  final String? beneficiaireNom;
  final String? beneficiairePoste;
  final int quantiteDeployee;
  final String dateDeploiement;
  final String? motif;
  final String? regionName;
  final String? districtName;
  final bool active;

  const FournitureDeploiementModel({
    required this.id,
    required this.fournitureId,
    required this.fournitureCode,
    required this.fournitureDesignation,
    required this.fournitureCategorie,
    required this.quantiteDeployee,
    required this.dateDeploiement,
    required this.active,
    this.beneficiaireNom,
    this.beneficiairePoste,
    this.motif,
    this.regionName,
    this.districtName,
  });

  factory FournitureDeploiementModel.fromJson(Map<String, dynamic> j) =>
      FournitureDeploiementModel(
        id: j['id'] as int? ?? 0,
        fournitureId: j['fournitureId'] as int? ?? 0,
        fournitureCode: j['fournitureCode'] as String? ?? '',
        fournitureDesignation: j['fournitureDesignation'] as String? ?? '',
        fournitureCategorie: j['fournitureCategorie'] as String? ?? '',
        beneficiaireNom: j['beneficiaireNom'] as String?,
        beneficiairePoste: j['beneficiairePoste'] as String?,
        quantiteDeployee: (j['quantiteDeployee'] as num?)?.toInt() ?? 0,
        dateDeploiement: j['dateDeploiement'] as String? ?? '',
        motif: j['motif'] as String?,
        regionName: j['regionName'] as String?,
        districtName: j['districtName'] as String?,
        active: j['active'] as bool? ?? false,
      );
}

class FournitureStats {
  final int total;
  final int disponibles;
  final int deployes;
  final int enRupture;
  final int totalDeploiements;
  final int mobilier;
  final int papeterie;
  final int bureautique;
  final int electromenager;
  final int informatique;

  const FournitureStats({
    required this.total,
    required this.disponibles,
    required this.deployes,
    required this.enRupture,
    required this.totalDeploiements,
    required this.mobilier,
    required this.papeterie,
    required this.bureautique,
    required this.electromenager,
    required this.informatique,
  });

  factory FournitureStats.fromJson(Map<String, dynamic> j) => FournitureStats(
        total: (j['total'] as num?)?.toInt() ?? 0,
        disponibles: (j['disponibles'] as num?)?.toInt() ?? 0,
        deployes: (j['deployes'] as num?)?.toInt() ?? 0,
        enRupture: (j['enRupture'] as num?)?.toInt() ?? 0,
        totalDeploiements: (j['totalDeploiements'] as num?)?.toInt() ?? 0,
        mobilier: (j['mobilier'] as num?)?.toInt() ?? 0,
        papeterie: (j['papeterie'] as num?)?.toInt() ?? 0,
        bureautique: (j['bureautique'] as num?)?.toInt() ?? 0,
        electromenager: (j['electromenager'] as num?)?.toInt() ?? 0,
        informatique: (j['informatique'] as num?)?.toInt() ?? 0,
      );

  factory FournitureStats.empty() => const FournitureStats(
        total: 0,
        disponibles: 0,
        deployes: 0,
        enRupture: 0,
        totalDeploiements: 0,
        mobilier: 0,
        papeterie: 0,
        bureautique: 0,
        electromenager: 0,
        informatique: 0,
      );
}
