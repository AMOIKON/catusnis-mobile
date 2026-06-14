// lib/features/deployments/models/fiche_pdf_models.dart
//
// Modèles EXCLUSIFS au PDF / impression / e-mail.
// Fichier intentionnellement séparé de deployment_model.dart
// pour éviter tout conflit de classes.

class FichePdf {
  final int id;
  final String reference;
  final String statut; // EN_COURS | TERMINE | SUSPENDU
  final DateTime dateDeploiement;
  final DateTime? dateFin;
  final String? observations;
  final FichePdfEquipement equipement;
  final FichePdfSite site;
  final FichePdfDistrict district;
  final FichePdfRegion region;
  final FichePdfUser? technicien;
  final FichePdfUser? logisticien;
  final FichePdfAcquisition? acquisition;

  const FichePdf({
    required this.id,
    required this.reference,
    required this.statut,
    required this.dateDeploiement,
    this.dateFin,
    this.observations,
    required this.equipement,
    required this.site,
    required this.district,
    required this.region,
    this.technicien,
    this.logisticien,
    this.acquisition,
  });

  factory FichePdf.fromJson(Map<String, dynamic> json) => FichePdf(
        id: json['id'] as int,
        reference: json['reference'] as String? ?? 'N/A',
        statut: json['statut'] as String? ?? 'INCONNU',
        dateDeploiement: DateTime.parse(json['dateDeploiement'] as String),
        dateFin: json['dateFin'] != null
            ? DateTime.parse(json['dateFin'] as String)
            : null,
        observations: json['observations'] as String?,
        equipement: FichePdfEquipement.fromJson(
            json['equipement'] as Map<String, dynamic>),
        site: FichePdfSite.fromJson(json['site'] as Map<String, dynamic>),
        district:
            FichePdfDistrict.fromJson(json['district'] as Map<String, dynamic>),
        region: FichePdfRegion.fromJson(json['region'] as Map<String, dynamic>),
        technicien: json['technicien'] != null
            ? FichePdfUser.fromJson(json['technicien'] as Map<String, dynamic>)
            : null,
        logisticien: json['logisticien'] != null
            ? FichePdfUser.fromJson(json['logisticien'] as Map<String, dynamic>)
            : null,
        acquisition: json['acquisition'] != null
            ? FichePdfAcquisition.fromJson(
                json['acquisition'] as Map<String, dynamic>)
            : null,
      );

  // ── Données de démo (id == -1) ────────────────────────────────────────────
  static FichePdf get sample => FichePdf(
        id: 42,
        reference: 'DEPL-2025-0042',
        statut: 'EN_COURS',
        dateDeploiement: DateTime(2025, 4, 15),
        observations:
            "Déploiement effectué sans incident. Équipement opérationnel.",
        equipement: FichePdfEquipement(
          id: 7,
          designation: 'Échographe portable SonoScape S2',
          numeroSerie: 'SS2-ABJ-2025-007',
          marque: 'SonoScape',
          modele: 'S2 Pro',
          categorie: 'Imagerie médicale',
          etat: 'BON',
        ),
        site: FichePdfSite(id: 3, nom: 'Centre de Santé de Yopougon Attié'),
        district:
            FichePdfDistrict(id: 2, nom: 'District Sanitaire de Yopougon'),
        region: FichePdfRegion(id: 1, nom: "Direction Régionale d'Abidjan"),
        technicien: FichePdfUser(
          id: 5,
          nom: 'Koné',
          prenom: 'Mamadou',
          email: 'mkone@catusnis.ci',
          telephone: '+225 07 00 11 22 33',
        ),
        logisticien: FichePdfUser(
          id: 2,
          nom: 'Bamba',
          prenom: 'Aïssatou',
          email: 'abamba@catusnis.ci',
          telephone: '+225 05 44 55 66 77',
        ),
        acquisition: FichePdfAcquisition(
          id: 11,
          reference: 'ACQ-2025-0011',
          fournisseur: "MedEquip Côte d'Ivoire",
          dateAcquisition: DateTime(2025, 2, 20),
          prixUnitaire: 4500000,
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────

class FichePdfEquipement {
  final int id;
  final String designation;
  final String numeroSerie;
  final String marque;
  final String modele;
  final String categorie;
  final String etat;

  const FichePdfEquipement({
    required this.id,
    required this.designation,
    required this.numeroSerie,
    required this.marque,
    required this.modele,
    required this.categorie,
    required this.etat,
  });

  factory FichePdfEquipement.fromJson(Map<String, dynamic> json) =>
      FichePdfEquipement(
        id: json['id'] as int,
        designation: json['designation'] as String? ?? '-',
        numeroSerie: json['numeroSerie'] as String? ?? '-',
        marque: json['marque'] as String? ?? '-',
        modele: json['modele'] as String? ?? '-',
        categorie: json['categorie'] as String? ?? '-',
        etat: json['etat'] as String? ?? 'INCONNU',
      );
}

class FichePdfSite {
  final int id;
  final String nom;
  const FichePdfSite({required this.id, required this.nom});
  factory FichePdfSite.fromJson(Map<String, dynamic> json) =>
      FichePdfSite(id: json['id'] as int, nom: json['nom'] as String);
}

class FichePdfDistrict {
  final int id;
  final String nom;
  const FichePdfDistrict({required this.id, required this.nom});
  factory FichePdfDistrict.fromJson(Map<String, dynamic> json) =>
      FichePdfDistrict(id: json['id'] as int, nom: json['nom'] as String);
}

class FichePdfRegion {
  final int id;
  final String nom;
  const FichePdfRegion({required this.id, required this.nom});
  factory FichePdfRegion.fromJson(Map<String, dynamic> json) =>
      FichePdfRegion(id: json['id'] as int, nom: json['nom'] as String);
}

class FichePdfUser {
  final int id;
  final String nom;
  final String prenom;
  final String email;
  final String? telephone;

  const FichePdfUser({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.email,
    this.telephone,
  });

  String get nomComplet => '$prenom $nom';

  factory FichePdfUser.fromJson(Map<String, dynamic> json) => FichePdfUser(
        id: json['id'] as int,
        nom: json['nom'] as String,
        prenom: json['prenom'] as String,
        email: json['email'] as String,
        telephone: json['telephone'] as String?,
      );
}

class FichePdfAcquisition {
  final int id;
  final String reference;
  final String fournisseur;
  final DateTime dateAcquisition;
  final double prixUnitaire;

  const FichePdfAcquisition({
    required this.id,
    required this.reference,
    required this.fournisseur,
    required this.dateAcquisition,
    required this.prixUnitaire,
  });

  factory FichePdfAcquisition.fromJson(Map<String, dynamic> json) =>
      FichePdfAcquisition(
        id: json['id'] as int,
        reference: json['reference'] as String,
        fournisseur: json['fournisseur'] as String,
        dateAcquisition: DateTime.parse(json['dateAcquisition'] as String),
        prixUnitaire: (json['prixUnitaire'] as num).toDouble(),
      );
}
