// lib/features/dashboard/services/dashboard_service.dart
import '../../../core/api/dio_client.dart';
import '../../../core/api/api_constants.dart';
import '../models/dashboard_stats.dart';

class DashboardService {
  static final DashboardService _instance = DashboardService._internal();
  factory DashboardService() => _instance;
  DashboardService._internal();

  final DioClient _dio = DioClient();

  Future<DashboardStats> getStats() async {
    try {
      final results = await Future.wait([
        _getPageData(ApiConstants.DEPLOYMENTS),
        _getPageData(ApiConstants.INTERVENTIONS),
        _getPageData(ApiConstants.ACQUISITIONS, size: 200),
        _getTotal(ApiConstants.HEALTHS),
        _getTotal(ApiConstants.ARCHIVES),
        _getPageData(ApiConstants.VEHICULES, size: 200),
        _getFournituresStats(),
        _getVehiculesAlertes(),
      ]);

      final deps = results[0] as List<Map<String, dynamic>>;
      final inters = results[1] as List<Map<String, dynamic>>;
      final acqs = results[2] as List<Map<String, dynamic>>;
      final sites = results[3] as int;
      final archives = results[4] as int;
      final vehs = results[5] as List<Map<String, dynamic>>;
      final fStats = results[6] as Map<String, int>;
      final alerts = results[7] as int;

      // ✅ Statut déploiement déduit depuis dateRecep (pas de champ statut dans l'API)
      final depLivres = deps.where((d) {
        final date = d['dateRecep'] as String?;
        return date != null && date.isNotEmpty;
      }).length;
      final depBrouillon = deps.where((d) {
        final date = d['dateRecep'] as String?;
        return date == null || date.isEmpty;
      }).length;
      const depEnCours = 0; // pas de statut EN_COURS dans l'API actuelle

      final interEnLigne =
          inters.where((i) => i['typeInter'] == 'EN_LIGNE').length;
      final interSurSite =
          inters.where((i) => i['typeInter'] == 'SUR_SITE').length;
      final interEnAttente = inters
          .where((i) => (i['enAttenteMaintenance'] as bool?) == true)
          .length;

      // ✅ Filtre status ET statut pour couvrir les deux conventions API
      final acqDispo = acqs
          .where(
              (a) => a['status'] == 'DISPONIBLE' || a['statut'] == 'DISPONIBLE')
          .length;
      final acqDeploy = acqs
          .where((a) =>
              a['status'] == 'DEPLOYE' ||
              a['statut'] == 'DEPLOYE' ||
              (a['deployed'] as bool?) == true)
          .length;
      // ✅ NON_FONCTIONNEL = EN_PANNE dans le web
      final acqPanne = acqs
          .where((a) =>
              a['status'] == 'EN_PANNE' ||
              a['status'] == 'NON_FONCTIONNEL' ||
              a['statut'] == 'EN_PANNE' ||
              a['statut'] == 'NON_FONCTIONNEL')
          .length;

      final vehDispo = vehs
          .where(
              (v) => v['statut'] == 'DISPONIBLE' || v['status'] == 'DISPONIBLE')
          .length;
      final vehMission = vehs
          .where(
              (v) => v['statut'] == 'EN_MISSION' || v['status'] == 'EN_MISSION')
          .length;
      final vehPanne = vehs
          .where((v) => v['statut'] == 'EN_PANNE' || v['status'] == 'EN_PANNE')
          .length;

      return DashboardStats(
        deploymentsTotal: deps.length,
        deploymentsBrouillon: depBrouillon,
        deploymentsEnCours: depEnCours,
        deploymentsLivres: depLivres,
        interventionsTotal: inters.length,
        interventionsEnLigne: interEnLigne,
        interventionsSurSite: interSurSite,
        interventionsEnAttente: interEnAttente,
        acquisitionsTotal: acqs.length,
        acquisitionsDisponibles: acqDispo,
        acquisitionsDeployees: acqDeploy,
        acquisitionsEnPanne: acqPanne,
        sitesTotal: sites,
        archivesTotal: archives,
        vehiculesTotal: vehs.length,
        vehiculesDisponibles: vehDispo,
        vehiculesEnMission: vehMission,
        vehiculesEnPanne: vehPanne,
        vehiculesAlertes: alerts,
        fournituresTotal: fStats['total'] ?? 0,
        fournituresDisponibles: fStats['disponibles'] ?? 0,
        fournituresDeployees: fStats['deployes'] ?? 0,
        fournituresEnRupture: fStats['enRupture'] ?? 0,
      );
    } catch (e) {
      return DashboardStats.empty();
    }
  }

  Future<List<DeploymentItem>> getRecentDeployments({int size = 5}) async {
    try {
      final r = await _dio.get(ApiConstants.DEPLOYMENTS,
          params: {'page': 0, 'size': size, 'sort': 'id,desc'});
      return _extractList(r.data)
          .map((e) => DeploymentItem.fromJson(e))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<InterventionItem>> getRecentInterventions({int size = 5}) async {
    try {
      final r = await _dio.get(ApiConstants.INTERVENTIONS,
          params: {'page': 0, 'size': size, 'sort': 'id,desc'});
      return _extractList(r.data)
          .map((e) => InterventionItem.fromJson(e))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<AcquisitionItem>> getRecentAcquisitions({int size = 5}) async {
    try {
      final r = await _dio.get(ApiConstants.ACQUISITIONS,
          params: {'page': 0, 'size': size, 'sort': 'id,desc'});
      return _extractList(r.data)
          .map((e) => AcquisitionItem.fromJson(e))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<VehiculeAlerteItem>> getVehiculeAlertes({int size = 5}) async {
    try {
      final r = await _dio
          .get(ApiConstants.ALERTES_VEHICULES, params: {'joursAvance': 30});
      final data = r.data['data'];
      if (data is List) {
        return data
            .take(size)
            .map((e) => VehiculeAlerteItem.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<List<AcquisitionItem>> getAcquisitionsEnPanne({int size = 5}) async {
    try {
      // Tentative 1 — filtre via 'status'
      final r = await _dio.get(ApiConstants.ACQUISITIONS,
          params: {'page': 0, 'size': 50, 'status': 'NON_FONCTIONNEL'});
      final all =
          _extractList(r.data).map((e) => AcquisitionItem.fromJson(e)).toList();

      // ✅ Filtre Flutter — couvre EN_PANNE et NON_FONCTIONNEL
      final enPanne = all
          .where((a) => a.status == 'EN_PANNE' || a.status == 'NON_FONCTIONNEL')
          .take(size)
          .toList();

      if (enPanne.isNotEmpty) return enPanne;

      // Tentative 2 — filtre EN_PANNE
      final r2 = await _dio.get(ApiConstants.ACQUISITIONS,
          params: {'page': 0, 'size': 50, 'status': 'EN_PANNE'});
      final all2 = _extractList(r2.data)
          .map((e) => AcquisitionItem.fromJson(e))
          .toList();

      return all2
          .where((a) => a.status == 'EN_PANNE' || a.status == 'NON_FONCTIONNEL')
          .take(size)
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ── Privées ──────────────────────────────────────────────────────────────────

  Future<int> _getTotal(String endpoint) async {
    try {
      final r = await _dio.get(endpoint, params: {'page': 0, 'size': 1});
      final raw = r.data;
      if (raw is Map) {
        final d = raw['data'];
        if (d is Map) {
          final p = d['page'];
          if (p is Map && p['totalElements'] != null) {
            return (p['totalElements'] as num).toInt();
          }
          if (d['totalElements'] != null) {
            return (d['totalElements'] as num).toInt();
          }
        }
        if (raw['totalElements'] != null) {
          return (raw['totalElements'] as num).toInt();
        }
      }
      return _extractList(raw).length;
    } catch (_) {
      return 0;
    }
  }

  Future<List<Map<String, dynamic>>> _getPageData(String endpoint,
      {int size = 100}) async {
    try {
      final r = await _dio.get(endpoint, params: {'page': 0, 'size': size});
      return _extractList(r.data);
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, int>> _getFournituresStats() async {
    try {
      final r = await _dio.get(ApiConstants.FOURNITURES_STATS);
      final raw = r.data;
      final data = (raw is Map && raw['data'] is Map)
          ? raw['data'] as Map
          : (raw is Map ? raw : <String, dynamic>{});
      return {
        'total': _firstInt(
                data, ['total', 'totalArticles', 'count', 'nbArticles']) ??
            0,
        'disponibles':
            _firstInt(data, ['disponibles', 'nbDisponibles', 'disponible']) ??
                0,
        'deployes':
            _firstInt(data, ['deployes', 'nbDeployes', 'deployed']) ?? 0,
        'enRupture': _firstInt(
                data, ['enRupture', 'rupture', 'nbRupture', 'stockZero']) ??
            0,
      };
    } catch (e) {
      return {};
    }
  }

  Future<int> _getVehiculesAlertes() async {
    try {
      final r = await _dio
          .get(ApiConstants.ALERTES_VEHICULES, params: {'joursAvance': 30});
      final data = r.data['data'];
      if (data is List) return data.length;
      return 0;
    } catch (_) {
      return 0;
    }
  }

  List<Map<String, dynamic>> _extractList(dynamic raw) {
    try {
      if (raw is Map) {
        // Format A — {"data": {"content": [...]}}
        if (raw['data'] is Map && raw['data']['content'] is List) {
          return (raw['data']['content'] as List).cast<Map<String, dynamic>>();
        }
        // Format B — {"content": [...]}
        if (raw['content'] is List) {
          return (raw['content'] as List).cast<Map<String, dynamic>>();
        }
        // Format D — {"data": [...]}
        if (raw['data'] is List) {
          return (raw['data'] as List).cast<Map<String, dynamic>>();
        }
        // Format E
        for (final key in ['items', 'list', 'records', 'results', 'payload']) {
          if (raw[key] is List) {
            return (raw[key] as List).cast<Map<String, dynamic>>();
          }
        }
      }
      // Format C — [...]
      if (raw is List) {
        return raw.cast<Map<String, dynamic>>();
      }
    } catch (_) {}
    return [];
  }

  int? _firstInt(Map data, List<String> keys) {
    for (final k in keys) {
      final v = data[k];
      if (v != null) return (v as num).toInt();
    }
    return null;
  }
}
